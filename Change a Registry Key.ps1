## *REGISTRY SETTING NAME* Variables ##
$ErrorActionPreference = "SilentlyContinue"
$RegSettings = "HKLM:\"
$ValueName = "Example"
$ValueData = "0"
$OverridePath = Get-ItemPropertyValue -Path $RegSettings -name $ValueName -ErrorAction SilentlyContinue
$OverridePath2 = Get-ItemProperty -Path $RegSettings -ErrorAction SilentlyContinue | Get-ItemProperty -name $ValueName -ErrorAction SilentlyContinue

## *REGISTRY SETTING NAME* Override ##
if (!($OverridePath2)){
    New-ItemProperty -path $RegSettings -Name $ValueName -Value $ValueData -force -PropertyType DWORD
    Write-Host "Creating *REGISTRY SETTING NAME* Registry Entry"
    Break
}

if ($OverridePath -eq $ValueData){
    Write-Host "Path and setting already exist"
    Break
}

if ($OverridePath -ne $ValueData){
    Set-Itemproperty -path $RegSettings -Name $ValueName -Value $ValueData 
    Write-Host "Setting *REGISTRY SETTING NAME* Registry Entry"
    Break
}