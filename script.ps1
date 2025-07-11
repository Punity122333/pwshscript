#Requires -RunAsAdministrator
<#
.SYNOPSIS
Allows only specified websites while maintaining Wi-Fi connection
.DESCRIPTION
Creates firewall rules to:
1. Allow all local network traffic (essential for Wi-Fi)
2. Allow DNS to your specified server
3. Allow HTTP/HTTPS to selected domains
4. Block all other internet traffic
.NOTES
- Run as Administrator
- Maintains Wi-Fi connection by allowing local traffic
#>

# Domain list to allow
$allowedDomains = @(
    "vjudge.net",
    "programiz.com",
    "cppreference.com"
)

# Custom DNS server IP
$dnsServer = "172.16.120.1"

# Rule name prefix
$rulePrefix = "RestrictedAccess_"

function Update-FirewallRules {
    # Remove existing rules
    Get-NetFirewallRule -DisplayName "$rulePrefix*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -Confirm:$false

    # CRITICAL: Allow all local network traffic (keeps Wi-Fi connected)
    New-NetFirewallRule -DisplayName "${rulePrefix}LocalSubnet" -Direction Outbound `
        -RemoteAddress "192.168.0.0/16,10.0.0.0/8,172.16.0.0/12,169.254.0.0/16" -Action Allow

    # Allow critical services (DHCP for IP renewal)
    New-NetFirewallRule -DisplayName "${rulePrefix}DHCP" -Direction Outbound `
        -Protocol UDP -LocalPort 68 -RemotePort 67 -Action Allow

    # Allow DNS ONLY to specified DNS server
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

    # Block all other internet traffic (but not local)
    New-NetFirewallRule -DisplayName "${rulePrefix}BlockInternet" -Direction Outbound `
        -Action Block -RemoteAddress Internet
}

# Execute rule update
Update-FirewallRules

Write-Host "Firewall configured successfully!" -ForegroundColor Green
Write-Host "Allowed domains: $($allowedDomains -join ', ')"
Write-Host "Allowed DNS server: $dnsServer" -ForegroundColor Cyan
Write-Host "Local network traffic ALLOWED (Wi-Fi stays connected)" -ForegroundColor Green
Write-Warning "Outbound internet traffic restricted to allowed sites only"
Write-Host "To revert: Get-NetFirewallRule -DisplayName '${rulePrefix}*' | Remove-NetFirewallRule" -ForegroundColor Yellow
