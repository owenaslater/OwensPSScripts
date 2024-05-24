<# User based settings for Windows 11 Task bar #>

#first check we are on Windows 11

if ((Get-ComputerInfo | Select-Object -expand OsName) -Match 11) {
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        
    ####
    #Move the Windows 11 Taskbar to left
    $StartButtonLocationName = "TaskbarAl" 
    $StartMenuLeft = "0"
    #Shift Start Menu Left
    New-ItemProperty -Path $registryPath -Name $StartButtonLocationName -Value $StartMenuLeft -PropertyType DWORD -Force -ErrorAction Ignore

    ####
    #HideTaskView
    $TaskViewButtonName = "ShowTaskViewButton"
    $HideTaskViewButton = 0

    New-ItemProperty -Path $registryPath -Name $TaskViewButtonName -Value $HideTaskViewButton -PropertyType DWORD -Force -ErrorAction Ignore

    #Hide Copilot Button
    $CopilotButtonName = "ShowCopilotButton"
    $HideCopilotButton = 0

    New-ItemProperty -Path $registryPath -Name $CopilotButtonName -Value $HideCopilotButton -PropertyType DWORD -Force -ErrorAction Ignore

    #Enable More Pins Layout
    $StartMenuLayoutName = "Start_Layout"
    #$PinsDefaultLayout = "0"
    $MorePinsLayout = "1"
    #$MoreRecommendationsLayout = "2"

    New-ItemProperty -Path $registryPath -Name $StartMenuLayoutName-Value $MorePinsLayout -PropertyType DWORD -Force -ErrorAction Ignore
  

}