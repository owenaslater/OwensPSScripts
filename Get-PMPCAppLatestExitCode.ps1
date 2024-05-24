# Define the installer name and the path to the log file
$InstallerName = "AcrobatDCUpd"
$logFilePath = "$env:ProgramData\PatchMyPCIntuneLogs\PatchMyPC-ScriptRunner.log"

# Read the log file content
$logContent = Get-Content -Path $logFilePath

# Find the index of the line starting the installer process
$AdobeLines = (($logContent | Select-String -Pattern "$InstallerName").LineNumber)
$NumberOfLines = $AdobeLines.Count-1
$index = $AdobeLines[$NumberOfLines]


# Check if the line exists
if ($index -ne -1) {
    # Calculate the index of the line 33 lines below the installer line
    $targetIndex = $index + 33
    #If the line is too close to the end, it will select the previous instance of the installation instead
    while($targetIndex -gt $logContent.Count){
        $NumberOfLines-=1
        $index = $AdobeLines[$NumberOfLines]
        $targetIndex = $index +33
    }

    #Reads the line 33 lines below the installer
    $targetLine = $logContent[$targetIndex]
    #Read line by line until the Exit code is found
    while($targetLine -notlike "*Exit code*"){
        $targetIndex+=1
        $targetLine = $logContent[$targetIndex]
        if($targetIndex -gt $logContent.Count){
            Write-Output "No exit codes found for $InstallerName, detection has failed"
        }
    }
        # Check if the target line contains "1602" which is User deferral
    if ($targetLine -like "*1602*") {
        Write-Output "The exit code for $InstallerName is '1602':"
        Write-Output $targetLine
        Write-Output "The user had deferred the update"
    } else {
        Write-Output "The exit code for $InstallerName is not '1602'."
        Write-Output $targetLine
    }

} else {
    Write-Output "The installation process was not found."
}
