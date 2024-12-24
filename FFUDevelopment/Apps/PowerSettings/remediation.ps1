# based on script/info found here:
#   https://powers-hell.com/2018/12/10/control-advanced-power-settings-with-powercfg-powershell/

# grab powercfg guids necessary for lid switch action
#   https://docs.microsoft.com/en-us/windows-hardware/customize/power-settings/power-button-and-lid-settings-lid-switch-close-action

#capture the active scheme GUID
$activeScheme = cmd /c "powercfg /getactivescheme"
$regEx = '(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}'
$asGuid = [regex]::Match($activeScheme,$regEx).Value

# Relevent settings group GUIDs
$DisplaySettingsGuid = "7516b95f-f776-4464-8c53-06167f40cc99"
$DiskSettingsGuid = "0012ee47-9041-4b5d-9b77-535fba8b1442"
$SleepSettingsGuid = "238c9fa8-0aad-41ed-83f4-97be242c8f20"

# Specific Settings GUIDs
$DisplayIdleTimeoutGuid = "3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e"
$DiskIdleTimeoutGuid = "6738e2c4-e8a5-4a42-b16a-e040e769756e"
$SleepIdleTimeoutGuid = "29f6c1db-86da-48c5-9fdb-f2b67b1f44da"

# Get current settings
$CurrentDisplayTimeout = (cmd /c "powercfg.exe /q $asGuid $DisplaySettingsGuid $DisplayIdleTimeoutGuid")
$CurrentDiskIdleTimeout = (cmd /c "powercfg.exe /q $asGuid $DiskSettingsGuid $DiskIdleTimeoutGuid")
$CurrentSleepIdleTimeout = (cmd /c "powercfg.exe /q $asGuid $SleepSettingsGuid $SleepIdleTimeoutGuid")


if (($CurrentDisplayTimeout -notcontains "    Current AC Power Setting Index: 0x00001C20") -or ($CurrentDisplayTimeout -notcontains "    Current DC Power Setting Index: 0x00000384")){
    # Set display idle timeout
    cmd /c "powercfg.exe /setacvalueindex $asGuid $DisplaySettingsGuid $DisplayIdleTimeoutGuid 7200" # 7200 seconds = 120 minutes
    cmd /c "powercfg.exe /setdcvalueindex $asGuid $DisplaySettingsGuid $DisplayIdleTimeoutGuid 900" # 900 seconds = 15 minutes
}

if (($CurrentDiskIdleTimeout -notcontains "    Current AC Power Setting Index: 0x00000000") -or ($CurrentDiskIdleTimeout -notcontains "    Current DC Power Setting Index: 0x00000000")){
    # Set disk idle timeout
    cmd /c "powercfg.exe /setacvalueindex $asGuid $DiskSettingsGuid $DiskIdleTimeoutGuid 0" # never
    cmd /c "powercfg.exe /setdcvalueindex $asGuid $DiskSettingsGuid $DiskIdleTimeoutGuid 0" # never
}

if (($CurrentSleepIdleTimeout -notcontains "    Current AC Power Setting Index: 0x00000000") -or ($CurrentSleepIdleTimeout -notcontains "    Current DC Power Setting Index: 0x00000708")){
    # Set sleep idle timeout
    cmd /c "powercfg.exe /setacvalueindex $asGuid $SleepSettingsGuid $SleepIdleTimeoutGuid 0" # never
    cmd /c "powercfg.exe /setdcvalueindex $asGuid $SleepSettingsGuid $SleepIdleTimeoutGuid 1800" # 1800 seconds = 30 minutes
}

# Apply to settings
cmd /c "powercfg /s $asGuid"