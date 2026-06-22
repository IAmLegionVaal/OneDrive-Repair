# OneDrive Repair

Single-run PowerShell diagnostics and supported reset workflow for the Microsoft OneDrive desktop client.

> **Testing note:** This was tested by me to be working. User experience may vary.

## Included

`Repair-OneDrive.ps1`

## Usage

```powershell
.\Repair-OneDrive.ps1
.\Repair-OneDrive.ps1 -RestartOnly
.\Repair-OneDrive.ps1 -Repair
```

The default run reports installation, process and sync-root information. Repair mode uses OneDrive’s supported reset argument and restarts the client. User files are not removed.

Preview actions with `-WhatIf`. Logs are stored in `C:\ProgramData\OneDriveRepair\Logs`.

Exit code `0` means success, `1` means a fatal error and `2` means warnings were recorded.

## Disclaimer

Use this project at your own risk. Sync recovery time varies according to account size, connectivity, policy and client version. Confirm that important files are available before troubleshooting.

## License

MIT
