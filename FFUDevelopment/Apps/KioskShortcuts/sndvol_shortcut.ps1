# This is required for Windows 11 kiosks because Quick Actions cannot be enabled (Volume slider at bottom right) 
# Should a method of enabling Quick Actions be found, this script can be removed
# Define the shortcut target and the location for the shortcut
$shortcutName = "Volume Mixer"
$shortcutTarget = "$env:SystemRoot\System32\sndvol.exe"
$shortcutPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\$shortcutName.lnk"

# Create a WScript.Shell COM object to create the shortcut
$wshShell = New-Object -ComObject WScript.Shell

# Create the shortcut
$shortcut = $wshShell.CreateShortcut($shortcutPath)

# Set the target path and other shortcut properties
$shortcut.TargetPath = $shortcutTarget
$shortcut.IconLocation = $shortcutTarget
$shortcut.Description = "Open Volume Mixer"

# Save the shortcut
$shortcut.Save()