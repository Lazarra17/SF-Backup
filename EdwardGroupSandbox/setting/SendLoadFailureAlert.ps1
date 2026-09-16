param(
    [Parameter(Mandatory = $true)][string]$ProcessName,
    [Parameter(Mandatory = $true)][int]$ExitCode,
    [string]$DebugLogPath = ""
)

<#
Called by the nightly batch wrapper when the Data Loader CLI itself exits with a
non-zero code (auth failure, connectivity failure, malformed file, etc.) -- i.e. the
load never reached Salesforce at all, so the in-Salesforce staging-error monitoring
(Tickets 2/3) has nothing to catch. This is the backstop for a fully failed night.

Reads the encrypted credential created by SetupSmtpCredential.ps1. If sending the
alert itself fails, falls back to a local log file so the failure isn't completely
silent even when email is unavailable.
#>

$ErrorActionPreference = 'Stop'
$settingDir  = $PSScriptRoot
$keyPath     = Join-Path $settingDir 'smtp.key'
$credPath    = Join-Path $settingDir 'smtp.cred'
$fallbackLog = Join-Path $settingDir 'alert-failures.log'

$smtpServer = 'smtp.office365.com'
$smtpPort   = 587
$fromAddr   = 'chad@bricoleurtech.com'
$toAddr     = 'chad@bricoleurtech.com'

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$subject   = "[ALERT] $ProcessName load FAILED - $timestamp"
$body = @"
The nightly Data Loader CLI run for process '$ProcessName' did not complete successfully.

Time:        $timestamp
Exit code:   $ExitCode
Debug log:   $DebugLogPath
Data Loader log: $env:TEMP\sdl.log

This means the CLI invocation itself failed (authentication, connectivity, or a
malformed source file) BEFORE any data reached Salesforce -- there is nothing in
the staging object's error field to review for this run. Check the log paths above
for the underlying cause.
"@

function Write-Fallback([string]$reason) {
    $line = "$timestamp | $ProcessName failed with exit code $ExitCode | ALERT EMAIL NOT SENT: $reason"
    Add-Content -Path $fallbackLog -Value $line
}

try {
    if (-not (Test-Path $keyPath) -or -not (Test-Path $credPath)) {
        throw "Missing $keyPath or $credPath -- run SetupSmtpCredential.ps1 first."
    }

    $key       = Get-Content -Path $keyPath -Encoding Byte -Raw
    $encrypted = Get-Content -Path $credPath -Raw
    $securePwd = ConvertTo-SecureString -String $encrypted -Key $key

    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePwd)
    $plainPwd = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

    $mail = New-Object System.Net.Mail.MailMessage
    $mail.From = $fromAddr
    $mail.To.Add($toAddr)
    $mail.Subject = $subject
    $mail.Body = $body

    $smtp = New-Object System.Net.Mail.SmtpClient($smtpServer, $smtpPort)
    $smtp.EnableSsl = $true
    $smtp.Credentials = New-Object System.Net.NetworkCredential($fromAddr, $plainPwd)
    $smtp.Send($mail)

    $plainPwd = $null
    Write-Host "Failure alert sent to $toAddr for $ProcessName (exit code $ExitCode)."
}
catch {
    Write-Fallback $_.Exception.Message
    Write-Warning "Could not send failure alert email: $($_.Exception.Message)"
    Write-Warning "Logged to $fallbackLog instead."
}
