function privacy {
    [CmdletBinding()]
    param()

    function registry {
        param([string]$Path)
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
    }

    Write-Host "🔒 Applying Windows privacy hardening..." -ForegroundColor Cyan

    # Elevate if needed
    if (-not (Test-IsAdmin)) {
        Invoke-Elevate -Command "all my homies hate windows privacy" -Description "Apply privacy fixes" -Prompt $true
        return
    }

    # Disable web search in start
    Write-Host "🧠 Disabling Windows search web integration..."
    Set-ItemProperty -Path "HKCU:\Control Panel\International\User Profile" -Name "HttpAcceptLanguageOptOut" -Value 1

    # Advertising ID
    registry "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0

    # Typing diagnostics
    registry "HKCU:\SOFTWARE\Microsoft\Input\TIPC"
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Input\TIPC" -Name "Enabled" -Value 0

    # Input personalization
    $inkPath = "HKCU:\SOFTWARE\Microsoft\InputPersonalization"
    registry $inkPath
    Set-ItemProperty -Path $inkPath -Name "RestrictImplicitInkCollection" -Value 1
    Set-ItemProperty -Path $inkPath -Name "RestrictImplicitTextCollection" -Value 1

    # Disable location sensor
    $sensorKey = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Permissions\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}"
    registry $sensorKey
    Set-ItemProperty -Path $sensorKey -Name "SensorPermissionState" -Value 0

    # Prevent Windows Defender from submitting samples
    try {
        Takeown-Registry "HKLM:\SOFTWARE\Microsoft\Windows Defender\Spynet"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Spynet" -Name "SpyNetReporting" -Value 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Spynet" -Name "SubmitSamplesConsent" -Value 0
    } catch {
        Write-Host "⚠️ Could not write to Defender\Spynet — permission denied" -ForegroundColor Yellow
    }

    # Disable Cortana personalization (inking/contacts/etc.)
    $ppKey = "HKCU:\SOFTWARE\Microsoft\Personalization\Settings"
    registry $ppKey
    Set-ItemProperty -Path $ppKey -Name "AcceptedPrivacyPolicy" -Value 0

    # Disable background access for apps
    $appsKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
    if (Test-Path $appsKey) {
        foreach ($sub in Get-ChildItem $appsKey) {
            Set-ItemProperty -Path "$appsKey\$($sub.PSChildName)" -Name "Disabled" -Value 1
        }
    }

    # Disable sync groups
    Write-Host "📦 Disabling sync groups..."
    $groups = @(
        "Accessibility", "AppSync", "BrowserSettings", "Credentials", "DesktopTheme",
        "Language", "PackageState", "Personalization", "StartLayout", "Windows"
    )
    foreach ($group in $groups) {
        $groupKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\$group"
        registry $groupKey
        Set-ItemProperty -Path $groupKey -Name "Enabled" -Value 0
    }

    Write-Host "✅ Privacy hardening complete." -ForegroundColor Green
}


function DisableTailoredExperiences {
    Write-Output "Disabling Tailored Experiences..."
    If (!(Test-Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent")) {
        New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableTailoredExperiencesWithDiagnosticData" -Type DWord -Value 1
}

function DisableAdvertisingID {
    Write-Output "Disabling Advertising ID..."
    If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Type DWord -Value 1
    Write-Output "done"
}

function DisableActivityHistory {
	Write-Output "Disabling Activity History..."
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Type DWord -Value 0
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Type DWord -Value 0
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Type DWord -Value 0
    Write-Output "Done"
}

function DisableLocation {
	Write-Output "Disabling location services..."
	If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors")) {
		New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Force | Out-Null
	}
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -Type DWord -Value 1
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocationScripting" -Type DWord -Value 1
    Write-Output "Done"
}