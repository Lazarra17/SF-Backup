#Requires -Version 5.1
<#
One-time setup: run this yourself (double-click, or right-click > Run with PowerShell).
It stores an encrypted copy of your mailbox password so the unattended nightly task
(which runs as SYSTEM, with no Windows user profile of its own) can send failure alerts
without a plaintext password sitting on disk.

The encryption key is a raw AES key file, not tied to your Windows user account, so the
SYSTEM-context scheduled task can decrypt it later. Anyone who can read BOTH smtp.key and
smtp.cred could recover the password, so this script locks both files down to
Administrators + SYSTEM only. Re-run this script any time the password changes.
#>

$ErrorActionPreference = 'Stop'
$settingDir = $PSScriptRoot
$keyPath  = Join-Path $settingDir 'smtp.key'
$credPath = Join-Path $settingDir 'smtp.cred'

if (-not (Test-Path $keyPath)) {
    Write-Host "Generating new AES key at $keyPath ..."
    $key = New-Object byte[] 32
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($key)
    Set-Content -Path $keyPath -Value $key -Encoding Byte
} else {
    Write-Host "Using existing key at $keyPath"
    $key = Get-Content -Path $keyPath -Encoding Byte -Raw
}

$securePwd = Read-Host -AsSecureString -Prompt "Enter the SMTP password / app password for chad@bricoleurtech.com"
$encrypted = ConvertFrom-SecureString -SecureString $securePwd -Key $key
Set-Content -Path $credPath -Value $encrypted -Encoding UTF8

Write-Host "Saved encrypted credential to $credPath"

foreach ($p in @($keyPath, $credPath)) {
    try {
        icacls $p /inheritance:r | Out-Null
        icacls $p /grant:r "SYSTEM:(R)" "*S-1-5-32-544:(R)" | Out-Null   # SYSTEM + Administrators group, read-only
        Write-Host "Locked down permissions on $p"
    } catch {
        Write-Warning "Could not restrict permissions on $p (run this script as Administrator to lock it down). Error: $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "Done. The nightly task can now send failure alerts via smtp.office365.com:587 as chad@bricoleurtech.com."
Write-Host "If the mailbox password ever changes, just re-run this script."
