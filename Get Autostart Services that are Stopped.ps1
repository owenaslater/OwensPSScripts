﻿Get-Service * | Where-Object {$_.StartType -eq "Automatic" } | Where-Object {$_.Status -eq "Stopped"}