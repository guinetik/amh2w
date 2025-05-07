function img {
    param(
        [Parameter(Position = 1, ValueFromRemainingArguments)]
        [object[]]$Arguments
    )
    
    if (-not $Arguments -or $Arguments[0] -eq "help") {
        $help = @"
AMH2W Converter Module
Usage: all my homies convert img [inputfile] [format] [outputfile] [width] [height] [quality] [preservemetadata] [recursive]
Examples:
  all my homies convert img input.png jpg
  all my homies convert img folder/ png 800 auto
  all my homies convert img *.jpg png -Quality 90
"@
        Write-Host $help
        return Ok "Help displayed"
    }

    return Convert-Image @Arguments
}

function Convert-Image {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$InputFile,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Format,
        [Parameter(Position = 2)]
        [string]$Output,
        [Parameter(Position = 3)]
        [string]$Width = "auto",
        [Parameter(Position = 4)]
        [string]$Height = "auto",
        [int]$Quality,
        [switch]$PreserveMetadata,
        [switch]$Recursive
    )

    # Check for available image processing tools
    $imageProcessor = Get-ImageProcessor
    if (-not $imageProcessor.ok) {
        return $imageProcessor
    }

    $processor = $imageProcessor.Value

    # Determine if input is file or directory
    if (Test-Path -Path $InputFile -PathType Container) {
        # Directory processing
        return Convert-ImageDirectory -Path $InputFile -Format $Format -Width $Width -Height $Height -Quality $Quality -PreserveMetadata:$PreserveMetadata -OutputDir $Output -Recursive:$Recursive -Processor $processor
    }
    elseif (Test-Path -Path $InputFile -PathType Leaf) {
        # Single file processing
        return Convert-SingleImage -Input $InputFile -Format $Format -Output $Output -Width $Width -Height $Height -Quality $Quality -PreserveMetadata:$PreserveMetadata -Processor $processor
    }
    else {
        # Pattern matching (e.g., *.png)
        return Convert-Images-From-Patterns -Pattern $InputFile -Format $Format -Width $Width -Height $Height -Quality $Quality -PreserveMetadata:$PreserveMetadata -OutputDir $Output -Processor $processor
    }
}

function Get-ImageProcessor {
    # Check for ImageMagick
    $magick = Get-Command "magick" -ErrorAction SilentlyContinue
    if ($magick) {
        Log-Info "Using ImageMagick for image processing"
        return Ok @{ Name = "ImageMagick"; Command = "magick" }
    }

    # Check for FFmpeg
    $ffmpeg = Get-Command "ffmpeg" -ErrorAction SilentlyContinue
    if ($ffmpeg) {
        Log-Info "Using FFmpeg for image processing"
        Log-Warning "Yo you should install ImageMagick, it's better! 🤓"
        return Ok @{ Name = "FFmpeg"; Command = "ffmpeg" }
    }

    # Fallback to System.Drawing (limited functionality)
    try {
        Add-Type -AssemblyName System.Drawing
        Log-Info "Using System.Drawing for image processing (limited features)"
        Log-Warning "Hello, if you do a lot of image processing, you should install ImageMagick, it's better! 🤓"
        return Ok @{ Name = "System.Drawing"; Command = $null }
    }
    catch {
        return Err "No image processor found. Install ImageMagick with: all my homies install imagemagick"
    }
}

function Convert-SingleImage {
    param(
        $InputFile,
        $Format,
        $Output,
        $Width,
        $Height,
        $Quality,
        $PreserveMetadata,
        $Processor
    )

    # Generate output filename if not specified
    if (-not $Output) {
        $outputDir = [System.IO.Path]::GetDirectoryName($InputFile)
        $outputName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
        $Output = Join-Path $outputDir "$outputName.$Format"
    }

    # Process based on available processor
    switch ($Processor.Name) {
        "ImageMagick" {
            return Convert-WithImageMagick -Input $InputFile -Output $Output -Width $Width -Height $Height -Quality $Quality -PreserveMetadata:$PreserveMetadata
        }
        "FFmpeg" {
            return Convert-WithFFmpeg -Input $InputFile -Output $Output -Width $Width -Height $Height -Quality $Quality
        }
        "System.Drawing" {
            return Convert-WithSystemDrawing -Input $InputFile -Output $Output -Width $Width -Height $Height -Quality $Quality
        }
    }
}

