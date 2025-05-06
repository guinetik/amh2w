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
		$commits = (git -C "$RepoDir" log --boundary --pretty=oneline --pretty=format:%s | sort -u)

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
		$contributors = (git -C "$RepoDir" log --format='%aN' | sort -u)
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

function Write-Typewriter {
	param([string]$text = "Hello World, this is the PowerShell typewriter.", [int]$speed = 200) # in milliseconds

	try {
		$Random = New-Object System.Random
		$text -split '' | ForEach-Object {
			Write-Host $_ -noNewline
			Start-Sleep -milliseconds $Random.Next($speed)
		}
		Write-Host ""
	}
 catch {
		"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
		exit 1
	}
}

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