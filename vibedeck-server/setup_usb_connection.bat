@echo off
title VibeDeck USB Cable Tunnel Setup
echo ===================================================
echo     VibeDeck USB Cable Low-Latency Tunnel Setup
echo ===================================================
echo This will route port 8765 through your USB cable.
echo On your Android device, you can now connect to:
echo     ws://127.0.0.1:8765  or  ws://localhost:8765
echo.

adb reverse tcp:8765 tcp:8765
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] USB reverse tunnel established!
    echo You can now tap 'Connect via USB' in the VibeDeck App.
) else (
    echo [ERROR] Could not set up USB reverse tunnel.
    echo Please make sure USB Debugging is enabled on your phone and device is connected.
)
echo ===================================================
pause
