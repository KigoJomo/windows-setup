Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Set-RegistryValue {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] $Value,
        [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord')] [string] $Type = 'DWord'
    )

    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

function Remove-BundledApps {
    $appPatterns = @(
        'Clipchamp.Clipchamp',
        'Microsoft.549981C3F5F10',
        'Microsoft.BingNews',
        'Microsoft.BingWeather',
        'Microsoft.BingSearch',
        'Microsoft.Copilot',
        'Microsoft.DevHome',
        'Microsoft.Edge.GameAssist',
        'Microsoft.GamingApp',
        'Microsoft.GetHelp',
        'Microsoft.Getstarted',
        'Microsoft.MicrosoftOfficeHub',
        'Microsoft.MicrosoftJournal',
        'Microsoft.MicrosoftSolitaireCollection',
        'Microsoft.MixedReality.Portal',
        'Microsoft.People',
        'Microsoft.PowerAutomateDesktop',
        'Microsoft.SkypeApp',
        'Microsoft.Todos',
        'Microsoft.WindowsFeedbackHub',
        'Microsoft.WindowsMaps',
        'Microsoft.Windows.DevHome',
        'Microsoft.OutlookForWindows',
        'Microsoft.Xbox.TCUI',
        'Microsoft.XboxApp',
        'Microsoft.XboxGameOverlay',
        'Microsoft.XboxGamingOverlay',
        'Microsoft.XboxIdentityProvider',
        'Microsoft.XboxSpeechToTextOverlay',
        'Microsoft.YourPhone',
        'Microsoft.ZuneMusic',
        'Microsoft.ZuneVideo',
        'MicrosoftCorporationII.MicrosoftFamily',
        'MicrosoftCorporationII.MicrosoftOutlookForWindows',
        'MicrosoftCorporationII.QuickAssist',
        'MicrosoftWindows.Client.WebExperience',
        'MSTeams'
    )

    foreach ($pattern in $appPatterns) {
        Write-Host "Removing bundled app: $pattern"
        Get-AppxPackage -AllUsers -Name $pattern -ErrorAction SilentlyContinue |
            Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

        Get-AppxProvisionedPackage -Online |
            Where-Object DisplayName -Like $pattern |
            Remove-AppxProvisionedPackage -Online -AllUsers -ErrorAction SilentlyContinue | Out-Null
    }
}

function Remove-Edge {
    Write-Host 'Removing Microsoft Edge...' -ForegroundColor Yellow

    Set-RegistryValue -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdateDev' -Name 'AllowUninstall' -Value 1

    $setup = Get-ChildItem @(
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\*\Installer\setup.exe",
        "$env:ProgramFiles\Microsoft\Edge\Application\*\Installer\setup.exe"
    ) -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | Select-Object -First 1

    if ($setup) {
        $process = Start-Process -FilePath $setup.FullName -ArgumentList '--uninstall', '--system-level', '--verbose-logging', '--force-uninstall' -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            Write-Warning "The Edge uninstaller returned exit code $($process.ExitCode)."
        }
    }
    else {
        Write-Host 'Edge installer was not found; it may already be removed.'
    }

    Get-AppxPackage -AllUsers -Name 'Microsoft.MicrosoftEdge.Stable' -ErrorAction SilentlyContinue |
        Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

    $shortcuts = @(
        "$env:PUBLIC\Desktop\Microsoft Edge.lnk",
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk",
        "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk"
    )
    $shortcuts | ForEach-Object { Remove-Item $_ -Force -ErrorAction SilentlyContinue }
}

function Remove-OneDrive {
    Write-Host 'Removing OneDrive...'
    Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue

    $setupCandidates = @(
        "$env:SystemRoot\SysWOW64\OneDriveSetup.exe",
        "$env:SystemRoot\System32\OneDriveSetup.exe"
    )
    $setup = $setupCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($setup) {
        Start-Process -FilePath $setup -ArgumentList '/uninstall' -Wait
    }

    Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive' -Name 'DisableFileSyncNGSC' -Value 1
    Remove-Item "$env:USERPROFILE\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
}

