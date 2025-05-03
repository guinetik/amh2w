function ram {
    function GetRAMType {
        param([int]$Type)
        switch ($Type) {
            2 { "DRAM" }
            5 { "EDO RAM" }
            6 { "EDRAM" }
            7 { "VRAM" }
            8 { "SRAM" }
            10 { "ROM" }
            11 { "Flash" }
            12 { "EEPROM" }
            13 { "FEPROM" }
            14 { "EPROM" }
            15 { "CDRAM" }
            16 { "3DRAM" }
            17 { "SDRAM" }
            18 { "SGRAM" }
            19 { "RDRAM" }
            20 { "DDR RAM" }
            21 { "DDR2 RAM" }
            22 { "DDR2 FB-DIMM" }
            24 { "DDR3 RAM" }
            26 { "DDR4 RAM" }
            27 { "DDR5 RAM" }
            28 { "DDR6 RAM" }
            29 { "DDR7 RAM" }
            default { "Unknown" }
        }
    }

    function Bytes2String {
        param([int64]$Bytes)
        switch ($Bytes) {
            {$_ -lt 1KB}   { return "$Bytes bytes" }
            {$_ -lt 1MB}   { return "{0:N2} KB" -f ($Bytes / 1KB) }
            {$_ -lt 1GB}   { return "{0:N2} MB" -f ($Bytes / 1MB) }
            {$_ -lt 1TB}   { return "{0:N2} GB" -f ($Bytes / 1GB) }
            {$_ -lt 1PB}   { return "{0:N2} TB" -f ($Bytes / 1TB) }
            default        { return "{0:N2} PB" -f ($Bytes / 1PB) }
        }
    }

    try {
        $ram = @()

        if ($IsLinux) {
            # TODO: Add support for Linux /proc/meminfo or lshw
        }
        else {
            $Banks = Get-WmiObject -Class Win32_PhysicalMemory
            foreach ($Bank in $Banks) {
                $ram += [PSCustomObject]@{
                    Capacity     = Bytes2String($Bank.Capacity)
                    Type         = GetRAMType $Bank.SMBIOSMemoryType
                    SpeedMHz     = $Bank.Speed
                    VoltageV     = [math]::Round($Bank.ConfiguredVoltage / 1000.0, 2)
                    Manufacturer = $Bank.Manufacturer
                    Location     = "$($Bank.BankLabel)/$($Bank.DeviceLocator)"
                }
            }

            # Pretty output
            Write-Host ""
            Write-Host "🧠 Installed RAM Sticks:" -ForegroundColor Cyan
            Write-Host "------------------------" -ForegroundColor Cyan
            $index = 1
            foreach ($stick in $ram) {
                Write-Host "`n[$index] $($stick.Location)" -ForegroundColor Yellow
                Write-Host "   Capacity    : $($stick.Capacity)"
                Write-Host "   Type        : $($stick.Type)"
                Write-Host "   Speed       : $($stick.SpeedMHz) MHz"
                Write-Host "   Voltage     : $($stick.VoltageV) V"
                Write-Host "   Manufacturer: $($stick.Manufacturer)"
                $index++
            }
        }

        return Ok -Value $ram
    }
    catch {
        return Err -Message "Error reading memory info: $_"
    }
}
