<#
.SYNOPSIS
Displays recent git commits by the current user.

.DESCRIPTION
Shows git commits from the last month by the currently configured git user,
formatted as a table with hash, date, message, and author information.

.NOTES
File: all/my/gitcommits.ps1
Command: all my gitcommits

.EXAMPLE
all my gitcommits
Displays recent commits by the current user in a formatted table.

.OUTPUTS
Returns an Ok result object containing the commit information.
#>

function gitcommits {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    try {
        Log-Info "Getting recent git commits..."
        
        # Set console encoding to handle Unicode characters properly
        $originalEncoding = [Console]::OutputEncoding
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        
        # Check if we're in a git repository
        $gitCheck = & git rev-parse --is-inside-work-tree 2>$null
        if ($LASTEXITCODE -ne 0) {
            Log-Error "Not in a git repository or git is not available"
            return Err "Not in a git repository or git is not available"
        }
        
        # Get the current user's email
        $userEmail = & git config user.email 2>$null
        if ([string]::IsNullOrEmpty($userEmail)) {
            Log-Warning "Git user email not configured, showing all commits"
            $authorFilter = ""
        } else {
            $authorFilter = "--author=$userEmail"
            Log-Debug "Filtering commits by author: $userEmail"
        }
        
        # Get the git log output with UTF-8 encoding
        $gitArgs = @(
            "-c"
            "core.quotepath=false"
            "-c"
            "i18n.logoutputencoding=utf-8"
            "log"
            "--all"
            "--since=1 month ago"
            "--pretty=format:%h | %ad | %s | %an"
            "--date=short"
        )
        
        if (-not [string]::IsNullOrEmpty($authorFilter)) {
            $gitArgs += $authorFilter
        }
        
        $commits = & git @gitArgs 2>$null
        
        if ($LASTEXITCODE -ne 0) {
            Log-Error "Failed to retrieve git commits"
            return Err "Failed to retrieve git commits"
        }
        
        # Display the header
        Write-Host "Hash    | Date       | Message                                          | Author" -ForegroundColor Cyan
        Write-Host "--------|------------|--------------------------------------------------|--------" -ForegroundColor Gray
        
        # Display each commit
        if ($commits -and $commits.Count -gt 0) {
            foreach ($commit in $commits) {
                if (-not [string]::IsNullOrEmpty($commit)) {
                    # Split the commit line and format each part
                    $parts = $commit -split ' \| ', 4
                    if ($parts.Length -eq 4) {
                        $hash = $parts[0]
                        $date = $parts[1]
                        $message = $parts[2]
                        $author = $parts[3]
                        
                        # Truncate message if too long
                        if ($message.Length -gt 48) {
                            $message = $message.Substring(0, 45) + "..."
                        }
                        
                        # Truncate author if too long
                        if ($author.Length -gt 20) {
                            $author = $author.Substring(0, 17) + "..."
                        }
                        
                        # Format and display the line
                        Write-Host ("{0,-8}| {1,-10} | {2,-48} | {3}" -f $hash, $date, $message, $author)
                    } else {
                        # Fallback: display the raw line if parsing fails
                        Write-Host $commit
                    }
                }
            }
            
            Log-Info "Found $($commits.Count) commits in the last month"
        } else {
            Write-Host "No commits found in the last month" -ForegroundColor Yellow
            Log-Info "No commits found in the last month"
        }
        
        # Return success with the commit data
        return Ok -Value $commits -Message "Git commits retrieved successfully"
    }
    catch {
        Log-Error "Error retrieving git commits: $_"
        return Err "Error retrieving git commits: $_"
    }
    finally {
        # Restore original console encoding
        if ($originalEncoding) {
            [Console]::OutputEncoding = $originalEncoding
        }
    }
}