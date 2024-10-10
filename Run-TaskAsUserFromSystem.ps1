$taskName = "Run-Cisco"

#Trigger for when the task should run. At logon is needed for items run in user context vs at startup.
$trigger = New-ScheduledTaskTrigger -AtLogOn

#Which exe and arguments to launch.
$action= New-ScheduledTaskAction -Execute "C:\Program Files (x86)\Cisco\Cisco Secure Client\UI\csc_ui.exe"

#Create the task as an object so we can add the principal group to it.
$Newtask = New-ScheduledTask -Action $Action -Trigger $trigger

#Runs for the local users group. That is any user who logs on, in that user's context.
$principal = New-ScheduledTaskPrincipal -GroupId "Users" -RunLevel Limited
$newTask.Principal = $principal

#Register the scheduled task with Task Scheduler
$newTask | Register-ScheduledTask -TaskName $taskName

#Run the Scheduled Task
Start-ScheduledTask -TaskName $taskName

#Pause to allow the Scheduled Task to run
Start-Sleep -Seconds 10

#Delete the Scheduled Task
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false