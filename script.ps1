# PowerShell script to allow specific websites via Windows Defender Firewall

# Define all IPs to allow (from nslookup results)
$allowedIPs = @(
    # cppreference.com
    "208.80.6.137", "2604:4f00::3:0:1238:1",
    
    # programiz.com
    "104.21.42.88", "172.67.204.38",
    "2606:4700:3035::ac43:cc26", "2606:4700:3033::6815:2a58",
    
    # vjudge.net
    "172.67.157.148", "104.21.40.232",
    "2606:4700:3036::ac43:9d94", "2606:4700:3031::6815:28e8"
)

# Create a rule for each IP (IPv4 and IPv6)
foreach ($ip in $allowedIPs) {
    $ruleName = "Allow Website IP - $ip"
    New-NetFirewallRule -DisplayName $ruleName `
                        -Direction Outbound `
                        -Action Allow `
                        -RemoteAddress $ip `
                        -Protocol Any `
                        -Profile Any `
                        -Description "Allow traffic to $ip (known good site)" `
                        -Group "Custom Allow Rules"
}

Write-Host "✅ Firewall allow rules created for cppreference, programiz, and vjudge."
