function encrypt_aes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Text,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Password
    )

    try {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $key = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Password))

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
        return Err -Msg "Encryption failed: $_"
    }
}
