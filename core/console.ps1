<#
.SYNOPSIS
Prints text to the console character by character with a typing animation effect.

.DESCRIPTION
Displays text one character at a time with a specified speed to create a typewriter-like animation.
This function centers the text in the terminal window as it's being typed.

.PARAMETER line
The text to display with the typewriter effect.

.PARAMETER speed
The delay in milliseconds between characters. Default is 10.0 ms.

.EXAMPLE
WriteLine "Welcome to AMH2W!" 20.0

.NOTES
This function is primarily used for visual effects in welcome screens or interactive prompts.
#>
function WriteLine([string]$line, [double]$speed = 10.0) {
    [int]$end = $line.Length
    $startPos = $HOST.UI.RawUI.CursorPosition
    $spaces = "                                                                     "
    [int]$termHalfWidth = 120 / 2
    foreach ($pos in 1 .. $end) {
        $HOST.UI.RawUI.CursorPosition = $startPos
        Write-Host "$($spaces.Substring(0, $termHalfWidth - $pos / 2) + $line.Substring(0, $pos))" -noNewline
        Start-Sleep -milliseconds $speed
    }
    Write-Host ""
}

<#
.SYNOPSIS
Outputs text centered in the console window.

.DESCRIPTION
Calculates the appropriate number of spaces to add before text to center it in the console window.

.PARAMETER text
The text to center in the console window. If empty, prompts the user for input.

.EXAMPLE
Write-Centered "This text will be centered"

.NOTES
Uses the console's maximum window width to determine centering.
#>
function Write-Centered {
    param([string]$text = "")

    try {
        if ($text -eq "") { $text = Read-Host "Enter the text to write" }

        $ui = (Get-Host).ui
        $rui = $ui.rawui 
        [int]$numSpaces = ($rui.MaxWindowSize.Width - $text.Length) / 2

        [string]$spaces = ""
        for ([int]$i = 0; $i -lt $numSpaces; $i++) { $spaces += " " }
        Write-Host "$spaces$text"
        exit 0 # success
    }
    catch {
        "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
        exit 1
    }
}

<#
.SYNOPSIS
Generates a formatted changelog from Git commit messages.

.DESCRIPTION
Analyzes commit messages in a Git repository and organizes them into categories based on
the first word of each commit message (e.g., "New", "Add", "Fix", etc.). The output is
formatted as a readable changelog with emoji indicators for each category.

.PARAMETER RepoDir
The path to the Git repository directory. Defaults to the current directory.

.EXAMPLE
Write-CHANGELOG

.EXAMPLE
Write-CHANGELOG -RepoDir "C:\Projects\MyRepo"

.NOTES
Requires Git to be installed and accessible in the PATH.
#>
function Write-CHANGELOG {
    param([string]$RepoDir = "$PWD")
 
    try {
        [system.threading.thread]::currentthread.currentculture = [system.globalization.cultureinfo]"en-US"

        Write-Progress "(1/6) Searching for Git executable..."
        $null = (git --version)
        if ($lastExitCode -ne 0) { throw "Can't execute 'git' - make sure Git is installed and available" }

        Write-Progress "(2/6) Checking local repository..."
        if (!(Test-Path "$RepoDir" -pathType container)) { throw "Can't access folder: $RepoDir" }
        $RepoDirName = (Get-Item "$RepoDir").Name

        Write-Progress "(3/6) Fetching the latest commits..."
        & git -C "$RepoDir" fetch --all --force --quiet
        if ($lastExitCode -ne 0) { throw "'git fetch --all' failed with exit code $lastExitCode" }

        Write-Progress "(4/6) Listing all Git commit messages..."
        $commits = (git -C "$RepoDir" log --boundary --pretty=oneline --pretty=format:%s | Sort-Object -u)

        Write-Progress "(5/6) Sorting the Git commit messages..."
        $new = @()
        $improved = @()
        $fixed = @()
        $various = @()
        foreach ($commit in $commits) {
            if ($commit -like "New*") {
                $new += $commit
            }
            elseif ($commit -like "Add*") {
                $new += $commit
            }
            elseif ($commit -like "Create*") {
                $new += $commit
            }
            elseif ($commit -like "Upda*") {
                $improved += $commit
            }
            elseif ($commit -like "Adapt*") {
                $improved += $commit
            }
            elseif ($commit -like "Improve*") {
                $improved += $commit
            }
            elseif ($commit -like "Change*") {
                $improved += $commit
            }
            elseif ($commit -like "Changing*") {
                $improved += $commit
            }
            elseif ($commit -like "Fix*") {
                $fixed += $commit
            }
            elseif ($commit -like "Hotfix*") {
                $fixed += $commit
            }
            elseif ($commit -like "Bugfix*") {
                $fixed += $commit
            }
            else {
                $various += $commit
            }
        }
        Write-Progress "(6/6) Listing all contributors..."
        $contributors = (git -C "$RepoDir" log --format='%aN' | Sort-Object -u)
        Write-Progress -completed " "

        $Today = (Get-Date).ToShortDateString()
        Write-Output " "
        Write-Output "Changelog of Repo '$RepoDirName'"
        Write-Output "================================"
        Write-Output " "
        Write-Output "🚀 New Features"
        Write-Output "---------------"
        foreach ($c in $new) {
            Write-Output "* $c"
        }
        Write-Output " "
        Write-Output "🎉 Improved"
        Write-Output "----------"
        foreach ($c in $improved) {
            Write-Output "* $c"
        }
        Write-Output " "
        Write-Output "⚠️ Fixed"
        Write-Output "--------"
        foreach ($c in $fixed) {
            Write-Output "* $c"
        }
        Write-Output " "
        Write-Output "🔦 Various"
        Write-Output "----------"
        foreach ($c in $various) {
            Write-Output "* $c"
        }
        Write-Output " "
        Write-Output "🥇 Contributors"
        Write-Output "---------------"
        foreach ($c in $contributors) {
            Write-Output "* $c"
        }
        Write-Output ""
        Write-Output "Changelog as of $Today."
        exit 0 # success
    }
    catch {
        Write-Error $_.Exception.ToString()
        exit 1
    }
}

