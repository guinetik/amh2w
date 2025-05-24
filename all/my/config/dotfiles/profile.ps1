# PowerShell Profile configured by AMH2W on $(Get-Date)
# This profile reads configuration from AMH2W-Profile-Config.json

# Constants
$script:JABBA_PATH = Join-Path $env:USERPROFILE ".jabba\jabba.ps1"
$script:CONFIG_FILE = Join-Path (Split-Path $PROFILE) "AMH2W-Profile-Config.json"

# Load configuration
$script:Config = @{
    HistorySearch = $false
    PredictiveIntelliSense = $false
    EnhancedKeybindings = $false
    VisualEnhancements = $false
    SmartQuotes = $false
    AdvancedHistory = $false
}

# Read config file if it exists
if (Test-Path $script:CONFIG_FILE) {
    try {
        $configData = Get-Content $script:CONFIG_FILE -Raw | ConvertFrom-Json
        # Update config with saved preferences
        foreach ($key in $configData.PSObject.Properties.Name) {
            if ($script:Config.ContainsKey($key)) {
                $script:Config[$key] = $configData.$key
            }
        }
    }
    catch {
        # Ignore config file errors, use defaults
    }
}

# PSReadLine configuration
if ($host.Name -eq 'ConsoleHost') {
    # Import PSReadLine if not already loaded
    if (-not (Get-Module PSReadLine -ErrorAction SilentlyContinue)) {
        try {
            Import-Module PSReadLine -ErrorAction SilentlyContinue
        } catch {
            # Ignore PSReadLine import errors
        }
    }
    
    # Only configure PSReadLine if it's actually loaded
    if (Get-Module PSReadLine -ErrorAction SilentlyContinue) {
        # Default configuration - Tab completion (always enabled)
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
        
        # Enhanced History Search
        if ($script:Config.HistorySearch) {
            Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
            Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
        }
        
        # Predictive IntelliSense
        if ($script:Config.PredictiveIntelliSense) {
            Set-PSReadLineOption -PredictionSource HistoryAndPlugin
            Set-PSReadLineOption -PredictionViewStyle ListView
        }
        
        # Enhanced Key Bindings
        if ($script:Config.EnhancedKeybindings) {
            Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteChar
            Set-PSReadLineKeyHandler -Key Ctrl+w -Function BackwardDeleteWord
            Set-PSReadLineKeyHandler -Key Alt+d -Function DeleteWord
            Set-PSReadLineKeyHandler -Key Ctrl+LeftArrow -Function BackwardWord
            Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function ForwardWord
            Set-PSReadLineKeyHandler -Key Ctrl+z -Function Undo
            Set-PSReadLineKeyHandler -Key Ctrl+y -Function Redo
        }
        
        # Visual Enhancements
        if ($script:Config.VisualEnhancements) {
            Set-PSReadLineOption -Colors @{
                Command            = 'Yellow'
                Parameter          = 'Green'
                Operator           = 'Magenta'
                Variable           = 'Green'
                String             = 'Blue'
                Number             = 'Blue'
                Type               = 'Cyan'
                Comment            = 'DarkCyan'
                Keyword            = 'Yellow'
                Error              = 'Red'
                Selection          = 'DarkGray'
                InlinePrediction   = 'DarkGray'
            }
        }
        
        # Smart Quotes and Brackets
        if ($script:Config.SmartQuotes) {
            Set-PSReadLineKeyHandler -Key '"' -BriefDescription SmartInsertQuote -LongDescription "Insert paired quotes if not already on a quote" -ScriptBlock {
                param($key, $arg)
                $quote = $key.KeyChar
                $selectionStart = $null
                $selectionLength = $null
                [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)
                $line = $null
                $cursor = $null
                [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
                if ($selectionStart -ne -1) {
                    [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $quote + $line.SubString($selectionStart, $selectionLength) + $quote)
                    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
                } else {
                    if ($cursor -lt $line.Length -and $line[$cursor] -eq $quote) {
                        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
                    } else {
                        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$quote$quote")
                        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
                        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor - 1)
                    }
                }
            }
        }
        
        # Advanced History
        if ($script:Config.AdvancedHistory) {
            Set-PSReadLineOption -HistorySearchCursorMovesToEnd
            Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
            Set-PSReadLineOption -MaximumHistoryCount 4000
        }
    }
}

# Winget tab completion
try {
    Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
        $Local:word = $wordToComplete.Replace('"', '""')
        $Local:ast = $commandAst.ToString().Replace('"', '""')
        winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
} catch {
    # Ignore winget completion errors
}

# Terminal Icons for file display
if (-not (Get-Module Terminal-Icons -ErrorAction SilentlyContinue)) {
    try {
        Import-Module -Name Terminal-Icons -ErrorAction SilentlyContinue
    } catch {
        # Ignore Terminal-Icons import errors
    }
}

# AMH2W Module (only if not already loaded)
if (-not (Get-Module AMH2W -ErrorAction SilentlyContinue)) {
    try {
        Import-Module -Name AMH2W -ErrorAction SilentlyContinue
    } catch {
        # Ignore AMH2W import errors
    }
}

# Starship prompt (if available)
if (Get-Command starship -ErrorAction SilentlyContinue) {
    try {
        Invoke-Expression (&starship init powershell)
    }
    catch {
        # Ignore starship errors
    }
}

# Jabba Java Version Manager (if available)
if (Test-Path $script:JABBA_PATH) {
    try {
        . $script:JABBA_PATH
    } catch {
        # Ignore jabba errors
    }
}