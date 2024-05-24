$RegKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
$RegValue = "AllowTelemetry_PolicyManager"

#If Key exists
if(Test-Path -Path "$RegKey"){
    $Telemetry = Get-Item -Path $RegKey | where Property -eq "AllowTelemetry_PolicyManager"
    #If Value exists
    if(-not[string]::IsNullOrEmpty($Telemetry)){
        $AllowTelemetryValue = (Get-ItemProperty -Path $RegKey -Name $RegValue).AllowTelemetry_PolicyManager
        #If Value data is correct
        if($AllowTelemetryValue -eq "3"){
            "Full Telemetry is allowed"
        }
        #If Value data is incorrect
        else{
            "Telemetry is not set correctly, altering to correct value"
            Set-ItemProperty -Path $RegKey -Name $RegValue -Value 3
        }
    }
    #If Value doesn't exist
    else{
    New-ItemProperty -Path $RegKey -Name $RegValue -Value 3 -PropertyType DWord -Force
    }
}


