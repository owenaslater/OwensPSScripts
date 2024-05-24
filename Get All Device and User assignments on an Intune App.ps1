$appName = ''

$authparams = @{
    ClientId    = ''
    TenantId    = ''
    ClientSecret = ('' | ConvertTo-SecureString -AsPlainText -Force )
}
#Creates access token
$auth = Get-MsalToken @authParams
#Alternatively use Connect-AZToken (I probably got that name wrong) to connect with user creds
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

#Gets the ID of the app by the name
$URI = "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps?`$filter=displayName eq `'$appName`'"
$Method = "GET"
$MSGraphCall = Invoke-MsGraphCall -AccessToken $AccessToken -URI $URI -Method $Method -Body $Body
$Application = $MSGraphCall.value
$ApplicationID = $Application.id

$URI = "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps/$ApplicationID/assignments"
$MSGraphCall = Invoke-MsGraphCall -AccessToken $AccessToken -URI $URI -Method $Method -Body $Body
$AssignedGroups = $MSGraphCall.value

$Required = @()
$Available =@()
#Issue: Groups appended to the $AssignedGroups variable don't run through this process
#fix: change into a while loop that counts length of $AssignedGroups until it's run through them all
$counter = 0
while($counter -lt $AssignedGroups.Count ){
    $group = $AssignedGroups[$counter]
    $counter++
#foreach($group in $AssignedGroups){
    Write-Output "doing $group now"
    if(($group.target).'@odata.type' -like "*AllLicensedUsersAssignmentTarget"){
         $URI = "https://graph.microsoft.com/v1.0/users"
         $AllUsers = (Invoke-MsGraphCall -AccessToken $AccessToken -URI $URI -Method $Method -Body $Body).value
         foreach($user in $AllUsers){
             $result = New-Object -TypeName PSObject -Property @{
                        ID = $user.ID
                        Name = $user.displayName
                        Type = "User"
                    }
             $Available+=$result
         }
    }
    else{
        $GroupID = ($group.id).Substring(0, ($group.id).Length - 4)
        $URI = "https://graph.microsoft.com/v1.0/groups/$GroupID/members"
        $MSGraphCall = Invoke-MsGraphCall -AccessToken $AccessToken -URI $URI -Method $Method -Body $Body
        #I think this can be trimmed by splitting the @odata.type and taking the last value i.e $value[2]
        foreach($entry in $MsGraphCall.value){
            if($entry."@odata.type" -eq "#microsoft.graph.user"){
                    $result = New-Object -TypeName PSObject -Property @{
                    ID = $entry.ID
                    Name = $entry.displayName
                    Type = "User"
                }
            }
            elseif($entry."@odata.type" -eq "#microsoft.graph.device"){
                 $result = New-Object -TypeName PSObject -Property @{
                    ID = $entry.ID
                    Name = $entry.displayName
                    Type = "Device"
                }
            }
            elseif($entry."@odata.type" -eq "#microsoft.graph.group"){
                $result = New-Object -TypeName PSObject -Property @{
                    ID = $entry.ID+"_0_0"
                    Intent = $group.intent
                }
                $AssignedGroups+=$result
                continue
            }
            if($group.intent -eq "available"){
                $Available+=$result
            }
            else{
                $Required+=$result
            }
        }
    }
}

#Writes the assignments to the console
Write-Output "`nRequired Assignments`n"
Write-Output $Required | Sort-Object Type | Format-Table -GroupBy Type 
Write-Output "`nAvailable Assignments"
Write-Output $Available | Sort-Object Type |Format-Table -GroupBy Type

