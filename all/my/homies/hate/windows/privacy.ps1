function privacy {
    [CmdletBinding()]
    param()
    # We need to comprehensivlly tell the users whats up and ask for consent
    $disclaimer = @"
This script will apply several privacy enhancements to your Windows system.
It will disable features such as:
- Web search integration in the Start Menu
- Advertising ID and personalized ads
- Typing diagnostics and input personalization
- Location tracking and sensor access
- Automatic sample submission by Windows Defender
- Cortana personalization features
- Background app access
- Syncing of settings and activities across devices
- Tailored experiences based on diagnostic data
- Activity history logging and uploading

These changes involve modifying system registry settings and will require administrator privileges to apply.
Please ensure you understand these changes before proceeding.
"@
    Write-Host $disclaimer -ForegroundColor DarkRed

    $choice = Get-SelectionFromUser -Options @("Apply", "Cancel") -Prompt "Apply Windows privacy hardening?"
    if ($choice -ne "Apply") {
        return Ok "Privacy hardening cancelled by user"
    }

    Write-Host "Yolo! 👾" -ForegroundColor DarkCyan

    Write-Host "🔒 Applying Windows privacy hardening..." -ForegroundColor Cyan

    # Elevate if needed
    if (-not (Test-IsAdmin)) {
        Invoke-Elevate -Command "all my homies hate windows privacy" -Description "Apply privacy fixes" -Prompt $true
        return Ok "Elevated"
    }

    Disable-WebSearchIntegration
    Disable-ActivityHistory
    Disable-AdvertisingID
    Disable-AdvertisingIdHKCU
    Disable-TypingDiagnostics
    Disable-InputPersonalization
    Disable-Location
    Disable-LocationSensorHKCU
    Set-WindowsDefenderPrivacy
    Disable-CortanaPersonalization
    Disable-BackgroundAppAccess
    Disable-SyncGroups
    Disable-TailoredExperiences

    Write-Host "✅ Privacy hardening complete." -ForegroundColor Green
}

function Disable-WebSearchIntegration {
    Write-Host "🔍 Disabling Windows search web integration..." -ForegroundColor Cyan
    Set-ItemProperty -Path "HKCU:\\Control Panel\\International\\User Profile" -Name "HttpAcceptLanguageOptOut" -Value 1
    Write-Host "✔️ Done`n" -ForegroundColor Green
}

function Disable-AdvertisingIdHKCU {
    Write-Host "🔑 Disabling Advertising ID (HKCU)..." -ForegroundColor Cyan
    Set-RegistryValues -Path "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\AdvertisingInfo" -PropertyValues @{ "Enabled" = 0 } -EnsurePath
    Write-Host "✔️ Done`n" -ForegroundColor Green
}

function Disable-TypingDiagnostics {
    Write-Host "⌨️ Disabling typing diagnostics..." -ForegroundColor Cyan
    Set-RegistryValues -Path "HKCU:\\SOFTWARE\\Microsoft\\Input\\TIPC" -PropertyValues @{ "Enabled" = 0 } -EnsurePath
    Write-Host "✔️ Done`n" -ForegroundColor Green
}

function Disable-InputPersonalization {
    Write-Host "👤 Disabling input personalization..." -ForegroundColor Cyan
    Set-RegistryValues -Path "HKCU:\\SOFTWARE\\Microsoft\\InputPersonalization" -PropertyValues @{
        "RestrictImplicitInkCollection" = 1
        "RestrictImplicitTextCollection" = 1
    } -EnsurePath
    Write-Host "✔️ Done`n" -ForegroundColor Green
}

function Disable-LocationSensorHKCU {
    Write-Host "🌐 Disabling location sensor (HKCU)..." -ForegroundColor Cyan
    Set-RegistryValues -Path "HKCU:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Sensor\\Permissions\\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -PropertyValues @{
        "SensorPermissionState" = 0
    } -EnsurePath
    Write-Host "✔️ Done`n" -ForegroundColor Green
}

