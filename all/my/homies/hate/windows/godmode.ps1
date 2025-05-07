function godmode {
    try {
        $GodModeSplat = @{
            Path     = "$HOME\Desktop"
            Name     = "GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}"
            ItemType = 'Directory'
        }
        $null = New-Item @GodModeSplat
        "✅ God mode enabled - just double-click the new desktop icon."
        return Ok
    }
    catch {
        return Err "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    }
}