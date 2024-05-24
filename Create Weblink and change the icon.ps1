$targetURL = ""
# Define the path to the file whose icon you want to change
$filePath = ""
$wshshell = New-Object -ComObject WScript.Shell
$lnk = $wshshell.CreateShortcut($env:PUBLIC + "\Desktop\Shop OneDrive.lnk")
$shortcutFile = "%SystemRoot%\System32\SHELL32.dll"
$lnk.WorkingDirectory = "C:\Program Files (x86)\Microsoft\Edge\Application"
$lnk.TargetPath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$lnk.Arguments = "-inprivate $targetURL"
$lnk.Save()



# Define the path to the .ico file that contains the new icon
$newIconPath = "C:\WINDOWS\system32\imageres.dll"

# Set the new icon for the file using the Registry
$iconRegistryPath = "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\TrayNotify"
$iconRegistryName = "IconStreams"
$iconRegistry = Get-ItemProperty -Path $iconRegistryPath
$iconRegistry.IconStreams = [byte[]] (Get-Content $newIconPath -Encoding Byte)
Set-ItemProperty -Path $iconRegistryPath -Name $iconRegistryName -Value $iconRegistry.IconStreams

# Refresh the Windows Explorer to apply the changes
Stop-Process -Name explorer -Force
