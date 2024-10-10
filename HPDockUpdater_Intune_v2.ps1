<#
     .Author 
      Gary Blok | HP Inc | @gwblok | GARYTOWN.COM
      Dan Felman | HP Inc | @dan_felman 
 
     .Synopsis
      HP Dock Updater Script for Intune Proactive Remediation | Configuration Manager Configuration Items

     .Description
      This script will call the functions to detect and or update the Dock Firmware based on variables set at start.

     .Requirements
      PowerShell on the device you're running the script must have access to the interent to download the Firmware

     .Parameters 
      See embedded function Get-HPDockUpdateDetail for more info

     .ChangeLog

     .Notes
     
     For Intune set Purpose to "IntunePR"
     For ConfigMgr Set Purpose to "ConfigMgr"

     For Detect/Discovery, set $Remediate = $false
     For Remediation, Set $Remedation = $true

    #>


#Purpose: ConfigItem (Configuratn Manager) | IntunePR (Intune Proactive Remedation)
$Purpose = "IntunePR"
$Remediate = $true #Use for Detect if $false | Remedaite if $true
$Compliance = "Compliant"

### Grab Function Get-HPDockUpdateDetails and Paste Here: https://github.com/gwblok/garytown/edit/master/hardware/HP/Docks/Function_Get-HPDockUpdateDetails.ps1

