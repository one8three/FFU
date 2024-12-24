# Required files:
#   cisco-secure-client-win-{Version}-core-vpn-predeploy-k9.msi
#   cisco-secure-client-win-{Version}-umbrella-predeploy-k9.msi
#   cisco-secure-client-win-{Version}-dart-predeploy-k9.msi
#   OrgInfo.json

###### Make config folder #####
$ConfigPath = "C:\ProgramData\Cisco\Cisco Secure Client\Umbrella"
Write-Host "Creating Cisco Umbrella config directory."
mkdir "$ConfigPath" -force

##### Place the Umbrella Config file in its proper folder ######
Write-Host "Creating Umbrella config file"
Copy-Item -Path "$PSScriptRoot\OrgInfo.json" -Destination "$ConfigPath\OrgInfo.json" -Force


##### Get installer files #####
$CSCInstaller = (Get-ChildItem "$PSScriptRoot\" -Filter "*-core-vpn-predeploy-k9.msi").Name # Get file name of the Cisco Secure Client Installer
$UmbrellaInstaller = (Get-ChildItem "$PSScriptRoot\" -Filter "*-umbrella-predeploy-k9.msi").Name # Get file name of the Umbrella installer
$DARTInstaller = (Get-ChildItem "$PSScriptRoot\" -Filter "*-dart-predeploy-k9.msi").Name # Get file name of the DART installer

##### Run installers #####
# Cisco Secure Client - AnyConnect
cmd /c "msiexec.exe /package $CSCInstaller /norestart /qn PRE_DEPLOY_DISABLE_VPN=1 LOCKDOWN=1"

# Cisco Secure Client - Umbrella
cmd /c "msiexec.exe /package $UmbrellaInstaller /norestart LOCKDOWN=1 /qn"

# Cisco Secure Client - DART
cmd /c "msiexec.exe /package $DARTInstaller /norestart LOCKDOWN=1 /qn"
