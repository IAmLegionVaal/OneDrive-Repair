@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Repair-OneDrive.ps1" -Repair
set "RC=%ERRORLEVEL%"
echo.
echo OneDrive Repair finished with exit code %RC%.
pause
exit /b %RC%