#Replace this next line with the content of the actual function when running in production.  Right now it pulls the function from Github directly when running.
function Get-HPDockUpdateDetails {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, HelpMessage="Only matters when used with -Update, determine if user will see dialog or not")][ValidateSet('NonInteractive', 'Silent')][String]$UIExperience,
        [Parameter(Mandatory = $false, HelpMessage="Number between 60 and 600 for seconds to wait for a dock to be connected before exiting automatically")][ValidateRange(60,600)][int]$WaitTimer,
        [switch]$CMPackage, #This requires that you have a download step in the TS that downloads the Dock Firmware Softpaqs and places in variable HPDOCK (%HPDOCK01%)
        [switch]$BypassHPCMSL,
        [switch]$Transcript = $true,
        [switch]$Update,
        [switch]$Stage,
        [switch]$DebugOut
        
    ) # param
    $Transcript = $true
    $ScriptVersion = '23.06.06.02'

    # check for CMSL
    if ($CMPackage -ne $true){
        Try {
            $HPDeviceDetails = Get-HPDeviceDetails -ErrorAction SilentlyContinue }
        catch {
            Write-Host "Bypassing CMSL"
            $BypassHPCMSL = $true }

        $AdminRights = ([Security.Principal.WindowsPrincipal] `
                    [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        if ( $DebugOut ) { Write-Host "--Admin rights:"$AdminRights }
    }
    function Get-HPDockInfo {
        [CmdletBinding()]
        param($pPnpSignedDrivers)

        # **** Hardcode URLs in case of no CMSL installed: ****
        $Url_TBG2 = 'ftp.hp.com/pub/softpaq/sp143501-144000/sp143977.exe'   #  (as of apr 6, 2023)
        $Url_TBG4 = 'ftp.hp.com/pub/softpaq/sp143501-144000/sp143669.exe'   #  (as of apr 6, 2023)
        $Url_UniG2 = 'ftp.hp.com/pub/softpaq/sp146001-146500/sp146291.exe'  #  (as of june 6, 2023)
        $Url_UsbG5 = 'ftp.hp.com/pub/softpaq/sp146001-146500/sp146273.exe'  #  (as of june 6, 2023)
        $Url_UsbG4 = 'ftp.hp.com/pub/softpaq/sp88501-89000/sp88999.exe'     #  (as of apr 6, 2023)
        $Url_EssG5 = 'ftp.hp.com/pub/softpaq/sp144501-145000/sp144502.exe'  #  (as of apr 6, 2023)

        #######################################################################################
        $Dock_Attached = 0      # default: no dock found
        $Dock_ProductName = $null
        $Dock_Url = $null   
        # Find out if a Dock is connected - assume a single dock, so stop at first find
        foreach ( $iDriver in $pPnpSignedDrivers ) {
            $f_InstalledDeviceID = "$($iDriver.DeviceID)"   # analyzing current device
            if ( ($f_InstalledDeviceID -match "HID\\VID_03F0") -or ($f_InstalledDeviceID -match "USB\\VID_17E9") ) {
                switch -Wildcard ( $f_InstalledDeviceID ) {
                    '*PID_0488*' { $Dock_Attached = 1 ; $Dock_ProductName = 'HP Thunderbolt Dock G4' ; $Dock_Url = $Url_TBG4 ; $FirmwareInstaller = 'HPFirmwareInstaller.exe'}
                    '*PID_0667*' { $Dock_Attached = 2 ; $Dock_ProductName = 'HP Thunderbolt Dock G2' ; $Dock_Url = $Url_TBG2 ; $FirmwareInstaller = 'HPFirmwareInstaller.exe' }
                    '*PID_484A*' { $Dock_Attached = 3 ; $Dock_ProductName = 'HP USB-C Dock G4' ; $Dock_Url = $Url_UsbG4 ; $FirmwareInstaller = 'HP_USB-C_Dock_G4_FW_Update_Tool_Console.exe' }
                    '*PID_046B*' { $Dock_Attached = 4 ; $Dock_ProductName = 'HP USB-C Dock G5' ; $Dock_Url = $Url_UsbG5  ; $FirmwareInstaller = 'HPFirmwareInstaller.exe'}
                    #'*PID_600A*' { $Dock_Attached = 5 ; $Dock_ProductName = 'HP USB-C Universal Dock' }
                    '*PID_0A6B*' { $Dock_Attached = 6 ; $Dock_ProductName = 'HP USB-C Universal Dock G2' ; $Dock_Url = $Url_UniG2 ; $FirmwareInstaller = 'HPFirmwareInstaller.exe' }
                    '*PID_056D*' { $Dock_Attached = 7 ; $Dock_ProductName = 'HP E24d G4 FHD Docking Monitor' }
                    '*PID_016E*' { $Dock_Attached = 8 ; $Dock_ProductName = 'HP E27d G4 QHD Docking Monitor' }
                    '*PID_379D*' { $Dock_Attached = 9 ; $Dock_ProductName = 'HP USB-C G5 Essential Dock' ; $Dock_Url =  $Url_EssG5 ; $FirmwareInstaller = 'HPFirmwareInstaller.exe' }
                } # switch -Wildcard ( $f_InstalledDeviceID )
            } # if ( $f_InstalledDeviceID -match "VID_03F0")
            if ( $Dock_Attached -gt 0 ) { break }
        } # foreach ( $iDriver in $gh_PnpSignedDrivers )
        #######################################################################################

        return @(
            @{Dock_Attached = $Dock_Attached ;  Dock_ProductName = $Dock_ProductName  ;  Dock_Url = $Dock_Url;  Dock_InstallerName = $FirmwareInstaller}
        )
    } # function Get-HPDockInfo

    function Get-PackageVersion {
        [CmdletBinding()]param( $pDocknum, $pCheckFile ) # param

        if (Test-Path -Path $pCheckFile){
            $TestInfo = Get-Content -Path $pCheckFile
        }
        if ( $pDocknum -eq 9 ) {       
            [String]$InstalledVersion = $TestInfo | Select-String -Pattern 'installed' -SimpleMatch
            $InstalledVersion = $InstalledVersion.Split(":") | Select-Object -Last 1            
        } 
        elseif ( $pDocknum -in (1,2)){
            $TBDockPath = "HKLM:\SOFTWARE\HP\HP Firmware Installer"
            if (Test-Path -Path $TBDockPath) {
                $TBDockKeyChildren = Get-ChildItem -Path $TBDockPath -Recurse
                foreach ($Children in $TBDockKeyChildren){
                    if ($Children.Name -match "Thunder"){
                        $InstalledPackageVersion = $Children.GetValue('InstalledPackageVersion')    
                        if ($InstalledPackageVersion){$InstalledVersion = $InstalledPackageVersion}
                    }
                }
            }
        }
        else {
            [String]$InstalledVersion = $TestInfo | Select-String -Pattern 'Package' -SimpleMatch
            $InstalledVersion = $InstalledVersion.Split(":") | Select-Object -Last 1
        }
        return $InstalledVersion
    } # function Get-PackageVersion

    #########################################################################################

    #'-- Reading signed drivers list - use to scan for attached HP docks'
    $PnpSignedDrivers = Get-CimInstance win32_PnpSignedDriver 

    $Dock = Get-HPDockInfo $PnpSignedDrivers
    if ( $DebugOut ) { Write-Host "--Dock detected:"$Dock.Dock_ProductName }
    $HPFIrmwareUpdateReturnValues = @(
            @{Code = "0" ;  Message = "Success"}
            @{Code = "101" ;  Message = "Install or stage failed. One or more firmware failed to install."}
            @{Code = "102" ;  Message = "Configuration file failed to be loaded.This may be because it could not be found or that it was not properly formatted."}
            @{Code = "103" ;  Message = "One or more firmware packages specified in the configuration file could not be loaded."}
            @{Code = "104" ;  Message = "No devices could be communicated with.This could be because necessary drivers are missing to detect the device."}
            @{Code = "105" ;  Message = "Out - of - date firmware detected when running with 'check' flag."}
            @{Code = "106" ;  Message = "An instance of HP Firmware Installer is already running"}
            @{Code = "107" ;  Message = "Device not connected.This could be because PID or VID is not detected."}
            @{Code = "108" ;  Message = "Force option disabled.Firmware downgrade or re - flash not possible on this device."}
            @{Code = "109" ;  Message = "The host is not able to update firmware"}
        )
    # lop for up to 10 secs in case we just powered-on, or Dock detection takes a bit of time
    [int]$Counter = 0
    [int]$StepAmt = 20
    if ( $Dock.Dock_Attached -eq 0 ) {
        if ( $DebugOut ) { Write-Host "Waiting for Dock to be fully attached up to $WaitTimer seconds" -ForegroundColor Green }
        do {
            if ( $DebugOut ) { Write-Host " Waited $Counter Seconds Total.. waiting additional $StepAmt" -ForegroundColor Gray}
            $counter += $StepAmt
            Start-Sleep -Seconds $StepAmt
	    $PnpSignedDrivers = Get-CimInstance win32_PnpSignedDriver
            $Dock = Get-HPDockInfo $PnpSignedDrivers
            if ( $counter -eq $WaitTimer ) {
                if ( $DebugOut ) { Write-Host "Waited $WaitTimer Seconds, no dock found yet..." -ForegroundColor Red}
            }
        }
        while ( ($counter -lt $WaitTimer) -and ($Dock.Dock_Attached -eq "0") )
    } # if ( $Dock.Dock_Attached -eq "0" )

    if ( $Dock.Dock_Attached -eq 0 ) {
        Write-Host " No dock attached" -ForegroundColor Green
    } else {
        # NOW, let's get to work on the dock, if found
        if ( ($BypassHPCMSL -eq $true) -or ($CMPackage -eq $true) ) {
            $URL = $Dock.Dock_Url
            if ( $DebugOut ) { Write-Host "--Dock detected Url - hardcoded:"$Dock.Dock_Url }
        } else {
            $URL = (Get-SoftpaqList -Category Dock | Where-Object { $_.Name -match $dock.Dock_ProductName -and ($_.Name -match 'firmware') }).Url
            if ((!($URL))-or ($URL -eq "")){ #Fall back
                $URL = $Dock.Dock_Url
                if ( $DebugOut ) { Write-Host "--Dock detected Url - hardcoded:"$Dock.Dock_Url }
            }
        } # else if ( $BypassHPCMSL )

        $SPEXE = ($URL.Split("/") | Select-Object -Last 1)
        $SPNumber = ($URL.Split("/") | Select-Object -Last 1).replace(".exe","")
        if ( $DebugOut ) { Write-Host "--Dock detected firmware Softpaq:"$SPEXE }

        # Create Required Folders
        $OutFilePath = "$env:SystemDrive\swsetup\dockfirmware"
        $ExtractPath = "$OutFilePath\$SPNumber"
    
        
        if ($Transcript) {
            $Date = Get-Date -Format yyyyMMdd
            Start-Transcript -Path "$OutFilePath\$($SPNumber)-$($Date).txt"
        }
        if (($DebugOut) -or ($Transcript)) {write-Host $ScriptVersion}
        if (!($CMPackage)){ if (($DebugOut) -or ($Transcript)) {write-Host "  Running script with CMSL ="(-not $BypassHPCMSL) -ForegroundColor Gray}}
        if ( $Update ) {
            if (($DebugOut) -or ($Transcript)) {write-Host "  Executing a dock firmware update" -ForegroundColor Cyan}
        } else {
            if (($DebugOut) -or ($Transcript)) {write-Host "  Executing a check of the dock firmware version. Use -Update to update the firmware" -ForegroundColor Cyan}
        }
        try {
            [void][System.IO.Directory]::CreateDirectory($OutFilePath)
            [void][System.IO.Directory]::CreateDirectory($ExtractPath)
        } catch { 
            if ( $DebugOut ) { Write-Host "--Error creating folder"$ExtractPath }
            throw 
        }
        # Download Softpaq EXE
        if ($CMPackage){ #USE CM PACKAGE
            try { #Connect to TS Environment
                $tsenv = new-object -comobject Microsoft.SMS.TSEnvironment
                }

            catch{Write-Output "Not in TS"}
            if ($tsenv) {
                $CMPackagePath = $tsenv.value("HPDOCK01") #Make sure you have a step to download the package into the CCMCache before you run this... store the patch in HPDOCK variable
                Copy-Item -Path "$CMPackagePath\$SPEXE" -Destination "$OutFilePath\$SPEXE"
                if (!(Test-Path "$OutFilePath\$SPEXE")){
                    if (($DebugOut) -or ($Transcript)) {write-Host "  Failed to Copy $SPEXE to $OutFilePath from CCMCache: $CMPackagePath" -ForegroundColor Red}
                }
                else {
                    if (($DebugOut) -or ($Transcript)) {write-Host "  Successfully Copied $SPEXE to $OutFilePath from CCMCache: $CMPackagePath" -ForegroundColor Cyan}
                }
            }
        }
        else {
            if ( !(Test-Path "$OutFilePath\$SPEXE") ) { 
                try {
                    $Error.Clear()
                    if (($DebugOut) -or ($Transcript)) {Write-Host "  Starting Download of $URL to $OutFilePath\$SPEXE" -ForegroundColor Magenta}
                    Invoke-WebRequest -UseBasicParsing -Uri $URL -OutFile "$OutFilePath\$SPEXE"
                } catch {
                    if (($DebugOut) -or ($Transcript)) {Write-Host "!!!Failed to download Softpaq!!!" -ForegroundColor red}
                    if ($Transcript){ Stop-Transcript}
                    return -1
                }
            } else {
                if (($DebugOut) -or ($Transcript)) {Write-Host "  Softpaq already downloaded to $OutFilePath\$SPEXE" -ForegroundColor Gray}
            }
        }
        # Extract Softpaq EXE
        $FirmwareInstallerName = $Dock.Dock_InstallerName
        if ( Test-Path "$OutFilePath\$SPEXE" ) {     
            if (!(Test-Path "$OutFilePath\$SPNumber\$FirmwareInstallerName")){
                if (($DebugOut) -or ($Transcript)) {Write-Host "  Extracting to $ExtractPath" -ForegroundColor Magenta}
                if ( $AdminRights -or $CMPackage ) {
                    $Extract = Start-Process -FilePath $OutFilePath\$SPEXE -ArgumentList "/s /e /f $ExtractPath" -NoNewWindow -PassThru -Wait
                } else {
                    if (($DebugOut) -or ($Transcript)) {Write-Host "  Admin rights require to extract to $ExtractPath" -ForegroundColor Red}
                    Stop-Transcript
                    return -1
                }           
            } else {
                if (($DebugOut) -or ($Transcript)) {Write-Host "  Softpaq already Extracted to $ExtractPath" -ForegroundColor Gray}
            }
        } else {
            if (($DebugOut) -or ($Transcript)) {Write-Host "  Failed to find $OutFilePath\$SPEXE" -ForegroundColor Red}
            if ($Transcript){ Stop-Transcript}
            return -1
        }

        # Get package version from downloaded Softpaq configuration file
        $ConfigFile = "$OutFilePath\$SPNumber\HPFIConfig.xml"       # All docks except Essential
        $ConfigFileEssential = "$OutFilePath\$SPNumber\config.ini"  # Essential dock
        $ReadmeFileUSBCGen4 = "$OutFilePath\$SPNumber\HP_USB-C_Dock_G4_FW_Update_Tool_readme.txt"
        if ( Test-Path $ConfigFile ) {
            $xmlConfigContent = [xml](Get-Content -Path $ConfigFile)
            $PackageVersion = $xmlConfigContent.SelectNodes("FirmwareCollectionPackage/PackageVersion").'#Text'
            $ModelName = $xmlConfigContent.SelectNodes("FirmwareCollectionPackage/Name").'#Text'
            if (($DebugOut) -or ($Transcript)) {Write-Host "  Extracted Softpaq Info file: $ConfigFile" -ForegroundColor Cyan}
        } elseif ( Test-Path $ConfigFileEssential ) {    
            $ConfigInfo = Get-Content -Path $ConfigFileEssential
            [String]$PackageVersion = $ConfigInfo | Select-String -Pattern 'PackageVersion' -CaseSensitive -SimpleMatch
            [String]$ToolVersion = $ConfigInfo | Select-String -Pattern 'ToolVersion' -CaseSensitive -SimpleMatch
            if($PackageVersion){$PackageVersion = $PackageVersion.Split("=") | Select-Object -Last 1}
            if ($ToolVersion){$PackageVersion = $ToolVersion.Split("=") | Select-Object -Last 1}
            [String]$ModelName = $ConfigInfo | Select-String -Pattern 'ModelName' -CaseSensitive -SimpleMatch
            $ModelName = $ModelName.Split("=") | Select-Object -Last 1
            if (($DebugOut) -or ($Transcript)) {Write-Host "  Extracted Softpaq Info file: $ConfigFileEssential" -ForegroundColor Cyan}
        } # elseif ( Test-Path $ConfigFileEssential )
    
        if (($DebugOut) -or ($Transcript)) {Write-Host "  Softpaq for Device: $ModelName" -ForegroundColor Gray}
        if (($DebugOut) -or ($Transcript)) {Write-Host "  Softpaq Version: $PackageVersion" -ForegroundColor Gray}
        $script:SoftpaqSupportedDevice = $ModelName
        $script:SoftPaqVersion = $PackageVersion
        $DockRegPath = 'HKLM:\SOFTWARE\HP\HP Firmware Installer'
        [string]$MACAddress = (Get-WmiObject win32_networkadapterconfiguration | Where-Object {$_.Description -match "Realtek USB GbE Family Controller"}).MACAddress
        $MACAddress = $MACAddress.Trim()
        if (Test-Path "$OutFilePath\$SPNumber\$FirmwareInstallerName") { # Run Test only - Check if Update Required
            Set-Location -Path "$OutFilePath\$SPNumber"
            if (($DebugOut) -or ($Transcript)) {Write-Host " Running HP Firmware Check... please, wait" -ForegroundColor Magenta}
            # HP USB-C Dock G4 Special Process
            if ($Dock.Dock_ProductName -eq "HP USB-C Dock G4"){
                $DockG4RegPath = "$DockRegPath\HP USB-C Dock G4"
                if (!(Test-Path -path $DockG4RegPath)){
                    if (($DebugOut) -or ($Transcript)) {Write-Host " Creating $DockG4RegPath Key" -ForegroundColor green}
                    New-Item -Path $DockG4RegPath -Force | Out-Null
                    }
                New-ItemProperty -Path $DockG4RegPath -Name 'AvailablePackageVersion' -Value $PackageVersion -PropertyType string -Force | Out-Null
                New-ItemProperty -Path $DockG4RegPath -Name 'LastChecked' -Value $(Get-Date -Format "yyyy/MM/dd HH:mm:ss") -PropertyType string -Force | Out-Null
                
                New-ItemProperty -Path $DockG4RegPath -Name 'MACAddress' -Value $MACAddress -PropertyType string -Force | Out-Null
                $DockG4RegItem = Get-Item -Path $DockG4RegPath
                if ($DockG4RegItem.GetValue('InstalledPackageVersion') -eq $PackageVersion){
                    $script:UpdateRequired = $false
                    if (($DebugOut) -or ($Transcript)) {Write-Host " Firmware Already Current (according to the Registry): $PackageVersion" -ForegroundColor Green}
                }
                else {
                    if ($Update){
                        if (($DebugOut) -or ($Transcript)) {Write-Host " Update Needed (according to the Registry): $PackageVersion" -ForegroundColor Magenta}
                        Try {
                            $Error.Clear()
                            $HPFirmwareTest = Start-Process -FilePath "$OutFilePath\$SPNumber\$FirmwareInstallerName" -PassThru -Wait -NoNewWindow
                            New-ItemProperty -Path $DockG4RegPath -Name 'LastUpdateRun' -Value $(Get-Date -Format "yyyy/MM/dd HH:mm:ss") -PropertyType string -Force | Out-Null
                        } 
                        Catch {
                            if (($DebugOut) -or ($Transcript)) {write-Host $error[0].exception}
                            Stop-Transcript
                            return -5
                        }
                        if ($HPFirmwareTest.ExitCode -eq 0){
                            New-ItemProperty -Path $DockG4RegPath -Name 'InstalledPackageVersion' -Value $PackageVersion -PropertyType string -Force | Out-Null
                            New-ItemProperty -Path $DockG4RegPath -Name 'ErrorCode' -Value $HPFirmwareTest.ExitCode -PropertyType dword -Force | Out-Null
                            New-ItemProperty -Path $DockG4RegPath -Name 'LastUpdateStatus' -Value "Success" -PropertyType string -Force | Out-Null
                            if (($DebugOut) -or ($Transcript)) {Write-Host " Firmware is now updated" -ForegroundColor Green}
                            if (($DebugOut) -or ($Transcript)) {Write-Host " Installed Version: $PackageVersion" -ForegroundColor Green}
                            $script:UpdateRequired = $false
                            $script:InstalledFirmwareVersion = $PackageVersion
                            if (($DebugOut) -or ($Transcript)) {Write-Host " Update Successful: Exit 0" -ForegroundColor Green}
                        }
                        else {
                            New-ItemProperty -Path $DockG4RegPath -Name 'InstalledPackageVersion' -Value "NA" -PropertyType string -Force | Out-Null
                            New-ItemProperty -Path $DockG4RegPath -Name 'ErrorCode' -Value $HPFirmwareTest.ExitCode -PropertyType dword -Force | Out-Null
                            New-ItemProperty -Path $DockG4RegPath -Name 'LastUpdateStatus' -Value "Fail" -PropertyType string -Force | Out-Null
                            if (($DebugOut) -or ($Transcript)) {Write-Host " Update Failed: Exit $($HPFirmwareTest.ExitCode)" -ForegroundColor Red}
                        }

                    }
                    else {
                        $script:UpdateRequired = $true
                    }
                }
            } #IF "HP USB-C Dock G4"

            else {
                Try {
                    $Error.Clear()
                    $HPFirmwareTest = Start-Process -FilePath "$OutFilePath\$SPNumber\$FirmwareInstallerName" -ArgumentList "-C" -PassThru -Wait -NoNewWindow
                } Catch {
                    if (($DebugOut) -or ($Transcript)) {write-Host $error[0].exception}
                    Stop-Transcript
                    return -5
                }
                if ( $Dock.Dock_Attached -eq 9 ) {  # Essential dock found
                    $VersionFile = "$OutFilePath\$SPNumber\HPFI_Version_Check.txt"
                } else {
                    $VersionFile = ".\HPFI_Version_Check.txt"
                }


        
                switch ( $HPFirmwareTest.ExitCode ) {
                    0   { 
                            if (($DebugOut) -or ($Transcript)) {Write-Host " Firmware is up to date" -ForegroundColor Green}
                            $InstalledVersion = Get-PackageVersion $Dock.Dock_Attached $VersionFile
                            if (($DebugOut) -or ($Transcript)) {Write-Host " Installed Version: $InstalledVersion" -ForegroundColor Green}
                            $script:UpdateRequired = $false
                            $script:InstalledFirmwareVersion = $InstalledVersion
                        } # 0
                    105 {
                            if (!($UIExperience)){$UIExperience = 'NonInteractive'}
                            $Mode = switch ($UIExperience)
                            {
                                "NonInteractive" {"-ni"}
                                "Silent" {"-s"}
                                "Check" {"-C"}
                                "Force" {"-f"}
                            }
                            if (($DebugOut) -or ($Transcript)) {Write-Host " Update Required" -ForegroundColor Yellow}
                            $InstalledVersion = Get-PackageVersion $Dock.Dock_Attached $VersionFile
                            if (($DebugOut) -or ($Transcript)) {Write-Host " Installed Version: $InstalledVersion" -ForegroundColor Yellow}
                            
                            $script:InstalledFirmwareVersion = $InstalledVersion
                            if ($InstalledVersion -eq $PackageVersion){
                                if (($DebugOut) -or ($Transcript)) {Write-Host " Exit Code 105, but Versions already match, skipping Update" -ForegroundColor Yellow}
                                $script:UpdateRequired = $false
                            }
                            else {
                                $script:UpdateRequired = $true
                                if ( $Update ) {          
                                    $FirmwareArgList = "$Mode"
                                    if (($Dock.Dock_ProductName -eq "HP Thunderbolt Dock G4") -or ($Dock.Dock_ProductName -eq "HP USB-C Dock G5") -or ($Dock.Dock_ProductName -eq "HP USB-C Universal Dock G2")){
                                         if ($stage){
                                            $FirmwareArgList = "$Mode -stage"
                                         }
                                    }
                                    if (($DebugOut) -or ($Transcript)) {Write-Host " Starting Dock Firmware Update" -ForegroundColor Magenta}
                                    
                                    $HPFirmwareUpdate = Start-Process -FilePath "$OutFilePath\$SPNumber\HPFirmwareInstaller.exe" -ArgumentList "$FirmwareArgList" -PassThru -Wait -NoNewWindow
                                    $ExitInfo = $HPFIrmwareUpdateReturnValues | Where-Object { $_.Code -eq $HPFirmwareUpdate.ExitCode }
                                    if ($ExitInfo.Code -eq "0"){
                                        if (($DebugOut) -or ($Transcript)) {Write-Host " Update Successful!" -ForegroundColor Green}
                                    } else {
                                        if (($DebugOut) -or ($Transcript)) {Write-Host " Update Failed" -ForegroundColor Red}
                                        if (($DebugOut) -or ($Transcript)) {Write-Host " Exit Code: $($ExitInfo.Code)" -ForegroundColor Gray}
                                        if (($DebugOut) -or ($Transcript)) {Write-Host " $($ExitInfo.Message)" -ForegroundColor Gray}
                                    }
                                }
                            } # if ( $Update )
                        } # 105
                }
            } # Not HP USB-C Dock G4
            # HP USB-C G5 Essential Dock Registry Items
            if ($Dock.Dock_ProductName -eq "HP USB-C G5 Essential Dock"){
                $DockEssentialRegPath = "$DockRegPath\HP USB-C G5 Essential Dock"
                if (!(Test-Path -path $DockEssentialRegPath)){
                    if (($DebugOut) -or ($Transcript)) {Write-Host " Creating $DockEssentialRegPath Key" -ForegroundColor green}
                    New-Item -Path $DockEssentialRegPath -Force | Out-Null
                }
                New-ItemProperty -Path $DockEssentialRegPath -Name 'AvailablePackageVersion' -Value $PackageVersion -PropertyType string -Force | Out-Null
                New-ItemProperty -Path $DockEssentialRegPath -Name 'LastChecked' -Value $(Get-Date -Format "yyyy/MM/dd HH:mm:ss") -PropertyType string -Force | Out-Null
                New-ItemProperty -Path $DockEssentialRegPath -Name 'InstalledPackageVersion' -Value $InstalledVersion -PropertyType string -Force | Out-Null
                New-ItemProperty -Path $DockEssentialRegPath -Name 'ErrorCode' -Value $HPFirmwareTest.ExitCode -PropertyType dword -Force | Out-Null
                New-ItemProperty -Path $DockEssentialRegPath -Name 'MACAddress' -Value $MACAddress -PropertyType string -Force | Out-Null
                if ($HPFirmwareTest.ExitCode -eq "0"){
                    New-ItemProperty -Path $DockEssentialRegPath -Name 'LastUpdateStatus' -Value "Success" -PropertyType string -Force | Out-Null
                }
                elseif ($HPFirmwareTest.ExitCode -eq "105"){
                    if ($update) {
                        New-ItemProperty -Path $DockEssentialRegPath -Name 'LastUpdateRun' -Value $(Get-Date -Format "yyyy/MM/dd HH:mm:ss") -PropertyType string -Force | Out-Null
                        if ($ExitInfo.Code -eq "0"){
                            New-ItemProperty -Path $DockEssentialRegPath -Name 'ErrorCode' -Value $ExitInfo.Code -PropertyType dword -Force | Out-Null
                            New-ItemProperty -Path $DockEssentialRegPath -Name 'LastUpdateStatus' -Value "Success" -PropertyType string -Force | Out-Null
                            New-ItemProperty -Path $DockEssentialRegPath -Name 'InstalledPackageVersion' -Value $PackageVersion -PropertyType string -Force | Out-Null
                        }
                        else {
                            New-ItemProperty -Path $DockEssentialRegPath -Name 'ErrorCode' -Value $ExitInfo.Code -PropertyType dword -Force | Out-Null
                            New-ItemProperty -Path $DockEssentialRegPath -Name 'LastUpdateStatus' -Value "Fail" -PropertyType string -Force | Out-Null
                        }
                    }
                    else {
                        New-ItemProperty -Path $DockEssentialRegPath -Name 'LastUpdateStatus' -Value "UpdateRequired" -PropertyType string -Force | Out-Null

                    }
                }

            } #HP USB-C G5 Essential Dock
            # HP Thunderbolt Dock G2 Registry Items
            if ($Dock.Dock_ProductName -eq "HP Thunderbolt Dock G2"){
            $DockTB2RegPath = "$DockRegPath\HP Thunderbolt Dock G2"
                if (!(Test-Path -path $DockTB2RegPath)){
                    if (($DebugOut) -or ($Transcript)) {Write-Host " Creating $DockTB2RegPath Key" -ForegroundColor green}
                    New-Item -Path $DockTB2RegPath -Force | Out-Null
                }
                New-ItemProperty -Path $DockTB2RegPath -Name 'MACAddress' -Value $MACAddress -PropertyType string -Force | Out-Null
                if ($HPFirmwareTest.ExitCode -eq "0"){
                    New-ItemProperty -Path $DockTB2RegPath -Name 'LastUpdateStatus' -Value "Success" -PropertyType string -Force | Out-Null
                }
                elseif ($HPFirmwareTest.ExitCode -eq "105"){
                    if ($update) {
                        New-ItemProperty -Path $DockTB2RegPath -Name 'LastUpdateRun' -Value $(Get-Date -Format "yyyy/MM/dd HH:mm:ss") -PropertyType string -Force | Out-Null
                        if ($ExitInfo.Code -eq "0"){
                            New-ItemProperty -Path $DockTB2RegPath -Name 'LastUpdateStatus' -Value "Success" -PropertyType string -Force | Out-Null
                            #Run Check to update Current Registry Values
                            $HPFirmwareTest = Start-Process -FilePath "$OutFilePath\$SPNumber\$FirmwareInstallerName" -ArgumentList "-C" -PassThru -Wait -NoNewWindow
                        }
                        else {
                            New-ItemProperty -Path $DockTB2RegPath -Name 'LastUpdateStatus' -Value "Fail" -PropertyType string -Force | Out-Null
                        }
                    }
                    else {
                        if ($script:UpdateRequired -eq $true){
                            New-ItemProperty -Path $DockTB2RegPath -Name 'LastUpdateStatus' -Value "UpdateRequired" -PropertyType string -Force | Out-Null
                        }
                        else {
                            New-ItemProperty -Path $DockTB2RegPath -Name 'LastUpdateStatus' -Value "Success" -PropertyType string -Force | Out-Null
                            New-ItemProperty -Path $DockTB2RegPath -Name 'ErrorCode' -Value 0 -PropertyType dword -Force | Out-Null
                        }

                    }
                }
            }#HP Thunderbolt Dock G2
        } # if (Test-Path "$OutFilePath\$SPNumber\HPFirmwareInstaller.exe")
        if ($Transcript) {Stop-Transcript}
         $Return = @(
        @{Dock = "$($Dock.Dock_ProductName)"; InstalledFirmware = $script:InstalledFirmwareVersion ; SoftpaqFirmware = $script:SoftPaqVersion ; UpdateRequired = $script:UpdateRequired ; SoftpaqNumber = $SPNumber}
        )
        if (!($Update)){Return $Return}
        else {
            if (!(($DebugOut) -or ($Transcript))){Write-Output "$($ExitInfo.Message)"}
        }   
    }
}



### Function Ends

#Installation of HP CMSL if it's not present
if(-not(Test-Path "C:\Program Files\WindowsPowerShell\HP.CMSL.UninstallerData\unins000.exe")){
    $CMSLPath = "$env:SystemDrive\swsetup\dockfirmware\hp-cmsl-1.7.2.exe"
    if(-not(Test-Path "$env:SystemDrive\swsetup\dockfirmware")){
        New-Item -ItemType Directory -Path "$env:SystemDrive\swsetup\dockfirmware"
    }
    try{
        Invoke-WebRequest -URI "https://hpia.hpcloud.hp.com/downloads/cmsl/hp-cmsl-1.7.2.exe" -UseBasicParsing -OutFile $CMSLPath

    }
    catch {
        Write-Host "Network location was not accessible, trying again with Proxy settings"
        Invoke-WebRequest -URI "https://hpia.hpcloud.hp.com/downloads/cmsl/hp-cmsl-1.7.2.exe" -UseBasicParsing -Proxy http:\\proxy.aqa.org.uk -OutFile $CMSLPath
    }


    Start-Process -FilePath $CMSLPath -ArgumentList "/VERYSILENT"
}
#Loading of HP.ClientManagement module if not present
$HPModuleStatus = Get-Module HP.ClientManagement
if([string]::IsNullOrEmpty([string]$HPModuleStatus)){
    try{
        Import-Module HP.ClientManagement -ErrorAction Stop
        }
    catch{
        Start-Sleep -Seconds 15
        Import-Module HP.ClientManagement
    }
}



$DockInfo = Get-HPDockUpdateDetails
if ($DockInfo.UpdateRequired -eq $true){ #Update Required
    if ($Remediate -eq $false){ # NO Remediation (Discovery / Detection)
        if ($Purpose -eq "IntunePR") { exit 1} #Intune PR
        else { #ConfigMgr Configuration Item
            $Compliance = "Non-Compliant"
            return $Compliance
        }
    } #End NO Remediation ($false)
    if ($Remediate -eq $true){ #Run Update Process for Firmware
       #Run Function with Paramters to Update the Firmware showing a non-interactive UI and creating a Transcript file of the process.
       Get-HPDockUpdateDetails -UIExperience NonInteractive -Update -Transcript -Stage
    }
}
else{ #NO Dock Update Available / Needed
    if ($Purpose -eq "IntunePR") { exit 0} #Intune PR
    else{ return $Compliance} #ConfigMgr Configuration Item
}