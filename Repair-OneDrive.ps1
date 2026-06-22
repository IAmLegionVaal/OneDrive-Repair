<#
.SYNOPSIS
Reports OneDrive health and optionally runs the supported client reset.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Repair,
    [switch]$RestartOnly,
    [string]$LogRoot="$env:ProgramData\OneDriveRepair\Logs"
)

Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$runPath=Join-Path $LogRoot (Get-Date -Format 'yyyyMMdd_HHmmss')
$warnings=New-Object System.Collections.Generic.List[string]

function Find-OneDrive{
    @(
        "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe",
        "$env:ProgramFiles\Microsoft OneDrive\OneDrive.exe",
        "${env:ProgramFiles(x86)}\Microsoft OneDrive\OneDrive.exe"
    )|Where-Object{$_ -and(Test-Path $_)}|Select-Object -First 1
}

function Save-OneDriveState{
    param([string]$Suffix)
    Get-Process OneDrive -ErrorAction SilentlyContinue|
        Select-Object Id,StartTime,CPU,WorkingSet,Path|
        Export-Csv (Join-Path $runPath ("OneDriveProcesses-$Suffix.csv")) -NoTypeInformation
}

try{
    if($env:OS -ne 'Windows_NT'){throw 'Windows is required.'}
    New-Item $runPath -ItemType Directory -Force|Out-Null
    $exe=Find-OneDrive
    if(-not $exe){throw 'OneDrive.exe was not found.'}

    Get-Item $exe|Select-Object FullName,@{n='Version';e={$_.VersionInfo.FileVersion}},LastWriteTime|
        Export-Csv (Join-Path $runPath 'OneDriveInstallation.csv') -NoTypeInformation
    Save-OneDriveState 'Before'

    $variables=Get-ChildItem Env:|Where-Object{$_.Name -like 'OneDrive*'}
    $variables|Select-Object Name,Value|Export-Csv (Join-Path $runPath 'OneDriveEnvironment.csv') -NoTypeInformation
    $roots=foreach($entry in $variables){
        [pscustomobject]@{Variable=$entry.Name;Path=$entry.Value;Exists=(Test-Path $entry.Value)}
    }
    $roots|Export-Csv (Join-Path $runPath 'SyncRoots.csv') -NoTypeInformation

    if(($Repair -or $RestartOnly) -and $PSCmdlet.ShouldProcess('OneDrive client','Stop current process')){
        Get-Process OneDrive -ErrorAction SilentlyContinue|Stop-Process -Force -ErrorAction Stop
        Start-Sleep -Seconds 2
    }

    if($Repair -and -not $RestartOnly -and $PSCmdlet.ShouldProcess('OneDrive client','Run supported reset')){
        $reset=Start-Process -FilePath $exe -ArgumentList '/reset' -PassThru -Wait
        if($reset.ExitCode -ne 0){$warnings.Add("OneDrive reset returned exit code $($reset.ExitCode).")}
        Start-Sleep -Seconds 5
    }

    if(($Repair -or $RestartOnly) -and $PSCmdlet.ShouldProcess('OneDrive client','Start client')){
        Start-Process -FilePath $exe|Out-Null
        $deadline=(Get-Date).AddSeconds(60)
        do{
            Start-Sleep -Seconds 2
            $running=Get-Process OneDrive -ErrorAction SilentlyContinue|Select-Object -First 1
        }until($running -or (Get-Date) -ge $deadline)
        if(-not $running){$warnings.Add('OneDrive did not remain running within 60 seconds after restart.')}
    }

    Save-OneDriveState 'After'
    $warnings|Out-File (Join-Path $runPath 'Warnings.txt') -Encoding UTF8

    if($warnings.Count -gt 0){Write-Host "[WARN] Completed with warnings. Logs: $runPath" -ForegroundColor Yellow;exit 2}
    Write-Host "[OK] Completed. Logs: $runPath" -ForegroundColor Green
    exit 0
}catch{Write-Error $_.Exception.Message;exit 1}