function Convert-WithImageMagick {
    param($InputFile, $Output, $Width, $Height, $Quality, $PreserveMetadata)
    
    $arguments = @($InputFile)
    
    # Handle resize parameters
    if ($Width -ne "auto" -or $Height -ne "auto") {
        $resizeParam = ""
        if ($Width -eq "auto" -and $Height -ne "auto") {
            $resizeParam = "x$Height"
        }
        elseif ($Width -ne "auto" -and $Height -eq "auto") {
            $resizeParam = "${Width}x"
        }
        elseif ($Width -ne "auto" -and $Height -ne "auto") {
            $resizeParam = "${Width}x${Height}!"
        }
        
        if ($resizeParam) {
            $arguments += "-resize"
            $arguments += $resizeParam
        }
    }
    
    # Handle quality
    if ($Quality) {
        $arguments += "-quality"
        $arguments += $Quality
    }
    
    # Handle metadata
    if (-not $PreserveMetadata) {
        $arguments += "-strip"
    }
    
    $arguments += $Output
    
    try {
        $result = & magick @arguments 2>&1
        if ($LASTEXITCODE -ne 0) {
            return Err "ImageMagick failed: $result"
        }
        return Ok "Converted $InputFile to $Output"
    }
    catch {
        return Err "ImageMagick error: $_"
    }
}

function Convert-WithFFmpeg {
    param($InputFile, $Output, $Width, $Height, $Quality)
    
    $arguments = @("-i", $InputFile)
    
    # Handle resize with FFmpeg
    if ($Width -ne "auto" -or $Height -ne "auto") {
        $scaleParam = ""
        if ($Width -eq "auto" -and $Height -ne "auto") {
            $scaleParam = "-1:$Height"
        }
        elseif ($Width -ne "auto" -and $Height -eq "auto") {
            $scaleParam = "${Width}:-1"
        }
        elseif ($Width -ne "auto" -and $Height -ne "auto") {
            $scaleParam = "${Width}:${Height}"
        }
        
        if ($scaleParam) {
            $arguments += "-vf"
            $arguments += "scale=$scaleParam"
        }
    }
    
    # Handle quality for JPEG
    if ($Quality -and $Output -match "\.(jpg|jpeg)$") {
        $arguments += "-q:v"
        $arguments += [math]::Round((100 - $Quality) / 3.33)  # FFmpeg uses inverse scale
    }
    
    $arguments += $Output
    
    try {
        $result = & ffmpeg @arguments -y 2>&1
        if ($LASTEXITCODE -ne 0) {
            return Err "FFmpeg failed: $result"
        }
        return Ok "Converted $InputFile to $Output"
    }
    catch {
        return Err "FFmpeg error: $_"
    }
}

function Convert-WithSystemDrawing {
    param($InputFile, $Output, $Width, $Height, $Quality)
    
    try {
        $image = [System.Drawing.Image]::FromFile($InputFile)
        
        # Calculate new dimensions
        $newWidth = $image.Width
        $newHeight = $image.Height
        
        if ($Width -ne "auto" -and $Width -match '^\d+$') {
            $newWidth = [int]$Width
            if ($Height -eq "auto") {
                $newHeight = [int]($image.Height * ($newWidth / $image.Width))
            }
        }
        
        if ($Height -ne "auto" -and $Height -match '^\d+$') {
            $newHeight = [int]$Height
            if ($Width -eq "auto") {
                $newWidth = [int]($image.Width * ($newHeight / $image.Height))
            }
        }
        
        # Create resized bitmap if dimensions changed
        if ($newWidth -ne $image.Width -or $newHeight -ne $image.Height) {
            $resized = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
            $graphics = [System.Drawing.Graphics]::FromImage($resized)
            $graphics.DrawImage($image, 0, 0, $newWidth, $newHeight)
            $graphics.Dispose()
            $image.Dispose()
            $image = $resized
        }
        
        # Determine output format
        $imageFormat = [System.Drawing.Imaging.ImageFormat]::Png
        switch -Regex ($Output) {
            "\.(jpg|jpeg)$" { $imageFormat = [System.Drawing.Imaging.ImageFormat]::Jpeg }
            "\.bmp$" { $imageFormat = [System.Drawing.Imaging.ImageFormat]::Bmp }
            "\.gif$" { $imageFormat = [System.Drawing.Imaging.ImageFormat]::Gif }
            "\.tiff?$" { $imageFormat = [System.Drawing.Imaging.ImageFormat]::Tiff }
        }
        
        # Save with quality settings for JPEG
        if ($imageFormat -eq [System.Drawing.Imaging.ImageFormat]::Jpeg -and $Quality) {
            $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
            $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, $Quality)
            $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.FormatDescription -eq "JPEG" }
            $image.Save($Output, $jpegCodec, $encoderParams)
        }
        else {
            $image.Save($Output, $imageFormat)
        }
        
        $image.Dispose()
        return Ok "Converted $InputFile to $Output"
    }
    catch {
        return Err "System.Drawing error: $_"
    }
}

