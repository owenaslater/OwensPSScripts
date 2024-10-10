$LocalAdmins = net localgroup administrators
$results = $LocalAdmins[6..($LocalAdmins.Length-3)]

#Present Categorized Local Admins. Local / AAD users.
Write-Output "Categorizing administrators"
foreach ($member in $results){
    Write-Output "Formatting $member"
    if($member -like "*\*"){
        $AadMembers+=@($member.Split("\")[1])
    }
    else{
        $LocalMembers+=@($member)
    }
}
Write-Output "Printing Members."
Write-Host "AAD members: $($AadMembers -join “, “).” -ForegroundColor Cyan
Write-Host "Local members: $($LocalMembers -join “, “)." -ForegroundColor Green
#Get the original local admin user
Write-Output "Fetching the built-in admin account"
$OGAdmin = Get-LocalUser  | Where-Object  {$_.Description -eq "Built-in account for administering the computer/domain"}
if($OgAdmin.Enabled -eq "True")
{
    $FinalOutput += @("Local Admin Account $($OGAdmin.name) is Enabled.")
}
else
{
    $FinalOutput += @("Local Admin Account $($OGAdmin.name) is Disabled.")
}
Write-Host "Computed built-in admin state"
if($($results.Count) -gt 1){
    $FinalOutput += @("There are $($results.Count) local administrators.")
}
else{
    Write-Host "There is only one local administrator, $($OGAdmin.name)."
}
#Final Output display for Intune Remediation results.
Write-Output "$($FinalOutput -join “ | “)”