@echo off
title Photo Album - Local Server
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-album.ps1"
echo.
echo Server stopped. Press any key to close this window.
pause >nul
