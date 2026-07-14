Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ----------------------------
# Config from env
# ----------------------------
$LoginUrl     = $env:SF_LOGIN_URL
$ClientId     = $env:SF_CLIENT_ID
$ClientSecret = $env:SF_CLIENT_SECRET
$RefreshToken = $env:SF_REFRESH_TOKEN
$ApiVersion   = "60.0"

# ----------------------------
# EmailMessage export mode toggle
#   incremental      = normal run + EmailMessage incremental
#   full_partition   = full backup of ALL objects, but EmailMessage exported in partitions
# ----------------------------
$EmailExportMode = ($env:SF_EMAIL_EXPORT_MODE ?? "incremental").ToLowerInvariant()
$EmailFullPartition = ($EmailExportMode -eq "full_partition")

Write-Host "SF_EMAIL_EXPORT_MODE = $EmailExportMode"

# Partition settings (only used when full_partition)
$EmailPartition    = "month"                 # month | week | day
$EmailFullStartUtc = "2025-04-01T00:00:00Z"  # earliest date to baseline from
$EmailDateField    = "MessageDate"           # or "CreatedDate"

$ExcludeObjectRegex = ".*(ChangeEvent|History|Feed|Share|Tag|EventLogFile|LoginHistory|StaticResource|SolutionStatus|RelatedListColumnDefinition|SiteDetail|.*Definition$|.*Setting$|.*Info$|Content.*|Document.*|.*Status$).*"
$MaxObjects = 0

$IncludeFiles = $false
$MaxFileVersions = 0

$AzureConnStr   = $env:AZURE_BACKUP_STORAGE_CONNECTION_STRING
$AzureContainer = $env:SF_BACKUP_AZURE_CONTAINER

if (-not $ClientId -or -not $ClientSecret -or -not $RefreshToken -or -not $AzureConnStr -or -not $AzureContainer) {
  throw "Missing env vars. Need SF_LOGIN_URL, SF_CLIENT_ID, SF_CLIENT_SECRET, SF_REFRESH_TOKEN, AZURE_BACKUP_STORAGE_CONNECTION_STRING, SF_BACKUP_AZURE_CONTAINER."
}

# ----------------------------
# Incremental config (EmailMessage only)
# (used ONLY when mode = incremental)
# ----------------------------
$EmailMessageIncremental = $true
$EmailStateBlobPath = "salesforce-backups/_state/emailmessage.json"
$DefaultLookbackDays = 30
$OverlapMinutes = 10

# ----------------------------
# Azure setup
# ----------------------------
Import-Module Az.Storage -ErrorAction Stop
$azCtx = New-AzStorageContext -ConnectionString $AzureConnStr
New-AzStorageContainer -Name $AzureContainer -Context $azCtx -ErrorAction SilentlyContinue | Out-Null

function AzureUploadFile([string]$localPath, [string]$blobPath, [string]$contentType = $null) {
  $props = $null
  if ($contentType) { $props = @{ ContentType = $contentType } }
  Set-AzStorageBlobContent -Context $azCtx -Container $AzureContainer -File $localPath -Blob $blobPath -Properties $props -Force | Out-Null
}

# ----------------------------
# HTTP client
# ----------------------------
$http = New-Object System.Net.Http.HttpClient
$http.Timeout = [TimeSpan]::FromMinutes(30)

function HttpPostForm([string]$url, [hashtable]$form) {
  Invoke-RestMethod -Method Post -Uri $url -Body $form -ContentType "application/x-www-form-urlencoded"
}

function HttpGetJson([string]$url, [string]$token) {
  $req = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Get, $url)
  $req.Headers.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", $token)
  $resp = $http.SendAsync($req).Result
  $body = $resp.Content.ReadAsStringAsync().Result
  if (-not $resp.IsSuccessStatusCode) { throw "GET failed $($resp.StatusCode): $body" }
  return ($body | ConvertFrom-Json)
}

function HttpPostJson([string]$url, [string]$token, [object]$bodyObj) {
  $req = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Post, $url)
  $req.Headers.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", $token)
  $json = $bodyObj | ConvertTo-Json -Compress
  $req.Content = New-Object System.Net.Http.StringContent($json, [Text.Encoding]::UTF8, "application/json")
  $resp = $http.SendAsync($req).Result
  $body = $resp.Content.ReadAsStringAsync().Result
  if (-not $resp.IsSuccessStatusCode) { throw "POST failed $($resp.StatusCode): $body" }
  return ($body | ConvertFrom-Json)
}

