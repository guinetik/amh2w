function sshkeygen {
    [CmdletBinding()]
    param()

    try {
        $sshDir = if ($env:USERPROFILE) {
            Join-Path $env:USERPROFILE ".ssh"
        } elseif ($env:HOMEPATH) {
            Join-Path $env:HOMEPATH ".ssh"
        } else {
            "$HOME/.ssh"
        }

        if (-not (Test-Path $sshDir)) {
            New-Item -ItemType Directory -Path $sshDir | Out-Null
        }

        Write-Host "🔐 Generating SSH key..." -ForegroundColor Cyan
        & ssh-keygen

        if ($LASTEXITCODE -ne 0) {
            return Err -Message "ssh-keygen failed"
        }

        $keyTypes = @(
            @{ Type = "Ed25519"; Path = "$sshDir\id_ed25519.pub" },
            @{ Type = "RSA";     Path = "$sshDir\id_rsa.pub"     }
        )

        foreach ($key in $keyTypes) {
            if (Test-Path $key.Path) {
                $publicKey = Get-Content $key.Path -Raw
                Write-Host "`n✅ New SSH key ($($key.Type)) saved to $sshDir" -ForegroundColor Green
                Write-Host "📎 Public key:"
                Write-Host "   $publicKey" -ForegroundColor Yellow

                return Ok -Value ([PSCustomObject]@{
                    Algorithm = $key.Type
                    Path      = $key.Path
                    PublicKey = $publicKey
                }) -Message "SSH key generated"
            }
        }

        return Err -Message "SSH key was generated, but no known public key file was found"
    }
    catch {
        Write-Host "Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])" -ForegroundColor Red
        return Err -Message "SSH key generation failed: $_"
    }
}