function Convert-ImageDirectory {
    param($Path, $Format, $Width, $Height, $Quality, $PreserveMetadata, $OutputDir, $Recursive, $Processor)
    
    # Get image files
    $extensions = @("*.jpg", "*.jpeg", "*.png", "*.gif", "*.bmp", "*.tiff", "*.tif")
    
    $files = @()
    foreach ($ext in $extensions) {
        $files += Get-ChildItem -Path $Path -Filter $ext -File -Recurse:$Recursive
    }
    
    if ($files.Count -eq 0) {
        return Err "No image files found in $Path"
    }
    
    # Create output directory if specified
    if ($OutputDir -and -not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }
    
    $results = @()
    $successCount = 0
    $errorCount = 0
    
    foreach ($file in $files) {
        $outputPath = if ($OutputDir) {
            Join-Path $OutputDir "$([System.IO.Path]::GetFileNameWithoutExtension($file.Name)).$Format"
        }
        else {
            Join-Path $file.DirectoryName "$([System.IO.Path]::GetFileNameWithoutExtension($file.Name)).$Format"
        }
        
        $result = Convert-SingleImage -Input $file.FullName -Format $Format -Output $outputPath -Width $Width -Height $Height -Quality $Quality -PreserveMetadata:$PreserveMetadata -Processor $Processor
        
        if ($result.ok) {
            $successCount++
            Log-Info $result.value
        }
        else {
            $errorCount++
            Log-Error $result.message
        }
        
        $results += $result
    }
    # Return the files list and a message
    return Ok $files "Processed $($files.Count) files: $successCount successful, $errorCount errors"
}

function Convert-Images-From-Patterns {
    param($Pattern, $Format, $Width, $Height, $Quality, $PreserveMetadata, $OutputDir, $Processor)
    
    $files = Get-ChildItem -Path $Pattern -File -ErrorAction SilentlyContinue
    
    if ($files.Count -eq 0) {
        return Err "No files found matching pattern: $Pattern"
    }
    
    # Create output directory if specified
    if ($OutputDir -and -not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }
    
    $results = @()
    $successCount = 0
    $errorCount = 0
    
    foreach ($file in $files) {
        $outputPath = if ($OutputDir) {
            Join-Path $OutputDir "$([System.IO.Path]::GetFileNameWithoutExtension($file.Name)).$Format"
        }
        else {
            Join-Path $file.DirectoryName "$([System.IO.Path]::GetFileNameWithoutExtension($file.Name)).$Format"
        }
        
        $result = Convert-SingleImage -Input $file.FullName -Format $Format -Output $outputPath -Width $Width -Height $Height -Quality $Quality -PreserveMetadata:$PreserveMetadata -Processor $Processor
        
        if ($result.ok()) {
            $successCount++
            Log-Info $result.value
        }
        else {
            $errorCount++
            Log-Error $result.message
        }
        
        $results += $result
    }
    
    return Ok "Processed $($files.Count) files: $successCount successful, $errorCount errors"
}