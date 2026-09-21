@echo off
title VibeDeck APK Builder
echo ===================================================
echo             VibeDeck APK Builder (Release)
echo ===================================================
cd /d "%~dp0\vibedeck-app"
set "JAVA_HOME=C:\Program Files\Java\jdk-21.0.12"
set "PATH=%JAVA_HOME%\bin;%PATH%"
echo Building VibeDeck Android Release APK with JDK 21...
call flutter build apk --release
if %ERRORLEVEL% EQU 0 (
    copy /y "build\app\outputs\flutter-apk\app-release.apk" "%~dp0\VibeDeck.apk" >nul
    echo.
    echo ===================================================
    echo [SUCCESS] Release APK built successfully!
    echo Output: %~dp0\VibeDeck.apk
    echo ===================================================
) else (
    echo.
    echo [ERROR] Failed to build Release APK.
)
pause