<#
.SYNOPSIS
Displays text with a typewriter effect at a random-ish pace.

.DESCRIPTION
Prints each character of the input text with a random delay to simulate a more natural typing effect.

.PARAMETER text
The text to display with the typewriter effect. Default is "Hello World, this is the PowerShell typewriter."

.PARAMETER speed
The maximum delay in milliseconds between characters. The actual delay will be a random value
between 0 and this number. Default is 200 ms.

.EXAMPLE
Write-Typewriter "Loading system..." 100

.NOTES
This creates a more natural-looking typing effect than WriteLine as it uses random delays.
#>
function Write-Typewriter {
    param(
        [string]$text = "Hello World, this is the PowerShell typewriter.", 
        [int]$speed = 200, # in milliseconds
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White
    ) 

    try {
        $Random = New-Object System.Random
        $text -split '' | ForEach-Object {
            Write-Host $_ -noNewline -ForegroundColor $ForegroundColor
            Start-Sleep -milliseconds $Random.Next($speed)
        }
        Write-Host ""
    }
    catch {
        "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
        exit 1
    }
}

<#
.SYNOPSIS
Prompts the user to select an option from a numbered list.

.DESCRIPTION
Displays a list of options to the user, each with a number, and prompts the user to make a selection.
Returns the selected option as a string. The user can also cancel the selection by entering 0.

.PARAMETER Options
An array of strings representing the available options.

.PARAMETER Prompt
The text to display as the prompt before the list of options.

.EXAMPLE
$choice = Get-SelectionFromUser -Options @("Option A", "Option B", "Option C") -Prompt "Please select an option:"

.NOTES
If the user selects 0 (Cancel), the function will exit the script with code 0.
#>
function Get-SelectionFromUser {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Options,
        [Parameter(Mandatory = $true)]
        [string]$Prompt        
    )
    
    [int]$Response = 0;
    [bool]$ValidResponse = $false    

    while (!($ValidResponse)) {            
        [int]$OptionNo = 0

        Write-Host $Prompt -ForegroundColor DarkYellow
        Write-Host "[0]: Cancel"

        foreach ($Option in $Options) {
            $OptionNo += 1
            Write-Host ("[$OptionNo]: {0}" -f $Option)
        }

        if ([Int]::TryParse((Read-Host), [ref]$Response)) {
            if ($Response -eq 0) {
                # if cancel return with code zero
                exit 0
            }
            elseif ($Response -le $OptionNo) {
                $ValidResponse = $true
            }
        }
    }

    return $Options.Get($Response - 1)
}

function Print-HR {
    param(
        [int]$LeftMargin = 0,
        [int]$RightMargin = 0,
        [string]$Char = "-"
    )
    $width = $Host.UI.RawUI.WindowSize.Width
    $lineLength = $width - $LeftMargin - $RightMargin
    if ($lineLength -lt 1) { $lineLength = 1 }
    $marginLeft = ' ' * $LeftMargin
    $marginRight = ' ' * $RightMargin
    Write-Host ("$marginLeft" + ($Char * $lineLength) + "$marginRight")
}

