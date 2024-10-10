# Remediation script to log folder redirection paths
 
# Function to get the redirected path of a special folder
function Get-RedirectedPath {
    param (
        [string]$FolderName
    )
    try {
        $shell = New-Object -ComObject WScript.Shell
        $path = $shell.SpecialFolders.Item($FolderName)
        return $path
    } catch {
        Write-Error "Failed to get redirected path for ${FolderName}: $_"
        return $null
    }
}
 
# Get the paths for Documents and Desktop
$documentsPath = Get-RedirectedPath "MyDocuments"
$desktopPath = Get-RedirectedPath "Desktop"
 
# Log the results
Write-Output "User: $env:USERNAME", "DocumentsPath: $documentsPath", "DesktopPath: $desktopPath"