@echo off
REM ============================================================================
REM  Pulse.WPF launcher
REM ============================================================================
REM  Drop this file on a VPU's desktop and double-click. Pulse.WPF downloads
REM  itself, installs to %LOCALAPPDATA%\Pulse.WPF, and runs.
REM
REM  Future double-clicks auto-update to the latest release. No manual update
REM  step required.
REM
REM  How it works:
REM    Calls install.ps1 from ianmoore-playon/pulse-releases (a public repo).
REM    install.ps1 fetches the latest Pulse.WPF release, extracts, launches.
REM
REM  Requirements:
REM    Windows 10+ (already on every VPU)
REM    .NET Framework 4.8 (already on every VPU)
REM    Internet access to github.com
REM ============================================================================

PowerShell -NoProfile -ExecutionPolicy Bypass -Command ^
  "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls; ^
   irm 'https://raw.githubusercontent.com/ianmoore-playon/pulse-releases/main/install.ps1' | iex"

if %ERRORLEVEL% neq 0 (
    echo.
    echo Pulse.WPF installer reported an error.
    echo Check the messages above for details.
    pause
)
