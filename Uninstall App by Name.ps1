$productCode = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE (Name LIKE 'Master Packager%')" | Select-Object -ExpandProperty IdentifyingNumber
 
# Uninstall McAfee 16.0 R52
 
if ($productCode) {
    $uninstallString = "/x" + $productCode + " /qn REBOOT=R"
    Start-Process -FilePath "msiexec.exe" -ArgumentList $uninstallString -Wait
    Write-Output "McAfee 16.0 R52 has been uninstalled."
} else {
    Write-Output "McAfee 16.0 R52 is not found on this system."
}