# Pulse.WPF — public release feed

This repo is the public distribution channel for **Pulse**, the Pixellot VPU
diagnostic toolset. The application source lives in a private repo; this
public repo only contains the installer scripts and the tagged release
binaries.

## Install on a VPU

### Easiest — drag a launcher onto the desktop

1. Right-click [**`Pulse.WPF.bat`**](Pulse.WPF.bat) → **Save link as…** to
   download the launcher.
2. Drop it on the VPU's desktop (LogMeIn → File Manager works).
3. Double-click. Pulse.WPF downloads itself, installs to
   `%LOCALAPPDATA%\Pulse.WPF`, and runs.
4. **Subsequent double-clicks auto-update** to the latest release.

The launcher is ~600 bytes and never needs to be replaced. New releases
flow through automatically.

### One-line PowerShell installer

Open PowerShell on the VPU (regular or Admin) and paste:

```powershell
irm https://raw.githubusercontent.com/ianmoore-playon/pulse-releases/main/install.ps1 | iex
```

Same end result — installs and runs Pulse.WPF.

### Manual install

1. Download the latest `Pulse.WPF-*.zip` from [Releases](../../releases/latest).
2. Extract anywhere (`%LOCALAPPDATA%\Pulse.WPF` is the convention).
3. Run `Pulse.WPF.exe`.

## What's in the zip

```
Pulse.WPF.exe                    The application
MaterialDesignThemes.Wpf.dll     UI theming
MaterialDesignColors.dll
Microsoft.Xaml.Behaviors.dll
… plus a few support DLLs
```

Total ~5 MB.

## Requirements

- **Windows 10 or 11** — every VPU qualifies
- **.NET Framework 4.8** — pre-installed on every VPU
- **Internet access to `github.com`** during install or launch

## How releases work

Releases are published automatically when the source repo's CI builds a
tagged commit (`wpf-pilot-v*`). Each release contains:

- `Pulse.WPF-pilot-<timestamp>-<sha>.zip` — the application bundle
- `Pulse.WPF.bat` — the launcher (also lives at the root of this repo)
- Release notes summarizing the build

## Source

The application source is in a separate, private repo. Contact the
maintainers if you need access to source code.

## Trouble?

If `Pulse.WPF.bat` does nothing, open PowerShell on the VPU and run the
one-line installer above instead — it surfaces error messages the bat
hides.

If both fail, check that the VPU can reach `github.com`:

```powershell
Test-NetConnection github.com -Port 443
```
