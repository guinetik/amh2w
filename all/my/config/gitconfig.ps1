function gitconfig {
    param(
        [string]$fullName = "", 
        [string]$emailAddress = "", 
        [string]$favoriteEditor = "",
        [string]$scope = "global", # New scope parameter: "global" or "local"
        [string]$repoPath = "." # Only used with local scope
    )

    # If scope is local, verify the directory is a git repository
    if ($scope -eq "local") {
        # Check if the provided path exists
        if (-not (Test-Path $repoPath)) {
            return Err "Repository path '$repoPath' does not exist"
        }

        # Change to the repository directory
        $originalLocation = Get-Location
        try {
            Set-Location $repoPath
            
            # Test if this is a git repository
            $gitDirExists = Test-Path -Path ".git" -PathType Container
            if (-not $gitDirExists) {
                $gitDirCheck = & git rev-parse --is-inside-work-tree 2>&1
                if ($LASTEXITCODE -ne 0 -or $gitDirCheck -ne "true") {
                    Set-Location $originalLocation
                    return Err "The directory '$repoPath' is not a git repository"
                }
            }
        }
        catch {
            Set-Location $originalLocation
            return Err "Failed to verify git repository: $_"
        }
    }

    try {
        Log-Info "⏳ (1/5) Searching for Git executable..."
        & git --version | Out-Null
        if ($lastExitCode -ne 0) { 
            return Err "Can't execute 'git' - make sure Git is installed and available"
        }

        Log-Info "⏳ (2/5) Collecting user details..."
        if ($fullName -eq "") { $fullName = Read-Host "Enter your full name" }
        if ($emailAddress -eq "") { $emailAddress = Read-Host "Enter your e-mail address" }
        if ($favoriteEditor -eq "") { $favoriteEditor = Read-Host "Enter your favorite text editor, e.g. atom,code,emacs,nano,notepad,subl,vi,vim" }
        $stopWatch = [system.diagnostics.stopwatch]::startNew()

        # Set the scope flag for git commands
        $scopeFlag = if ($scope -eq "global") { "--global" } else { "--local" }

        Log-Info "⏳ (3/5) Saving basic settings (autocrlf,symlinks,longpaths,etc.)..."
        & git config $scopeFlag core.autocrlf false          # don't change newlines
        & git config $scopeFlag core.symlinks true           # enable support for symbolic link files
        & git config $scopeFlag core.longpaths true          # enable support for long file paths
        & git config $scopeFlag init.defaultBranch main      # set the default branch name to 'main'
        & git config $scopeFlag merge.renamelimit 99999      # raise the rename limit
        & git config $scopeFlag pull.rebase false
        & git config $scopeFlag fetch.parallel 0             # enable parallel fetching to improve the speed
        if ($lastExitCode -ne 0) { 
            return Err "'git config' failed with exit code $lastExitCode"
        }

        Log-Info "⏳ (4/5) Saving user settings (name,email,editor)..."
        & git config $scopeFlag user.name $fullName
        & git config $scopeFlag user.email $emailAddress
        & git config $scopeFlag core.editor $favoriteEditor
        if ($lastExitCode -ne 0) { 
            return Err "'git config' failed with exit code $lastExitCode" 
        }

        Log-Info "⏳ (5/5) Saving user shortcuts ('git br', 'git ls', 'git st', etc.)..."
        & git config $scopeFlag alias.br "branch"
        & git config $scopeFlag alias.addi "git add -i"
        & git config $scopeFlag alias.chp "cherry-pick --no-commit"
        & git config $scopeFlag alias.ci "commit"
        & git config $scopeFlag alias.co "checkout"
        & git config $scopeFlag alias.ls "log -n20 --pretty=format:'%Cred%h%Creset%C(yellow)%d%Creset %s %C(bold blue)by %an%Creset %C(green)%cr%Creset' --abbrev-commit"
        & git config $scopeFlag alias.mrg "merge --no-commit --no-ff"
        & git config $scopeFlag alias.pl "pull --recurse-submodules"
        & git config $scopeFlag alias.ps "push"
        & git config $scopeFlag alias.smu "submodule update --init"
        & git config $scopeFlag alias.st "status"
        if ($lastExitCode -ne 0) { 
            return Err "'git config' failed with exit code $lastExitCode" 
        }

        [int]$elapsed = $stopWatch.Elapsed.TotalSeconds
        $configPath = if ($scope -eq "global") { "~/.gitconfig" } else { ".git/config" }
        $successMsg = "Git configuration saved to $configPath in $($elapsed)s"
        Log-Info "✅ $successMsg"
        
        # Reset location if we changed directories
        if ($scope -eq "local" -and (Get-Location).Path -ne $originalLocation) {
            Set-Location $originalLocation
        }

        return Ok -Value $successMsg
    }
    catch {
        $errorMsg = "Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
        Log-Error "⚠️ $errorMsg"
        
        # Reset location if we changed directories
        if ($scope -eq "local" -and (Get-Location).Path -ne $originalLocation) {
            Set-Location $originalLocation
        }
        
        return Err $errorMsg
    }
}

