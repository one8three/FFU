# Parameter help description
param(
     [Parameter(Mandatory)]
     [string]$Url,
     [Parameter(Mandatory)]
     [string]$Name
)

$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\$Name.lnk")
$Shortcut.TargetPath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$Shortcut.Arguments = "--kiosk $Url --edge-kiosk-type=public-browsing --kiosk-idle-timeout-minutes=10" # --no-first-run will break the shortcut
$Shortcut.Save()