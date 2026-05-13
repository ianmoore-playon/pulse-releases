@echo off
setlocal
title Pulse.WPF launcher
REM ============================================================================
REM  Pulse.WPF launcher
REM ============================================================================
REM  Drop this file on a VPU's desktop and double-click. Pulse.WPF downloads
REM  itself, installs to "C:\Program Files (x86)\Pulse.WPF", and runs.
REM
REM  Future double-clicks auto-update to the latest release. No manual update
REM  step required.
REM
REM  How it works:
REM    1. Self-elevates via UAC so the install can write under
REM       %ProgramFiles(x86)%. If the user declines the prompt the installer
REM       falls back to a per-user location under %LOCALAPPDATA%.
REM    2. Calls install.ps1 from ianmoore-playon/pulse-releases. The script
REM       stops any running Pulse.WPF.exe, wipes the existing install (with
REM       retries to defeat file locks), fetches /releases/latest, extracts,
REM       and launches Pulse.WPF.exe.
REM
REM  Requirements:
REM    Windows 10+, .NET Framework 4.8, internet access to github.com.
REM ============================================================================

REM ---- Are we already elevated? -----------------------------------------------
net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Pulse.WPF needs admin rights to install under Program Files (x86).
    echo A UAC prompt will appear in a moment.
    echo.
    PowerShell -NoProfile -Command ^
      "Start-Process -FilePath '%~dpnx0' -Verb RunAs"
    exit /b 0
)

REM ---- Elevated path: run install.ps1 -----------------------------------------
PowerShell -NoProfile -ExecutionPolicy Bypass -Command ^
  "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls; ^
   try { irm 'https://raw.githubusercontent.com/ianmoore-playon/pulse-releases/main/install.ps1' | iex } catch { Write-Host ''; Write-Host ('FATAL: ' + $_.Exception.Message) -ForegroundColor Red; exit 1 }"

set RC=%ERRORLEVEL%
if %RC% neq 0 (
    echo.
    echo Pulse.WPF installer exited with code %RC%.
    echo Check the messages above for details.
    echo.
    pause
)
endlocal
