$FinalOutput = @()
$LocalAdmins = net localgroup administrators
$results = $LocalAdmins[6..($LocalAdmins.Length-3)]
$AADmember =@()
$localmember =@()
foreach ($member in $results){
    Write-Output "Formatting $member"
    if($member -like "*\*"){
        $AADmember+=$member.Split("\")[1]
    }
    else{
        $localmember+=$member
    }
}

Write-Host "AAD members:" -ForegroundColor Cyan
foreach ($member in $AADmember){
    Write-Host $member
}
Write-Host "Local members:" -ForegroundColor Green
foreach ($member in $localmember){
    Write-Host $member
}
$OGAdmin =Get-LocalUser  | where  {$_.Description -eq "Built-in account for administering the computer/domain"}
$OGAdminName = $OGAdmin.Name
if($OgAdmin.Enabled -eq "True")
{
    Write-Output "Local Admin account is enabled"
    $FinalOutput += "Local Admin Account $OGAdminName is Enabled."
}
else
{
    Write-Output "Local Admin Account is not enabled"
    $FinalOutput += "Local Admin Account $OGAdminName is Disabled."
}
$resultsCount = $results.Count
if($resultsCount -gt 1){
    Write-Output "Total administrators is $resultsCount"
    $FinalOutput += "`nThere are $resultsCount local administrators."
}

Write-Output $FinalOutput
