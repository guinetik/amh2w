function folders {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    return namespace "folders" "all my folders" 
}