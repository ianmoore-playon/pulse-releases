# =============================================================================
#  install.ps1 — Pulse.WPF installer
# =============================================================================
# Hosted in the public ianmoore-playon/pulse-releases repo. Three ways to run:
#
#   1. Double-click Pulse.WPF.bat (recommended — self-elevates via UAC).
#   2. Elevated PowerShell one-liner:
#        irm https://raw.githubusercontent.com/ianmoore-playon/pulse-releases/main/install.ps1 | iex
#   3. Manually download the latest release zip from the Releases page.
#
# Install behavior:
#   - Stops any running Pulse.WPF.exe first so files aren't locked.
#   - When elevated, installs to "C:\Program Files (x86)\Pulse.WPF".
#     When NOT elevated, falls back to "%LOCALAPPDATA%\Pulse.WPF" so the
#     installer still works for users who decline the UAC prompt.
#   - Wipes the existing install dir before extract, with retries to defeat
#     stray file locks (the root cause of "re-running doesn't pull latest").
#   - Downloads to a unique temp zip per run so no HTTP cache lingers.
#   - Verifies Pulse.WPF.exe exists after extract; aborts cleanly if not.
#   - Unblocks every extracted file (no SmartScreen nag every launch).
#   - Launches Pulse.WPF.exe.
#
# Error handling: every failure path THROWS (not `return`) so the parent
# Pulse.WPF.bat sees a non-zero exit code and pauses to show the message.
# (Earlier versions used `return` which exits clean → the bat flash-and-vanished
# bug.)
#
# Requirements: Windows 10+, .NET Framework 4.8 (pre-installed on every VPU).
# =============================================================================

$ErrorActionPreference = 'Stop'

$repo    = "ianmoore-playon/pulse-releases"
$apiBase = "https://api.github.com/repos/$repo"

Write-Host ""
Write-Host "  Pulse.WPF installer" -ForegroundColor Cyan
Write-Host "  -------------------" -ForegroundColor DarkCyan

# ---- TLS (older VPU images still default to 1.0/1.1) ------------------------
[Net.ServicePointManager]::SecurityProtocol = `
    [Net.SecurityProtocolType]::Tls12 -bor `
    [Net.SecurityProtocolType]::Tls11 -bor `
    [Net.SecurityProtocolType]::Tls

# ---- Pick install directory --------------------------------------------------
# Elevated → Program Files (x86). Non-elevated → per-user LOCALAPPDATA so the
# installer still works without admin rights (degraded but functional).
function Test-Elevated {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = [System.Security.Principal.WindowsPrincipal]::new($id)
    return $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (Test-Elevated) {
    $programFiles = [Environment]::GetFolderPath('ProgramFilesX86')
    if ([string]::IsNullOrEmpty($programFiles)) {
        # Fallback for systems where ProgramFilesX86 is unset (rare).
        $programFiles = "C:\Program Files (x86)"
    }
    $installDir = Join-Path $programFiles 'Pulse.WPF'
    Write-Host "  Installing to: $installDir  (elevated)" -ForegroundColor Gray
} else {
    $installDir = Join-Path $env:LOCALAPPDATA 'Pulse.WPF'
    Write-Host "  Installing to: $installDir  (per-user — re-run as admin for Program Files install)" -ForegroundColor Yellow
}

# ---- Stop a running Pulse.WPF FIRST so files aren't locked -------------------
$running = Get-Process -Name 'Pulse.WPF' -ErrorAction SilentlyContinue
if ($running) {
    Write-Host "  Stopping running Pulse.WPF instance(s)..." -ForegroundColor Gray
    $running | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 750
}

# ---- Look up the latest release ---------------------------------------------
Write-Host "  Looking up the latest release..." -ForegroundColor Gray
try {
    $release = Invoke-RestMethod "$apiBase/releases/latest" -UseBasicParsing
} catch {
    throw "Could not reach the release server. Check your internet connection. Details: $($_.Exception.Message)"
}

$zipAsset = $release.assets | Where-Object { $_.name -like 'Pulse.WPF-*.zip' } | Select-Object -First 1
if (-not $zipAsset) {
    throw "No Pulse.WPF zip asset on the latest release ($($release.tag_name)). Contact support."
}

Write-Host "  Release : $($release.tag_name)" -ForegroundColor Green
Write-Host "  Bundle  : $($zipAsset.name)"    -ForegroundColor Green
Write-Host "  Size    : $([math]::Round($zipAsset.size / 1MB, 1)) MB" -ForegroundColor DarkGray

# ---- Download (unique temp filename per run defeats any HTTP cache) ----------
$stamp   = (Get-Date).ToString("yyyyMMdd-HHmmss")
$zipPath = Join-Path $env:TEMP "Pulse.WPF-$stamp.zip"
Write-Host "  Downloading..." -ForegroundColor Gray
try {
    Invoke-WebRequest $zipAsset.browser_download_url -OutFile $zipPath -UseBasicParsing
} catch {
    throw "Download failed. Details: $($_.Exception.Message)"
}

# ---- Wipe existing install with retry loop ----------------------------------
# Root cause of "re-running doesn't pull latest data": Remove-Item used to fail
# silently when a file was still in use (a previous Pulse.WPF.exe holding a
# handle, or AV scanning a freshly-extracted DLL), and the new extract overlaid
# on top of the old directory. The first matching Pulse.WPF.exe under that tree
# was then often the stale copy.
if (Test-Path $installDir) {
    Write-Host "  Removing previous install at $installDir..." -ForegroundColor Gray
    $cleared = $false
    for ($attempt = 1; $attempt -le 5; $attempt++) {
        try {
            Remove-Item $installDir -Recurse -Force -ErrorAction Stop
            $cleared = $true
            break
        } catch {
            Write-Host "    Retry $attempt/5 — $($_.Exception.Message)" -ForegroundColor DarkYellow
            Start-Sleep -Milliseconds 800
        }
    }
    if (-not $cleared) {
        throw "Could not remove previous install at $installDir after 5 attempts. Close any open Pulse.WPF window and retry."
    }
}

New-Item -ItemType Directory -Force -Path $installDir | Out-Null

# ---- Extract ----------------------------------------------------------------
Write-Host "  Extracting to $installDir..." -ForegroundColor Gray
try {
    Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
} catch {
    throw "Extraction failed. Details: $($_.Exception.Message)"
}

# Mark-of-the-Web strip — no SmartScreen nag on every launch.
Get-ChildItem -Path $installDir -Recurse -ErrorAction SilentlyContinue |
    Unblock-File -ErrorAction SilentlyContinue

# Clean the downloaded zip (per-run unique name so this is always safe).
Remove-Item $zipPath -ErrorAction SilentlyContinue

# ---- Find + launch Pulse.WPF.exe --------------------------------------------
$exe = Get-ChildItem -Path $installDir -Recurse -Filter 'Pulse.WPF.exe' -ErrorAction SilentlyContinue |
       Sort-Object FullName | Select-Object -First 1
if (-not $exe) {
    throw "Pulse.WPF.exe not found after extraction. Check $installDir manually."
}

Write-Host ""
Write-Host "  Launching $($exe.FullName)" -ForegroundColor Green
Write-Host ""
Start-Process -FilePath $exe.FullName
