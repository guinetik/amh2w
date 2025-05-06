# my.ps1
# Handles 'my' namespace commands

function my {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    return namespace "my" "all my"
}
