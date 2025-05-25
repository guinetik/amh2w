<#
.SYNOPSIS
Severance-inspired interactive number grid animation for the AMH2W PowerShell utility library.

.DESCRIPTION
Creates an eerie, corporate-aesthetic number grid animation inspired by the TV show "Severance".
Numbers float, pulse, and respond to cursor-like interactions with scaling and color effects.
Features auto-wandering focus point, pulsing animations, and that distinctive clinical digital aesthetic.

.NOTES
File: all/my/homies/luv/severance.ps1
Command: all my homies luv severance [options]

This will not work in Microsoft's ISE, Quest's PowerGUI or other graphical hosts.
It requires a true console host like powershell.exe for proper buffer manipulation.

.EXAMPLE
all my homies luv severance
Starts the Severance number grid with default settings.

.EXAMPLE
all my homies luv severance -Density high -Speed slow -Theme blue
Creates a dense, slow-moving grid with blue corporate theme.

.EXAMPLE
all my homies luv severance -Duration 60 -Interactive
Runs for 60 seconds with interactive cursor following.
#>

<#
.SYNOPSIS
Starts the Severance-inspired number grid animation.

.DESCRIPTION
Creates a grid of floating numbers that pulse, scale, and respond to a wandering focus point.
Captures the eerie corporate digital aesthetic of the Severance TV show.

.PARAMETER Density
Grid density. Valid values: low, normal, high. Default: normal.

.PARAMETER Speed
Animation speed. Valid values: slow, normal, fast. Default: normal.

.PARAMETER Theme
Color theme. Valid values: classic (green/white), blue, amber, mono. Default: classic.

.PARAMETER Duration
Duration to run the animation in seconds. If not specified, runs until key press.

.PARAMETER Interactive
Enable interactive mode where focus follows cursor position (simulated).

.PARAMETER Corporate
Enable corporate mode with occasional "WORK" messages and productivity metrics.

.PARAMETER Arguments
Additional arguments (for future extensibility).

.OUTPUTS
Returns an Ok or Err result object according to the AMH2W result pattern.

.EXAMPLE
severance -Density high -Theme blue -Corporate
#>
function severance {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet("low", "normal", "high")]
        [string]$Density = "high",
        
        [Parameter(Position = 1)]
        [ValidateSet("slow", "normal", "fast")]
        [string]$Speed = "fast",
        
        [Parameter()]
        [ValidateSet("classic", "blue", "amber", "mono")]
        [string]$Theme = "blue",
        
        [Parameter()]
        [ValidateRange(1, 3600)]
        [int]$Duration = 0,
        
        [Parameter()]
        [switch]$Interactive,
        
        [Parameter()]
        [switch]$Corporate,
        
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    try {
        Log-Info "Initializing Severance digital environment..."
        
        # Validate console host
        if ($host.ui.rawui.windowsize -eq $null) {
            Log-Error "Severance grid requires a true console host"
            return Err "Severance animation only works in console hosts like powershell.exe"
        }
        
        # Convert parameters to internal values
        $spacing = switch ($Density) {
            "low" { 4 }     # Every 4th character
            "normal" { 3 }  # Every 3rd character  
            "high" { 2 }    # Every 2nd character
        }
        
        $frameDelay = switch ($Speed) {
            "slow" { 150 }
            "normal" { 80 }
            "fast" { 40 }
        }
        
        Log-Info "Configuration: Density=$Density (spacing=$spacing), Speed=$Speed ($frameDelay ms), Theme=$Theme"
        if ($Duration -gt 0) {
            Log-Info "Session duration: $Duration seconds"
        }
        if ($Interactive) {
            Log-Info "Interactive mode: Enabled"
        }
        if ($Corporate) {
            Log-Info "Corporate mode: Productivity monitoring active"
        }
        
        # Start the Severance animation
        $result = Start-SeveranceGrid -Spacing $spacing -FrameDelay $frameDelay -Theme $Theme -Duration $Duration -Interactive $Interactive -Corporate $Corporate
        
        if ($result.ok) {
            Log-Success "Severance session completed successfully"
            return Ok -Value $result.value -Message "Digital environment session completed"
        }
        else {
            Log-Error "Severance session failed: $($result.error)"
            return Err $result.error
        }
    }
    catch {
        Log-Error "Error initializing Severance environment: $_"
        return Err "Error initializing digital environment: $_"
    }
}

