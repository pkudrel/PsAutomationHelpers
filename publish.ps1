Write-Host "Preparing to run build script..."

if(!$PSScriptRoot){
    $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}


$DATE = ((Get-Date).ToUniversalTime())
$DATE_TEXT = ($DATE.ToString("yyyyMMddHHmm"))
$VERSION = ($DATE.ToString("yyyyMM.ddHHmm"))
$DIFF = $DATE -  ((Get-Date -Year $DATE.Year -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0).ToUniversalTime())
$SECONDS = [math]::Round($DIFF.TotalMinutes)
$VERSION = "1.$($DATE.Year).$SECONDS"
Write-Host "Version: $VERSION "


$VERSION_FILE =  Join-Path $PSScriptRoot "VERSION"
[System.IO.File]::WriteAllText($VERSION_FILE, $VERSION)

$message = "Version: $VERSION"
&git add .
&git commit -am $VERSION -m $message
&git tag -a $VERSION -m $message
&git push origin --tags
&git push

Write-Host "Done"