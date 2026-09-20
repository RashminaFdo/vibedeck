@echo off
title VibeDeck Server Host
cd /d "%~dp0"
echo Freeing port 8765 if already in use...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8765 ^| findstr LISTENING') do taskkill /f /pid %%a >nul 2>&1
echo Starting VibeDeck Host Server...
python server.py
pause
