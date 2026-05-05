# =============================================================================
#  install.ps1 — Pulse.WPF installer
# =============================================================================
# Hosted in the public ianmoore-playon/pulse-releases repo. Three ways to run:
#
#   1. Double-click Pulse.WPF.bat (it just calls this script)
#   2. PowerShell one-liner:
#        irm https://raw.githubusercontent.com/ianmoore-playon/pulse-releases/main/install.ps1 | iex
#   3. Manually download the latest release zip from the Releases page
#
# Behavior:
#   - Looks up the latest release on this repo
#   - Downloads the Pulse.WPF zip asset
#   - Extracts to %LOCALAPPDATA%\Pulse.WPF (overwrites previous install)
#   - Unblocks every file (skips Windows SmartScreen "downloaded from internet" warnings)
#   - Launches Pulse.WPF.exe
#
# Requirements: Windows 10+, .NET Framework 4.8 (pre-installed on every VPU)
# =============================================================================

$ErrorActionPreference = 'Stop'

$repo       = "ianmoore-playon/pulse-releases"
$installDir = Join-Path $env:LOCALAPPDATA 'Pulse.WPF'
$apiBase    = "https://api.github.com/repos/$repo"

Write-Host ""
Write-Host "  Pulse.WPF installer" -ForegroundColor Cyan
Write-Host "  -------------------" -ForegroundColor DarkCyan

# Older VPU images default to TLS 1.0/1.1 which GitHub rejects. Force 1.2.
[Net.ServicePointManager]::SecurityProtocol = `
    [Net.SecurityProtocolType]::Tls12 -bor `
    [Net.SecurityProtocolType]::Tls11 -bor `
    [Net.SecurityProtocolType]::Tls

# ---- Look up the latest release ---------------------------------------------
Write-Host "  Looking up the latest release..." -ForegroundColor Gray
try {
    $release = Invoke-RestMethod "$apiBase/releases/latest" -UseBasicParsing
} catch {
    Write-Host ""
    Write-Host "  ERROR: Could not reach the release server." -ForegroundColor Red
    Write-Host "  Check your internet connection and try again." -ForegroundColor Red
    Write-Host "  Details: $($_.Exception.Message)" -ForegroundColor DarkGray
    Write-Host ""
    return
}

$zipAsset = $release.assets | Where-Object { $_.name -like 'Pulse.WPF-*.zip' } | Select-Object -First 1
if (-not $zipAsset) {
    Write-Host ""
    Write-Host "  ERROR: No Pulse.WPF zip in the latest release." -ForegroundColor Red
    Write-Host "  Release: $($release.tag_name)" -ForegroundColor DarkGray
    Write-Host ""
    return
}

Write-Host "  Release : $($release.tag_name)" -ForegroundColor Green
Write-Host "  Bundle  : $($zipAsset.name)" -ForegroundColor Green
Write-Host "  Size    : $([math]::Round($zipAsset.size / 1MB, 1)) MB" -ForegroundColor DarkGray

# ---- Download ----------------------------------------------------------------
$zipPath = Join-Path $env:TEMP $zipAsset.name
Write-Host "  Downloading..." -ForegroundColor Gray
try {
    Invoke-WebRequest $zipAsset.browser_download_url -OutFile $zipPath -UseBasicParsing
} catch {
    Write-Host ""
    Write-Host "  ERROR: Download failed." -ForegroundColor Red
    Write-Host "  Details: $($_.Exception.Message)" -ForegroundColor DarkGray
    Write-Host ""
    return
}

# ---- Clean previous install + extract ---------------------------------------
if (Test-Path $installDir) {
    try { Remove-Item $installDir -Recurse -Force } catch { }
}
New-Item -ItemType Directory -Force -Path $installDir | Out-Null

Write-Host "  Extracting to $installDir..." -ForegroundColor Gray
try {
    Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
} catch {
    Write-Host ""
    Write-Host "  ERROR: Extraction failed." -ForegroundColor Red
    Write-Host "  Details: $($_.Exception.Message)" -ForegroundColor DarkGray
    Write-Host ""
    return
}

# Strip the Mark-of-the-Web from every extracted file so SmartScreen doesn't
# nag the tech every launch.
Get-ChildItem -Path $installDir -Recurse -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue

# Cleanup the downloaded zip
Remove-Item $zipPath -ErrorAction SilentlyContinue

# ---- Find and launch Pulse.WPF.exe ------------------------------------------
$exe = Get-ChildItem -Path $installDir -Recurse -Filter 'Pulse.WPF.exe' -ErrorAction SilentlyContinue |
       Select-Object -First 1
if (-not $exe) {
    Write-Host ""
    Write-Host "  ERROR: Pulse.WPF.exe not found after extraction." -ForegroundColor Red
    Write-Host "  Check $installDir manually." -ForegroundColor DarkGray
    Write-Host ""
    return
}

Write-Host ""
Write-Host "  Launching Pulse.WPF..." -ForegroundColor Green
Write-Host ""
Start-Process -FilePath $exe.FullName
