function rss {
    param([int]$maxLines = 10, [string]$RSS_URL = "https://news.yahoo.com/rss/world", [int]$speed = 5)

    try {
        Log-Info "Fetching headlines from $RSS_URL"
        [xml]$content = (Invoke-WebRequest -URI $RSS_URL -useBasicParsing).Content
        $channelTitle = $content.rss.channel.title
        if ($channelTitle -is [System.Xml.XmlNode]) {
            $channelTitle = $channelTitle.InnerText
        }
        WriteLine "📰 NEWS FROM $channelTitle"
        
        # Create namespace manager for XPath queries once
        $nsManager = New-Object System.Xml.XmlNamespaceManager($content.NameTable)
        # Add the media namespace - common URL for media RSS content
        $nsManager.AddNamespace("media", "http://search.yahoo.com/mrss/")
        
        $headlines = @()
        [int]$count = 1
        foreach ($item in $content.rss.channel.item) {
            # Extract text content directly using proper handling for CDATA
            # XPath-like approach for getting the raw text regardless of it being in CDATA or not
            $title = $item.title
            if ($title -is [System.Xml.XmlNode]) {
                # For titles in CDATA or with mixed content
                $title = $title.InnerText
            }
            $title = $title -replace "â", "'"
            $link = $item.link
            # Process description text for display
            $desc = $item.description
            if ($desc -ne $null) {
                # Extract raw text from description node
                if ($desc -is [System.Xml.XmlNode]) {
                    # For descriptions in CDATA or with mixed content
                    $desc = $desc.InnerText
                }
                else {
                    # Regular string conversion
                    $desc = $desc.ToString()
                }
                
                # Remove HTML tags
                $desc = [System.Text.RegularExpressions.Regex]::Replace($desc, '<.*?>', '')
                # Decode HTML entities
                $desc = [System.Net.WebUtility]::HtmlDecode($desc)
                # Clean up whitespace
                $desc = $desc -replace '\s+', ' '
                $desc = $desc.Trim()
            }
            else {
                $desc = "No description available"
            }
            $pubDate = $item.pubDate
            
            # Extract image URL directly from the item
            $imageUrl = $null
            
            # Try to get media:content with SelectSingleNode and XPath
            $mediaNode = $item.SelectSingleNode("media:content", $nsManager)
            if ($mediaNode -and $mediaNode.HasAttribute("url")) {
                $imageUrl = $mediaNode.GetAttribute("url")
            }
            
            # If that didn't work, try with regex extraction on the raw XML
            if (-not $imageUrl) {
                try {
                    $itemXml = $item.OuterXml
                    if ($itemXml -match '<media:content[^>]*url="([^"]+)"') {
                        $imageUrl = $matches[1]
                    }
                }
                catch {
                    # Silent error - just continue with other methods
                }
            }
            
            # Create headline object with all processed data
            $headlineObj = [PSCustomObject]@{
                Title       = $title
                Link        = $link
                Description = $desc  # Use the processed description
                PubDate     = $pubDate
                ImageUrl    = $imageUrl
            }
            $headlines += $headlineObj
            if ($count++ -eq $maxLines) { break }
        }
        $width = $Host.UI.RawUI.WindowSize.Width
        $result = @()
        foreach ($headline in $headlines) {
            $date = $headline.PubDate
            $title = $headline.Title
            $link = $headline.Link
            $imageUrl = $headline.ImageUrl
            # Prepare ASCII art
            $asciiArt = @()
            $tempFile = $null
            $asciiWidth = 50
            if ($imageUrl) {
                try {
                    $tempFile = [System.IO.Path]::GetTempFileName()
                    Invoke-WebRequest -Uri $imageUrl -OutFile $tempFile -ErrorAction Stop
                    $asciiResult = (Convert-ImageToAscii -ImagePath $tempFile -Width $asciiWidth -NoLog)
                    if ($asciiResult.ok) {
                        $asciiArt = $asciiResult.value
                    }
                    else {
                        Log-Error "Error converting image to ASCII: $($asciiResult.error)"
                    }
                }
                catch {
                    Log-Error "Error converting image to ASCII: $_"
                }
                finally {
                    if ($tempFile -and (Test-Path $tempFile)) { Remove-Item $tempFile -ErrorAction SilentlyContinue }
                }
            }
            # Print date
            if ($date) { 
                Write-Host "🗓️ " -NoNewline
                Write-Typewriter $date $speed
            }
            # Print title
            if ($title) { 
                Write-Host "📰 " -NoNewline
                Write-Typewriter $title $speed -ForegroundColor Yellow
            }
            # Print ASCII art or placeholder
            if ($asciiArt.Count -gt 0) {
                foreach ($line in $asciiArt) { Write-Host $line -ForegroundColor DarkGray }
            }
            else {
                Write-Host "[No Image]" -ForegroundColor DarkGray
            }
            # Print description
            if ($headline.Description -and $headline.Description -ne "No description available") {
                $gravatinha = Write-Text-Elipsis $headline.Description (($width * 2) + $width / 2)
                Write-Host "📝  " -NoNewline
                Write-Host $gravatinha -ForegroundColor White
            }
            # Print link
            if ($link) { Write-Host ("🔗  " + $link) -ForegroundColor DarkBlue }
            # Blank line between headlines
            Write-Host ""
            Print-HR
            # Add sanitized object to array
            $result += [PSCustomObject]@{
                Date        = $date
                Title       = $title
                Description = $headline.Description
                Link        = $link
                ImageUrl    = $imageUrl
            }
        }
        return Ok $result
    }
    catch {
        Log-Error "$_"
        return Err "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $_"
    }
}