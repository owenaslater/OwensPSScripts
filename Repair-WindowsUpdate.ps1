#Get services
$global:OriginalServiceStates = Get-Service -DisplayName "Windows Update", "Cryptographic Services", "Background Intelligent Transfer Service", "Windows Installer" | Select-Object -Property Name, Status
Write-Output $global:OriginalServiceStates
#Stop services
foreach($service in $global:OriginalServiceStates){
    if($service.status -ine "Stopped"){
        Stop-Service $service.name -Force
    }
}

Write-Output " "
$PostStopStatus = Get-Service -DisplayName "Windows Update", "Cryptographic Services", "Background Intelligent Transfer Service", "Windows Installer" | Select-Object -Property Name, Status
Write-Output $PostStopStatus
Write-Output " "

#Remove old Windows update folders
if(Test-Path C:\Windows\SoftwareDistribution.old){
    Remove-Item C:\Windows\SoftwareDistribution.old -Recurse -Force
    Write-Output "Removed old SoftwareDistribution file"
}
if(Test-Path C:\Windows\Catroot2.old){
    Remove-Item C:\Windows\Catroot2.old -Recurse - Force
    Write-Output "Removed old Catroot2 file"
}

#Rename Windows update folders
if(Test-Path C:\Windows\SoftwareDistribution) {
    Rename-Item C:\Windows\SoftwareDistribution SoftwareDistribution.old
    Write-Output "Renamed SoftwareDistribution file"
}
if(Test-Path C:\Windows\Catroot2) {
    Rename-Item C:\Windows\System32\catroot2 Catroot2.old
    Write-Output "Renamed Catroot2 file"
}

$CurrentServiceState = Get-Service -DisplayName "Windows Update", "Cryptographic Services", "Background Intelligent Transfer Service", "Windows Installer" | Select-Object -Property Name, Status
$PreScriptStatus = $global:OriginalServiceStates
#Restart stopped services

foreach($service in $CurrentServiceState){
        $PreServiceStatus = $PreScriptStatus| Where-Object { $_.Name -ieq $Service.name }
        if ($PreServiceStatus.Status -ne $Service.Status) {
            if($service.Status -eq "Stopped") {
                Start-Service -Name $($PreServiceStatus.name) -ErrorAction Stop
                }
                else {
                Set-Service -Name $($PreServiceStatus.name) -Status $($PreServiceStatus.status) -ErrorAction Stop
                } 
        }
}

$FinalServiceStatus = Get-Service -DisplayName "Windows Update", "Cryptographic Services", "Background Intelligent Transfer Service", "Windows Installer" | Select-Object -Property Name, Status
Write-Output "Final Service Status:"
Write-Output $FinalServiceStatus