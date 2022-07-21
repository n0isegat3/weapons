#requires -version 5.1

<#
.SYNOPSIS

Installs Microsoft Azure and Office 365 PowerShell modules either online or offline via two steps process (download, install).

.DESCRIPTION

Installs Microsoft Azure and Office 365 PowerShell modules either online or offline via two steps process (download, install).
PowerShell modules are installed into the current user profile.

.PARAMETER Online
Installs PowerShell modules locally from the internet. Requires internet connectivity.

.PARAMETER Offline
Instructs script to either download files to local folder to be ready for further installation or to install modules from already downloaded files.

.PARAMETER Download
Used in combination with Offline parameter. Instructs script to only download files to local folder to be ready for the future installation.

.PARAMETER ModulePath
Used in combination with Offline parameter. Specifies the path to where to download PowerShell modules or to from to install them.

.EXAMPLE

PS> Install-MicrosoftCloudModules.ps1 -Online
Installs PowerShell modules from the internet.

.EXAMPLE

PS> Install-MicrosoftCloudModules.ps1 -Offline -Download -ModulePath C:\Temp\Modules
Downloads PowerShell modules from the internet to the specified folder. You can then copy this folder to the target system and using this script install them.

.EXAMPLE

PS> Install-MicrosoftCloudModules.ps1 -Offline -ModulePath C:\Temp\Modules
Installs PowerShell modules using the already download module files.


.LINK

http://www.cyber-rangers.com

.NOTES

2021 (c) Cyber Rangers, s.r.o.
Jan Marek, jan@cyber-rangers.com
#>

[CmdletBinding(DefaultParameterSetName='Online')]
param (
    [Parameter(ParameterSetName='Online')][switch]$Online,
    [Parameter(ParameterSetName='Offline')][switch]$Offline,
    [Parameter(ParameterSetName='Offline',Mandatory=$true)][string]$ModulePath,
    [Parameter(ParameterSetName='Offline')][switch]$Download
)

Clear-Host
1..10 | ForEach-Object { Write-Host '' }

[string[]]$ModulesToInstall = 'Az','ExchangeOnlineManagement','MSOnline','AzureAD','Microsoft.Online.SharePoint.PowerShell','SharePointPnPPowerShellOnline','MicrosoftTeams','ExchangeOnlineManagement'

if ($Online.IsPresent) {
    Write-Host 'Starting online installation of Microsoft Cloud PowerShell modules.'
    Install-PackageProvider -Name Nuget -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop -InformationAction SilentlyContinue | Out-Null

    foreach ($ModuleToInstall in $ModulesToInstall) {
        Write-Host ('Installing PowerShell module {0}.' -f $ModuleToInstall)
        Install-Module -Name $ModuleToInstall -Force -Confirm:$false -Scope CurrentUser -AllowClobber
    }
}
if ($Offline.IsPresent) {
    if ($Download.IsPresent) {
        Write-Host 'Starting download of Microsoft Cloud PowerShell modules.'
        if (Test-Path $ModulePath) {
            throw ('ModulePath {0} already exists. Please delete it first' -f $ModulePath)
        }

        New-Item -ItemType Directory -Path $ModulePath -ErrorAction Stop | Out-Null

        Install-PackageProvider -Name Nuget -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop -InformationAction SilentlyContinue | Out-Null

        foreach ($ModuleToInstall in $ModulesToInstall) {
            Write-Host ('Downloading PowerShell module {0}.' -f $ModuleToInstall)
            Save-Module -Name $ModuleToInstall -Path $ModulePath -Force -Confirm:$false
        }

        Write-Host ('PowerShell modules downloaded to {0}. Copy this folder to the target computer and rerun this script without parameter -Download.' -f $ModulePath)
    } else {
        Write-Host 'Starting offline install (copy) of Microsoft Cloud PowerShell modules.'
        if (!$(Test-Path $ModulePath)) {
            throw ('ModulePath {0} does not exist. Please download modules first.' -f $ModulePath)
        }
        if ((Get-ChildItem -Path $ModulePath | Measure-Object | Select-Object -ExpandProperty Count) -lt 1) {
            throw ('ModulePath {0} does not contain any file. Please download modules first.' -f $ModulePath)
        }

        foreach ($ModuleFolder in $(Get-ChildItem -Path $ModulePath)) {
            Write-Host ('Copying module {0} to {1} ...' -f $ModuleFolder.Name,$($env:PSModulePath.Split(';') | Where-Object {$_ -like "$($env:USERPROFILE)*"}))
            Copy-Item -Force -Confirm:$false -Recurse -Path $ModuleFolder.FullName -Destination ($env:PSModulePath.Split(';') | Where-Object {$_ -like "$($env:USERPROFILE)*"})
        }

        Write-Host ('PowerShell modules installed from {0} to {1}.' -f $ModulePath,$($env:PSModulePath.Split(';') | Where-Object {$_ -like "$($env:USERPROFILE)*"}))
    }
}

