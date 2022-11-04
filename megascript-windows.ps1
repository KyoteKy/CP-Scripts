[int]$executedCommands = 0;

# ask and restart program if admin isn't present
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList $MyInvocation.MyCommand.Definition
    Exit
}

# log function
function log {
    param ( [string]$message, [string]$color )
    Write-Host $message -ForegroundColor $color
}

# Disable the Firewall. Duh
function FirewallDisable {
    param ( [string]$ruleName )
    netsh advfirewall firewall set rule name=$ruleName new enable=no | Out-Null
}

# Don't think I need to explain this one
function FirewallRuleBlock {
    param (
        [string]$DisplayName,
        [int]$LocalPort
    )
    New-NetFirewallRule -DisplayName $DisplayName -Direction Inbound -Action Block -LocalPort $LocalPort -Protocol TCP | Out-Null
}
# local audit policies
[array]$policies = @(
    "Account Logon",
    "Account Management",
    "DS Access",
    "Logon/Logoff",
    "Object Access",
    "Policy Change",
    "Privilege Use",
    "Detailed Tracking",
    "System"
)

echo   _______________________________________________________________________________
echo  /                                                                               \
echo /|  Welcome to the CyberPatriot Windows 10/Windows Server 2019 megascript!       |\
echo  |  Use of this script by any other CP teams for competition use is strictly     |
echo  |  prohibited by the CyberPartiot Rulebook. Currently, this script only changes |
echo  |  Firewall stuff, as well as the Security Audit Policy stuff. There will be    |
echo  |  more things added in the future, such as authorized users and admins.        |
echo  *********************************************************************************



# firewall rules 
[array]$firewallRules = @(
    "Remote Assistance (DCOM-In)",
    "Remote Assistance (PNRP-In)",
    "Remote Assistance (RA Server TCP-In)",
    "Remote Assistance (SSDP TCP-In)",
    "Remote Assistance (SSDP UDP-In)",
    "Remote Assistance (TCP-In)"
)

# disable netFirewall Rules 
[array]$netFirewallRules = @(
    "sshTCP:22",
    "ftpTCP:21",
    "telnetTCP:23",
    "SMTPTCP:25",
    "POP3TCP:110",
    "SNMPTCP:161",
    "RDPTCP:3389"
)

log "local policies" "yellow"
For ($i = 0; $i -lt $policies.Length; $i++) {
    auditpol /set /category:$($policies[$i]) /success:enable /failure:enable | Out-Null
    $executedCommands++
}

log "Account Policies / Password Policies" "yellow"
net accounts /UNIQUEPW:24 /MAXPWAGE:60 /MINPWAGE:1 /MINPWLEN:12 /lockoutthreshold:5 | Out-Null
$executedCommands++

# disable guest account
log "Guest Account" "yellow"
Get-LocalUser Guest | Disable-LocalUser | Out-Null
$executedCommands++

# clear out DNS cache
log "Flush DNS" "yellow";
ipconfig /flushdns | Out-Null
$executedCommands++

# per-profile Firewall configs
log "Firewall features" "yellow"
# per-profile Firewall configs
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
Set-NetFirewallProfile -DefaultInboundAction Block -DefaultOutboundAction Allow -NotifyOnListen True -AllowUnicastResponseToMulticast True -LogFileName %SystemRoot%\System32\LogFiles\Firewall\pfirewall.log
$executedCommands += 2

# Block Firewall Rules
log "Firewall rules" "yellow"
foreach ($netFirewallRule in $netFirewallRules) {
    $rule = $netFirewallRule -split ":"
    blockNetFirewallRule $rule[0] $rule[1]
    $executedCommands++
}

# Firewall Feature Disable
foreach ($fireWall in $firewallRules) {
    disableFirewallFeature $fireWall
    $executedCommands++
}

log "done. executed $executedCommands commands" "green"
# little goodbye thing
echo    ____________________________
echo   /                            \
echo  /|         Finished!          |\
echo   |                            |
echo   ******************************
pause
