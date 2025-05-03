function encryptfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Password
    )

    function BytesToBase64 {
        param([char[]]$CharArray)
        return [Convert]::ToBase64String($CharArray)
    }

    function EncryptFileInternal {
        [CmdletBinding(DefaultParameterSetName = 'SecureString')]
        param(
            [Parameter(Mandatory = $true)]
            [string[]]$FileName,

            [Parameter(Mandatory = $true)]
            [string]$KeyAsPlainText,

            [string]$Algorithm = 'AES',
            [string]$Suffix = ".$Algorithm",
            [System.Security.Cryptography.CipherMode]$CipherMode = [System.Security.Cryptography.CipherMode]::CBC,
            [System.Security.Cryptography.PaddingMode]$PaddingMode = [System.Security.Cryptography.PaddingMode]::PKCS7,
            [switch]$RemoveSource
        )

        try {
            $Key = $KeyAsPlainText | ConvertTo-SecureString -AsPlainText -Force
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Key)
            $EncryptionKey = [Convert]::FromBase64String([System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR))

            $Crypto = [System.Security.Cryptography.SymmetricAlgorithm]::Create($Algorithm)
            $Crypto.KeySize = $EncryptionKey.Length * 8
            $Crypto.Key = $EncryptionKey
            $Crypto.Mode = $CipherMode
            $Crypto.Padding = $PaddingMode

            $results = @()
            $Files = Get-Item -LiteralPath $FileName

            foreach ($File in $Files) {
                $DestinationFile = $File.FullName + $Suffix

                $reader = $null
                $writer = $null
                $cryptoStream = $null
                try {
                    $reader = [System.IO.File]::OpenRead($File.FullName)
                    $writer = [System.IO.File]::Open($DestinationFile, [System.IO.FileMode]::Create)

                    $Crypto.GenerateIV()
                    $writer.Write([System.BitConverter]::GetBytes($Crypto.IV.Length), 0, 4)
                    $writer.Write($Crypto.IV, 0, $Crypto.IV.Length)

                    $transform = $Crypto.CreateEncryptor()
                    $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($writer, $transform, [System.Security.Cryptography.CryptoStreamMode]::Write)
                    $reader.CopyTo($cryptoStream)

                    $cryptoStream.FlushFinalBlock()

                    if ($RemoveSource) {
                        Remove-Item -LiteralPath $File.FullName -Force
                    }

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
                    Write-Error "Encryption failed for $($File.FullName): $_"
                }
                finally {
                    if ($cryptoStream) { $cryptoStream.Close() }
                    if ($reader) { $reader.Close() }
                    if ($writer) { $writer.Close() }
                }
            }

            return Ok -Value $results -Message "$($results.Count) file(s) encrypted"
        }
        catch {
            return Err -Message "Encryption error: $_"
        }
    }

    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        [char[]]$charArray = $Password
        $base64 = BytesToBase64 $charArray

        $result = EncryptFileInternal -FileName $Path -KeyAsPlainText $base64 -RemoveSource
        $stopwatch.Stop()

        if ($result.ok) {
            Write-Host "✅ File encrypted in $([math]::Round($stopwatch.Elapsed.TotalSeconds, 1)) sec" -ForegroundColor Green
        }

        return $result
    }
    catch {
        return Err -Message "Top-level error: $_"
    }
}
