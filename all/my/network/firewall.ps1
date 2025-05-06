function firewall {
    try {
        if ($IsLinux) {
            WriteLine "✅ Firewall " -noNewline
            & sudo ufw status
        }
        else {
            $enabled = (gp 'HKLM:\SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile').EnableFirewall
            if ($enabled) {
                WriteLine "✅ Firewall enabled"
            }
            else {
                WriteLine "⚠️ Firewall disabled"
            }
        }
        return Ok -Value $enabled
    }
    catch {
        Return Err -Message "Error: $_"
    }
}