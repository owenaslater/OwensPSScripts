$SID = "S-1-12-1-1327247158-1109106752-3913634993-1947446400"
$username = $null

try {
    $objUser = New-Object System.Security.Principal.SecurityIdentifier($SID)
    $username = $objUser.Translate([System.Security.Principal.NTAccount]).Value
}
catch {
    Write-Host "An error occurred while attempting to translate the SID to a username." -ForegroundColor Red
}

if ($username) {
    Write-Host "The username corresponding to the SID '$SID' is '$username'." -ForegroundColor Green
}
else {
    Write-Host "Unable to find a username corresponding to the SID '$SID'." -ForegroundColor Red
}