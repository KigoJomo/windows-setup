# Jomo Windows Setup Kit

This kit turns a clean Windows 11 installation into a configured development machine. It keeps disk selection and account creation interactive, then applies the repeatable work automatically.

## What it does

- Bypasses Windows 11 TPM, Secure Boot and RAM checks.
- Skips the forced network/Microsoft-account screens where the current Windows build permits it.
- Uses Kenya's time zone and British English regional defaults.
- Removes Edge and a broad list of bundled consumer applications.
- Disables Copilot, Recall, widgets, Start-menu web search, consumer suggestions, advertising, activity history, cross-device features, telemetry services and OneDrive.
- Installs the enabled applications in `config/packages.json` with WinGet.
- Writes a detailed log to `%USERPROFILE%\JomoWindowsSetup\setup.log`.

Windows Defender, UAC, Windows Update, Microsoft Store and WebView2 remain enabled. Security and shared app runtimes are not bloat.

## Prepare the USB

1. Download an official Windows 11 ISO from Microsoft.
2. Write it to a USB drive with Rufus.
3. In Rufus's **Windows User Experience** dialog, leave every customization box unchecked. Rufus creates its own answer file and it would conflict with this one.
4. Copy `autounattend.xml` to the root of the Windows USB.
5. Copy the entire `JomoWindows` folder to the root of the USB. Rename this extracted folder to `JomoWindows` if necessary.

The root should look like this:

```text
USB:\
├── autounattend.xml
├── JomoWindows\
│   ├── Run-Bootstrap.cmd
│   ├── config\
│   └── scripts\
├── setup.exe
└── sources\
```

## Install Windows

1. Boot from the USB.
2. Select the Windows edition and target disk manually.
3. Complete local-account creation if Windows asks for it.
4. Keep the USB connected until the first desktop appears.
5. Connect to the internet. The bootstrap waits for connectivity and should start automatically. Approve its UAC prompt.

If it does not start, open `JomoWindows` on the USB and double-click `Run-Bootstrap.cmd`.

## Customise the package list

Edit `config/packages.json`. Set `enabled` to `true` or `false`; package IDs must be exact WinGet IDs. The default set installs Helium, Git, GitHub CLI, Node.js LTS, VS Code, PowerShell 7 and Windows Terminal. pnpm is installed through npm after Node.js.

## Run it again

The bootstrap is designed to be rerun. Existing WinGet packages are upgraded or reported as already installed, registry settings are reapplied, and removed AppX packages are skipped.

## Known limits

- Windows Setup changes frequently; Microsoft can break an OOBE bypass in a later ISO.
- Device-specific drivers are left to Windows Update or the manufacturer.
- Microsoft Store app registration can take a few minutes after first login, so the script waits for WinGet to become available.
- Edge removal relies on Microsoft's bundled Edge uninstaller and can break when Microsoft changes it. A failure is logged without deleting WebView2 or Edge Update services.
