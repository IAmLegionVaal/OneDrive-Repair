<#
.SYNOPSIS
Reports OneDrive health and optionally runs the supported client reset.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param([switch]$Repair,[switch]$RestartOnly,[string]$LogRoot="$env:ProgramData\OneDriveRepair\Logs")

Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$runPath=Join-Path $LogRoot (Get-Date -Format 'yyyyMMdd_HHmmss')

function Find-OneDrive{
    @("$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe","$env:ProgramFiles\Microsoft OneDrive\OneDrive.exe","${env:ProgramFiles(x86)}\Microsoft OneDrive\OneDrive.exe")|
        Where-Object{$_ -and(Test-Path $_)}|Select-Object -First 1
}

try{
    if($env:OS -ne 'Windows_NT'){throw 'Windows is required.'}
    New-Item $runPath -ItemType Directory -Force|Out-Null
    $exe=Find-OneDrive
    if(-not $exe){throw 'OneDrive.exe was not found.'}

    Get-Item $exe|Select-Object FullName,@{n='Version';e={$_.VersionInfo.FileVersion}},LastWriteTime|
        Export-Csv (Join-Path $runPath 'OneDriveInstallation.csv') -NoTypeInformation
    Get-Process OneDrive -ErrorAction SilentlyContinue|Select-Object Id,StartTime,CPU,WorkingSet,Path|
        Export-Csv (Join-Path $runPath 'OneDriveProcesses.csv') -NoTypeInformation

    $variables=Get-ChildItem Env:|Where-Object{$_.Name -like 'OneDrive*'}
    $variables|Select-Object Name,Value|Export-Csv (Join-Path $runPath 'OneDriveEnvironment.csv') -NoTypeInformation
    $roots=foreach($entry in $variables){
        [pscustomobject]@{Variable=$entry.Name;Path=$entry.Value;Exists=(Test-Path $entry.Value)}
    }
    $roots|Export-Csv (Join-Path $runPath 'SyncRoots.csv') -NoTypeInformation

    if(($Repair -or $RestartOnly) -and $PSCmdlet.ShouldProcess('OneDrive client','Restart')){
        Get-Process OneDrive -ErrorAction SilentlyContinue|Stop-Process -Force
        Start-Sleep 2
    }
    if($Repair -and -not $RestartOnly -and $PSCmdlet.ShouldProcess('OneDrive client','Reset')){
        Start-Process $exe -ArgumentList '/reset' -Wait
        Start-Sleep 5
    }
    if(($Repair -or $RestartOnly) -and $PSCmdlet.ShouldProcess('OneDrive client','Start')){
        Start-Process $exe
    }

    Write-Host "[OK] Completed. Logs: $runPath" -ForegroundColor Green
    exit 0
}catch{Write-Error $_.Exception.Message;exit 1}
