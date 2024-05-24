$RegKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
$RegValue = "AllowTelemetry_PolicyManager"
try{
    if(((Get-ItemProperty -Path $RegKey -Name $RegValue).AllowTelemetry_PolicyManager) -ieq 3){
        Exit 0
    }
    Write-Error "Value data is not correct"
    Exit 1

}catch{
Write-Error $_
Exit 1
}