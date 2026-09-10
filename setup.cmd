@echo off
rem Launch the guided setup relative to this file, including when double-clicked.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
set "setup_exit=%ERRORLEVEL%"
if not "%setup_exit%"=="0" echo Setup did not complete. See the message above.
pause
exit /b %setup_exit%
