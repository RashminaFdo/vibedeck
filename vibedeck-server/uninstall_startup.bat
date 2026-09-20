@echo off
title Remove VibeDeck from Windows Startup
set "STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "SHORTCUT_PATH=%STARTUP_FOLDER%\VibeDeckServer.lnk"

if exist "%SHORTCUT_PATH%" (
    del "%SHORTCUT_PATH%"
    echo [SUCCESS] Removed VibeDeck from Windows Startup.
) else (
    echo VibeDeck was not in Startup.
)
pause