function Ellipsize-Text {
    param (
        [string]$text,
        [int]$maxLength,
        [switch]$preferSentenceEnd = $false
    )

    if ($text.Length -le $maxLength) {
        return $text
    }
    
    # Reserve space for the ellipsis
    $effectiveMaxLength = $maxLength - 3
    
    if ($preferSentenceEnd) {
        # First try to find the last sentence end within the limit
        $lastSentenceEnd = [Math]::Max(
            $text.LastIndexOf('. ', $effectiveMaxLength),
            $text.LastIndexOf('! ', $effectiveMaxLength),
            $text.LastIndexOf('? ', $effectiveMaxLength)
        )
        
        if ($lastSentenceEnd -gt 0) {
            return $text.Substring(0, $lastSentenceEnd + 1) + "..."
        }
    }
    
    # If no sentence end found or not preferring sentence ends,
    # fall back to word boundaries
    $lastSpaceIndex = $text.LastIndexOf(' ', $effectiveMaxLength)
    
    if ($lastSpaceIndex -gt 0) {
        return $text.Substring(0, $lastSpaceIndex) + "..."
    }
    
    # If no suitable breaking point found, just cut at the max length
    return $text.Substring(0, $effectiveMaxLength) + "..."
}

function Write-SuspenseText {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,
        
        [Parameter(Mandatory = $false)]
        [int]$Speed = 50, # Lower = faster (milliseconds delay)
        
        [Parameter(Mandatory = $false)]
        [string]$CharacterSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_+{}[]|:;<>,.?/~",
        
        [Parameter(Mandatory = $false)]
        [int]$RevealSteps = 5, # How many iterations before a character settles
        
        [Parameter(Mandatory = $false)]
        [switch]$PreserveSpaces = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$PreservePunctuation = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$RevealSequentially = $false,
        
        [Parameter(Mandatory = $false)]
        [ConsoleColor]$FinalColor = [Console]::ForegroundColor,
        
        [Parameter(Mandatory = $false)]
        [ConsoleColor]$AnimColor = [ConsoleColor]::DarkGray
    )
    
    # Create a character array to hold our animated text
    $currentText = New-Object char[] $Text.Length
    
    # Track which characters have been revealed
    $revealed = New-Object bool[] $Text.Length
    
    # Define punctuation characters
    $punctuation = " ,.!?;:()[]{}""'`-_/\|@#$%^&*+=<>~"
    
    # Pre-populate preserved characters and mark as revealed
    for ($i = 0; $i -lt $Text.Length; $i++) {
        $currentChar = $Text[$i]
        $shouldPreserve = ($PreserveSpaces -and $currentChar -eq ' ') -or 
                          ($PreservePunctuation -and $punctuation.Contains($currentChar))
        
        if ($shouldPreserve) {
            $currentText[$i] = $currentChar
            $revealed[$i] = $true
        }
        else {
            $revealed[$i] = $false
        }
    }
    
    # We'll track animation progress
    $totalRevealed = ($revealed | Where-Object { $_ -eq $true }).Count
    $totalToReveal = $Text.Length
    $nextToReveal = 0  # Used for sequential revealing
    
    # Store cursor position to overwrite the same line
    $originalCursorTop = [Console]::CursorTop
    $originalCursorLeft = [Console]::CursorLeft
    
    # Create random number generator
    $random = New-Object System.Random
    
    # Animation loop
    $animationCounter = 0
    while ($totalRevealed -lt $totalToReveal) {
        $animationCounter++
        
        # Update unrevealed characters (either randomize or reveal)
        for ($i = 0; $i -lt $Text.Length; $i++) {
            if (-not $revealed[$i]) {
                # Should we reveal this character?
                $shouldReveal = $false
                
                if ($RevealSequentially) {
                    # In sequential mode, we reveal characters one by one
                    $shouldReveal = ($i -eq $nextToReveal)
                }
                else {
                    # In random mode, we have a chance to reveal each iteration
                    $shouldReveal = ($animationCounter % $RevealSteps -eq 0 -and $random.Next(100) -lt 15)
                }
                
                if ($shouldReveal) {
                    $currentText[$i] = $Text[$i]
                    $revealed[$i] = $true
                    $totalRevealed++
                    if ($RevealSequentially) {
                        # Find next unrevealed character
                        $nextToReveal = $i + 1
                        while ($nextToReveal -lt $Text.Length -and $revealed[$nextToReveal]) {
                            $nextToReveal++
                        }
                    }
                }
                else {
                    # Keep it random
                    $randomChar = $CharacterSet[$random.Next($CharacterSet.Length)]
                    $currentText[$i] = $randomChar
                }
            }
        }
        
        # Reset cursor and output current state
        [Console]::SetCursorPosition($originalCursorLeft, $originalCursorTop)
        
        # Output with appropriate colors
        for ($i = 0; $i -lt $Text.Length; $i++) {
            if ($revealed[$i]) {
                [Console]::ForegroundColor = $FinalColor
            }
            else {
                [Console]::ForegroundColor = $AnimColor
            }
            [Console]::Write($currentText[$i])
        }
        
        # Restore color
        [Console]::ForegroundColor = $FinalColor
        
        # Delay based on speed parameter
        Start-Sleep -Milliseconds $Speed
    }
    
    # Ensure final state is correct and move to next line
    [Console]::SetCursorPosition($originalCursorLeft, $originalCursorTop)
    [Console]::WriteLine($Text)
}