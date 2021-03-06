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

function EnsureDirExists ($path){

    if((Test-Path $path) -eq 0) {
        mkdir $path | out-null;
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

$NUGET_URL = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
$GIT_DIR = Join-Path $PSScriptRoot ".git"
$TOOLS_DIR = Join-Path $PSScriptRoot "tools"
$SRC_DIR = Join-Path $PSScriptRoot "src"
$BUILD_DIR = Join-Path $SRC_DIR "build"

$PACKAGES_CONFIG = Join-Path $TOOLS_DIR "packages.config"
$NUGET_EXE = Join-Path $TOOLS_DIR "nuget.exe"
$IB = Join-Path $TOOLS_DIR "Invoke-Build\tools\Invoke-Build.ps1"
$DEV_HELPERS_DIR =  Join-Path $TOOLS_DIR "dev-helpers"
$DEV_HELPERS_URL = "https://github.com/pkudrel/PsAutomationHelpers.git"
$DEV_HELPERS_VERSION_FILE = Join-Path $DEV_HELPERS_DIR  "version.json"



if ((Test-Path $PSScriptRoot) -and !(Test-Path $GIT_DIR)) {
    Throw "$GIT_DIR dir not found. Script must be run in root directory of repository"

}

# Make sure DevHelpers directory exists
if ((Test-Path $PSScriptRoot) -and !(Test-Path $DEV_HELPERS_DIR )) {
    Write-Host  "Creating DevHelpers directory..."
    New-Item -Path $DEV_HELPERS_DIR  -Type directory | out-null
}


# Make sure tools folder exists
if ((Test-Path $PSScriptRoot) -and !(Test-Path $TOOLS_DIR)) {
    Write-Host  "Creating tools directory..."
    New-Item -Path $TOOLS_DIR -Type directory | out-null
}


# Try download NuGet.exe if not exists
if (!(Test-Path $NUGET_EXE)) {
    Write-Host  "Downloading NuGet.exe..."
    try {
        $wc = GetProxyEnabledWebClient
        $wc.DownloadFile($NUGET_URL, $NUGET_EXE)
    } catch {
        Throw "Could not download NuGet.exe."
    }
}

if (!(Test-Path $DEV_HELPERS_VERSION_FILE)) {
    Write-Host  "Clone DevHelpers..."
    Push-Location
    Set-Location $DEV_HELPERS_DIR

    try {
        &git clone --depth=1 $DEV_HELPERS_URL .
        EnsureDirExists $BUILD_DIR
        Copy-Item -Path bl.ps1 -Destination $BUILD_DIR
        Copy-Item -Path example.build.ps1 -Destination $BUILD_DIR
        Copy-Item -Path packages.config -Destination $TOOLS_DIR
        Get-ChildItem -Path $DEV_HELPERS_DIR -Force -Recurse |
            Where-Object {$_.Name -notlike "version.json"}  |
            Where-Object {$_.Fullname -notlike "$DEV_HELPERS_DIR\ps*"} |
            # it's important because first we have to delete the files in the directory and then the directory itself
            Sort-Object { $_.Fullname.length }  -Descending |
            Remove-Item -Force
    } catch {
        Throw "Could not clone DevHelpers."
    }
    Pop-Location
}



# Restore tools from NuGet?
if(-Not $SkipToolPackageRestore.IsPresent) {
    Push-Location
    Set-Location $TOOLS_DIR

    Write-Host  "Restoring tools from NuGet..."
    $NuGetOutput = Invoke-Expression "&`"$NUGET_EXE`" install -ExcludeVersion  -OutputDirectory `"$TOOLS_DIR`""

    if ($LASTEXITCODE -ne 0) {
        Throw "An error occurred while restoring NuGet tools."
    }
    
    Write-Host  ($NuGetOutput | out-string)

    Pop-Location
}


# Other functions


# Save nuget.exe path to environment to be available to child processed
$ENV:NUGET_EXE = $NUGET_EXE

Write-Host  "Done"


