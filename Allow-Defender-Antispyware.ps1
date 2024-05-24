# Define the registry path and value
$RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
$RegistryName = "DisableAntiSpyware"
$RegistryValue = 0

# Check if the registry key exists; if not, create it
if (-not (Test-Path $RegistryPath)) {
    New-Item -Path $RegistryPath -Force
}

# Set the registry value
Set-ItemProperty -Path $RegistryPath -Name $RegistryName -Value $RegistryValue
