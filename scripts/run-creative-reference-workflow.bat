@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "RUN_PS1=%SCRIPT_DIR%run-creative-reference-workflow.ps1"
where pwsh.exe >nul 2>nul
if errorlevel 1 goto windows_powershell
pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%RUN_PS1%" %*
exit /b %ERRORLEVEL%
:windows_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%RUN_PS1%" %*
exit /b %ERRORLEVEL%
