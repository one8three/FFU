#Requires -Modules Hyper-V, Storage
#Requires -PSEdition Desktop
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateSet('standard','kiosk','raptor','staff')]
    [string]$ImageType,
    [Parameter(Mandatory)]
    [ValidateSet('10','11')]
    [string]$ReleaseVersion,
    [ValidateSet(512, 4096)]
    [uint32]$SectorSize = 512,
    [Parameter(Mandatory = $false)]
    [string]$WinVer = '23H2',
    [ValidateScript({ Test-Path $_ })]
    [string]$ISO
    
)

#------------------Define image type and set up proper files------------------------------------------------------
if($ImageType -eq "standard"){ # If standard image, copy PROD files to be used
    Write-Host "Creating Windows $ReleaseVersion STANDARD image."
    $InstallOffice = $True
    $EnableNetwork = $False
    # Use the PRODUCTION app install file
    Copy-Item -Path "$PSScriptRoot\Apps\InstallAppsandSysprep-PROD.cmd" `
        -Destination "$PSScriptRoot\Apps\InstallAppsandSysprep.cmd" `
        -Force
    # Use the PRODUCTION Office deployment file
    Copy-Item -Path "$PSScriptRoot\Apps\Office\DeployFFU-PROD.xml" `
        -Destination "$PSScriptRoot\Apps\Office\DeployFFU.xml" `
        -Force
    # Use the PRODUCTION AppList.json file
    Copy-Item -Path "$PSScriptRoot\Apps\AppList-PROD.json" `
        -Destination "$PSScriptRoot\Apps\AppList.json" `
        -Force
} elseif ($ImageType -eq "kiosk"){ # If kiosk image, copy KIOSK files to be used
    Write-Host "Creating Windows $ReleaseVersion KIOSK image."
    $InstallOffice = $True
    $EnableNetwork = $False
    # Use the KIOSK app install file
    Copy-Item -Path "$PSScriptRoot\Apps\InstallAppsandSysprep-KIOSK.cmd" `
        -Destination "$PSScriptRoot\Apps\InstallAppsandSysprep.cmd" `
        -Force
    # Use the KIOSK office deployment file
    Copy-Item -Path "$PSScriptRoot\Apps\Office\DeployFFU-KIOSK.xml" `
        -Destination "$PSScriptRoot\Apps\Office\DeployFFU.xml" `
        -Force
        # Use the PRODUCTION Office deployment file
    Copy-Item -Path "$PSScriptRoot\Apps\Office\DeployFFU-KIOSK.xml" `
        -Destination "$PSScriptRoot\Apps\Office\DeployFFU.xml" `
        -Force
    # Use the PRODUCTION AppsList.json file
    Copy-Item -Path "$PSScriptRoot\Apps\AppList-KIOSK.json" `
        -Destination "$PSScriptRoot\Apps\AppList.json" `
        -Force    
} elseif ($ImageType -eq "raptor"){ # If raptor image, copy RAPTOR cmd file to be used
    Write-Host "Creating Windows $ReleaseVersion raptor image."
    $InstallOffice = $False
    $EnableNetwork = $true
    Copy-Item -Path "$PSScriptRoot\Apps\InstallAppsandSysprep-RAPTOR.cmd" `
        -Destination "$PSScriptRoot\Apps\InstallAppsandSysprep.cmd" `
        -Force
} elseif ($ImageType -eq "staff"){ # If raptor image, copy STAFF cmd file to be used
    Write-Host "Creating Windows $ReleaseVersion admin image."
    $InstallOffice = $true
    $EnableNetwork = $false
    Copy-Item -Path "$PSScriptRoot\Apps\InstallAppsandSysprep-STAFF.cmd" `
        -Destination "$PSScriptRoot\Apps\InstallAppsandSysprep.cmd" `
        -Force
}

# -----------------Define ISO path---------------------------------------------------------------------------------
if($ReleaseVersion -eq "10"){ # If building Windows 10 image, select Win 10 ISO and copy the relevent unattend file
    #$ISOPath = (Get-ChildItem -Path $PSScriptRoot -Filter Win_Pro_10*.iso | `
    #            Sort-Object -property Name -Descending)[0].FullName
    # Copy the appropriate unattend.xml for the selected Windows version
    Write-Host "Getting the $ReleaseVersion unattended.xml"
    Copy-Item -Path "$PSScriptRoot\BuildFFUUnattend\unattend_x64.win10.xml" `
        -Destination "$PSScriptRoot\BuildFFUUnattend\unattend_x64.xml" `
        -Force

} elseif ($ReleaseVersion -eq "11"){ # If building Windows 11 image, select Win 11 ISO
    #$ISOPath = (Get-ChildItem -Path $PSScriptRoot -Filter Win_Pro_11*.iso | `
    #            Sort-Object -property Name -Descending)[0].FullName
        # Copy the appropriate unattend.xml for the selected Windows version
        Write-Host "Getting the $ReleaseVersion unattended.xml"
        Copy-Item -Path "$PSScriptRoot\BuildFFUUnattend\unattend_x64.win11.xml" `
        -Destination "$PSScriptRoot\BuildFFUUnattend\unattend_x64.xml" `
        -Force
}

# Make sure all installers are present. If not, exit with error stating which is missing--------------------------
$TagFiles = (Get-ChildItem -Path $PSScriptRoot\Apps -Filter *.tag -Recurse).FullName 
$MissingFiles = @()

