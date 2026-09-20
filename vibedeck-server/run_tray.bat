@echo off
title VibeDeck System Tray Launcher
cd /d "%~dp0"
set "PW=%LOCALAPPDATA%\Python\pythoncore-3.14-64\pythonw.exe"
if exist "%PW%" (
    start "" "%PW%" tray_app.py
) else (
    start "" pythonw.exe tray_app.py
)
echo VibeDeck is running in your Windows System Tray (near the clock).
ping 127.0.0.1 -n 3 >nul
exit