<#
.SYNOPSIS
Core Severance grid animation engine.

.DESCRIPTION
Manages the number grid, focus point wandering, and corporate messaging system.
#>
function Start-SeveranceGrid {
    param(
        [int]$Spacing,
        [int]$FrameDelay,
        [string]$Theme,
        [int]$Duration,
        [bool]$Interactive,
        [bool]$Corporate
    )
    
    try {
        # Store original console state
        $originalBg = $host.ui.rawui.BackgroundColor
        $originalFg = $host.ui.rawui.ForegroundColor
        $originalTitle = $host.ui.rawui.WindowTitle
        $originalCursor = $host.ui.rawui.CursorSize
        
        # Setup corporate console environment
        $host.ui.rawui.BackgroundColor = "Black"
        $host.ui.rawui.WindowTitle = if ($Corporate) { "LUMON INDUSTRIES - Macrodata Refinement" } else { "AMH2W - Severance Grid" }
        $host.ui.rawui.CursorSize = 0  # Hide cursor
        Clear-Host
        
        # Initialize grid state
        $script:windowSize = $host.ui.rawui.WindowSize
        $script:numbers = Initialize-NumberGrid -Spacing $Spacing
        $script:focusX = $script:windowSize.Width / 2
        $script:focusY = $script:windowSize.Height / 2
        $script:targetX = Get-Random -Minimum 5 -Maximum ($script:windowSize.Width - 5)
        $script:targetY = Get-Random -Minimum 5 -Maximum ($script:windowSize.Height - 5)
        $script:frameCount = 0
        $script:lastCorporateMessage = 0
        $script:productivityScore = Get-Random -Minimum 85 -Maximum 99
        
        # Get theme colors
        $colors = Get-SeveranceTheme -Theme $Theme
        
        Log-Debug "Grid initialized. Window: $($script:windowSize.Width)x$($script:windowSize.Height), Numbers: $($script:numbers.Count)"
        
        $startTime = Get-Date
        $done = $false
        
        # Show corporate welcome if enabled
        if ($Corporate) {
            Show-CorporateWelcome -Colors $colors
            Start-Sleep -Seconds 2
            Clear-Host  # Clear welcome before starting grid
        }
        
        while (-not $done) {
            # Update focus point (auto-wander)
            Update-FocusPoint -Interactive $Interactive
            
            # Render the grid
            Render-SeveranceGrid -Colors $colors
            
            # Show corporate messages
            if ($Corporate -and (($script:frameCount % 300) -eq 0)) {
                Show-CorporateMessage -Colors $colors
                $script:productivityScore += Get-Random -Minimum -2 -Maximum 5
                $script:productivityScore = [Math]::Max(0, [Math]::Min(100, $script:productivityScore))
            }
            
            # Check exit conditions
            $done = $host.ui.rawui.KeyAvailable
            
            # Check duration timeout
            if ($Duration -gt 0) {
                $elapsed = (Get-Date) - $startTime
                if ($elapsed.TotalSeconds -ge $Duration) {
                    $done = $true
                    Log-Debug "Session duration completed: $($elapsed.TotalSeconds) seconds"
                }
            }
            
            if (-not $done) {
                Start-Sleep -Milliseconds $FrameDelay
            }
            
            $script:frameCount++
        }
        
        # Corporate goodbye
        if ($Corporate) {
            Show-CorporateGoodbye -Colors $colors
            Start-Sleep -Seconds 1
        }
        
        # Consume any key press
        if ($host.ui.rawui.KeyAvailable) {
            $null = $host.ui.rawui.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        # Restore console state
        $host.ui.rawui.BackgroundColor = $originalBg
        $host.ui.rawui.ForegroundColor = $originalFg
        $host.ui.rawui.WindowTitle = $originalTitle
        $host.ui.rawui.CursorSize = $originalCursor
        Clear-Host
        
        $totalTime = ((Get-Date) - $startTime).TotalSeconds
        Log-Debug "Session completed. Duration: $([math]::Round($totalTime, 1))s, Frames: $script:frameCount"
        
        return @{
            ok = $true
            value = @{
                Duration = $totalTime
                Frames = $script:frameCount
                ProductivityScore = if ($Corporate) { $script:productivityScore } else { $null }
                NumbersProcessed = $script:numbers.Count * $script:frameCount
            }
        }
    }
    catch {
        # Ensure console is restored on error
        try {
            $host.ui.rawui.BackgroundColor = $originalBg
            $host.ui.rawui.ForegroundColor = $originalFg
            $host.ui.rawui.WindowTitle = $originalTitle
            $host.ui.rawui.CursorSize = $originalCursor
            Clear-Host
        }
        catch {
            # Ignore restore errors
        }
        
        return @{
            ok = $false
            error = "Severance grid error: $_"
        }
    }
}

<#
.SYNOPSIS
Initializes the number grid data structure to fill the entire screen.
#>
function Initialize-NumberGrid {
    param([int]$Spacing)
    
    # Use the entire screen with no margins
    $maxWidth = $script:windowSize.Width
    $maxHeight = $script:windowSize.Height
    
    # Calculate grid layout to fill entire screen
    $cols = [Math]::Floor($maxWidth / $Spacing)
    $rows = $maxHeight  # Use every row
    
    $numbers = @()
    
    # Create full-screen grid
    for ($row = 0; $row -lt $rows; $row++) {
        for ($col = 0; $col -lt $cols; $col++) {
            $x = $col * $Spacing
            $y = $row
            
            # Ensure we don't go out of bounds
            if ($x -lt $maxWidth -and $y -lt $maxHeight) {
                $numbers += @{
                    Value = Get-Random -Minimum 0 -Maximum 9
                    GridX = $x
                    GridY = $y
                    Row = $row
                    Col = $col
                    LastColor = "Black"
                    ChangeTimer = Get-Random -Minimum 50 -Maximum 200
                }
            }
        }
    }
    
    Log-Debug "Created $($numbers.Count) numbers in ${rows}x${cols} full-screen grid (spacing: $Spacing)"
    return $numbers
}

<#
.SYNOPSIS
Updates the wandering focus point.
#>
function Update-FocusPoint {
    param([bool]$Interactive)
    
    if ($Interactive) {
        # Simulate cursor following (could be enhanced with actual mouse tracking)
        $script:focusX += (Get-Random -Minimum -2 -Maximum 2)
        $script:focusY += (Get-Random -Minimum -1 -Maximum 1)
    }
    else {
        # Auto-wander behavior
        $dx = $script:targetX - $script:focusX
        $dy = $script:targetY - $script:focusY
        $distance = [Math]::Sqrt($dx * $dx + $dy * $dy)
        
        if ($distance -lt 3) {
            # Pick new target
            $script:targetX = Get-Random -Minimum 5 -Maximum ($script:windowSize.Width - 5)
            $script:targetY = Get-Random -Minimum 5 -Maximum ($script:windowSize.Height - 5)
        }
        else {
            # Move toward target
            $moveSpeed = 0.8
            $script:focusX += ($dx / $distance) * $moveSpeed
            $script:focusY += ($dy / $distance) * $moveSpeed
        }
    }
    
    # Keep focus in bounds
    $script:focusX = [Math]::Max(0, [Math]::Min($script:windowSize.Width - 1, $script:focusX))
    $script:focusY = [Math]::Max(0, [Math]::Min($script:windowSize.Height - 1, $script:focusY))
}

<#
.SYNOPSIS
Renders the current frame of the number grid.
#>
function Render-SeveranceGrid {
    param($Colors)
    
    foreach ($number in $script:numbers) {
        # Numbers stay at fixed grid positions
        $currentX = $number.GridX
        $currentY = $number.GridY
        
        # Calculate distance from focus point
        $dx = $script:focusX - $currentX
        $dy = $script:focusY - $currentY
        $distance = [Math]::Sqrt($dx * $dx + $dy * $dy)
        
        # Calculate intensity based on distance (larger radius for better effect)
        $maxDistance = 20
        $proximity = [Math]::Max(0, 1 - ($distance / $maxDistance))
        $intensity = $proximity
        
        # Determine color based on intensity
        $color = if ($intensity -gt 0.7) { $Colors.Bright }
                elseif ($intensity -gt 0.4) { $Colors.Medium }
                elseif ($intensity -gt 0.1) { $Colors.Dim }
                else { $Colors.VeryDim }
        
        # Only render if color changed to reduce flicker
        if ($number.LastColor -ne $color) {
            # Always show the actual number (not dots)
            Set-ConsolePosition $currentX $currentY $number.Value.ToString() $color
            $number.LastColor = $color
        }
        
        # Occasionally change the number value for dynamic feel
        $number.ChangeTimer--
        if ($number.ChangeTimer -le 0) {
            $oldValue = $number.Value
            $number.Value = Get-Random -Minimum 0 -Maximum 9
            $number.ChangeTimer = Get-Random -Minimum 100 -Maximum 500
            
            # Re-render with new number if it changed
            if ($oldValue -ne $number.Value) {
                Set-ConsolePosition $currentX $currentY $number.Value.ToString() $color
            }
        }
    }
}

<#
.SYNOPSIS
Gets the color theme for Severance aesthetic.
#>
function Get-SeveranceTheme {
    param([string]$Theme)
    
    switch ($Theme) {
        "classic" {
            return @{
                Bright = "White"
                Medium = "Green"
                Dim = "DarkGreen"
                VeryDim = "DarkGray"
                Corporate = "Cyan"
            }
        }
        "blue" {
            return @{
                Bright = "White"
                Medium = "Cyan"
                Dim = "Blue"
                VeryDim = "DarkBlue"
                Corporate = "Blue"
            }
        }
        "amber" {
            return @{
                Bright = "White"
                Medium = "Yellow"
                Dim = "DarkYellow"
                VeryDim = "DarkGray"
                Corporate = "Yellow"
            }
        }
        "mono" {
            return @{
                Bright = "White"
                Medium = "Gray"
                Dim = "DarkGray"
                VeryDim = "Black"
                Corporate = "White"
            }
        }
    }
}

<#
.SYNOPSIS
Sets a character at a specific console position with color.
#>
function Set-ConsolePosition {
    param([int]$X, [int]$Y, [string]$Char, [ConsoleColor]$Color)
    
    try {
        if ($X -ge 0 -and $X -lt $script:windowSize.Width -and 
            $Y -ge 0 -and $Y -lt $script:windowSize.Height) {
            [Console]::SetCursorPosition($X, $Y)
            Write-Host $Char -NoNewline -ForegroundColor $Color
        }
    }
    catch {
        # Ignore positioning errors
    }
}

<#
.SYNOPSIS
Shows corporate welcome message.
#>
function Show-CorporateWelcome {
    param($Colors)
    
    $centerX = $script:windowSize.Width / 2
    $centerY = $script:windowSize.Height / 2
    
    $messages = @(
        "Welcome to Lumon Industries",
        "Macrodata Refinement Division",
        "Your productivity score: $($script:productivityScore)%",
        "Remember: Work is life. Life is work."
    )
    
    for ($i = 0; $i -lt $messages.Count; $i++) {
        $message = $messages[$i]
        $x = [Math]::Max(0, $centerX - ($message.Length / 2))
        $y = $centerY - 2 + $i
        Set-ConsolePosition $x $y $message $Colors.Corporate
    }
}

<#
.SYNOPSIS
Shows periodic corporate messages.
#>
function Show-CorporateMessage {
    param($Colors)
    
    $messages = @(
        "Data refinement in progress...",
        "Productivity optimal",
        "Numbers are beautiful",
        "Thank you for your service",
        "Work-life balance achieved",
        "Macrodata processed: $($script:frameCount * 3)",
        "Efficiency rating: $($script:productivityScore)%"
    )
    
    $message = $messages | Get-Random
    $x = Get-Random -Minimum 0 -Maximum ([Math]::Max(1, $script:windowSize.Width - $message.Length))
    $y = Get-Random -Minimum 0 -Maximum ($script:windowSize.Height - 1)
    
    Set-ConsolePosition $x $y $message $Colors.Corporate
    
    # Clear the message after a moment (in next few frames)
    $script:lastCorporateMessage = $script:frameCount
}

<#
.SYNOPSIS
Shows corporate goodbye message.
#>
function Show-CorporateGoodbye {
    param($Colors)
    
    Clear-Host
    $centerX = $script:windowSize.Width / 2
    $centerY = $script:windowSize.Height / 2
    
    $messages = @(
        "Session completed",
        "Final productivity score: $($script:productivityScore)%",
        "Thank you for your dedication",
        "Have a Lumon day!"
    )
    
    for ($i = 0; $i -lt $messages.Count; $i++) {
        $message = $messages[$i]
        $x = [Math]::Max(0, $centerX - ($message.Length / 2))
        $y = $centerY - 2 + $i
        Set-ConsolePosition $x $y $message $Colors.Corporate
    }
}