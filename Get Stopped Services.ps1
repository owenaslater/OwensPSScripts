$StoppedServices = Get-Service * | Where-Object -Property Status -eq "Stopped"
$StoppedServices.Count 