function headlines {
    param([string]$RSS_URL = "https://news.yahoo.com/rss/world", [int]$maxLines = 24, [int]$speed = 5)

    try {
        [xml]$content = (Invoke-WebRequest -URI $RSS_URL -useBasicParsing).Content
        $title = $content.rss.channel.title
        $URL = $content.rss.channel.link
        Write-Host "`n UTC   HEADLINES             (source: " -noNewline
        Write-Host $URL -foregroundColor blue -noNewline
        Write-Host ")"
        Write-Host " ---   ---------"
        [int]$count = 1
        foreach ($item in $content.rss.channel.item) {
            $title = $item.title -replace "â", "'"
            $time = $item.pubDate.Substring(11, 5)
            Write-Host "$time  $title"
            if ($count++ -eq $maxLines) { break }
        }
        exit 0 # success
    }
    catch {
        "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
        exit 1
    }
}