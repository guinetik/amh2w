function Convert-ImageToAscii {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$ImagePath,
        
        [Parameter(Mandatory=$false)]
        [int]$Width = 80,
        
        [Parameter(Mandatory=$false)]
        [switch]$Invert
    )
    
    # ASCII character palette from dark to light
    $asciiChars = @(' ', '.', ':', '-', '=', '+', '*', '#', '%', '@')
    if ($Invert) {
        [array]::Reverse($asciiChars)
    }
    
    try {
        # Check if image exists
        if (-not (Test-Path $ImagePath)) {
            return Err "Image file not found: $ImagePath"
        }
        
        # Load the image using .NET System.Drawing
        Add-Type -AssemblyName System.Drawing
        
        $img = [System.Drawing.Image]::FromFile((Resolve-Path $ImagePath).Path)
        
        # Calculate new height to maintain aspect ratio
        $aspectRatio = $img.Height / $img.Width
        $height = [int]($Width * $aspectRatio * 0.5)  # 0.5 because characters are typically taller than wide
        
        # Resize image
        $resized = New-Object System.Drawing.Bitmap($Width, $height)
        $graphics = [System.Drawing.Graphics]::FromImage($resized)
        $graphics.DrawImage($img, 0, 0, $Width, $height)
        
        # Convert to ASCII
        $asciiArt = @()
        for ($y = 0; $y -lt $resized.Height; $y++) {
            $line = ""
            for ($x = 0; $x -lt $resized.Width; $x++) {
                $pixel = $resized.GetPixel($x, $y)
                $brightness = [int](($pixel.R + $pixel.G + $pixel.B) / 3)
                $charIndex = [int]($brightness / 255 * ($asciiChars.Length - 1))
                $line += $asciiChars[$charIndex]
            }
            $asciiArt += $line
        }
        
        # Clean up
        $graphics.Dispose()
        $resized.Dispose()
        $img.Dispose()
        
        # Display ASCII art
        foreach ($line in $asciiArt) {
            Write-Host $line
        }
        
        return Ok -Value $asciiArt -Message "ASCII art generated successfully"
    }
    catch {
        return Err "Failed to convert image: $_"
    }
}

function ascii {
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        $ImagePath,
        
        [Parameter(Position = 1)]
        [int]$Width = 80,
        
        [Parameter(Position = 2)]
        [object]$Invert,
        
        [Parameter(Position = 3)]
        [object]$Help
    )

    $Invert = Truthy $Invert
    
    if ($Help) {
        Write-Host "`nASCII Art Converter - Transform images into text art"
        Write-Host "=================================================="
        Write-Host "`nUsage:"
        Write-Host "  all my homies luv ascii <ImagePath> [-Width <int>] [-Invert]"
        Write-Host "`nParameters:"
        Write-Host "  ImagePath   Path to the image file (jpg, png, gif, bmp)"
        Write-Host "  -Width      Width of ASCII output in characters (default: 80)"
        Write-Host "  -Invert     Invert the brightness mapping"
        Write-Host "  -Help       Show this help message"
        Write-Host "`nExamples:"
        Write-Host "  all my homies luv ascii ./photo.jpg"
        Write-Host "  all my homies luv ascii ./logo.png -Width 120"
        Write-Host "  all my homies luv ascii ./icon.gif -Invert"
        Write-Host "`nNote: Height is automatically calculated to maintain aspect ratio`n"
        return
    }
    
    if (-not $ImagePath) {
        return Err "Please provide an image path. Use -Help for usage information."
    }
    
    # Handle pipeline input
    if ($ImagePath -is [hashtable] -and $ImagePath.ContainsKey('Value')) {
        $ImagePath = $ImagePath.Value
    }
    
    Log-Info "Converting image to ASCII art..."
    
    # Call the converter
    $result = Convert-ImageToAscii -ImagePath $ImagePath -Width $Width -Invert:$Invert
    
    return $result
}