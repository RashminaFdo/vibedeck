@echo off
title VibeDeck APK Builder
echo ===================================================
echo             VibeDeck APK Builder
echo ===================================================
cd /d "%~dp0\vibedeck-app"
set "JAVA_HOME=C:\Program Files\Java\jdk-21.0.12"
set "PATH=%JAVA_HOME%\bin;%PATH%"
echo Building VibeDeck Android APK with JDK 21...
flutter build apk --debug
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ===================================================
    echo [SUCCESS] APK built successfully!
    echo Location: vibedeck-app\build\app\outputs\flutter-apk\app-debug.apk
    echo ===================================================
) else (
    echo.
    echo [ERROR] Failed to build APK.
)
pause
