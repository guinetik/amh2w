function decryupt_aes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$EncryptedText,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Password
    )

    try {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $key = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Password))

        $bytes = [Convert]::FromBase64String($EncryptedText)
        $mem = New-Object System.IO.MemoryStream
        $mem.Write($bytes, 0, $bytes.Length)
        $mem.Seek(0, 'Begin') | Out-Null

        [byte[]]$lenIV = New-Object byte[] 4
        $mem.Read($lenIV, 0, 4) | Out-Null
        $ivLength = [BitConverter]::ToInt32($lenIV, 0)

        [byte[]]$IV = New-Object byte[] $ivLength
        $mem.Read($IV, 0, $ivLength) | Out-Null

        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.KeySize = 256
        $aes.Key = $key
        $aes.IV = $IV

        $crypto = New-Object System.Security.Cryptography.CryptoStream($mem, $aes.CreateDecryptor(), 'Read')
        $reader = New-Object System.IO.StreamReader($crypto)
        $plaintext = $reader.ReadToEnd()
        $reader.Close()

        return Ok -Value $plaintext -Message "Text decrypted"
    }
    catch {
        Write-Host "Error: Command function '$arg' failed: $_" -ForegroundColor Red
        return Err -Msg "Decryption failed: $_"
    }
}
