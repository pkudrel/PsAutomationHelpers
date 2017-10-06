#requires -Version 3.0
<#
.Synopsis
	Build luncher for (https://github.com/nightroman/Invoke-Build)
	This script create spacial variable $BL
#>


param(
	$File = (Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) ".build.ps1"),
	$buildCounter = 0,
	$psGitVersionStrategy = "standard"
)

Write-Output "Invoke-Build script file: $File"

# 
$BL = @{}
$BL.RepoRoot = (Resolve-Path ( & git rev-parse --show-toplevel))
$BL.BuildDateTime = ((Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"))
$BL.ScriptsPath = (Split-Path $MyInvocation.MyCommand.Path -Parent)
$BL.BuildOutPath = (Join-Path $BL.RepoRoot ".build" )
$BL.BuildScriptPath = $File
$BL.PsAutoHelpers = (Join-Path $BL.ScriptsPath "vendor\ps-auto-helpers") 
$BL.ib = (Join-Path $BL.ScriptsPath "vendor\ps-auto-helpers\tools\ib\Invoke-Build.ps1")
$BL.ibVersionFile = (Join-Path $BL.ScriptsPath "vendor\ps-auto-helpers\tools\ib-version.txt")

# import tools
. (Join-Path $BL.PsAutoHelpers "ps\psgitversion.ps1")
. (Join-Path $BL.PsAutoHelpers "ps\ib-update-tools.ps1")

# check Invoke-Build version
IbUpdateIsNeeded $BL.ibVersionFile

$BL.BuildVersion = Get-GitVersion $psGitVersionStrategy 1 0 0 $buildCounter
$buildMiscInfo = $BL.BuildVersion.AssemblyInformationalVersion
Write-Output "Special $buildMiscInfo"
Write-Output "Special `$BL values"
$BL.GetEnumerator()| Sort-Object -Property name | Format-Table Name, Value -AutoSize

try {
# Invoke the build and keep results in the variable Result
& $BL.ib -File $BL.BuildScriptsPath -Result Result  @args
}
catch {
Write $Result.Error
Write $_
exit 1 # Failure
}

$Result.Tasks | Format-Table Elapsed, Name -AutoSize
exit 0
