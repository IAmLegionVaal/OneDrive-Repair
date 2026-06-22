<#
.SYNOPSIS
Diagnoses and repairs common Microsoft OneDrive client problems.
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
$transcript=$false

function Find-OneDrive{
    $paths=@(
        "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe",
        "$env:ProgramFiles\Microsoft OneDrive\OneDrive.exe",
        "${env:ProgramFiles(x86)}\Microsoft OneDrive\OneDrive.exe"
    )|Where-Object{$_ -and(Test-Path $_)}
    $paths|Select-Object -First 1
}

try{
    if($env:OS -ne 'Windows_NT'){throw 'Windows is required.'}
    New-Item $runPath -ItemType Directory -Force|Out-Null
    Start-Transcript -Path (Join-Path $runPath 'Transcript.txt') -Force|Out-Null
    $transcript=$true

    $exe=Find-OneDrive
    if(-not $exe){throw 'OneDrive.exe was not found.'}

    Get-Item $exe|Select-Object FullName,@{n='Version';e={$_.VersionInfo.FileVersion}},LastWriteTime|
        Export-Csv (Join-Path $runPath 'OneDriveInstallation.csv') -NoTypeInformation

    Get-Process OneDrive -ErrorAction SilentlyContinue|
        Select-Object Id,StartTime,CPU,WorkingSet,Path|
        Export-Csv (Join-Path $runPath 'OneDriveProcesses.csv') -NoTypeInformation

    Get-ChildItem Env:|Where-Object Name -Like 'OneDrive*'|
        Select-Object Name,Value|Export-Csv (Join-Path $runPath 'OneDriveEnvironment.csv') -NoTypeInformation

    foreach($entry in Get-ChildItem Env:|Where-Object Name -Like 'OneDrive*'){
        if(Test-Path $entry.Value){
            $drive=Get-PSDrive -Name ([IO.Path]::GetPathRoot($entry.Value).TrimEnd(':\')) -ErrorAction SilentlyContinue
            [pscustomobject]@{Variable=$entry.Name;Path=$entry.Value;Exists=$true;FreeBytes=$drive.Free}
        }
    }|Export-Csv (Join-Path $runPath 'SyncRoots.csv') -NoTypeInformation

    if(($Repair -or $RestartOnly) -and $PSCmdlet.ShouldProcess('Microsoft OneDrive client','Restart client')){
        Get-Process OneDrive -ErrorAction SilentlyContinue|Stop-Process -Force
        Start-Sleep -Seconds 2
    }

    if($Repair -and -not $RestartOnly -and $PSCmdlet.ShouldProcess('Microsoft OneDrive client','Run supported reset command')){
        Start-Process -FilePath $exe -ArgumentList '/reset' -Wait
        Start-Sleep -Seconds 5
    }

    if(($Repair -or $RestartOnly) -and $PSCmdlet.ShouldProcess('Microsoft OneDrive client','Start client')){
        Start-Process -FilePath $exe
        Start-Sleep -Seconds 3
        if(-not(Get-Process OneDrive -ErrorAction SilentlyContinue)){$warnings.Add('OneDrive did not appear to start.')}
    }

    $warnings|Out-File (Join-Path $runPath 'Warnings.txt') -Encoding UTF8
    if($transcript){Stop-Transcript|Out-Null;$transcript=$false}
    if($warnings.Count -gt 0){Write-Host "[WARN] Completed with warnings. Logs: $runPath" -ForegroundColor Yellow;exit 2}
    Write-Host "[OK] Completed. Logs: $runPath" -ForegroundColor Green;exit 0
}catch{
    if($transcript){try{Stop-Transcript|Out-Null}catch{}}
    Write-Error $_.Exception.Message;exit 1
}
