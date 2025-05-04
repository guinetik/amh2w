function scanpc {
    try {
        & all my hardware bios
        & all my hardware motherboard
        & all my hardware cpu
        & all my hardware gpu
        & all my hardware ram
        & all my hardware power
        & all my hardware storage
        & all my hardware bluetooth
        & all my network internet
        & all my network dns check
        & all my network ip interfaces
        & all my homies hate windows version
        return Ok "PC scanned successfully"
    }
    catch {
        Log-Error "Error scanning PC: $_"
        return Err "Error scanning PC: $_"
    }

}