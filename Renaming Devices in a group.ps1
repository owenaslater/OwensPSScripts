Try{
    Import-Module -Name MSAL.PS
    
}
Catch{
   Install-Module -Name MSAL.PS -Force 
   Import-Module -Name MSAL.PS
}
#
$authparams = @{
    ClientId    = ''
    TenantId    = ''
    ClientSecret = ('' | ConvertTo-SecureString -AsPlainText -Force )
}
#Creates access token
$auth = Get-MsalToken @authParams
#Alternatively use $auth = Connect-AzAD_Token to use user login creds
$AccessToken = $Auth.AccessToken

Function Invoke-MsGraphCall {

    [cmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$AccessToken,
        [Parameter(Mandatory=$True)]
        [string]$URI,
        [Parameter(Mandatory=$True)]
        [string]$Method,
        [Parameter(Mandatory=$False)]
        [string]$Body
    )

    #Create Splat hashtable
    $graphSplatParams = @{
        Headers     = @{
            "Content-Type"  = "application/json"
            "Authorization" = "Bearer $($AccessToken)"
        }
        Method = $Method
        URI = $URI
        ErrorAction = "SilentlyContinue"
       # StatusCodeVariable = "scv"
    }

    #If method requires body, add body to splat
    If($Method -in ('PUT','PATCH','POST')){

        $graphSplatParams["Body"] = $Body

    }

    #Return API call result to script
    $MSGraphResult = Invoke-RestMethod @graphSplatParams

    #Return status code variable to script
    Return $SCV, $MSGraphResult

}
#Defines the URI to get the members of the group
$GroupID = ""
$URI = "https://graph.microsoft.com/v1.0/groups/$GroupID/members"
$Method = "GET"

#Call Invoke-MsGraphCall
$MSGraphCall = Invoke-MsGraphCall -AccessToken $AccessToken -URI $URI -Method $Method -Body $Body

#Gets the AAD Object ID from the devices in the group
#$MSGraphCall |Get-Member
$Devices = $MSGraphCall.value
$AADObjectID = $Devices.deviceID
#Previous call only does the top 100, so this will add the rest
while($MSGraphCall."@odata.nextLink"){
    $MSGraphCall = Invoke-MsGraphCall -AccessToken $AccessToken -URI $MSGraphCall."@odata.nextLink" -Method $Method -Body $Body
    $Devices=$MSGraphCall.value
    $AADObjectID+= $Devices.deviceID
}


#Gets all the Intune device objects
$ManagedDevicesRoot = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices"
$MSGraphCall2 = Invoke-MSGraphCall -AccessToken $AccessToken -URI "$ManagedDevicesRoot" -Method $Method -Body $Body
$ManagedDevices = $MSGraphCall2.value
while ($MSGraphCall2."@odata.nextLink"){
    $MSGraphCall2 = Invoke-MsGraphCall -AccessToken $AccessToken -URI $MSGraphCall2."@odata.nextLink" -Method $Method -Body $Body
    $ManagedDevices+=$MSGraphCall2.value
}

#Filters the devices to get only the ones in the group and adds their Intune IDs
$FilteredDevices = @()
foreach($device in $ManagedDevices){
$aadID = $device.azureADDeviceID
if($AADObjectID -like "*$aadID*"){
 $FilteredDevices+=$device.id
}
}

#sets up the array to keep a tally of device numbers per site
$counterArray = @(1) * 136
#Imports the CSV file
#Path to CSV file with IP > Site definitions.Column titles:| SiteName | IPAddress |
$csvFilePath = ""
$csvData = Import-CSV $csvFilePath

foreach($device in $FilteredDevices){
    #grabs the device ip addresses
    $ManagedDevicesRoot = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$device"
    $query = "?`$select=hardwareInformation"
    $HardwareGraphCall = Invoke-MSGraphCall -AccessToken $AccessToken -URI "$ManagedDevicesRoot$query" -Method $Method -Body $Body
    $hardwareInfo = $HardwareGraphCall.hardwareInformation
    $deviceIP = $hardWareInfo.ipAddressV4

    if($deviceIP){
        #splits the ip Address into 4 parts for comparison with the IPs in the csv file
        $deviceOctets = $deviceIP.Split(".")
        foreach($row in $csvData){
            #splits CSV row IP address into 4 parts for comparison purposes
            $csvOctets = $row.CorpSubnet.Split(".")
            if(
                ([int]$csvOctets[0] -eq [int]$deviceOctets[0] -and
                [int]$csvOctets[1] -eq [int]$deviceOctets[1] -and
                [int]$csvOctets[2] -eq [int]$deviceOctets[2])){
                    $rowNumber = [array]::IndexOf($csvData, $row)
                    [string]$sitename =$row.SiteName
                    #removes spaces in the SiteName
                    $namept1 = $sitename -replace $string -replace '\s', ''
                    $namept2 ="_EPOS_"
                    $namept3 = $counterArray[$rowNumber]
                    #adds to the counter element for the specific site
                    $counterArray[$rowNumber]+=1
                    $NewManagementName = "$namept1$namept2$namept3"
                    $URI = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$device"
                    $Body = @{ "managedDeviceName" = "$NewManagementName" } | ConvertTo-Json  
                    $SendMethod = "PATCH"
                    Write-Output "Device $device with ip $deviceIP name is changing to $NewManagementName"
                    $MSGraphCall = Invoke-MsGraphCall -AccessToken $AccessToken -URI $URI -Method $SendMethod -Body $Body
                    break
                    
            }
        }
    }

}
