<#
.SYNOPSIS
Enhanced Matrix-style console animation for the AMH2W PowerShell utility library.

.DESCRIPTION
Provides a sophisticated Matrix-style screensaver with multiple animated columns, proper color fading,
random character generation, and clean exit handling. This implementation uses PowerShell's console
buffer manipulation capabilities for smooth animation.

.NOTES
File: all/my/homies/luv/thematrix.ps1
Command: all my homies luv thematrix [options]

This will not work in Microsoft's ISE, Quest's PowerGUI or other graphical hosts.
It requires a true console host like powershell.exe.

.EXAMPLE
all my homies luv thematrix
Starts the Matrix animation with default settings.

.EXAMPLE
all my homies luv thematrix -MaxColumns 15 -Speed fast
Starts with 15 columns and fast animation speed.

.EXAMPLE
all my homies luv thematrix -Duration 30
Runs the animation for 30 seconds then stops automatically.
#>

<#
.SYNOPSIS
Starts the Matrix-style console animation.

.DESCRIPTION
Creates multiple animated columns of falling characters with proper color fading effects.
Supports various configuration options and integrates with AMH2W's logging and result systems.

.PARAMETER MaxColumns
Maximum number of animated columns to display simultaneously. Default: 12.

.PARAMETER Speed
Animation speed preset. Valid values: slow, normal, fast, ludicrous. Default: normal.

.PARAMETER Duration
Duration to run the animation in seconds. If not specified, runs until key press.

.PARAMETER Characters
Character set to use for animation. Valid values: matrix, ascii, katakana, numbers. Default: matrix.

.PARAMETER Density
Column spawn density. Valid values: sparse, normal, dense. Default: normal.

.PARAMETER Arguments
Additional arguments (for future extensibility).

.OUTPUTS
Returns an Ok or Err result object according to the AMH2W result pattern.

.EXAMPLE
thematrix -MaxColumns 20 -Speed fast -Duration 60
#>
function thematrix {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateRange(1, 50)]
        [int]$MaxColumns = 12,
        
        [Parameter(Position = 1)]
        [ValidateSet("slow", "normal", "fast", "ludicrous")]
        [string]$Speed = "fast",
        
        [Parameter(Position = 2)]
        [ValidateRange(1, 3600)]
        [int]$Duration = 0,
        
        [Parameter(Position = 3)]
        [ValidateSet("matrix", "ascii", "katakana", "numbers")]
        [string]$Characters = "matrix",
        
        [Parameter(Position = 4)]
        [ValidateSet("sparse", "normal", "dense")]
        [string]$Density = "dense",
        
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    try {
        Log-Info "Starting Matrix animation..."
        
        # Validate console host
        if ($host.ui.rawui.windowsize -eq $null) {
            Log-Error "Matrix animation requires a true console host"
            return Err "Matrix animation only works in console hosts like powershell.exe, not GUI hosts"
        }
        
        # Convert speed to frame delay
        $frameDelay = switch ($Speed) {
            "slow" { 150 }
            "normal" { 80 }
            "fast" { 30 }
            "ludicrous" { 10 }
        }
        
        # Convert density to spawn chance
        $spawnChance = switch ($Density) {
            "sparse" { 2 }
            "normal" { 5 }
            "dense" { 8 }
        }
        
        Log-Info "Configuration: MaxColumns=$MaxColumns, Speed=$Speed ($frameDelay ms), Density=$Density, Characters=$Characters"
        if ($Duration -gt 0) {
            Log-Info "Duration: $Duration seconds"
        }
        
        # Start the Matrix animation
        $result = Start-MatrixAnimation -MaxColumns $MaxColumns -FrameDelay $frameDelay -SpawnChance $spawnChance -Characters $Characters -Duration $Duration
        
        if ($result.ok) {
            Log-Success "Matrix animation completed successfully"
            return Ok -Value $result.value -Message "Matrix animation completed"
        }
        else {
            Log-Error "Matrix animation failed: $($result.error)"
            return Err $result.error
        }
    }
    catch {
        Log-Error "Error starting Matrix animation: $_"
        return Err "Error starting Matrix animation: $_"
    }
}

<#
.SYNOPSIS
Core Matrix animation engine.

.DESCRIPTION
Manages the main animation loop, column creation, and console buffer manipulation.

.PARAMETER MaxColumns
Maximum number of columns to animate.

.PARAMETER FrameDelay
Delay between animation frames in milliseconds.

