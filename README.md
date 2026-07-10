# Jomo Windows Setup

An opinionated Windows 11 unattended-install and bootstrap kit. It removes Microsoft's advertising, consumer apps, cloud nags, AI features, telemetry services, web results and bundled distractions, then installs a development environment automatically.

It is deliberately aggressive. Microsoft Defender, UAC, Windows Update, the Microsoft Store and WebView2 remain intact because removing security and shared runtimes is not debloating—it is breaking the machine.

## Default result

- Local-account-friendly Windows setup with TPM, Secure Boot and RAM bypasses.
- Edge, OneDrive, Copilot, Recall, Widgets, Teams, Outlook, Xbox, Phone Link, Dev Home, news/weather and other bundled apps removed or disabled.
- Advertising, suggestions, tailored experiences, activity history, cross-device features, web search and telemetry services disabled.
- Helium, Git, GitHub CLI, Node.js LTS, pnpm, VS Code, PowerShell 7 and Windows Terminal installed.
- Disk selection and account naming remain interactive to prevent catastrophic automation.

## Use it

Read [`JomoWindows/README.md`](JomoWindows/README.md) for the USB preparation and installation procedure.

## Configuration

- [`JomoWindows/config/settings.json`](JomoWindows/config/settings.json) controls Windows cleanup.
- [`JomoWindows/config/packages.json`](JomoWindows/config/packages.json) controls application installation.

All scripts are intended to be idempotent and write a transcript to `%USERPROFILE%\JomoWindowsSetup\setup.log`.

## Status

This is an initial implementation. Test it in a disposable VM before using it on real hardware. Windows Setup and Edge removal are moving targets, because apparently installing an operating system needed an adversarial relationship.

## License

MIT

