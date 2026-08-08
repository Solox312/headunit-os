# Bypasses expired SSL certificate in Google Desktop Head Unit (DHU)
# Temporarily adjusts date during TLS handshake, then restores actual system clock.

$originalDate = Get-Date
if ($originalDate.Year -eq 2023) {
    # If date is currently 2023, restore to 2026
    $originalDate = Get-Date "2026-08-08 00:57:00"
}

Write-Host "Saved System Date: $originalDate"

try {
    Write-Host "Setting temporary date for DHU SSL handshake (2023-06-01)..."
    Set-Date -Date (Get-Date "2023-06-01") -ErrorAction SilentlyContinue

    Write-Host "Forwarding ADB TCP port 5277..."
    adb forward tcp:5277 tcp:5277

    Write-Host "Launching Google Desktop Head Unit Receiver..."
    Start-Process -FilePath "C:\Users\cnieves.wmg\AppData\Local\Android\Sdk\extras\google\auto\desktop-head-unit.exe"

    Write-Host "Waiting 5 seconds for SSL handshake completion..."
    Start-Sleep -Seconds 5
} finally {
    # Always restore system date back to real time
    Set-Date -Date $originalDate -ErrorAction SilentlyContinue
    Write-Host "System date successfully restored to: $(Get-Date)"
}
