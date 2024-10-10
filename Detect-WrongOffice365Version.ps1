if(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\O365ProPlusRetail - en-us"){
    Write-Output "Intune version of Microsoft 365 Apps Detected. Running removal script."
    Exit 1
}
Write-Output "Intune version of Microsoft 365 Apps not found. Nothing to remediate."
Exit 0