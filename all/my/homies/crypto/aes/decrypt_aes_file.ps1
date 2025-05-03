function decryptfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Password
    )

    function DeriveKeyFromPassword {
        param([string]$Password)
        $sha = [System.Security.Cryptography.SHA256]::Create()
        return $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Password))
    }

    function DecryptFileInternal {
        [CmdletBinding()]
        param(
            [string[]]$FileName,
            [byte[]]$KeyBytes,
            [string]$Algorithm = 'AES',
            [System.Security.Cryptography.CipherMode]$CipherMode = 'CBC',
            [System.Security.Cryptography.PaddingMode]$PaddingMode = 'PKCS7'
        )

        try {
            $Crypto = [System.Security.Cryptography.SymmetricAlgorithm]::Create($Algorithm)
            $Crypto.KeySize = $KeyBytes.Length * 8
            $Crypto.Key = $KeyBytes
            $Crypto.Mode = $CipherMode
            $Crypto.Padding = $PaddingMode

            $results = @()
            $Files = Get-Item -LiteralPath $FileName

            foreach ($File in $Files) {
                if (-not $File.Name -match '_encrypted') {
                    Write-Warning "$($File.FullName) does not look like an encrypted file. Skipping."
                    continue
                }

                $DestinationFile = $File.FullName -replace '_encrypted', '_decrypted'

                $reader = $null
                $writer = $null
                $cryptoStream = $null

                try {
                    $reader = [System.IO.File]::OpenRead($File.FullName)
                    $writer = [System.IO.File]::Open($DestinationFile, [System.IO.FileMode]::Create)

                    [byte[]]$lenIV = New-Object byte[] 4
                    $reader.Read($lenIV, 0, 4) | Out-Null
                    $ivLength = [BitConverter]::ToInt32($lenIV, 0)

                    [byte[]]$IV = New-Object byte[] $ivLength
                    $reader.Read($IV, 0, $ivLength) | Out-Null
                    $Crypto.IV = $IV

                    $decryptor = $Crypto.CreateDecryptor()
                    $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($writer, $decryptor, 'Write')
                    $reader.CopyTo($cryptoStream)
                    $cryptoStream.FlushFinalBlock()

                    $info = Get-Item $DestinationFile
                    $info | Add-Member NoteProperty SourceFile   $File.FullName
                    $info | Add-Member NoteProperty Algorithm    $Algorithm
                    $info | Add-Member NoteProperty CipherMode   $Crypto.Mode
                    $info | Add-Member NoteProperty PaddingMode  $Crypto.Padding

                    $results += $info
                }
                catch {
                    if ($writer) { $writer.Close() }
                    if (Test-Path $DestinationFile) { Remove-Item $DestinationFile -Force }
                    Write-Error "Decryption failed for $($File.FullName): $_"
                }
                finally {
                    if ($cryptoStream) { $cryptoStream.Close() }
                    if ($reader) { $reader.Close() }
                    if ($writer) { $writer.Close() }
                }
            }

            return Ok -Value $results -Message "$($results.Count) file(s) decrypted"
        }
        catch {
            return Err -Message "Decryption error: $_"
        }
    }

    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $keyBytes = DeriveKeyFromPassword $Password

        $result = DecryptFileInternal -FileName $Path -KeyBytes $keyBytes
        $stopwatch.Stop()

        if ($result.ok) {
            Write-Host "✅ File decrypted in $([math]::Round($stopwatch.Elapsed.TotalSeconds, 1)) sec" -ForegroundColor Green
        }

        return $result
    }
    catch {
        return Err -Message "Top-level decryption failed: $_"
    }
}
