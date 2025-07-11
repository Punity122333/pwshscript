# Must be run as Administrator

# STEP 1: Create a GLOBAL BLOCK OUTBOUND RULE
New-NetFirewallRule -DisplayName "Block All Outbound" `
                    -Direction Outbound `
                    -Action Block `
                    -RemoteAddress "Any" `
                    -Protocol Any `
                    -Profile Any `
                    -Enabled True `
                    -Group "Strict Internet Rules" `
                    -Description "Block all outbound traffic by default"

# STEP 2: Whitelist specific IPs (cppreference, programiz, vjudge)
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

foreach ($ip in $allowedIPs) {
    $ruleName = "Allow Website IP - $ip"
    New-NetFirewallRule -DisplayName $ruleName `
                        -Direction Outbound `
                        -Action Allow `
                        -RemoteAddress $ip `
                        -Protocol Any `
                        -Profile Any `
                        -Enabled True `
                        -Group "Strict Internet Rules" `
                        -Description "Allow traffic to $ip (whitelisted site)"
}

Write-Host "`n✅ All rules added. Only cppreference, programiz, and vjudge are allowed. Everything else is blocked."