function Invoke-JomoTweaks {
    param(
        [Parameter(Mandatory)] [pscustomobject] $Settings
    )

    if ($Settings.removeBundledApps) { Remove-BundledApps }
    if ($Settings.removeOneDrive) { Remove-OneDrive }

    if ($Settings.disableCopilot) {
        Set-RegistryValue -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot' -Value 1
        Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot' -Value 1
        Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowCopilotButton' -Value 0
    }

    if ($Settings.disableWidgets) {
        Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -Name 'AllowNewsAndInterests' -Value 0
        Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarDa' -Value 0
    }

    if ($Settings.disableStartWebSearch) {
        Set-RegistryValue -Path 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchBoxSuggestions' -Value 1
        Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'BingSearchEnabled' -Value 0
    }

    if ($Settings.disableConsumerFeatures) {
        Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsConsumerFeatures' -Value 1
        Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SilentInstalledAppsEnabled' -Value 0
        Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SystemPaneSuggestionsEnabled' -Value 0
        Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement' -Name 'ScoobeSystemSettingEnabled' -Value 0
    }

    if ($Settings.reduceTelemetry) {
        Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -Value 0
        Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'DisableTelemetryOptInSettingsUx' -Value 1
        Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'DoNotShowFeedbackNotifications' -Value 1
        Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -Value 0
        Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy' -Name 'TailoredExperiencesWithDiagnosticDataEnabled' -Value 0

        foreach ($serviceName in @('DiagTrack', 'dmwappushservice')) {
            Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
            Set-Service -Name $serviceName -StartupType Disabled -ErrorAction SilentlyContinue
        }

        $telemetryTasks = @(
            'Consolidator',
            'DmClient',
            'DmClientOnScenarioDownload',
            'Microsoft Compatibility Appraiser',
            'ProgramDataUpdater',
            'UsbCeip'
        )
        Get-ScheduledTask -ErrorAction SilentlyContinue |
            Where-Object TaskName -In $telemetryTasks |
            Disable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null

        Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization' -Name 'AllowInputPersonalization' -Value 0
        Set-RegistryValue -Path 'HKCU:\Software\Microsoft\InputPersonalization' -Name 'RestrictImplicitInkCollection' -Value 1
        Set-RegistryValue -Path 'HKCU:\Software\Microsoft\InputPersonalization' -Name 'RestrictImplicitTextCollection' -Value 1
    }

    if ($Settings.disableRecall) {
        Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -Name 'DisableAIDataAnalysis' -Value 1
        Set-RegistryValue -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsAI' -Name 'DisableAIDataAnalysis' -Value 1
    }

    if ($Settings.disableActivityHistory) {
        Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'EnableActivityFeed' -Value 0
        Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'PublishUserActivities' -Value 0
        Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'UploadUserActivities' -Value 0
    }

    if ($Settings.disableCrossDeviceFeatures) {
        Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'EnableCdp' -Value 0
        Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'AllowClipboardHistory' -Value 0
        Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'AllowCrossDeviceClipboard' -Value 0
        Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP' -Name 'CdpSessionUserAuthzPolicy' -Value 0
        Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP' -Name 'NearShareChannelUserAuthzPolicy' -Value 0
        Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP' -Name 'RomeSdkChannelUserAuthzPolicy' -Value 0
    }

    if ($Settings.disableAdvertising) {
        Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo' -Name 'DisabledByGroupPolicy' -Value 1
        Set-RegistryValue -Path 'HKCU:\Control Panel\International\User Profile' -Name 'HttpAcceptLanguageOptOut' -Value 1
        Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -Value 0
    }

    if ($Settings.disableTipsAndSuggestions) {
        $contentPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
        foreach ($name in @(
            'ContentDeliveryAllowed',
            'FeatureManagementEnabled',
            'OemPreInstalledAppsEnabled',
            'PreInstalledAppsEnabled',
            'PreInstalledAppsEverEnabled',
            'RotatingLockScreenEnabled',
            'RotatingLockScreenOverlayEnabled',
            'SilentInstalledAppsEnabled',
            'SoftLandingEnabled',
            'SubscribedContent-310093Enabled',
            'SubscribedContent-338387Enabled',
            'SubscribedContent-338388Enabled',
            'SubscribedContent-338389Enabled',
            'SubscribedContent-353694Enabled',
            'SubscribedContent-353696Enabled',
            'SystemPaneSuggestionsEnabled'
        )) {
            Set-RegistryValue -Path $contentPath -Name $name -Value 0
        }
    }

    if ($Settings.showFileExtensions) {
        Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Value 0
    }

    if ($Settings.showHiddenFiles) {
        Set-RegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Hidden' -Value 1
    }

    if ($Settings.removeEdge) {
        Remove-Edge
    }
}