function Set-WindowsDefenderPrivacy {
    try {
        Write-Host "🛡️ Windows Defender Privacy" -ForegroundColor Cyan
        Write-Host "Windows defender will still run normally, but will not submit samples to Microsoft" -ForegroundColor DarkGray
        try {
            Set-RegistryValues -Path "HKLM:\\SOFTWARE\\Microsoft\\Windows Defender\\Real-Time Protection" -PropertyValues @{
                "SpyNetReporting" = 0
                "SubmitSamplesConsent" = 0
            } -EnsurePath
        } catch {
            Write-Host "⚠️ Could not write to Defender\\Real-Time Protection" -ForegroundColor Yellow
            Write-Host $_
        }
        Write-Host "🛡️ Disabling Defender from submitting samples (MpPreference)..." -ForegroundColor Cyan
        Set-MpPreference -SubmitSamplesConsent NeverSend
        Set-MpPreference -MAPSReporting Disable
        Write-Host "✔️ Done`n" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Error Disabling Defender Privacy" -ForegroundColor Yellow
        Write-Host $_
    }
}

function Disable-CortanaPersonalization {
    Write-Host "🤖 Disabling Cortana personalization..." -ForegroundColor Cyan
    Set-RegistryValues -Path "HKCU:\\SOFTWARE\\Microsoft\\Personalization\\Settings" -PropertyValues @{
        "AcceptedPrivacyPolicy" = 0
    } -EnsurePath
    Write-Host "✔️ Done`n" -ForegroundColor Green
}

function Disable-BackgroundAppAccess {
    Write-Host "🚪 Disabling background access for apps..." -ForegroundColor Cyan
    $appsKey = "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\BackgroundAccessApplications"
    if (Test-Path $appsKey) {
        foreach ($sub in Get-ChildItem $appsKey) {
            Set-ItemProperty -Path "$appsKey\\$($sub.PSChildName)" -Name "Disabled" -Value 1
        }
    }
    Write-Host "✔️ Done`n" -ForegroundColor Green
}

function Disable-SyncGroups {
    Write-Host "🔄 Disabling sync groups..." -ForegroundColor Cyan
    $groups = @(
        "Accessibility", "AppSync", "BrowserSettings", "Credentials", "DesktopTheme",
        "Language", "PackageState", "Personalization", "StartLayout", "Windows"
    )
    foreach ($group in $groups) {
        $groupKey = "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\SettingSync\\Groups\\$group"
        Set-RegistryValues -Path $groupKey -PropertyValues @{ "Enabled" = 0 } -EnsurePath
    }
    Write-Host "✔️ Done`n" -ForegroundColor Green
}


function Disable-TailoredExperiences {
    Write-Host "☁️ Disabling Tailored Experiences..." -ForegroundColor Cyan
    Set-RegistryValues -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -PropertyValues @{
        "DisableTailoredExperiencesWithDiagnosticData" = @{ Value = 1; Type = "DWord" }
    } -EnsurePath
    Write-Host "✔️ Done" -ForegroundColor Green
}

function Disable-AdvertisingID {
    Write-Host "🔑 Disabling Advertising ID (HKLM Policy)..." -ForegroundColor Cyan
    Set-RegistryValues -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -PropertyValues @{
        "DisabledByGroupPolicy" = @{ Value = 1; Type = "DWord" }
    } -EnsurePath
    Write-Host "✔️ Done" -ForegroundColor Green
}

function Disable-ActivityHistory {
	Write-Host "📜 Disabling Activity History..." -ForegroundColor Cyan
	Set-RegistryValues -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -PropertyValues @{
        "EnableActivityFeed" = @{ Value = 0; Type = "DWord" }
        "PublishUserActivities" = @{ Value = 0; Type = "DWord" }
        "UploadUserActivities" = @{ Value = 0; Type = "DWord" }
    }
    Write-Host "✔️ Done" -ForegroundColor Green
}

function Disable-Location {
	Write-Host "🗺️ Disabling location services (HKLM Policy)..." -ForegroundColor Cyan  
	Set-RegistryValues -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -PropertyValues @{
        "DisableLocation" = @{ Value = 1; Type = "DWord" }
        "DisableLocationScripting" = @{ Value = 1; Type = "DWord" }
    } -EnsurePath
    Write-Host "✔️ Done" -ForegroundColor Green
}