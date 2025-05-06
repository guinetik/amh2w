function ascii {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        $ImagePath,
        
        [Parameter(Position = 1)]
        [int]$Width = 80,
        
        [Parameter(Position = 2)]
        [object]$Invert
    )

    try {
        if ($ImagePath -eq "help" -or $ImagePath -eq "h" -or $null -eq $ImagePath) {
            Write-Host "`nASCII Art Converter - Transform images into text art"
            Write-Host "=================================================="
            Write-Host "`nUsage:"
            Write-Host "  all my homies luv ascii <ImagePath> [-Width <int>] [-Invert]"
            Write-Host "`nParameters:"
            Write-Host "  ImagePath  Path to the image file (jpg, png, gif, bmp)"
            Write-Host "  Width      Width of ASCII output in characters (default: 80)"
            Write-Host "  Invert     Invert the brightness mapping"
            Write-Host "`nExamples:"
            Write-Host "  all my homies luv ascii ./photo.jpg"
            Write-Host "  all my homies luv ascii ./logo.png -Width 120"
            Write-Host "  all my homies luv ascii ./icon.gif -Invert"
            Write-Host "`nNote: Height is automatically calculated to maintain aspect ratio`n"
            return
        }
        Log-Info "Converting image to ASCII art..."
        return Convert-ImageToAscii -ImagePath $ImagePath -Width $Width -Invert:$Invert
    }
    catch {
        #print line number
        Write-Host "Line number: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
        return Err "Failed to convert image: $_"
    }
}

function Convert-ImageToAscii {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$ImagePath,
        
        [Parameter(Mandatory = $false)]
        [int]$Width = 80,
        
        [Parameter(Mandatory = $false)]
        [object]$Invert
    )
    
    Log-Info "Starting image conversion: $ImagePath"
    
    # More varied ASCII character palette from dark to light for better gradients
    $asciiChars = @(' ','.',':','-','=','+','*','!','%','#')
    
    # Invert is an object for a reason. It cannot be a switch. We need to check if it's truthy.
    if ($Invert) {
        $Invert = Truthy $Invert
        Log-Info "Inverting ASCII character palette"
    }

    if($Invert -eq $true) {
        $asciiChars = $asciiChars | Sort-Object -Descending
    }
    
    try {
        # Check if image exists with more detailed error
        if (-not (Test-Path $ImagePath)) {
            Log-Error "Image file not found: $ImagePath"
            return Err "Image file not found: $ImagePath. Please check the path and try again."
        }
        
        # Load the image using .NET System.Drawing
        Add-Type -AssemblyName System.Drawing
        
        try {
            $img = [System.Drawing.Image]::FromFile((Resolve-Path $ImagePath).Path)
        }
        catch {
            Log-Error "Failed to load image: $_"
            return Err "Failed to load image: The file exists but may be corrupted or in an unsupported format."
        }
        
        # Check image dimensions
        if ($img.Width -le 0 -or $img.Height -le 0) {
            $img.Dispose()
            Log-Error "Invalid image dimensions"
            return Err "The image has invalid dimensions (width: $($img.Width), height: $($img.Height))."
        }
        
        # Calculate new height to maintain aspect ratio with better precision
        $aspectRatio = $img.Height / $img.Width
        # Adjust for terminal character aspect ratio (characters are roughly twice as tall as wide)
        $height = [int]($Width * $aspectRatio * 0.43)
        
        if ($height -le 0) {
            $height = 1 # Ensure at least one line of output
        }
        
        Log-Info "Resizing image to $Width x $height for ASCII conversion"
        
        # Resize image with better quality settings
        $resized = New-Object System.Drawing.Bitmap($Width, $height)
        $graphics = [System.Drawing.Graphics]::FromImage($resized)
        # Set higher quality interpolation
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        # Draw the resized image
        $graphics.DrawImage($img, 0, 0, $Width, $height)
        
        # Convert to ASCII with improved brightness algorithm
        $asciiArt = [System.Collections.ArrayList]::new()
        
        Log-Info "Converting pixels to ASCII characters"
        
        for ($y = 0; $y -lt $height; $y++) {
            $line = ""
            for ($x = 0; $x -lt $Width; $x++) {
                $pixel = $resized.GetPixel($x, $y)
                $r, $g, $b = $pixel.R, $pixel.G, $pixel.B

                # Improved perceptual brightness formula (matches human eye sensitivity better)
                # Using the formula: 0.299R + 0.587G + 0.114B
                $brightness = [math]::Round((0.299 * $r + 0.587 * $g + 0.114 * $b))
                
                # Map brightness to character index with better distribution
                $index = [math]::Floor(($brightness / 255.0) * ($asciiChars.Length - 1))
                $index = [math]::Max(0, [math]::Min($index, $asciiChars.Length - 1))
                
                $line += $asciiChars[$index]
            }
            [void]$asciiArt.Add($line)
        }
        
        # Clean up resources properly
        $graphics.Dispose()
        $resized.Dispose()
        $img.Dispose()
        
        Log-Info "ASCII conversion complete: $($asciiArt.Count) lines generated"
        
        # Display ASCII art with coloring option for better visibility
        if ($host.UI.SupportsVirtualTerminal) {
            # Use a subtle gray color for better visibility in most terminals
            Write-Host "`e[38;5;250m" -NoNewline
        }
        
        foreach ($line in $asciiArt) {
            Write-Host $line
        }
        
        if ($host.UI.SupportsVirtualTerminal) {
            # Reset color
            Write-Host "`e[0m" -NoNewline
        }
        
        return Ok -Value $asciiArt -Message "ASCII art generated successfully ($Width x $($asciiArt.Count))"
    }
    catch {
        Log-Error "Exception during image conversion: $_"
        return Err "Failed to convert image: $($_.Exception.Message)"
    }
    finally {
        # Ensure resources are cleaned up even if an error occurs
        if ($null -ne $graphics) { $graphics.Dispose() }
        if ($null -ne $resized) { $resized.Dispose() }
        if ($null -ne $img) { $img.Dispose() }
    }
}
