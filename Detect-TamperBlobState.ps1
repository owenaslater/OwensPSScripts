#Checks for Tamper Blob protection
try{
    $TamperProtection = Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features" -Name "TPExclusions" -ErrorAction Stop
    if($TamperProtection.TPExclusions -ieq "1"){
        Write-Host "TPExclusions found and set correctly"
        Exit 0
    }
    else{
        Write-Host "TPExclusions found but incorrect"
        Exit 1
    }
}
catch{
    Write-Host "TPExclusions not found"
    Exit 1
}
