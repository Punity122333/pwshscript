#Requires -RunAsAdministrator
<#
.SYNOPSIS
Restricts outbound traffic to only specified websites and essential services
.DESCRIPTION
Creates Windows Firewall rules to:
1. Allow DNS (UDP 53) ONLY to specified DNS server (172.16.120.1)
2. Allow HTTP/HTTPS to specified domains
3. Block all other outbound traffic
.NOTES
- Run this script as Administrator
- This will disrupt other internet access until rules are modified/removed
- IP-based rules require periodic updates if website IPs change
#>

# Domain list to allow
$allowedDomains = @(
    "vjudge.net",
    "programiz.com",
    "cppreference.com"
)

# Custom DNS server IP
$dnsServer = "172.16.120.1"

# Rule name prefix for easy management
$rulePrefix = "RestrictedAccess_"

function Update-FirewallRules {
    # Remove existing rules if they exist
    Get-NetFirewallRule -DisplayName "$rulePrefix*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -Confirm:$false

    # Allow critical Windows services (ICMP, DHCP, NTP)
    New-NetFirewallRule -DisplayName "${rulePrefix}ICMPv4" -Direction Outbound `
        -Protocol ICMPv4 -IcmpType 8 -Action Allow
    New-NetFirewallRule -DisplayName "${rulePrefix}ICMPv6" -Direction Outbound `
        -Protocol ICMPv6 -IcmpType 128 -Action Allow
    New-NetFirewallRule -DisplayName "${rulePrefix}DHCP" -Direction Outbound `
        -Protocol UDP -LocalPort 68 -RemotePort 67 -Action Allow
    New-NetFirewallRule -DisplayName "${rulePrefix}NTP" -Direction Outbound `
        -Protocol UDP -RemotePort 123 -Action Allow

    # Allow DNS ONLY to specified DNS server (UDP 53)
    New-NetFirewallRule -DisplayName "${rulePrefix}DNS" -Direction Outbound `
        -Protocol UDP -RemotePort 53 -RemoteAddress $dnsServer -Action Allow

    # Create rules for each domain
    foreach ($domain in $allowedDomains) {
        try {
            $ips = [System.Net.Dns]::GetHostAddresses($domain) | 
                    Select-Object -ExpandProperty IPAddressToString -Unique
            
            foreach ($ip in $ips) {
                # HTTP rule
                New-NetFirewallRule -DisplayName "${rulePrefix}HTTP_${domain}" `
                    -Direction Outbound -Protocol TCP -RemotePort 80 -RemoteAddress $ip -Action Allow
                
                # HTTPS rule
                New-NetFirewallRule -DisplayName "${rulePrefix}HTTPS_${domain}" `
                    -Direction Outbound -Protocol TCP -RemotePort 443 -RemoteAddress $ip -Action Allow
            }
        }
        catch {
            Write-Warning "Failed to resolve $domain : $_"
        }
    }

    # Create block rule (must be created last)
    New-NetFirewallRule -DisplayName "${rulePrefix}BlockAll" -Direction Outbound `
        -Action Block -RemoteAddress Any
}

# Execute rule update
Update-FirewallRules

Write-Host "Firewall configured successfully!" -ForegroundColor Green
Write-Host "Allowed domains: $($allowedDomains -join ', ')"
Write-Host "Allowed DNS server: $dnsServer" -ForegroundColor Cyan
Write-Warning "Outbound traffic is now restricted to only these websites and essential services"
Write-Host "To revert: Get-NetFirewallRule -DisplayName '${rulePrefix}*' | Remove-NetFirewallRule" -ForegroundColor Yellow
