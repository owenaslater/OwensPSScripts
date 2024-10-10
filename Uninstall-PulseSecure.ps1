<# 
Remediation Script for Pulse Purge from Local Machine

Runs the inbuilt Pulse uninstaller(s), which doesn't fully remove all references to Pulse from the system. 
Checks all local locations (registry and folders) that might house any remaining Pulse files / folders, then removes them.  
Finally, reports back whether any reference to Pulse still exists and exits with the corresponding exit code (1 for potential issue with uninstallation, 0 for successful purge).
#>

Try {
    # Sets variables for the locations that Pulse saves files, then combines into one array. All used later on, make sure to list all locations & also combine into one. All locations need to have a file selector tested and added later in script. Examples on line 87/88 as of script iteration on 25/07/2024. Read selector section comment & adjust before running script.
    $PulseDPFLocation = "C:\Windows\Downloaded Program Files\*"
    #$PulseRoamingLocation = "C:\Users\*\Appdata\Roaming\*"
    $CombinedLocations = $null
    $CombinedLocations += @($PulseDPFLocation<#, $PulseRoamingLocation#>)

    # Loads the main Pulse MSI (as there isn't an EXE for it) and the sub-module uninstaller EXE's into a variable, for later reference in uninstallation commands. Any other exe's / MSI IDs discovered can be added (once tested as silent installs) to this array, and script function will continue as normal.
    $PulseUninstallTargets = @(
        #"C:\Users\*\AppData\Roaming\Pulse Secure\Setup Client\uninstall.exe", # Don't want this to be ran by system, it won't cleaup properly as it's user hive. Task scheduler cleanup.
        "C:\Windows\Downloaded Program Files\PulseSetupClientCtrlUninstaller.exe",
        "C:\Windows\Downloaded Program Files\PulseSetupClientCtrlUninstaller64.exe",
        "{65988A2A-C8AF-43FC-B415-488069C9C2A5}"
    )

    # Loads the known Pulse Registry keys into an array. Any keys discovered that are not listed can simply be added by continuing below array, and script will need no further adjustments to function. Make sure that there's a comma at the end of all but the final key. 
    $PulseRegistryLocations = @(
        "HKLM:\SOFTWARE\Pulse Secure",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Pulse_Setup_Client Activex Control",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Pulse_Setup_Client Activex Control",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Pulse Secure 9.1",
        "HKLM:\SOFTWARE\WOW6432Node\Pulse Secure" #Potentially comment out (32 bit in 64 bit window, test in Sandbox) - This seems fine, should be able to leave. Remove comment on final version. 
        #"HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Pulse_Setup_Client" - User context key, Remediation will never find it. Move to Task Scheduler.
    )

    # Checks for running Pulse related services. Stops any found.
    $PulseServices = $null
    $PulseServices = Get-Service | Where-Object {($_.Name -Like "*Pulse Secure*") -or ($_.DisplayName -Like "*Pulse Secure*") -or ($_.ServiceName -Like "*Pulse Secure*")}
    
    if ($null -ne $PulseServices) {
        Write-Host "Pulse services currently running. Stopping."
        foreach ($PulseService in $PulseServices) {
                try {
                    Write-Host "Stopping $($PulseService.Name)" -ForegroundColor Yellow
                    Stop-Service $PulseService -Force -Verbose
                    Write-Host "$($PulseService.name) stopped." -ForegroundColor Green
                }
                catch {
                    Write-Host "Error stopping; $($PulseServices.name -join (", "))"
                    Exit 1
                }
            }
        }
    else {
        Write-Host "No pulse services to stop. Continuing to processes." -ForegroundColor Green
    }

    # Checks for running Pulse related processes. Stops any found.
    $PulseProcesses = $null
    $PulseProcesses = Get-Process | Where-Object {$_.Product -like "Pulse Secure*"}

    if ($null -ne $PulseProcesses) {
    Write-Host "Pulse processes currently running. Stopping."
    foreach ($PulseProcess in $PulseProcesses) {
            try {
                Write-Host "Stopping $($PulseProcess.Name)" -ForegroundColor Yellow
                Stop-Process $PulseProcess -Force -Verbose
                Write-Host "$($PulseProcess.name) stopped." -ForegroundColor Green
            }
            catch {
                Write-Host "Error stopping; $($PulseProcesses.Description -join (", "))"
                Exit 1
            }
        }
    }
    else {
    Write-Host "No pulse processes to stop. Continuing to uninstallation commands." -ForegroundColor Green
    }

    # Uninstalls the four separate Pulse modules, silently. (Thanks Uninstall View)
    foreach ($UninstallTarget in $PulseUninstallTargets) {
        try {
            if ($UninstallTarget -like "C:\*") {
                if(Test-Path $UninstallTarget){
                    Start-Process -FilePath $UninstallTarget -ArgumentList "/S" -Wait
                    Write-Host "Ran $($UninstallTarget.Split("\")[-1])" -ForegroundColor Green
                }
                else{
                    Write-Host "Skipping Executable at $UninstallTarget, exe not found"
                }
            }
            Else {
                Write-Host "Uninstalling Pulse MSI" -ForegroundColor Green
                Start-Process msiexec -ArgumentList "/X $($UninstallTarget) /qn" -Wait
                Write-Host "Uninstalled MSI ($($UninstallTarget))" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "Error uninstalling $UninstallTarget" #Test with throw and return instead of write-host
            Exit 1
        }
    }
    
    # Selects Pulse's folders / files from common locations and stores them in a variable. Set so that the search is refined enough to prevent as many erroneous selections as possible (E.G. another application's files that are similarly named aren't caught). If any other selectors are added, make them as granular as possible (like below) and test to make sure no other applications are likely to be picked up.
    # All of the selectors need to be included in the $PulseItemsToRemove array. If adding selector below, make sure to update the array too.
    try {
        Write-Host "Selecting Pulse files from $($CombinedLocations -join " & ") for deletion." -ForegroundColor Yellow
        $PulseSelectedDPF = $null
        #$PulseSelectedRoaming = $null
        $PulseItemsToRemove = $null
        
        $PulseSelectedDPF = Get-ChildItem $PulseDPFLocation | Where-Object {(($_.Name -like "PulseExt*" -or $_.Name -like "PulseSetupClient*") -and ($_.Extension -eq ".exe" -or $_.Extension -eq ".inf" -or $_.Extension -eq ".ocx") -or ($_.Name -eq "Install.log"))}
        if ($null -ne $PulseSelectedDPF) {
            $PulseItemsToRemove += @($PulseSelectedDPF)
            Write-Host "$PulseSelectedDPF added to `$PulseItemsToRemove"
        }
        else {
            Write-Host "Nothing to remove from $PulseDPFLocation" -ForegroundColor Yellow
        }
    <#  $PulseSelectedRoaming = Get-ChildItem $PulseRoamingLocation | Where-Object {$_.Name -eq "Pulse Secure"} # Task scheduler - can't delete as path contains exe. Move cleanup to scheduler. 
        if ($null -ne $PulseSelectedRoaming) {
            $PulseItemsToRemove += @($PulseSelectedRoaming)
            Write-Host "$PulseSelectedRoaming added to `$PulseItemsToRemove"
        }
        else {
            Write-Host "Nothing to remove from $PulseRoamingLocation" -ForegroundColor Yellow
        }
    #>
        Write-Host "File selection complete. Moving on to deletion of following files; $PulseItemsToRemove"
    }
    catch {
        Write-Host "Error whilst selecting files for deletion from $($CombinedLocations -join " & ")"
        Exit 1
    }
    
    # Deletes all previously selected files / folders
    try {
            if ($null -ne $PulseItemsToRemove) {
                foreach ($PulseItem in $PulseItemsToRemove) {
                    Write-Host "Deleting $PulseItem" -ForegroundColor Yellow
                    Remove-Item -Path $PulseItem -Recurse -Force
                    Write-Host "$PulseItem deleted." -ForegroundColor Green
                }
            }
            else {
                Write-Host "No Pulse files / folders found on system. Nothing to delete. Moving on to registry cleanup"
            }
    }
    catch {
        Write-Host "Error whilst deleting $PulseItemstoRemove"
        Exit 1
    }
    
    # Purge Pulse Registry Keys
    try {
            foreach ($PulseKey in $PulseRegistryLocations) {
                if (Test-Path -path $PulseKey -ErrorAction SilentlyContinue) {
                    Write-Host "Pulse reg entry found here - $($PulseKey)." -ForegroundColor Yellow
                    Write-Host "Deleting $($PulseKey)" -ForegroundColor Green
                    Remove-Item $PulseKey -Recurse -Force #Error SilentlyContinue to test if the "Cannot remove key" error disappears (user context)
                }
                Else {
                Write-Host "Couldn't find $($PulseKey). Continuing." -ForegroundColor Cyan
                }
            }
            Write-Host "Finished deleting Pulse registry keys. Script should now exit with success."
    }
    catch {
        Write-Host "Error occurred whilst attempting to delete Pulse registry keys; ($PulseRegistryLocations)"
        Exit 1
    }
    
    Write-Host "All steps carried out successfully, exiting" -ForegroundColor Green
    Exit 0
    
    }
    Catch {
        Write-Host "Error with script; $($_.Exception.Message)" -ForegroundColor Red
        Exit 1
    }
    
    # Add any other Pulse reg keys / file locations (full system sweep)
    
    # Error Checking. Check both Pulse locations, return anything related to pulse. Also scan registry for any remaining Pulse entries. Would be worth reviewing at the end of all checks to remove exits to one last check and exit with all issues.
    
    <# Foreach ($PulseLocation in $CombinedLocations) {
        $PulseItems = Get-ChildItem -Path $PulseLocation | Where-Object {$_.Name -like "Pulse*"}
        if ($PulseItems) {
            Write-Host "File or folder that starts 'Pulse' has been detected in $($PulseLocation). This might be leftover from uninstallation, or it may be a similar named folder for an application which is still needed."
            Write-Host "Discovered file / folder(s) - $($PulseItems)" # Need splitting for readability
            Exit 1
        }
        Else {
            Write-Host "No remaining 'Pulse' folders found within the common installation locations - $($CombinedLocations)." # Need splitting for readability
            Exit 0
        }
    } #>
    # For as long as the Get-ChildItem check contains X property (IsContainer for folders), Get-ChildItem $_.FullName, Potentially Variable+1 if needed?
    
    
    # Full system scan for Pulse keys or folders.