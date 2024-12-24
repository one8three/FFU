$Apps = @(
    "Microsoft.BingWeather",
    "Microsoft.GetHelp",
    "Microsoft.GetStarted",
    "Microsoft.People",
    "Microsoft.MicrosoftSolitaireCollection",
    #"Microsoft.MicrosoftOfficeHub",
    "Microsoft.MixedReality.Portal",
    #"Microsoft.Office.OneNote",
    "Microsoft.OutlookForWindows",
    "Microsoft.SkypeApp",
    "Microsoft.Wallet",
    "Microsoft.WindowsAlarms",
    "Microsoft.WindowsCommunicationsApps",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxApp",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.YourPhone",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    # Windows 11 apps
    "Microsoft.BingNews",
    "Microsoft.GamingApp",
    "Microsoft.MicrosoftTeams"
)

Foreach ($App in $Apps){
    $Installed = Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match $App}
    If ($Installed){
        Write-Host "Uninstalling $($Installed.DisplayName)"
        Remove-AppxProvisionedPackage -Online -PackageName $Installed.PackageName -AllUsers
    }
}