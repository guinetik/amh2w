function edit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path
    )

    function TryEditor {
        param([string]$editor, [string]$targetPath)
        try {
            Write-Host "📝 Trying editor: $editor" -ForegroundColor Gray
            & $editor $targetPath
            if ($LASTEXITCODE -eq 0) {
                return $true
            }
        } catch {
            # silently ignore
        }
        return $false
    }

    try {
        if (-not (Test-Path $Path -PathType Leaf)) {
            return Err -Msg "❌ File not found or not accessible: '$Path'"
        }

        $editors = @(
            "nvim", "vim", "vi", "nano", "cursor",
            "code", "notepad.exe", "wordpad.exe"
        )

        foreach ($editor in $editors) {
            if (TryEditor $editor $Path) {
                return Ok -Message "Edited with $editor"
            }
        }

        Write-Host ""
        Write-Host "⚠️ No editor found." -ForegroundColor Yellow
        Write-Host "💡 Try installing one via 'winget install helix.helix' or similar."
        return Err -Msg "No available editor succeeded"
    }
    catch {
        Write-Host "Error: Command function '$arg' failed: $_" -ForegroundColor Red
        return Err -Msg "Edit command failed: $_"
    }
}
