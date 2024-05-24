# Define the registry path and value
$RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
$RegistryName = "DisableAntiSpyware"
$ExpectedValue = 0

# Check if the registry path exists
if (-not (Test-Path $RegistryPath)) {
    Write-Output "Registry path doesn't exist"
    exit 1
}


# Get the current registry value
$ActualValue = Get-ItemProperty -Path "$RegistryPath" | Select-Object -ExpandProperty $RegistryName

# Check if the registry value is not equal to the expected value
if ($ActualValue -ne $ExpectedValue) {
    Write-Error "Registry key value not 1"
    exit 1
}

# If all checks pass, exit with code 0 (success)
Write-Output "Registry key value is correct"
exit 0