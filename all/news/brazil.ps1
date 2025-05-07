function brazil {
    param([int]$maxLines = 24)
    return rss $maxLines "https://g1.globo.com/dynamo/rss2.xml"
}