function HttpDownloadToFile([string]$url, [string]$token, [string]$outFile, [hashtable]$extraHeaders = $null) {
  $req = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Get, $url)
  $req.Headers.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", $token)
  if ($extraHeaders) {
    foreach ($k in $extraHeaders.Keys) { $req.Headers.TryAddWithoutValidation($k, $extraHeaders[$k]) | Out-Null }
  }

  $resp = $http.SendAsync($req, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
  if (-not $resp.IsSuccessStatusCode) {
    $body = $resp.Content.ReadAsStringAsync().Result
    throw "Download failed $($resp.StatusCode): $body"
  }

  $stream = $resp.Content.ReadAsStreamAsync().Result
  $fs = [System.IO.File]::Open($outFile, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
  try { $stream.CopyTo($fs) } finally { $fs.Close() }
  return $resp
}

function RestQueryToCsv([string]$soql, [string]$outFile) {
  $url = "$instanceUrl/services/data/v$ApiVersion/query?q=$([Uri]::EscapeDataString($soql))"
  $all = @()
  while ($true) {
    $res = HttpGetJson $url $accessToken
    if ($res.records) { $all += $res.records }
    if ($res.done -eq $true -or -not $res.nextRecordsUrl) { break }
    $url = "$instanceUrl$($res.nextRecordsUrl)"
  }

  if (($all | Measure-Object).Count -eq 0) {
    "" | Out-File -FilePath $outFile -Encoding utf8
    return
  }

  $clean = $all | ForEach-Object {
    $_.PSObject.Properties.Remove("attributes") | Out-Null
    $_
  }

  $clean | Export-Csv -Path $outFile -NoTypeInformation -Encoding UTF8
}

# ----------------------------
# Helpers
# ----------------------------
function IsoZ([datetime]$dt) { $dt.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ") }
function ParseIsoZ([string]$s) { [datetime]::Parse($s).ToUniversalTime() }

function Get-TimeWindows([datetime]$startUtc, [datetime]$endUtc, [string]$grain) {
  $wins = @()
  $cur = $startUtc
  while ($cur -lt $endUtc) {
    $next = switch ($grain) {
      "day"   { $cur.AddDays(1) }
      "week"  { $cur.AddDays(7) }
      default { $cur.AddMonths(1) }
    }
    if ($next -gt $endUtc) { $next = $endUtc }
    $wins += ,@($cur, $next)
    $cur = $next
  }
  return $wins
}

# ----------------------------
# OAuth refresh token flow
# ----------------------------
Write-Host "Getting access token via refresh_token..."
$tokenResp = HttpPostForm "$LoginUrl/services/oauth2/token" @{
  grant_type    = "refresh_token"
  client_id     = $ClientId
  client_secret = $ClientSecret
  refresh_token = $RefreshToken
}

$accessToken = $tokenResp.access_token
$instanceUrl = $tokenResp.instance_url.TrimEnd("/")

# ----------------------------
# Work folder
# ----------------------------
$runDate = (Get-Date).ToString("yyyy-MM-dd")
$basePrefix = if ($env:SF_BACKUP_PREFIX) { $env:SF_BACKUP_PREFIX.TrimEnd('/') } else { "salesforce-backups/daily/$runDate" }
$tempRoot = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { $env:TEMP }
$workRoot = Join-Path $tempRoot "sf_backup_$runDate"
New-Item -ItemType Directory -Path $workRoot -Force | Out-Null

$runStartUtc = (Get-Date).ToUniversalTime()
$runUntilIso = IsoZ $runStartUtc

function Load-EmailState() {
  $tmp = Join-Path $workRoot "emailmessage_state.json"
  try {
    Get-AzStorageBlobContent -Context $azCtx -Container $AzureContainer -Blob $EmailStateBlobPath -Destination $tmp -Force -ErrorAction Stop | Out-Null
    return (Get-Content $tmp -Raw -Encoding UTF8 | ConvertFrom-Json)
  }
  catch {
    return [pscustomobject]@{ last_successful_utc = $null }
  }
  finally {
    if (Test-Path $tmp) { Remove-Item $tmp -Force }
  }
}

function Save-EmailState([string]$lastSuccessfulUtc) {
  $tmp = Join-Path $workRoot "emailmessage_state.json"
  ([pscustomobject]@{ last_successful_utc = $lastSuccessfulUtc } | ConvertTo-Json) | Out-File -FilePath $tmp -Encoding utf8
  AzureUploadFile $tmp $EmailStateBlobPath "application/json"
  Remove-Item $tmp -Force
}

$emailState = Load-EmailState

Write-Host "Disk free before run:"
Get-PSDrive -PSProvider FileSystem | Format-Table Name,Used,Free -Auto

# ----------------------------
# Bulk API helpers
# ----------------------------
function BulkNewQueryJob([string]$soql) {
  $url = "$instanceUrl/services/data/v$ApiVersion/jobs/query"
  (HttpPostJson $url $accessToken @{ operation="query"; query=$soql; contentType="CSV" }).id
}

function BulkGetJob([string]$jobId) {
  HttpGetJson "$instanceUrl/services/data/v$ApiVersion/jobs/query/$jobId" $accessToken
}

function BulkWaitComplete([string]$jobId, [int]$timeoutSec = 1800) {
  $start = Get-Date
  while ($true) {
    $job = BulkGetJob $jobId
    if ($job.state -in @("JobComplete","Failed","Aborted")) { return $job }
    if ((New-TimeSpan -Start $start -End (Get-Date)).TotalSeconds -gt $timeoutSec) { throw "Bulk job timeout: $jobId" }
    Start-Sleep -Seconds 5
  }
}

function BulkDownloadResultsCsv([string]$jobId, [string]$outFile) {
  if (Test-Path $outFile) { Remove-Item $outFile -Force }

  $base = "$instanceUrl/services/data/v$ApiVersion/jobs/query/$jobId/results"
  $locator = $null
  $first = $true

  while ($true) {
    $url = if ([string]::IsNullOrWhiteSpace($locator)) { $base } else { "${base}?locator=$([Uri]::EscapeDataString($locator))" }

    $tmp = "$outFile.part"
    $resp = HttpDownloadToFile $url $accessToken $tmp @{ "Accept" = "text/csv" }

    $loc = $null
    try { $loc = ($resp.Headers.GetValues("Sforce-Locator") | Select-Object -First 1) } catch { $loc = $null }

    if ($first) {
      Move-Item $tmp $outFile -Force
      $first = $false
    } else {
      $lines = Get-Content -Path $tmp -Encoding UTF8
      if ($lines.Count -gt 1) { $lines[1..($lines.Count-1)] | Add-Content -Path $outFile -Encoding UTF8 }
      Remove-Item $tmp -Force
    }

    if ([string]::IsNullOrWhiteSpace($loc) -or $loc -eq "null" -or $loc -eq "0") { break }
    $locator = $loc
  }
}

# ----------------------------
# Run export
# ----------------------------
$manifest = [ordered]@{
  run_date = $runDate
  api_version = $ApiVersion
  mode = $EmailExportMode
  objects_exported = @()
  files_exported = @()
  errors = @()
}

Write-Host "Discovering queryable objects..."
$global = HttpGetJson "$instanceUrl/services/data/v$ApiVersion/sobjects" $accessToken

$SkipObjects = @(
  "AppTabMember","ApexTypeImplementor","EntityParticle","RelationshipDomain","SearchLayout",
  "FlowTestView","FlowVariableView","FlowVersionView",
  "UserEntityAccess","UserFieldAccess","UserRecordAccess",
  "SalesforceContract","SalesforceInvoice","SalesforceQuote",
  "DatacloudAddress","DataStatistics","FieldChangeSnapshot",
  "OutgoingEmail","OutgoingEmailRelation","PlatformAction","RecentFieldChange",
  "FlexQueueItem","ListViewChartInstance",
  "IdeaComment","Vote",
  "DataType"
)

$objs = @(
  $global.sobjects |
  Where-Object {
    $_.queryable -eq $true -and
    (
      ($_.PSObject.Properties['dataSource'] -eq $null) -or
      [string]::IsNullOrWhiteSpace([string]$_.PSObject.Properties['dataSource'].Value)
    ) -and
    (
      ($_.PSObject.Properties['external'] -eq $null) -or
      ($_.PSObject.Properties['external'].Value -ne $true)
    )
  }
)

$objs = $objs | Where-Object { $SkipObjects -notcontains $_.name }
if ($ExcludeObjectRegex) { $objs = $objs | Where-Object { $_.name -notmatch $ExcludeObjectRegex } }
if ($MaxObjects -gt 0) { $objs = $objs | Select-Object -First $MaxObjects }

# NOTE: We DO NOT restrict to EmailMessage in full_partition mode.
# full_partition means: export all objects, and EmailMessage is partitioned.

# Upload inventory
$invPath = Join-Path $workRoot "queryable_objects.json"
($objs | ConvertTo-Json -Depth 6) | Out-File -FilePath $invPath -Encoding utf8
AzureUploadFile $invPath "$basePrefix/inventory/queryable_objects.json" "application/json"

foreach ($o in $objs) {
  $name = $o.name
  Write-Host "Exporting object: $name"

  try {
    $desc = HttpGetJson "$instanceUrl/services/data/v$ApiVersion/sobjects/$name/describe" $accessToken
    $fields = @(
      $desc.fields |
      Where-Object {
        $_.name -and $_.name -ne "attributes" -and
        $_.compoundFieldName -eq $null -and
        $_.type -ne "address" -and $_.type -ne "location" -and
        $_.type -ne "base64" -and $_.type -ne "blob"
      } |
      ForEach-Object { $_.name }
    )

    $fieldCount = ($fields | Measure-Object).Count
    if ($fieldCount -eq 0) { throw "No fields returned" }

    # Chunk fields to avoid SOQL length issues
    $chunkSize = 200
    $chunks = @()
    for ($i=0; $i -lt $fields.Count; $i += $chunkSize) {
      $chunks += ,($fields[$i..([Math]::Min($i+$chunkSize-1, $fields.Count-1))])
    }

    # -----------------------------------------
    # EmailMessage: FULL PARTITION MODE
    # -----------------------------------------
    if ($name -eq "EmailMessage" -and $EmailFullPartition) {

      $endUtc = (Get-Date).ToUniversalTime()
      $startUtc = [datetime]::Parse($EmailFullStartUtc).ToUniversalTime()
      $windows = Get-TimeWindows $startUtc $endUtc $EmailPartition

      foreach ($w in $windows) {
        $wStart = $w[0]
        $wEnd   = $w[1]
        $sinceIso = IsoZ $wStart
        $untilIso = IsoZ $wEnd

        Write-Host "EmailMessage partition: $sinceIso -> $untilIso"

        $outCsv = Join-Path $workRoot "EmailMessage_$($wStart.ToString('yyyy-MM-dd'))_to_$($wEnd.ToString('yyyy-MM-dd')).csv"
        if (Test-Path $outCsv) { Remove-Item $outCsv -Force }

        $firstChunk = $true
        $skipNoRows = $false

        foreach ($chunk in $chunks) {
          # IMPORTANT: date literals must be in SOQL datetime literal format without quotes for Z, but safest is: 2025-01-01T00:00:00Z
          $soql = "SELECT " + ($chunk -join ",") + " FROM EmailMessage WHERE $EmailDateField >= $sinceIso AND $EmailDateField < $untilIso"

          $jobId = BulkNewQueryJob $soql
          $job = BulkWaitComplete $jobId 1800
          if ($job.state -ne "JobComplete") { throw "Bulk job failed: $($job | ConvertTo-Json -Compress)" }

          if ($firstChunk -and [int]$job.numberRecordsProcessed -eq 0) {
            Write-Host "No rows in this partition window, skipping."
            $skipNoRows = $true
            break
          }

          $partCsv = Join-Path $workRoot "EmailMessage.part.csv"
          BulkDownloadResultsCsv $jobId $partCsv

          if ($firstChunk) {
            Move-Item $partCsv $outCsv -Force
            $firstChunk = $false
          } else {
            $lines = Get-Content -Path $partCsv -Encoding UTF8
            if ($lines.Count -gt 1) { $lines[1..($lines.Count-1)] | Add-Content -Path $outCsv -Encoding UTF8 }
            Remove-Item $partCsv -Force
          }
        }

        if ($skipNoRows) {
          if (Test-Path $outCsv) { Remove-Item $outCsv -Force }
          continue
        }

        $blob = "$basePrefix/baseline/EmailMessage/$($wStart.ToString('yyyy-MM'))/EmailMessage_$($wStart.ToString('yyyy-MM-dd'))_to_$($wEnd.ToString('yyyy-MM-dd')).csv"
        AzureUploadFile $outCsv $blob "text/csv"

        $manifest.objects_exported += @{
          name="EmailMessage"
          mode="baseline_partition"
          window_from=$sinceIso
          window_to=$untilIso
          blob=$blob
        }

        Remove-Item $outCsv -Force
      }

      # In full_partition mode we are NOT updating incremental watermark
      continue
    }

    # -----------------------------------------
    # Normal export for other objects (and EmailMessage when incremental mode)
    # -----------------------------------------
    $outCsv = Join-Path $workRoot "$name.csv"
    if (Test-Path $outCsv) { Remove-Item $outCsv -Force }

    $firstChunk = $true
    $useRestFallback = $false
    $skipNoRows = $false

    foreach ($chunk in $chunks) {
      $soql = "SELECT " + ($chunk -join ",") + " FROM " + $name

      # EmailMessage incremental ONLY when NOT full_partition
      if (-not $EmailFullPartition -and $EmailMessageIncremental -and $name -eq "EmailMessage") {
        $since = $runStartUtc.AddDays(-$DefaultLookbackDays)
        if ($emailState -and $emailState.last_successful_utc) {
          $since = (ParseIsoZ $emailState.last_successful_utc).AddMinutes(-$OverlapMinutes)
        }
        $sinceIso = IsoZ $since
        $soql += " WHERE SystemModstamp >= $sinceIso AND SystemModstamp < $runUntilIso"
      }

      try {
        $jobId = BulkNewQueryJob $soql
        $job = BulkWaitComplete $jobId 1800
        if ($job.state -ne "JobComplete") { throw "Bulk job failed: $($job | ConvertTo-Json -Compress)" }

        if ($firstChunk -and [int]$job.numberRecordsProcessed -eq 0) {
          Write-Host "Skipping $name - no records returned"
          $skipNoRows = $true
          break
        }

        $partCsv = Join-Path $workRoot "$name.part.csv"
        BulkDownloadResultsCsv $jobId $partCsv

        if ($firstChunk) {
          Move-Item $partCsv $outCsv -Force
          $firstChunk = $false
        } else {
          $lines = Get-Content -Path $partCsv -Encoding UTF8
          if ($lines.Count -gt 1) { $lines[1..($lines.Count-1)] | Add-Content -Path $outCsv -Encoding UTF8 }
          Remove-Item $partCsv -Force
        }
      }
      catch {
        $msg = $_.Exception.Message
        if ($msg -match "not supported by the Bulk API" -or $msg -match '"errorCode":"INVALIDENTITY"') {
          if ($name -eq "EmailMessage") {
            Write-Warning "Bulk not supported for EmailMessage and REST fallback disabled (avoid runner OOM)."
          } else {
            Write-Warning "Bulk not supported for $name. Falling back to REST query export..."
            $useRestFallback = $true
          }
          break
        }
        throw
      }
    }

    if ($skipNoRows) {
      if (Test-Path $outCsv) { Remove-Item $outCsv -Force }
      continue
    }

    if ($useRestFallback) {
      $soqlRest = "SELECT " + ($fields -join ",") + " FROM " + $name
      RestQueryToCsv $soqlRest $outCsv
    }

    # Folder logic:
    # - When incremental mode: EmailMessage goes to incremental, all else to data
    # - When full_partition mode: EmailMessage goes to baseline/EmailMessage/... (handled above),
    #   all else goes to data (full snapshot for the day)
    $folder = "data"
    if (-not $EmailFullPartition -and $name -eq "EmailMessage") { $folder = "incremental" }

    $blobPath = "$basePrefix/$folder/$name.csv"
    AzureUploadFile $outCsv $blobPath "text/csv"

    $manifest.objects_exported += @{
      name=$name
      field_count=$fields.Count
      blob=$blobPath
    }

    Remove-Item $outCsv -Force

    # update watermark only when we actually ran incremental for EmailMessage
    if (-not $EmailFullPartition -and $EmailMessageIncremental -and $name -eq "EmailMessage") {
      Save-EmailState $runUntilIso
    }
  }
  catch {
    $manifest.errors += @{ type="object"; object=$name; error=$_.Exception.Message }
    Write-Warning "FAILED $name : $($_.Exception.Message)"
  }
}

# Files (disabled by default)
if ($IncludeFiles) {
  Write-Host "Exporting Files..."
  Write-Warning "IncludeFiles is false; skipping."
}

# Upload manifest
$manifestPath = Join-Path $workRoot "manifest.json"
($manifest | ConvertTo-Json -Depth 10) | Out-File -FilePath $manifestPath -Encoding utf8
AzureUploadFile $manifestPath "$basePrefix/manifest.json" "application/json"

Write-Host "DONE. Objects: $($manifest.objects_exported.Count) Files: $($manifest.files_exported.Count) Errors: $($manifest.errors.Count)"
if ($manifest.errors.Count -gt 0) { exit 2 }