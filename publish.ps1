Write-Host "Preparing to run build script..."

if(!$PSScriptRoot){
    $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}


$DATE = ((Get-Date).ToUniversalTime())
$DATE_TEXT = ($DATE.ToString("yyyy-MM-ddTHH:mm:ssZ"))
$VERSION = ($DATE.ToString("yyyyMM.ddHHmm"))
$DIFF = $DATE -  ((Get-Date -Year $DATE.Year -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0).ToUniversalTime())
$SECONDS = [math]::Round($DIFF.TotalMinutes)
$VERSION = "1.$($DATE.Year).$SECONDS"

$DATA = [PSCustomObject]  @{ "Date" = $DATE_TEXT ; "SemVer" = "$semVer"}

Write-Host "Version: $VERSION "
$VERSION_FILE =  Join-Path $PSScriptRoot "version.json"
[System.IO.File]::WriteAllText($VERSION_FILE, $DATA)

$message = "Version: $VERSION"
&git add .
&git commit -am $VERSION -m $message
&git tag -a $VERSION -m $message
&git push origin --tags
&git push

Write-Host "Done"