function qrcode {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true)]
        [string]$text,
        [Parameter(Position = 1)]
        [string]$imageSize = "500x500",
        [Parameter(Position = 2)]
        [string]$filename = "QR_Code",
        [Parameter(Position = 3)]
        [string]$fileFormat = "jpg"
    )

    try {
        $ECC = "M" # can be L, M, Q, H
        $QuietZone = 1
        $ForegroundColor = "000000"
        $BackgroundColor = "ffffff"
        if ($IsLinux) {
            $pathToPictures = Resolve-Path "$HOME/Pictures"
        }
        else {
            $pathToPictures = [Environment]::GetFolderPath('MyPictures')
        }
        # check if the pictures folder exists
        if (-not(Test-Path "$pathToPictures" -pathType container)) {
            return Err "Pictures folder at 📂$Path doesn't exist (yet)" 
        }
        # create the new file path
        $newFile = "$pathToPictures/$filename.$fileFormat"
        # create the API URL
        $apiURL = ("http://api.qrserver.com/v1/create-qr-code/?data=" + $text + "&ecc=" + $ECC + `
                "&size=" + $imageSize + "&qzone=" + $QuietZone + `
                "&color=" + $ForegroundColor + "&bgcolor=" + $BackgroundColor.Text + `
                "&format=" + $fileFormat)
        # fetch the QR code from the API
        $fetch = fetch -Url $apiURL -OutFile $newFile
        if ($fetch.ok) {
            Write-Host "✅ New QR code saved as: $newFile" -foregroundColor green
            $ascii = all my homies luv ascii $newFile 50
            return Ok $newFile "New QR code saved as: $newFile"
        }
        else {
            Write-Host "❌ Fetch error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])" -foregroundColor red
            return $fetch
        } finally {
            delete $ascii
        }
    }
    catch {
        Write-Host "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])" -foregroundColor Yellow
        return Err "Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    }
}