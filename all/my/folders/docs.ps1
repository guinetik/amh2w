function docs {
    try {
        if ($IsLinux -or $IsMacOS) {
            if (-not(Test-Path "~/Documents" -pathType container)) {
                return Err -Message "No 📂Documents folder in your home directory yet"
            }
            $path = Resolve-Path "~/Documents"
        } else {
            $path = [Environment]::GetFolderPath('MyDocuments')
            if (-not(Test-Path "$path" -pathType container)) {
                return Err -Message "No documents folder at 📂$path yet"
            }
        }
        Set-Location "$path"
        $files = Get-ChildItem $path -attributes !Directory
        $folders = Get-ChildItem $path -attributes Directory
        Log-Info "📂$path entered (has $($files.Count) files and $($folders.Count) folders)"
        Return Ok
    } catch {
        Return Err -Message "Error: $($Error[0])"
    }
}