[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $arguments = @('-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
    Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments -Verb RunAs
    exit
}

$kitRoot = Split-Path -Parent $PSScriptRoot
$configRoot = Join-Path $kitRoot 'config'
$stateRoot = Join-Path $env:USERPROFILE 'JomoWindowsSetup'
$logPath = Join-Path $stateRoot 'setup.log'
New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null

Start-Transcript -Path $logPath -Append
try {
    Write-Host '=== Jomo Windows Setup ===' -ForegroundColor Cyan
    Write-Host "Kit: $kitRoot"
    Write-Host "Log: $logPath"

    $settings = Get-Content (Join-Path $configRoot 'settings.json') -Raw | ConvertFrom-Json
    $packageConfig = Get-Content (Join-Path $configRoot 'packages.json') -Raw | ConvertFrom-Json

    . (Join-Path $PSScriptRoot 'tweaks.ps1')
    Invoke-JomoTweaks -Settings $settings

    Write-Host 'Waiting for internet connectivity and WinGet...'
    $deadline = (Get-Date).AddMinutes(20)
    do {
        $online = Test-NetConnection -ComputerName 'cdn.winget.microsoft.com' -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue
        $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
        if (-not ($online -and $winget)) { Start-Sleep -Seconds 10 }
    } until (($online -and $winget) -or (Get-Date) -ge $deadline)

    if (-not $online) { throw 'Internet connectivity was not available after 20 minutes.' }
    if (-not $winget) { throw 'WinGet was not available after 20 minutes. Update App Installer from Microsoft Store, then rerun this script.' }

    winget.exe source update --disable-interactivity

    foreach ($package in $packageConfig.packages | Where-Object enabled) {
        Write-Host "Installing $($package.name)..." -ForegroundColor Cyan
        winget.exe install --id $package.id --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "WinGet returned exit code $LASTEXITCODE for $($package.name)."
        }
    }

    $nodeEnabled = $packageConfig.packages | Where-Object { $_.id -eq 'OpenJS.NodeJS.LTS' -and $_.enabled }
    if ($nodeEnabled) {
        $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        $env:Path = "$machinePath;$userPath"

        foreach ($npmPackage in $packageConfig.npmGlobals | Where-Object enabled) {
            Write-Host "Installing npm global: $($npmPackage.name)..." -ForegroundColor Cyan
            & npm.cmd install --global $npmPackage.name
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "npm returned exit code $LASTEXITCODE for $($npmPackage.name)."
            }
        }
    }

    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Process explorer.exe

    Write-Host 'Setup complete. Restart Windows when convenient.' -ForegroundColor Green
}
catch {
    Write-Error $_
    exit 1
}
finally {
    Stop-Transcript
}
