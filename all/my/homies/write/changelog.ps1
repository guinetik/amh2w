function changelog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$RepoDir
    )

    try {
        Write-CHANGELOG $RepoDir
        return Ok "Changelog written successfully"
    } catch {
        Log-Error "Failed to write changelog: $_"
        return Err "Failed to write changelog: $_"
    }
}