foreach($TagFile in $TagFiles){
    $FileExists = $False # Reset variable
    [string]$RealFile = $TagFile.Replace('[','`[').replace(']','`]').replace('.tag','') # Need these silly "replaces" thanks to PaperCut's file name
    $FileExists = Test-Path -Path $RealFile # Check for real installer file
    if (!$FileExists){ # If file doesn't exist, say so and exit
        $MissingFiles = $MissingFiles + $RealFile # Add missing file to MissingFiles array
    }
}
# If files are missing, show missing files and exit
if($MissingFiles -gt 0){
    Write-Host "ERROR: The following file(s) are missing:" -ForegroundColor DarkRed
    $MissingFiles | ForEach-Object{Write-Host "    $_" -ForegroundColor DarkRed}
    Exit 1
}


#------------------Make sure an ISO is present--------------------------------------------------------------------
$ISOExists = Get-ChildItem $PSScriptRoot/ -Filter *.iso # Check for .iso files
if(!$ISOExists){ # If ISO files do not exist, say so and exit
    Write-Host "ERROR: No ISO found." -ForegroundColor DarkRed
    exit 1
}

# Set parameter variables
$VMName = "_FFUVM-$(Get-Date -Format MMdd-mmss)"
$VMSwitchName = "Default Switch"
$VMHostIPAddress = (((get-netipaddress -InterfaceAlias "vEthernet (Default Switch)").IPv4Address) | Sort-Object -Unique)


# Raptop image requires internet connection in the VM

if($EnableNetwork){
    # Start job to set VM network
    # Set Job name
    $JobName = "_FFUVM_AddNetwork_$(Get-Date -format MMdd-mmss)"
    Write-Host "Starting background job to enable networking on VM when it starts..."
    Start-Job -Name "$JobName" -ScriptBlock {
        $VMSwitchName = $using:VMSwitchName

        # Wait for VM to be created and give it a network interface
        Write-Host "Waiting 60 seconds for VM to start..."
        Start-Sleep -Seconds 60
        # Checking for VM
        $VMOn = Get-VM -Name "$using:VMName"
        while($VMOn.State -ne "Running"){
            # If VM is not on, wait 15 more seconds
            Write-Host "Waiting 15 more seconds..."
            Start-Sleep -Seconds 15
            $VMOn = Get-VM -Name "$using:VMName"
        }
        # VM should be on now
        # Enabling networking on FFU VM
        $VMSwitch = Get-VMSwitch -name $VMSwitchName
        Write-Host "Setting $($VMSwitch.Name) as VMSwitch"
        $VMOn | Get-VMNetworkAdapter | Connect-VMNetworkAdapter -SwitchName $VMSwitch.Name
    }
}


Set-Location $PSScriptRoot

try{
    Write-Host "All checks passed! Starting FFU script..." -ForegroundColor DarkGreen
    .\BuildFFUVM.ps1 `
        -ISOPath $ISO `
        -WindowsSKU "Pro" `
        -InstallApps $True `
        -InstallOffice $InstallOffice `
        -Memory 8GB `
        -Disksize 30GB `
        -Processors 8 `
        -VMSwitchName $VMSwitchName `
        -VMHostIPAddress $VMHostIPAddress `
        -CreateCaptureMedia $True `
        -CreateDeploymentMedia $True `
        -ProductKey "VK7JG-NPHTM-C97JM-9MPGT-3V66T" `
        -BuildUSBDrive $False `
        -FFUDevelopmentPath "$PSScriptRoot" `
        -UpdateLatestCU $true `
        -UpdateLatestNet $true `
        -UpdateEdge $true `
        -UpdateOneDrive $true `
        -WindowsRelease "$ReleaseVersion" `
        -CleanupDeployISO $False `
  	    -LogicalSectorSizeBytes $SectorSize `
        -WindowsVersion "$WinVer" `
        -Verbose
        
} catch {
    Write-Host "FFU Script failed!" -ForegroundColor DarkRed
    if($EnableNetwork){
        Stop-Job -Name $JobName
        Remove-Job -Name $JobName
    }
    Exit 1
}

# Remove background job for enabling network
if($EnableNetwork){
    Remove-Job -Name $JobName
}

# Make sure FFU folder exists
if( ! ( Test-Path -Path "C:\FFU" -PathType Container ) ){
    mkdir "C:\FFU" -Force
}

### Append $ImageType to FFU file name
$FFUFile = Get-ChildItem "$PSScriptRoot\FFU\" -Filter *.ffu | Sort-Object LastWriteTime | Select-Object -last 1
# If file already exists, append date & time
if(Test-Path -Path "C:\FFU\$($FFUFile.BaseName)-$($ImageType.ToUpper()).ffu"){
    #Move-Item -Path $FFUFile.FullName -Destination "$PSScriptRoot\FFU\$($FFUFile.BaseName)-$($ImageType.ToUpper())$(Get-Date -Format yyMMddhhm).ffu"
    Move-Item -Path $FFUFile.FullName -Destination "C:\FFU\$($FFUFile.BaseName)-$($ImageType.ToUpper())$(Get-Date -Format yyMMddhhm).ffu"
}else{
    #Move-Item -Path $FFUFile.FullName -Destination "$PSScriptRoot\FFU\$($FFUFile.BaseName)-$($ImageType.ToUpper()).ffu"
    Move-Item -Path $FFUFile.FullName -Destination "C:\FFU\$($FFUFile.BaseName)-$($ImageType.ToUpper()).ffu"
}

# Report successful script run
Write-Host "New FFU created successfully." -ForegroundColor DarkGreen