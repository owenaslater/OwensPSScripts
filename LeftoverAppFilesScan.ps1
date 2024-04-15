$appName = ""
$scanDirectories = @("Program Files","Program Files (x86)", "users\*\AppData", "ProgramData")

foreach($directory in $scanDirectories){
Write-Host "Scanning $directory" -ForegroundColor Yellow
Get-ChildItem -Directory -Path "$env:HomeDrive\$directory" -Recurse | where {$_.Name -like "*$appName*"} | Select-Object -expandProperty FullName | Write-Host -ForegroundColor Cyan
}

$userRegistryDirectories = Get-ChildItem -Path Registry::HKEY_USERS | where {([string]$_.Name.Length -gt 20) -and ([string]$_.Name -notlike "*_Classes")}
 
$RegistryKeys = @($userRegistryDirectories.Name, "HKEY_LOCAL_MACHINE")
$RegistryAppPaths = @("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall","SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall")
foreach($directory in $RegistryKeys){
    $currentDirectory=$directory
    foreach($path in $RegistryAppPaths){
        Write-Host "Scanning Registry $directory\$path" -ForegroundColor Yellow
        try {
            $value = Get-ChildItem -Path "Registry::$currentdirectory\$path" -ErrorAction Ignore | Get-ItemProperty | where {$_.DisplayName -like "*$appName*"}
            if(-not[string]::IsNullOrEmpty($value)){
                foreach($app in $value){
                    $valueName = $app.DisplayName
                    $valuePath = $app.PSChildName
                    Write-Output "$valueName in key $valuePath" -ForegroundColor Cyan
                }
            }
        } catch {
            Write-Host "$_" -ForegroundColor Red
        }
    }
}