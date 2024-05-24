Get-Process | Where-Object {$_.Path -like "*Word*"} | Stop-Process -Force -ErrorAction Ignore
Get-Process | Where-Object {$_.Path -like "*POWERPNT*"} | Stop-Process -Force -ErrorAction Ignore
Get-Process | Where-Object {$_.Path -like "*Excel*"} | Stop-Process -Force -ErrorAction Ignore
Get-Process | Where-Object {$_.Path -like "*Publisher*"} | Stop-Process -Force -ErrorAction Ignore
Get-Process | Where-Object {$_.Path -like "*Outlook*"} | Stop-Process -Force -ErrorAction Ignore
Get-Process | Where-Object {$_.Path -like "*ONENOTE*"} | Stop-Process -Force -ErrorAction Ignore
Start-Process "C:\Program Files\Common Files\Microsoft Shared\ClickToRun\OfficeClickToRun.exe" -ArgumentList "scenario=install scenariosubtype=ARP sourcetype=None productstoremove=O365ProPlusRetail.16_en-us_x-none culture=en-us version.16=16.0 DisplayLevel=False" -Wait