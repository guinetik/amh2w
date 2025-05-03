function ssh {
    try {
        $path = "~/.ssh"
        if (-not(Test-Path "$path" -pathType container)) {
            return Err -Msg "No secure shell (SSH) folder at $path"
        }
        $path = Resolve-Path "$path"
        Set-Location "$path"
        $files = Get-ChildItem $path -attributes !Directory
        Log-Info "📂$path entered (has $($files.Count) files)"
        Return Ok
    } catch {
        Return Err -Msg "Error: $($Error[0])"
    }
}