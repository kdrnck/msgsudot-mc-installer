@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"
title MSGSU-DOT Minecraft:SMP Kurulum Sistemi - kdrnck & kheiron1
rem Run PowerShell script with ExecutionPolicy bypass
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%codes.ps1"
exit /b %ERRORLEVEL%

