manage-bde -off C:
Write-Output "Waiting 2 minutes while BitLocker decrypts"
Start-Sleep -Seconds 180
while((Get-BitLockerVolume C:).ProtectionStatus -ne "Off"){
    Write-Output "Waiting another minute for BitLocker to decrypt"
    Write-Output (Get-BitLockerVolume C:).EncryptionPercentage
    Start-Sleep -Seconds 60
}
Write-Output "BitLocker has been disabled, enabling recovery partition"
$reagentOutput = reagentc /enable
Start-Sleep -Seconds 30
manage-bde -on C:
if($reagentOutput -like "*Success*"){
    Write-Output "The Recovery Partition has been enabled"
    Exit 0
}
else{
    Write-Output "The Recovery Partition has been not been enabled"
    Exit 1
}
