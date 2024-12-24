function Set-Registry {
    param (
        $Key,
        $Name,
        $Value
    )

    #.....................Create the registry key if it doesn't exit..............................
    if (!(Test-Path -Path $Key)){
        New-Item -Path $Key -Force
    }

    #.....................Create or set the registry value............
    $RegValue = (Get-ItemProperty -Path $Key -Name $Name -ErrorAction silentlycontinue)
    if(!$RegValue){
        New-ItemProperty -Path $Key -Name $Name -Value $Value
    } elseif ($RegValue.$Name -ne $Value){
        Set-ItemProperty -Path $Key -Name $Name -Value $Value
    }

}

#...................Check for Windows 11..........................................................
$OSName = (Get-ComputerInfo).OsName
if ($OSName -match "Windows 11"){
    $Win11 = $true
} else {
    $Win11 = $false
}

################################
### Disable News & Interests ###
################################
$Key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds'
$Name = 'EnableFeeds'
$Value = 0

Write-Host "Disabling News & Interest"
Set-Registry -Key $Key -Name $Name -Value $Value

######################################
### Disable MS Store Task Bar icon ###
######################################
$Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
$Name = "NoPinningStoreToTaskbar"
$Value = 1

Write-Host "Removing MS Store taskbar icon"
Set-Registry -Key $Key -Name $Name -Value $Value


######################################
######### WINDOWS 11 CHANGES #########
######################################

<# This doesn't work so it is now set via FFUDevelopment/BuildFFUUnattend/unattend.win11.xml
####################################################
### Prevent Win11 Consumer Teams from Installing ###
####################################################

if($Win11){
    $Key = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Communications"
    $Name = "ConfigureChatAutoInstall"
    $Value = 0

    Write-Host "Preventing Windows 11 Consumer Teams from installing"
    Set-Registry -Key $Key -Name $Name -Value $Value
}
#>

###########################################
### Remove Win11 Chat Icon from taskbar ###
###########################################
if($Win11){
    $Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat"
    $Name = "ChatIcon"
    $Value = 3

    Write-Host "Removing Windows 11 Chat Icon from taskbar"
    Set-Registry -Key $Key -Name $Name -Value $Value
}

#############################
### Disable Win11 Widgets ###
#############################

if($Win11){
    $Key = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
    $Name = "AllowNewsAndInterests"
    $Value = 0

    Write-Host "Disabling Windowss 11 widgets"
    Set-Registry -Key $Key -Name $Name -Value $Value
}

<# THIS DOES NOT WORK for HKLM currently..or ever?...has been implemented in the defualt user hive below.
# Leaving this here for future reference
#############################
### Disable Win11 Copilot ###
#############################

if($Win11){
    # Disable for machine
    $Key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
    $Name = "TurnOffWindowsCopilot"
    $Value = 1

    Write-Host "Disabling Windows 11 Copilot feature for machine"
    Set-Registry -Key $Key -Name $Name -Value $Value

}
#END THIS DOES NOT WORK #>

#############################
### Disable Win11 Copilot ###
#############################
if($Win11){
    # Import the Default User registry hive and create a new PSDrive for the hive
    Start-Process "reg.exe" -ArgumentList "load HKLM\DefaultUser C:\Users\Default\NTUSER.DAT" -Wait
    New-PSDrive -Name HKDU -PSProvider Registry -Root HKLM\DefaultUser

    # Define the variables
    $Key = "HKDU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
    $Name = "TurnOffWindowsCopilot"
    $Value = 1

    # Make the registry change
    Set-Registry -Key $Key -Name $Name -Value $Value

    # Remove the temporary PSDrive and unload the default user registry hive
    Remove-PSDrive HKDU
    Start-Process "reg.exe" -ArgumentList "unload HKLM\DefaultUser" -Wait
}