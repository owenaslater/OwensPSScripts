
Get-PSDrive
#shortcuts
gci -Path Alias:

#Display encryption status of folder contents
cd "<folder>"
gci | ? {$_.Attributes -le "Encrypted"}
cipher

#alias showcase
gsv | ? Status -eq Stopped | select Name,DisplayName
Get-Service | Where-Object -Property Status -eq -Value Stopped | Select-Object -Property Name,DisplayName

#gets all functions
Get-ChildItem -Path function: | Get-Member

#List all loaded functions, displaying the name, number of parameter sets, total number of lines in function
$Functions = Get-ChildItem -Path function: | Select-Object Name, @{Name = "ParameterSetCount"; Expression = { $_.parametersets.count }}, @{Name = "Lines"; Expression = { ($_.Scriptblock | Measure-Object -Character).characters } }

gsv | ? Status -eq Running | select Name, @{Name = "MachineNameLength"; Expression = {($_.DisplayName | Measure-Object -Character -Line).characters}}, @{Name = "Poop"; Expression = {1+2}}

gsv | ? Status -eq Running | select Name, DisplayName

#new variable with multiple values

$Stoopid = @{
Duffer = "yabadoo"
Ningnoo = "zingyzong"
Dorr = "10"
}

Write-Output $Stoopid

#function with returning output

function Make-Item{
param($name,$description,$value)
$tempentry = New-Object -TypeName PSObject
$tempentry | Add-Member -MemberType NoteProperty -Name "Name" -Value $name -Force
$tempentry | Add-Member -MemberType NoteProperty -Name "Description" -Value $description -Force
if($value -ge 100){

}
$tempentry | Add-Member -MemberType NoteProperty -Name "Value" -Value $value -Force
return $tempentry
}
$FruitArray = @()
$FruitArray += Make-Item -name "Strawberry" -description "A red fruit" -value 30
$FruitArray += Make-Item -name "Pear" -description "a green fruit" -value 60
$FruitArray += Make-Item "apple" -description "a red or green fruit" -value 100
$FruitArray += Make-Item "banana" "a long yellow fruit" "150"

#Get active connections and resolve DNS names by cache (without cach it takes ages as it's probably querying it with the DNS)

$Connections = Get-NetTCPConnection | select RemoteAddress -Unique
$Connections.Count

foreach($ip in $Connections){
if($ip.RemoteAddress.length -ge 5){
$value = Resolve-DNSName $ip.RemoteAddress -CacheOnly -ErrorAction Ignore 
Write-Output $value
}
}


#open web page
start 'https:\\youtube.com\'
start 'https://www.youtube.com/watch?v=uwoD5YsGACg&t'


#switches
$number = 2
switch ($number){
1{"wun"}
2{"tuw"}
3{"frea"}
4{"fowa"}

}

switch(4){
4{"Here"}
4{"I"}
4{"Am";Break}
4{"Rock me like a hurricane"}
}

$script:scriptvar = 20
$variables = Get-Variable -Scope global
$variables.count

#enable Hyper-V
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
#for nested virtualization
#Set-VMProcessor -VMName <VMName> -ExposeVirtualizationExtensions $true

