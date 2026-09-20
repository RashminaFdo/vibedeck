# 🎛️ VibeDeck

> High-performance, customizable DIY Stream Deck alternative for Android and Windows. Control your laptop with zero latency, zero cloud dependency, and zero subscription fees.

---

## 🚀 Features

- **Pure Android APK**: Built with Flutter for 120Hz smooth animations, glowing neon aesthetic, and haptic feedback.
- **Ultra Low-Latency Local Link**: Sub-1ms response times via local WebSockets (`ws://`).
- **4 Easy Connection Modes**:
  1. **QR Code Quick Connect**: Point phone camera at the QR code displayed in the server terminal.
  2. **Auto-Discovery**: Automatically finds your laptop on local Wi-Fi via UDP beacons.
  3. **Zero-Lag USB Cable Mode**: Use a USB cable with ADB reverse tunneling for 0ms lag anywhere.
  4. **Manual IP**: Direct IP address and port input (`192.168.x.x:8765`).
- **Two-Way Status Feedback**:
  - Live latency indicator (e.g. `0.5ms`).
  - Master volume slider directly in the deck header.
  - Hardware mute toggle with real-time feedback from Windows.
- **100% Customizable Everything**:
  - **Dynamic Grid Size**: Adjust columns (2 to 6) and rows (2 to 6) to fit any phone or tablet screen.
  - **Custom Button Creator**:
    - **Media Keys**: Play/Pause, Next Track, Prev Track, Stop, Mute, Volume Up/Down.
    - **Hotkey Combos**: Any combination of `Ctrl`, `Shift`, `Alt`, `Win` + any key (`m`, `c`, `v`, `tab`, `esc`, `f1`-`f12`).
    - **App Launchers**: Spotify, Discord, VS Code, Chrome, Terminal, Calculator, Notepad, or custom `.exe` paths.
    - **Open URLs**: Quick-launch YouTube, GitHub, Twitch, SoundCloud, etc.
    - **Windows System Commands**: Lock Screen, Snip Tool / Screenshot (`Win+Shift+S`), Show Desktop (`Win+D`), Task Manager (`Ctrl+Shift+Esc`), Alt+Tab.
    - **Volume Levels**: Directly set volume percentage or relative steps.
    - **Type Text**: Automated typing snippets or macros.
  - **Vibrant Neon Styling**: 12 preset colors or full custom HSV color wheel picker.
  - **30+ Stream Deck Icons**: Play, media, mute, code, stats, lock, snip, chat, game, and more.
  - **Multi-Deck Profiles**: Switch seamlessly between *Media & Audio*, *System & Tools*, *Dev & Discord*, or create unlimited new profiles.

---

## 🛠️ Project Structure

```
vibedeck/
├── vibedeck-server/             # Windows Desktop Host Companion (Python)
│   ├── server.py                # WebSocket server & action handler
│   ├── actions.py               # Windows virtual key & audio dispatcher
│   ├── discovery.py             # UDP auto-discovery beacon
│   ├── profiles.json            # Profile & button storage
│   ├── test_client.py           # Automated diagnostic & latency test
│   ├── run_server.bat           # 1-Click Server Launcher
│   └── setup_usb_connection.bat # 1-Click USB Cable Port Forwarder
│
├── vibedeck-app/                # Android Mobile Application (Flutter)
│   ├── lib/
│   │   ├── models/deck_action.dart
│   │   ├── services/connection_service.dart
│   │   ├── services/storage_service.dart
│   │   ├── theme/vibe_theme.dart
│   │   └── ui/
│   │       ├── deck_screen.dart
│   │       ├── deck_button_widget.dart
│   │       ├── edit_button_dialog.dart
│   │       └── connect_dialog.dart
│   └── android/
│
├── build_apk.bat                # 1-Click Android APK Builder
└── README.md
```

---

## 🏁 Quick Start Guide

### Step 1: Start the Desktop Server
Double-click:
```bat
vibedeck-server\run_server.bat
```
This starts the local server on port `8765`, displays your local IP, and generates an ASCII QR code in your terminal.

---

### Step 2: Build & Install the Android APK
Double-click:
```bat
build_apk.bat
```
Once the build completes, find the APK at:
`vibedeck-app\build\app\outputs\flutter-apk\app-debug.apk`

Transfer it to your Android phone and install it (or run `adb install -r <path-to-apk>`).

---

### Step 3: Connect
Open **VibeDeck** on your phone:
- **Scan QR**: Tap the connection badge on top, switch to **QR Scan**, and point your camera at the server terminal.
- **Or Auto Wi-Fi**: Tap **Auto Wi-Fi** -> **Find My Laptop**.
- **Or USB Cable**: Plug in your USB cable, run `vibedeck-server\setup_usb_connection.bat`, and tap **Connect via USB**.

You're ready to control your laptop! 🎮🎛️
