# Parameter help description
param(
     [Parameter(Mandatory)]
     [string]$Url,
     [Parameter(Mandatory)]
     [string]$Name,
     [Parameter()]
     [switch]$ForceNewIcon
)

# If including an icon, name it the same as the shortcut name. Example:
#    $Name variable: Clever
#    Icon Name: Clever.ico

$ShortcutPath = "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\$Name.lnk"

# Remove old shortcut if it exists
if(Test-Path -Path $ShortcutPath -PathType Leaf){
     Remove-Item -Path $ShortcutPath -Force
}


# Make icon directory if it does not exist
$ShortcutIconFolder = "C:\ProgramData\WCSD\shortcut_icons\"
if(!(Test-Path -Path $ShortcutIconFolder -PathType Container)){
     mkdir $ShortcutIconFolder -Force
}


# Check for local icon
$IconPackIcon = Test-Path -Path "$ShortcutIconFolder\$Name.ico" -PathType Leaf
# Check for icon included with Intune app package
$IntunePkgIcon = Test-Path -Path "$PSScriptRoot\$Name.ico" -PathType Leaf


# Determine if icon is available
if ($IconPackIcon -and !$ForceNewIcon){
     Write-Host "Icon"
     # Icon already exists
     $Icon = "C:\ProgramData\WCSD\shortcut_icons\$Name.ico"
} elseif ($IntunePkgIcon -or $ForceNewIcon) {    
     # Copy icon to WCSD icon directory
     Copy-Item -Path "$PSScriptRoot\$Name.ico" -Destination "C:\ProgramData\WCSD\shortcut_icons\$Name.ico" -Force
     $Icon = "C:\ProgramData\WCSD\shortcut_icons\$Name.ico"
} else {
     # Set icon state to $false
     $Icon = $null
}


# Set shortcut configuration
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$ShortcutPath")
$Shortcut.TargetPath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$Shortcut.Arguments = "--kiosk $Url --edge-kiosk-type=public-browsing --kiosk-idle-timeout-minutes=10" # "--no-first-run" will break the shortcut

# If icon is available, use it
if($Icon){
     $Shortcut.IconLocation = $Icon
}

# Save shortcut
$Shortcut.Save()