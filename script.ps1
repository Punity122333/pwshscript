#Requires -RunAsAdministrator

# Define allowed websites and DNS server
$allowedWebsites = @(
    "vjudge.net",
    "programiz.com",
    "cppreference.com"
)
$dnsServer = "172.16.120.1"

# Remove existing rules if they exist to avoid duplicates
$ruleNames = @(
    "Allow Specific Websites - HTTP",
    "Allow Specific Websites - HTTPS",
    "Allow DNS Server",
    "Block HTTP Outbound",
    "Block HTTPS Outbound"
)

foreach ($name in $ruleNames) {
    if (Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue) {
        Remove-NetFirewallRule -DisplayName $name -Confirm:$false
    }
}

# Create allow rules for each website (HTTP and HTTPS)
foreach ($site in $allowedWebsites) {
    # HTTP Allow Rule
    New-NetFirewallRule -DisplayName "Allow Specific Websites - HTTP" `
        -Direction Outbound `
        -RemoteAddress $site `
        -RemotePort 80 `
        -Protocol TCP `
        -Action Allow `
        -Enabled True `
        -Profile Any `
        -Group "Allowed Websites"

    # HTTPS Allow Rule
    New-NetFirewallRule -DisplayName "Allow Specific Websites - HTTPS" `
        -Direction Outbound `
        -RemoteAddress $site `
        -RemotePort 443 `
        -Protocol TCP `
        -Action Allow `
        -Enabled True `
        -Profile Any `
        -Group "Allowed Websites"
}

# Create allow rules for DNS server (TCP and UDP)
New-NetFirewallRule -DisplayName "Allow DNS Server" `
    -Direction Outbound `
    -RemoteAddress $dnsServer `
    -RemotePort 53 `
    -Protocol UDP `
    -Action Allow `
    -Enabled True `
    -Profile Any

New-NetFirewallRule -DisplayName "Allow DNS Server" `
    -Direction Outbound `
    -RemoteAddress $dnsServer `
    -RemotePort 53 `
    -Protocol TCP `
    -Action Allow `
    -Enabled True `
    -Profile Any

# Create block rules for HTTP and HTTPS
New-NetFirewallRule -DisplayName "Block HTTP Outbound" `
    -Direction Outbound `
    -RemotePort 80 `
    -Protocol TCP `
    -Action Block `
    -Enabled True `
    -Profile Any `
    -Priority 100

New-NetFirewallRule -DisplayName "Block HTTPS Outbound" `
    -Direction Outbound `
    -RemotePort 443 `
    -Protocol TCP `
    -Action Block `
    -Enabled True `
    -Profile Any `
    -Priority 100

Write-Host "Firewall configuration completed successfully." -ForegroundColor Green
Write-Host "Allowed websites: $($allowedWebsites -join ', ')" 
Write-Host "Allowed DNS server: $dnsServer"
