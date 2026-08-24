# Install MayaOS from the terminal — Windows.
#
#   irm https://raw.githubusercontent.com/kingmeers/mayaos-releases/main/get.ps1 | iex
#
# Fetches the latest Windows build and installs it per-user, silently — no
# browser, no download page, and no SmartScreen dialog, because SmartScreen
# judges the browser's quarantine mark and a terminal download never gets one.
# A copy that is already running is quit first and the new one opened after,
# so running this again is also the upgrade path.

$ErrorActionPreference = 'Stop'

$repo = 'kingmeers/mayaos-releases'
$rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest"
$asset = $rel.assets | Where-Object { $_.name -like '*.exe' } | Select-Object -First 1
if (-not $asset) {
  throw "the latest release of $repo has no Windows build - see https://github.com/$repo/releases/latest"
}

$out = Join-Path $env:TEMP $asset.name
Write-Host "Downloading $($asset.name)" -ForegroundColor Cyan
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $out

# An installer cannot replace a running copy's files.
Get-Process -Name 'MayaOS' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host 'Installing' -ForegroundColor Cyan
# /S is NSIS silent mode; the app installs per-user, so no admin prompt here —
# the UAC prompts belong to the setup steps inside the app that genuinely
# change the machine (the Chrome policy, Tailscale).
Start-Process -FilePath $out -ArgumentList '/S' -Wait
Remove-Item $out -Force -ErrorAction SilentlyContinue

$app = Join-Path $env:LOCALAPPDATA 'Programs\MayaOS\MayaOS.exe'
if (Test-Path $app) {
  Write-Host 'Opening MayaOS' -ForegroundColor Cyan
  Start-Process -FilePath $app
  Write-Host 'Done. MayaOS walks you through the rest - about two minutes.'
} else {
  Write-Host "Installed, but $app was not found - open MayaOS from the Start menu."
}
