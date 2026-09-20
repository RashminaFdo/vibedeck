@echo off
title Install VibeDeck as Windows Startup App
echo ===================================================
echo     VibeDeck Auto-Start on Windows Boot Installer
echo ===================================================
echo.

set "SCRIPT_DIR=%~dp0"
set "TARGET_VBS=%SCRIPT_DIR%start_silent.vbs"
set "STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "SHORTCUT_PATH=%STARTUP_FOLDER%\VibeDeckServer.lnk"

echo Creating startup shortcut...
powershell -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%SHORTCUT_PATH%'); $s.TargetPath = 'wscript.exe'; $s.Arguments = '\"%TARGET_VBS%\"'; $s.WorkingDirectory = '%SCRIPT_DIR%'; $s.Save()"

if exist "%SHORTCUT_PATH%" (
    echo.
    echo ===================================================
    echo [SUCCESS] VibeDeck will now run automatically in the
    echo           background whenever your laptop powers on!
    echo ===================================================
) else (
    echo [ERROR] Failed to create startup shortcut.
)

pause
