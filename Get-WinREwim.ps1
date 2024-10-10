#Get Windows RE partition information
$reagentcOutput = reagentc /info
Write-Output $reagentcOutput
#Check if WinRE partition is already enabled
if([string]$reagentcOutput -notLike "*Enabled*"){
    #Search for the winre.wim in System32
    if(Test-Path "$env:HOMEDRIVE\Windows\System32\Recovery\winre.wim"){
        Write-Output "The WinRE Image is present in System32\Recovery`nFull Path: $env:HOMEDRIVE\Windows\System32\Recovery\winre.wim"
        Exit 0
    }
    #Search for WinRE partition in Recovery
    if(Test-Path "$env:HOMEDRIVE\Recovery\winre.wim"){
        Write-Output "The WinRE Image is present in $env:HomeDrive\Recovery`nFull Path: $env:HOMEDRIVE\Recovery\winre.wim"
        Exit 0
    }
    Write-Output "WinRE partition is disabled and WinRE Image not present"
    Exit 1
}
else{
Write-Output "WinRE is already enabled, and the device should wipe without issues"
    Exit 0
}


