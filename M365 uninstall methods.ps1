$app = Get-WmiObject -Class Win32_Product | Where-Object {
  $_.Name -match "Software Name"
}
$app.Uninstall()
Get-AppxPackage -name “Microsoft.Office.Desktop” | Remove-AppxPackage
winget uninstall "Microsoft 365 Apps for enterprise - en-us"

#discovery
winget show "Microsoft.Office"
Get-AppxPackage | where {$_.Name -like "*Microsoft.Office*"}
Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "*Office*"}
winget list