.PARAMETER SpawnChance
Chance (0-10) of spawning a new column each frame.

.PARAMETER Characters
Character set to use for animation.

.PARAMETER Duration
Duration to run in seconds (0 = until keypress).

.OUTPUTS
A hashtable with ok/error status and duration information.
#>
function Start-MatrixAnimation {
    param(
        [int]$MaxColumns,
        [int]$FrameDelay,
        [int]$SpawnChance,
        [string]$Characters,
        [int]$Duration
    )
    
    try {
        # Store original console state
        $originalBg = $host.ui.rawui.BackgroundColor
        $originalTitle = $host.ui.rawui.WindowTitle
        $originalCursor = $host.ui.rawui.CursorSize
        
        # Setup console
        $host.ui.rawui.BackgroundColor = "Black"
        $host.ui.rawui.WindowTitle = "AMH2W - The Matrix"
        $host.ui.rawui.CursorSize = 0  # Hide cursor
        Clear-Host
        
        # Initialize animation state
        $script:windowSize = $host.ui.rawui.WindowSize
        $script:columns = @{}
        $script:frameCount = 0
        $startTime = Get-Date
        
        Log-Debug "Animation initialized. Window size: $($script:windowSize.Width)x$($script:windowSize.Height)"
        
        $done = $false
        while (-not $done) {
            # Update frame
            Update-MatrixFrame -MaxColumns $MaxColumns -SpawnChance $SpawnChance -Characters $Characters
            Render-MatrixFrame
            
            # Check for exit conditions
            $done = $host.ui.rawui.KeyAvailable
            
            # Check duration timeout
            if ($Duration -gt 0) {
                $elapsed = (Get-Date) - $startTime
                if ($elapsed.TotalSeconds -ge $Duration) {
                    $done = $true
                    Log-Debug "Duration timeout reached: $($elapsed.TotalSeconds) seconds"
                }
            }
            
            if (-not $done) {
                Start-Sleep -Milliseconds $FrameDelay
            }
            
            $script:frameCount++
        }
        
        # Consume any key press
        if ($host.ui.rawui.KeyAvailable) {
            $null = $host.ui.rawui.ReadKey("NoEcho,IncludeKeyDown")
        }
        
        # Restore console state
        $host.ui.rawui.BackgroundColor = $originalBg
        $host.ui.rawui.WindowTitle = $originalTitle
        $host.ui.rawui.CursorSize = $originalCursor
        Clear-Host
        
        $totalTime = ((Get-Date) - $startTime).TotalSeconds
        Log-Debug "Animation completed. Total time: $([math]::Round($totalTime, 1))s, Frames: $script:frameCount"
        
        return @{
            ok = $true
            value = @{
                Duration = $totalTime
                Frames = $script:frameCount
                FramesPerSecond = [math]::Round($script:frameCount / $totalTime, 1)
            }
        }
    }
    catch {
        # Ensure console is restored on error
        try {
            $host.ui.rawui.BackgroundColor = $originalBg
            $host.ui.rawui.WindowTitle = $originalTitle
            $host.ui.rawui.CursorSize = $originalCursor
            Clear-Host
        }
        catch {
            # Ignore restore errors
        }
        
        return @{
            ok = $false
            error = "Animation error: $_"
        }
    }
}

<#
.SYNOPSIS
Updates the animation state for a single frame.

.DESCRIPTION
Manages column creation, updates existing columns, and removes completed columns.
#>
function Update-MatrixFrame {
    param(
        [int]$MaxColumns,
        [int]$SpawnChance,
        [string]$Characters
    )
    
    # Spawn new columns if needed
    if ($script:columns.Count -lt $MaxColumns) {
        if ((Get-Random -Minimum 0 -Maximum 10) -lt $SpawnChance) {
            # Find an unused column position
            do {
                $x = Get-Random -Minimum 0 -Maximum ($script:windowSize.Width - 1)
            } while ($script:columns.ContainsKey($x))
            
            $script:columns.Add($x, (New-MatrixColumn -X $x -Characters $Characters))
            Log-Trace "Spawned new column at position $x"
        }
    }
    
    # Update existing columns and collect completed ones
    $completedColumns = @()
    foreach ($entry in $script:columns.GetEnumerator()) {
        $column = $entry.Value
        if (-not $column.Step()) {
            $completedColumns += $entry.Key
        }
    }
    
    # Remove completed columns
    foreach ($key in $completedColumns) {
        $script:columns.Remove($key)
        Log-Trace "Removed completed column at position $key"
    }
}

