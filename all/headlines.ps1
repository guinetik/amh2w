function headlines {
    param([string]$RSS_URL = "https://news.yahoo.com/rss/world", [int]$maxLines = 24, [int]$speed = 5)

    try {
        [xml]$content = (Invoke-WebRequest -URI $RSS_URL -useBasicParsing).Content
        $title = $content.rss.channel.title
        $URL = $content.rss.channel.link
        Write-Host "`n UTC   HEADLINES             (source: " -noNewline
        Write-Host $URL -foregroundColor blue -noNewline
        Write-Host ")"
        Write-Host " ------------"
        [int]$count = 1
        $result = @()
        foreach ($item in $content.rss.channel.item) {
            $title = $item.title -replace "â", "'"
            # Parse time from pubDate
            $pubDate = $item.pubDate
            $time = $null
            if ($pubDate) {
                try {
                    $dt = [DateTime]::Parse($pubDate)
                    $time = $dt.ToString("HH:mm")
                } catch {
                    $time = $pubDate
                }
            }
            $link = $item.link
            Write-Host "$time  $title"
            $result += [PSCustomObject]@{
                Title = $title
                Time = $time
                Link = $link
            }
            if ($count++ -eq $maxLines) { break }
        }
        return Ok $result
    }
    catch {
        return Err "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    }
}