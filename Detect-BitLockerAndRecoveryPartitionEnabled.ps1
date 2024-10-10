try{
    $ReagentcOutput = reagentc /info
    if($ReagentcOutput -like "*Disabled*"){
        Write-Output "Recovery Partition is not enabled. Running Remediation"
        Exit 1
    }
    if([string]::IsNullOrEmpty($ReagentcOutput)){
        Write-Output "One or more variables were empty/null. Running Remediation."
        Exit 1
    }
} 
Catch {
    Write-Output "An error occurred: $_"
    Exit 1
}
Exit 0
