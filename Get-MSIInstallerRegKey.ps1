#The script aims to find out if the registry key is set to anything other than 0. If it doesn't exist, or if it's set to 0 then there is no issue.
function Get-MSIInstallerRegKey{
    try{
    #Tries to find the registry key value for allowing MSI installations
        $keyPath = 'HKLM:\Software\Policies\Microsoft\Windows\Installer'
        $valueName = 'DisableMSI'
        $value = (Get-ItemProperty -Path $keyPath -Name $valueName -ErrorAction Stop).$valueName 

    #If the value is not 0, MSI activity may be blocked
        if(0 -ne $value){
            Write-Output "Value found, but it is set to $value"
            Exit 1
        }
        Write-Output "Value is 0 as expected"
        Exit 0
    }

    #If there was an error getting the registry key value then report the error
    catch{
        Write-Output "An error occured"
        Write-Output "$_"
        Exit 0
    }
}
Get-MSIInstallerRegKey
