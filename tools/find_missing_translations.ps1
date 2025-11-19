$base = Get-Content lib/l10n/app_en.arb -Raw | ConvertFrom-Json
$locales = @('fr','sw','rw')
foreach($loc in $locales){
  $path = "lib/l10n/app_$($loc).arb"
  if(-not (Test-Path $path)){
    Write-Host "$loc: file not found"
    continue
  }
  $obj = Get-Content $path -Raw | ConvertFrom-Json
  $baseKeys = $base.PSObject.Properties.Name | Where-Object { -not ($_.StartsWith('@')) }
  $locKeys = $obj.PSObject.Properties.Name | Where-Object { -not ($_.StartsWith('@')) }
  $missing = $baseKeys | Where-Object { $locKeys -notcontains $_ } | Sort-Object
  Write-Host "$loc: $($missing.Count) missing"
  foreach($k in $missing){ Write-Host "  - $k" }
}