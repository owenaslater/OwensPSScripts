Try{
    Import-Module -Name MSAL.PS
    
}
Catch{
   Install-Module -Name MSAL.PS -Force 
   Import-Module -Name MSAL.PS
}
#Get these auth params from:
#TenantID > Azure Active Directory > Overview
#ClientID > App Resource > whichever is the graph api access resource > Overview
#You will have to get the client secret from LastPass, as the value is not visible in Azure

$authparams = @{
    ClientId    = '<INSERT CLIENTID>'
    TenantId    = '<INSERT TENANTID>'
    ClientSecret = ('<INSERT CLIENTSECRET' | ConvertTo-SecureString -AsPlainText -Force )
}
#Creates access token
$auth = Get-MsalToken @authParams
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
#get the group ID from the overview of the Group
$GroupID = "<INSERT GROUP ID>"
$URI = "https://graph.microsoft.com/v1.0/groups/$GroupID/members"
$Method = "GET"

#Call Invoke-MsGraphCall
$MSGraphCall = Invoke-MsGraphCall -AccessToken $AccessToken -URI $URI -Method $Method -Body $Body

#Gets the AAD Object ID from the devices in the group
$Devices = $MSGraphCall.value
$AADObjectID = $Devices.deviceID


#Gets all the Intune device objects
$ManagedDevicesRoot = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices"
$MSGraphCall2 = Invoke-MSGraphCall -AccessToken $AccessToken -URI "$ManagedDevicesRoot" -Method $Method -Body $Body
$ManagedDevices = $MSGraphCall2.value

#Filters the devices to get only the ones in the group and adds their Intune IDs
$FilteredDevices = @()
foreach($device in $ManagedDevices){
$aadID = $device.azureADDeviceID
if($AADObjectID -like "*$aadID*"){
 $FilteredDevices+=$device
}
}
