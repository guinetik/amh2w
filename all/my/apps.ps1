function apps {
    Get-AppxPackage | Format-Table -property Name,Version,InstallLocation,Status -autoSize
    return Ok
}