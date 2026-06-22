# OneDrive Repair

Single-run PowerShell diagnostics and supported reset workflow for the Microsoft OneDrive desktop client.

> **Testing note:** This was tested by me to be working. User experience may vary.

## One-click use

1. Download and extract the repository.
2. Double-click `Run-OneClick.bat` while signed in as the affected user.
3. The launcher runs the supported OneDrive reset and restart directly—there is no menu.
4. Review the displayed exit code and the logs in `C:\ProgramData\OneDriveRepair\Logs`.

## Included

`Repair-OneDrive.ps1`

## PowerShell usage

```powershell
.\Repair-OneDrive.ps1
.\Repair-OneDrive.ps1 -RestartOnly
.\Repair-OneDrive.ps1 -Repair
.\Repair-OneDrive.ps1 -Repair -WhatIf
```

The default run reports installation, process and sync-root information. Repair mode uses OneDrive’s supported reset argument, restarts the client and verifies that the process returns. User files are not removed.

Exit code `0` means success, `1` means a fatal error and `2` means repair or restart warnings were recorded.

## Disclaimer

Use this project at your own risk. Sync recovery time varies according to account size, connectivity, policy and client version. Confirm that important files are available before troubleshooting.

## License

MIT
