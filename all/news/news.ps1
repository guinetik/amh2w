function my {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    # I want to do something where you can add your own RSS feeds to the news namespace. 
    # TODO: Implement this.
    <# if ($Arguments.Count -ne 0) {
        if ($Arguments[0] -eq "add") {
        
        }

    } #>
    
    return namespace "news" "all news"
}
