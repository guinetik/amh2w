function decrypt_aes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$EncryptedText,

        [Parameter(Mandatory = $true, Position = 1)]
        [SecureString]$Password
    )

    try {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        # Convert SecureString to string
        $passwordString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
        $key = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($passwordString))

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
        return Err -Message "Decryption failed: $_"
    }
}
