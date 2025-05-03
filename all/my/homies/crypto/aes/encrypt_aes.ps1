function encrypt_aes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Text,

        [Parameter(Mandatory = $true, Position = 1)]
        [SecureString]$Password
    )

    try {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        # Convert SecureString to string
        $passwordString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
        $key = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($passwordString))

        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.KeySize = 256
        $aes.Key = $key
        $aes.GenerateIV()

        $mem = New-Object System.IO.MemoryStream
        $mem.Write([BitConverter]::GetBytes($aes.IV.Length), 0, 4)
        $mem.Write($aes.IV, 0, $aes.IV.Length)

        $crypto = New-Object System.Security.Cryptography.CryptoStream($mem, $aes.CreateEncryptor(), 'Write')
        $writer = New-Object System.IO.StreamWriter($crypto)
        $writer.Write($Text)
        $writer.Close()

        return Ok -Value ([Convert]::ToBase64String($mem.ToArray())) -Message "Text encrypted"
    }
    catch {
        return Err -Message "Encryption failed: $_"
    }
}