<#
.SYNOPSIS
Renders the current frame to the console.

.DESCRIPTION
Currently delegates to individual column rendering. Could be optimized to use
a frame buffer approach for better performance.
#>
function Render-MatrixFrame {
    # Individual columns handle their own rendering
    # Future optimization: render to a frame buffer then display all at once
}

<#
.SYNOPSIS
Creates a new animated column object.

.DESCRIPTION
Returns a script block module that manages the state and animation of a single column.

.PARAMETER X
The horizontal position of the column.

.PARAMETER Characters
The character set to use for this column.

.OUTPUTS
A module object with Step method for animation.
#>
function New-MatrixColumn {
    param(
        [int]$X,
        [string]$Characters
    )
    
    # Create character generator function based on character set
    $charGenerator = switch ($Characters) {
        "matrix" { { [char](Get-Random -Minimum 33 -Maximum 126) } }  # Printable ASCII
        "ascii" { { [char](Get-Random -Minimum 65 -Maximum 90) } }   # A-Z
        "katakana" { { [char](Get-Random -Minimum 0x30A0 -Maximum 0x30FF) } }  # Katakana
        "numbers" { { [char](Get-Random -Minimum 48 -Maximum 57) } }   # 0-9
        default { { [char](Get-Random -Minimum 33 -Maximum 126) } }
    }
    
    # Return column module
    New-Module -AsCustomObject -Name "MatrixColumn_$X" -ScriptBlock {
        param([int]$PosX, [scriptblock]$CharGen)
        
        # Column state
        $script:xPos = $PosX
        $script:yLimit = $host.ui.rawui.WindowSize.Height
        $script:head = 0
        $script:fade = 0
        
        # Random length variation (70% to 150% of base length)
        $randomLengthVariation = (0.7 + (Get-Random -Minimum 0 -Maximum 80) / 100)
        $script:fadeLength = [math]::Max(3, [int]($yLimit / 4 * $randomLengthVariation))
        $script:fadeLength += Get-Random -Minimum 0 -Maximum ($script:fadeLength / 2)
        
        # Console buffer utility functions
        function New-BufferCell {
            param([string]$Char, [ConsoleColor]$ForeColor, [ConsoleColor]$BackColor = "Black")
            $cell = New-Object System.Management.Automation.Host.BufferCell
            $cell.Character = $Char
            $cell.ForegroundColor = $ForeColor
            $cell.BackgroundColor = $BackColor
            $cell.BufferCellType = "Complete"
            return $cell
        }
        
        function Set-BufferCell {
            param([int]$X, [int]$Y, $Cell)
            if ($Y -ge 0 -and $Y -lt $script:yLimit -and $X -ge 0 -and $X -lt $host.ui.rawui.WindowSize.Width) {
                $rect = New-Object System.Management.Automation.Host.Rectangle $X, $Y, $X, $Y
                $host.ui.rawui.SetBufferContents($rect, $Cell)
            }
        }
        
        # Animation step function
        function Step {
            $needsContinue = $false
            
            # Draw the head (bright white)
            if ($script:head -lt $script:yLimit) {
                $char = & $CharGen
                Set-BufferCell $script:xPos $script:head (New-BufferCell $char "White")
                
                # Previous head becomes bright green
                if ($script:head -gt 0) {
                    $char = & $CharGen
                    Set-BufferCell $script:xPos ($script:head - 1) (New-BufferCell $char "Green")
                }
                
                $script:head++
                $needsContinue = $true
            }
            
            # Start the fade tail
            if ($script:head -gt $script:fadeLength) {
                # Dark green fading section
                if ($script:fade -lt $script:yLimit) {
                    $char = & $CharGen
                    Set-BufferCell $script:xPos $script:fade (New-BufferCell $char "DarkGreen")
                    
                    # Clear the tail end
                    $tailPos = $script:fade - 1
                    if ($tailPos -ge 0) {
                        Set-BufferCell $script:xPos $tailPos (New-BufferCell " " "Black")
                    }
                    
                    $script:fade++
                    $needsContinue = $true
                }
            }
            
            # Continue until completely faded
            if ($script:fade -lt $script:yLimit -and $script:head -ge $script:yLimit) {
                $needsContinue = $true
            }
            
            return $needsContinue
        }
        
        Export-ModuleMember -Function Step
        
    } -ArgumentList $X, $charGenerator
}