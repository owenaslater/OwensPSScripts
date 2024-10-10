#Joel Spink 26/02/24 - Gets names from CCM collection and adds to "CM Ring 3" AD security group. If removed from ccm collection but still in AD group, removes.

# Set SCCM Site server and site code
$SiteServer = ""
$SiteCode = ""

# Set Collection ID
$CollectionID = ""

# Set Active Directory security group name
$ADSecurityGroup = ""

# Connect to SCCM via WMI
$SCCMNamespace = "root\SMS\site_$SiteCode"
$SCCMQuery = "SELECT Name FROM SMS_FullCollectionMembership WHERE CollectionID = '$CollectionID'"
$SCCMResults = Get-WmiObject -Namespace $SCCMNamespace -Query $SCCMQuery -ComputerName $SiteServer

# Check if any results were returned
if ($SCCMResults) {
    # Create an array to store computer names from SCCM collection
    $SCCMComputers = @()

    # Iterate through each result and append trimmed hostname to the output file
    foreach ($Result in $SCCMResults) {
        $Hostname = $Result.Name.Trim() # Trim any leading or trailing spaces
        $SCCMComputers += $Hostname
    }

    Write-Host "Hostnames from SCCM collection retrieved."

    # Get current members of the Active Directory security group
    $ADGroupMembers = Get-ADGroupMember -Identity $ADSecurityGroup

    # Add computers to Active Directory security group if they are not already members
    foreach ($Computer in $SCCMComputers) {
        # Check if computer exists in Active Directory
        $ADComputer = Get-ADComputer -Identity $Computer -Properties DistinguishedName
        if ($ADComputer) {
            $ComputerDN = $ADComputer.DistinguishedName
            # Check if computer is already a member of the security group
            if ($ADGroupMembers.Name -notcontains $Computer) {
                # Add computer to the security group using its DN
                Add-ADGroupMember -Identity $ADSecurityGroup -Members $ComputerDN -ErrorAction SilentlyContinue
                Write-Host "Added $ComputerDN to $ADSecurityGroup"
            } else {
                Write-Host "$Computer is already a member of $ADSecurityGroup"
            }
        } else {
            Write-Host "Computer $Computer not found in Active Directory."
        }
    }

    # Remove computers from AD security group if they are not in SCCM collection
    foreach ($ADMember in $ADGroupMembers) {
        $ComputerName = $ADMember.Name.Trim() # Trim any leading or trailing spaces
        if ($ComputerName -notin $SCCMComputers) {
            Remove-ADGroupMember -Identity $ADSecurityGroup -Members $ADMember -Confirm:$false
            Write-Host "Removed $ComputerName from $ADSecurityGroup"
        }
    }

    Write-Host "Script execution completed."
} else {
    Write-Host "No hosts found in the SCCM collection."
}

# Get the current date and time
$CurrentDateTime = Get-Date

# Convert the current date and time to a string format
$LastSyncDateTime = $CurrentDateTime.ToString("dd-MM-yy HH:mm")

# Get the updated members of the Active Directory security group
$UpdatedADGroupMembers = Get-ADGroupMember -Identity $ADSecurityGroup

# Update the description field of the AD group with the total number of hosts and last sync date and time
$Description = "Total hosts: $($UpdatedADGroupMembers.Count), Last Sync: $LastSyncDateTime"
Set-ADGroup -Identity $ADSecurityGroup -Description $Description

Write-Host "Updated description field of $ADSecurityGroup with total number of hosts and last sync date: $LastSyncDateTime"