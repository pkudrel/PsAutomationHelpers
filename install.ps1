<#

.SYNOPSIS
This is a Powershell script to bootstrap development environment


.PARAMETER ScriptArgs
Remaining arguments are added here.

.LINK
https://github.com/pkudrel/PsAutomationHelpers

#>

[CmdletBinding()]
Param(
    [string[]]$ScriptArgs
)

[Reflection.Assembly]::LoadWithPartialName("System.Security") | Out-Null
function MD5HashFile([string] $filePath)
{
    if ([string]::IsNullOrEmpty($filePath) -or !(Test-Path $filePath -PathType Leaf))
    {
        return $null
    }

    [System.IO.Stream] $file = $null;
    [System.Security.Cryptography.MD5] $md5 = $null;
    try
    {
        $md5 = [System.Security.Cryptography.MD5]::Create()
        $file = [System.IO.File]::OpenRead($filePath)
        return [System.BitConverter]::ToString($md5.ComputeHash($file))
    }
    finally
    {
        if ($file -ne $null)
        {
            $file.Dispose()
        }
    }
}



function GetProxyEnabledWebClient
{
    $wc = New-Object System.Net.WebClient
    $proxy = [System.Net.WebRequest]::GetSystemWebProxy()
    $proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials        
    $wc.Proxy = $proxy
    return $wc
}




Write-Host "Preparing to run build script..."

if(!$PSScriptRoot){
    $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

$GIT_DIR = Join-Path $PSScriptRoot ".git"
$TOOLS_DIR = Join-Path $PSScriptRoot "tools"
$NUGET_EXE = Join-Path $TOOLS_DIR "nuget.exe"
$NUGET_URL = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"


if ((Test-Path $PSScriptRoot) -and !(Test-Path $GIT_DIR)) {
    Throw "$GIT_DIR dir not found. Script must be run in root directory of repository"

}

# Make sure tools folder exists
if ((Test-Path $PSScriptRoot) -and !(Test-Path $TOOLS_DIR)) {
    Write-Verbose -Message "Creating tools directory..."
    New-Item -Path $TOOLS_DIR -Type directory | out-null
}



# Try download NuGet.exe if not exists
if (!(Test-Path $NUGET_EXE)) {
    Write-Verbose -Message "Downloading NuGet.exe..."
    try {
        $wc = GetProxyEnabledWebClient
        $wc.DownloadFile($NUGET_URL, $NUGET_EXE)
    } catch {
        Throw "Could not download NuGet.exe."
    }
}

# Other functions
function DownloadNugetIfNotExists ($packageName, $dstDirectory, $checkFile) {
    $msg = "Package name: '$packageName'; Dst dir: '$dstDirectory'; Check file: '$checkFile'"
    If (-not (Test-Path  $checkFile)){
        Write-Host "$msg ; Check file not exists - processing"
        & $NUGET_EXE install $packageName -excludeversion -outputdirectory $dstDirectory
    } else {
        Write-Host "$msg ; Check file exists - exiting"
    }
}

# Save nuget.exe path to environment to be available to child processed
$ENV:NUGET_EXE = $NUGET_EXE

DownloadNugetIfNotExists "Invoke-Build" $TOOLS_DIR $7zip





