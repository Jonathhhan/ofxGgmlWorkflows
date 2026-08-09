@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-multimodal-reference-smoke.ps1" %*
exit /b %errorlevel%
