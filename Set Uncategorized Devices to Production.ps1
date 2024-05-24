[CmdletBinding()]
param (

    [Parameter(DontShow = $true)]
    [string]$MsGraphVersion = "beta",
    [Parameter(DontShow = $true)]
    [string]$MsGraphHost = "graph.microsoft.com",
    $GraphURI = "https://$MSGraphHost/$MsGraphVersion"
)

$AccessToken = Connect-AzAD_Token

$Graph_Headers =  @{Authorization = "Bearer $($AccessToken.AccessToken)"} #Create the Graph Authentication header

$d_CategorySplat = @{
    Method = "GET"
    URI = "$GraphURI/deviceManagement/deviceCategories"
    Headers = $Graph_Headers
    ContentType = "Application/JSON"
} # Create the Category Splat for the Post Rest Call

$d_Categories = Invoke-RestMethod @d_CategorySplat -ErrorAction Stop #Call for the information.

$d_IntuneSplat = @{
        Method = "GET"
        URI = "$GraphURI/devicemanagement/managedDevices?`$Filter=operatingSystem eq 'Windows' and ownerType eq 'Company'"
        Headers = $Graph_Headers
        ContentType = "Application/JSON"
    }
    $d_IntuneGraphResult = Invoke-RestMethod @d_IntuneSplat -ErrorAction Stop #Gets all Windows Company Devices
    $d_IntuneDevices = @()
    $d_IntuneDevices += $d_IntuneGraphResult.value #Adds the first set of results from the above call
    $Count = 1
    while(-not ([string]::IsNullOrEmpty($d_IntuneGraphResult.'@odata.nextLink'))) {
        Write-Output "Querying Azure AD Devices @odata.next link NO: $($Count)..."
        $d_IntuneGraphResult_NextLink = @{
            Method = "GET"
            URI = $d_IntuneGraphResult.'@odata.nextLink'
            Headers = $Graph_Headers
            ContentType = "application/JSON"
        }
        $d_IntuneGraphResult = Invoke-RestMethod @d_IntuneGraphResult_NextLink -ErrorAction Stop
        $d_IntuneDevices += $d_IntuneGraphResult.value #adds all concurrent devices to the list
        $Count++
    }

FOREACH ($Device in $d_IntuneDevices) {
        if (([String]::IsNullOrEmpty($Device.deviceCategoryDisplayName)) -or ($Device.deviceCategoryDisplayName -Match "Unknown")){#if device category is null or unknown
            "Updating $($Device.deviceName) from $(
                if([String]::IsNullOrEmpty($Device.deviceCategoryDisplayName)){
                    "null"
                } else {
                    $Device.deviceCategoryDisplayName
                }
            ) category to $deviceCategory"
            #Changing from current category to Production
            $UpdateCategorySplat = @{
                Method = "PUT"
                URI =  "$GraphURI/deviceManagement/managedDevices/$($Device.ID)/deviceCategory/`$ref"
                Headers = $Graph_Headers
                ContentType = "application/JSON"
                Body = @{ "@odata.id" = "https://graph.microsoft.com/beta/deviceManagement/deviceCategories/$d_CategoryID"} | ConvertTo-Json
            }
			
            Invoke-RestMethod @UpdateCategorySplat -ErrorAction Stop | Out-Null
        } 
        #Uncomment the below line to see all devices and categories 
        <#Else {
            "$($Device.deviceName) Has Category $($Device.deviceCategoryDisplayName)"

        }#>
    }
}