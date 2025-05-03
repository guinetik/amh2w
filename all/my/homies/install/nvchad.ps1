function nvchad {
    $target = "$env:USERPROFILE\AppData\Local\nvim"
    $repo = "https://github.com/NvChad/starter"

    if (Test-Path $target) {
        Log-Warning "Neovim config already exists at $target"
        $choice = Get-SelectionFromUser -Options @("Overwrite", "Cancel") -Prompt "NvChad already exists. Overwrite?"
        if ($choice -ne "Overwrite") {
            return Ok "NvChad install cancelled by user"
        }
        Remove-Item -Recurse -Force $target
    }

    try {
        Log-Info "Cloning NvChad starter repo..."
        git clone $repo $target

        Log-Info "Launching Neovim..."
        Start-Process "nvim"
        return Ok "NvChad installed and launched."
    } catch {
        return Err "Failed to install NvChad: $_"
    }
}
