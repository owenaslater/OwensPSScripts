Get-WmiObject Win32_BIOS | Get-Member | Where-Object -Property MemberType -eq -Value Property | Select-Object -Property Name
 