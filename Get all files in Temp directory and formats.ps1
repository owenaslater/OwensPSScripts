$Set = Get-ChildItem -Path $env:TEMP -Recurse | Group-Object Extension
$TotalDirectory =$Set.group| Measure-Object -Property Length -Sum 
$Total = 0
Foreach($item in $Set){
$groupSize = $item.group | Measure-Object -Property Length -Sum -ErrorAction Ignore
$PercentOf = [math]::Round(($groupSize.Sum/$TotalDirectory.Sum)*100,4)
$Total+=$PercentOf
[pscustomobject]@{
Extension = $item.Name
Count = $item.Count
Size = $groupSize.Sum
SizePercent = "$PercentOf%"
}
}

$Total
