# Windows Setup

My opinionated Windows 11 installer and bootstrap scripts. They remove advertising, bundled consumer apps, cloud prompts, web search, telemetry services, and most notifications, then install a development environment.

This is intentionally aggressive. It keeps Defender, UAC, Windows Update, the Microsoft Store, and WebView2. Removing those crosses the line from debloating into breaking shared runtimes or basic security.

## What the default setup does

- Allows a local account and bypasses TPM, Secure Boot, and RAM checks during setup.
- Removes or disables Edge, OneDrive, Copilot, Recall, Widgets, Teams, Outlook, Xbox, Phone Link, Dev Home, news, and weather.
- Turns off advertising, Spotlight, suggestions, background apps, Game DVR, error reporting, activity history, cross-device features, web results, and telemetry services.
- Installs Helium, Git, GitHub CLI, Node.js LTS, pnpm, VS Code, PowerShell 7, and Windows Terminal.
- Leaves disk selection and account naming interactive. Automating either is a good way to wipe the wrong disk or create the wrong user.

## Use it

Start with [WindowsSetup/README.md](WindowsSetup/README.md). It covers USB preparation, the unattended install, and the bootstrap step.

The settings live in two JSON files.

- [settings.json](WindowsSetup/config/settings.json) controls Windows cleanup.
- [packages.json](WindowsSetup/config/packages.json) controls application installation.

The scripts are meant to be safe to rerun. They write a transcript to `%USERPROFILE%\WindowsSetup\setup.log`.

## Before trusting it

Test the full install in a disposable virtual machine. Microsoft changes package names, policy keys, and protected components often enough that a script which worked last month can fail halfway through today.

MIT licensed.
