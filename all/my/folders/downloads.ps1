function downloads {
	try {
		if ($IsLinux -or $IsMacOS) {
			if (-not(Test-Path "~/Downloads" -pathType container)) {
				return Err -Message "No 📂Downloads folder in your home directory yet"
			}
			$path = Resolve-Path "~/Downloads"
		}
		else {
			$path = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
			if (-not(Test-Path "$path" -pathType container)) {
				return Err -Message "No downloads folder at 📂$path"
			}
		}
		Set-Location "$path"
		$files = Get-ChildItem $path -attributes !Directory
		$folders = Get-ChildItem $path -attributes Directory
		Log-Info "📂$path entered (has $($files.Count) files and $($folders.Count) folders)"
		Return Ok
	}
 catch {
		Return Err -Message "Error: $($Error[0])"
	}
}
