param(
  [Parameter(Mandatory=$true)][string]$ClientId,
  [Parameter(Mandatory=$true)][string]$ClientSecret,
  [Parameter(Mandatory=$true)][string]$LoginUrl,   # https://login.salesforce.com (prod) or https://test.salesforce.com
  [string]$RedirectUri = "http://localhost:1717/callback"
)

$ErrorActionPreference = "Stop"

function UrlEncode([string]$s) { [System.Uri]::EscapeDataString($s) }

# --- PKCE helpers (S256) ---
function New-CodeVerifier {
  # RFC7636 allows 43-128 chars; use 64 bytes -> base64url (~86 chars)
  $bytes = New-Object byte[] 64
  [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)

  $b64 = [Convert]::ToBase64String($bytes).TrimEnd("=") -replace '\+', '-' -replace '/', '_'
  return $b64
}

function New-CodeChallengeS256([string]$verifier) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $hash = $sha.ComputeHash([Text.Encoding]::ASCII.GetBytes($verifier))
  $b64 = [Convert]::ToBase64String($hash).TrimEnd("=") -replace '\+', '-' -replace '/', '_'
  return $b64
}

$codeVerifier  = New-CodeVerifier
$codeChallenge = New-CodeChallengeS256 $codeVerifier

Write-Host "PKCE generated (will be used once)."

# 1) Start local listener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:1718/callback/")
$listener.Start()
Write-Host "Listening on $RedirectUri ..."

# 2) Build authorize URL with PKCE
$scope = "api refresh_token offline_access"
$authUrl = "$LoginUrl/services/oauth2/authorize" +
          "?response_type=code" +
          "&client_id=$(UrlEncode $ClientId)" +
          "&redirect_uri=$(UrlEncode $RedirectUri)" +
          "&scope=$(UrlEncode $scope)" +
          "&code_challenge=$(UrlEncode $codeChallenge)" +
          "&code_challenge_method=S256"

Write-Host "Opening browser for authorization..."
Start-Process $authUrl

# 3) Wait for callback with code
$context = $listener.GetContext()
$request = $context.Request
$code = $request.QueryString["code"]
$error = $request.QueryString["error"]
$errorDesc = $request.QueryString["error_description"]

$responseString = if ($code) { "Authorization successful. You can close this window." }
                  else { "Authorization failed: $error $errorDesc" }

$buffer = [System.Text.Encoding]::UTF8.GetBytes($responseString)
$context.Response.ContentLength64 = $buffer.Length
$context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
$context.Response.OutputStream.Close()
$listener.Stop()

if (-not $code) { throw "No authorization code received. Error: $error $errorDesc" }

Write-Host "Got authorization code. Exchanging for tokens..."

# 4) Exchange code for tokens (include code_verifier!)
$tokenUrl = "$LoginUrl/services/oauth2/token"
$body = @{
  grant_type    = "authorization_code"
  code          = $code
  client_id     = $ClientId
  client_secret = $ClientSecret
  redirect_uri  = $RedirectUri
  code_verifier = $codeVerifier
}

$resp = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $body -ContentType "application/x-www-form-urlencoded"

Write-Host "`n=== SAVE THESE SECURELY ==="
Write-Host "instance_url : $($resp.instance_url)"
Write-Host "refresh_token: $($resp.refresh_token)"
Write-Host "==========================="
