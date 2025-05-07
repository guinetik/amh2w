function world {
    [CmdletBinding()]
    param(
        [int]$maxLines = 10
    )
    return rss $maxLines "https://news.yahoo.com/rss/world"
}
