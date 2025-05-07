<#
.SYNOPSIS
Generates an animated Julia set fractal in the console.

.DESCRIPTION
Creates and displays an animated Julia set fractal directly in the console window,
using ASCII characters to represent the fractal's escape-time values. The animation
cycles through different zoom levels to create a pulsing effect.

.OUTPUTS
No explicit return value. The function displays the fractal animation directly in the console
and runs in an infinite loop until manually terminated.

.EXAMPLE
all fractals
# Starts the fractal animation in the console window

.NOTES
File: all/fractals.ps1
Command: all fractals

This function runs an infinite loop animation and can only be stopped by pressing Ctrl+C
or otherwise terminating the process.

The animation uses the console's full width and height for display and performs best
in a reasonably sized console window. Characters from the ASCII set are used to
represent different iteration counts of the Julia set algorithm.

The fractals are rendered using an escape-time algorithm for the Julia set, with
varying zoom levels to create the animation effect.
#>
function fractals {
	function CalculateFractal([float]$left, [float]$top, [float]$xside, [float]$yside, [float]$zoom) { 
		[int]$maxx = $rui.MaxWindowSize.Width
		[int]$maxy = $rui.MaxWindowSize.Height
		[float]$xscale = $xside / $maxx 
		[float]$yscale = $yside / $maxy 
		for ([int]$y = 0; $y -lt $maxy; $y++) { 
			for ([int]$x = 0; $x -lt $maxx; $x++) { 
				[float]$cx = $x * $xscale + $left
				[float]$cy = $y * $yscale + $top
				[float]$zx = 0
				[float]$zy = 0
				for ([int]$count = 0; ($zx * $zx + $zy * $zy -lt 4) -and ($count -lt $MAXCOUNT); $count++) { 
					[float]$tempx = $zx * $zx - $zy * $zy + $cx
					$zy = $zoom * $zx * $zy + $cy
					$zx = $tempx
				} 
				$global:buf[$y * $maxx + $x] = $([char](65 + $count))
			} 
		}
	}
	
	$MAXCOUNT = 30 
	$ui = (Get-Host).ui
	$rui = $ui.rawui
	[float]$left = -1.75 
	[float]$top = -0.25 
	[float]$xside = 0.25 
	[float]$yside = 0.45 
	$buffer0 = ""
	1..($rui.MaxWindowSize.Width * $rui.MaxWindowSize.Height) | ForEach-Object { $buffer0 += " " }
	$global:buf = $buffer0.ToCharArray()
	
	while ($true) {
		for ([float]$zoom = 4.0; $zoom -gt 1.1; $zoom -= 0.02) {
			CalculateFractal $left $top $xside $yside $zoom
			[console]::SetCursorPosition(0,0)
			[string]$Screen = New-Object system.string($global:buf, 0, $global:buf.Length)
			Write-Host -foreground green $Screen -noNewline
		}
		for ([float]$zoom = 1.1; $zoom -lt 4.0; $zoom += 0.02) {
			CalculateFractal $left $top $xside $yside $zoom
			[console]::SetCursorPosition(0,0)
			[string]$Screen = New-Object system.string($global:buf, 0, $global:buf.Length)
			Write-Host -foreground green $Screen -noNewline
		}
	}
}