function desktop {
    try {
        if ($IsLinux -or $IsMacOS) {
            if (-not(Test-Path "~/Desktop" -pathType container)) {
                return Err -Msg "No 📂Desktop folder in your home directory yet"
            }
            $path = Resolve-Path "~/Desktop"
        } else {
            $path = [Environment]::GetFolderPath('DesktopDirectory')
            if (-not(Test-Path "$path" -pathType container)) {
                return Err -Msg "No desktop folder at 📂$path yet"
            }
        }
        Set-Location "$path"
        Log-Info "📂$path"
        Return Ok
    } catch {
        Return Err -Msg "Error: $($Error[0])"
    }
}