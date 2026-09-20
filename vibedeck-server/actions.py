"""
VibeDeck Action Dispatcher
Controls Windows media keys, hotkeys, volume, app launches, and system commands.
"""

import sys
import os
import time
import ctypes
import subprocess
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("VibeDeckActions")

# Windows Virtual-Key Codes for Media and System
VK_CODES = {
    # Media keys
    "media_play_pause": 0xB3,
    "media_next": 0xB0,
    "media_prev": 0xB1,
    "media_stop": 0xB2,
    "volume_mute": 0xAD,
    "volume_down": 0xAE,
    "volume_up": 0xAF,
    
    # Modifiers
    "ctrl": 0x11,
    "shift": 0x10,
    "alt": 0x12,
    "win": 0x5B,
    "meta": 0x5B,
    
    # Common keys
    "esc": 0x1B,
    "tab": 0x09,
    "enter": 0x0D,
    "space": 0x20,
    "backspace": 0x08,
    "delete": 0x2E,
    "up": 0x26,
    "down": 0x28,
    "left": 0x25,
    "right": 0x27,
    "printscreen": 0x2C,
    
    # F-keys
    "f1": 0x70, "f2": 0x71, "f3": 0x72, "f4": 0x73,
    "f5": 0x74, "f6": 0x75, "f7": 0x76, "f8": 0x77,
    "f9": 0x78, "f10": 0x79, "f11": 0x7A, "f12": 0x7B,
}

# Add standard letters and digits
for char in "abcdefghijklmnopqrstuvwxyz":
    VK_CODES[char] = ord(char.upper())
for num in "0123456789":
    VK_CODES[num] = ord(num)

# Keyboard event flags
KEYEVENTF_KEYDOWN = 0x0000
KEYEVENTF_KEYUP = 0x0002
KEYEVENTF_EXTENDEDKEY = 0x0001


def _send_key(vk_code: int, keyup: bool = False):
    """Sends a single virtual key event via Windows keybd_event."""
    flags = KEYEVENTF_KEYUP if keyup else KEYEVENTF_KEYDOWN
    # Extended keys flag for media keys
    if vk_code in (0xB3, 0xB0, 0xB1, 0xB2, 0xAD, 0xAE, 0xAF, 0x5B):
        flags |= KEYEVENTF_EXTENDEDKEY
    ctypes.windll.user32.keybd_event(vk_code, 0, flags, 0)


def press_media_key(action_name: str) -> bool:
    """Triggers a native Windows media hardware key."""
    code = VK_CODES.get(action_name.lower())
    if not code:
        logger.warning(f"Unknown media action: {action_name}")
        return False
    
    logger.info(f"Pressing media key: {action_name} (VK: 0x{code:X})")
    _send_key(code, keyup=False)
    time.sleep(0.02)
    _send_key(code, keyup=True)
    return True


def execute_hotkey(keys: list[str]) -> bool:
    """Presses and releases a combination of keys (e.g. ['ctrl', 'shift', 'm'])."""
    vk_list = []
    for k in keys:
        clean_k = k.lower().strip()
        code = VK_CODES.get(clean_k)
        if code is not None:
            vk_list.append(code)
        else:
            logger.warning(f"Unknown key in combo: {k}")
    
    if not vk_list:
        return False
    
    logger.info(f"Executing hotkey: {keys}")
    # Press all down in order
    for code in vk_list:
        _send_key(code, keyup=False)
        time.sleep(0.01)
        
    time.sleep(0.03)
    
    # Release in reverse order
    for code in reversed(vk_list):
        _send_key(code, keyup=True)
        time.sleep(0.01)
        
    return True


def launch_application(app_target: str) -> bool:
    """Launches an application, executable, shortcut, or shell command."""
    target = app_target.strip().strip('"').strip("'")
    logger.info(f"Launching application: {target}")
    
    # 1. Try direct os.startfile (handles .lnk, .exe, protocols like spotify:, files, etc.)
    try:
        os.startfile(target)
        return True
    except Exception as e1:
        logger.debug(f"os.startfile failed for '{target}': {e1}")

    # 2. Known aliases
    known_aliases = {
        "spotify": "spotify:",
        "discord": "discord:",
        "chrome": "chrome",
        "vscode": "code",
        "code": "code",
        "notepad": "notepad.exe",
        "calc": "calc.exe",
        "calculator": "calc.exe",
        "terminal": "wt.exe",
        "taskmgr": "taskmgr.exe",
        "task_manager": "taskmgr.exe",
        "explorer": "explorer.exe",
        "settings": "ms-settings:",
        "steam": "steam:",
    }
    
    alias_cmd = known_aliases.get(target.lower())
    if alias_cmd:
        try:
            if ":" in alias_cmd:
                os.startfile(alias_cmd)
            else:
                subprocess.Popen(f'start "" "{alias_cmd}"', shell=True)
            return True
        except Exception as e2:
            logger.debug(f"Alias launch failed for '{alias_cmd}': {e2}")

    # 3. Fallback: Shell start
    try:
        subprocess.Popen(f'start "" "{target}"', shell=True)
        return True
    except Exception as e3:
        logger.error(f"Failed to launch app '{target}': {e3}")
        return False


def get_installed_apps() -> list[dict]:
    """Scans Windows Start Menu shortcuts to return a list of installed apps."""
    import glob
    app_dirs = [
        os.path.expandvars(r"%APPDATA%\Microsoft\Windows\Start Menu\Programs"),
        os.path.expandvars(r"%ProgramData%\Microsoft\Windows\Start Menu\Programs"),
    ]
    
    seen_names = set()
    apps = []
    
    # Common system apps to include
    common_defaults = [
        {"name": "Spotify", "target": "spotify"},
        {"name": "Discord", "target": "discord"},
        {"name": "Google Chrome", "target": "chrome"},
        {"name": "Visual Studio Code", "target": "code"},
        {"name": "Windows Terminal", "target": "wt.exe"},
        {"name": "Task Manager", "target": "taskmgr.exe"},
        {"name": "Notepad", "target": "notepad.exe"},
        {"name": "Calculator", "target": "calc.exe"},
        {"name": "File Explorer", "target": "explorer.exe"},
        {"name": "Windows Settings", "target": "ms-settings:"},
    ]
    for d in common_defaults:
        seen_names.add(d["name"].lower())
        apps.append(d)

    for base_dir in app_dirs:
        if not os.path.exists(base_dir):
            continue
        for lnk in glob.glob(os.path.join(base_dir, "**", "*.lnk"), recursive=True):
            base_name = os.path.splitext(os.path.basename(lnk))[0]
            clean_name = base_name.strip()
            
            # Skip uninstallers and helpers
            lower_name = clean_name.lower()
            if any(skip in lower_name for skip in ["uninstall", "remove", "help", "readme", "documentation", "license"]):
                continue
            if lower_name in seen_names:
                continue
                
            seen_names.add(lower_name)
            apps.append({
                "name": clean_name,
                "target": lnk
            })
            
    # Sort alphabetically by name
    apps.sort(key=lambda x: x["name"].lower())
    return apps


def open_url(url: str) -> bool:
    """Opens a URL in the default browser."""
    logger.info(f"Opening URL: {url}")
    try:
        if not url.startswith(("http://", "https://")):
            url = "https://" + url
        os.startfile(url)
        return True
    except Exception as e:
        logger.error(f"Failed to open URL '{url}': {e}")
        return False


def execute_system_command(command: str) -> bool:
    """Executes a Windows system command."""
    cmd = command.lower().strip()
    logger.info(f"Executing system command: {cmd}")
    try:
        if cmd == "lock":
            ctypes.windll.user32.LockWorkStation()
            return True
        elif cmd == "screenshot":
            # Win + Shift + S
            return execute_hotkey(["win", "shift", "s"])
        elif cmd == "show_desktop":
            # Win + D
            return execute_hotkey(["win", "d"])
        elif cmd == "task_manager":
            # Ctrl + Shift + Esc
            return execute_hotkey(["ctrl", "shift", "esc"])
        elif cmd == "alt_tab":
            return execute_hotkey(["alt", "tab"])
        else:
            logger.warning(f"Unknown system command: {cmd}")
            return False
    except Exception as e:
        logger.error(f"System command failed: {e}")
        return False


def _get_endpoint_volume():
    """Helper to get IAudioEndpointVolume across different pycaw versions."""
    from pycaw.pycaw import AudioUtilities, IAudioEndpointVolume
    devices = AudioUtilities.GetSpeakers()
    if hasattr(devices, 'EndpointVolume'):
        return devices.EndpointVolume
    else:
        from comtypes import CLSCTX_ALL
        interface = devices.Activate(IAudioEndpointVolume._iid_, CLSCTX_ALL, None)
        return ctypes.cast(interface, ctypes.POINTER(IAudioEndpointVolume))


def get_master_volume() -> dict:
    """Gets the master volume and mute status using pycaw if available, else fallback."""
    try:
        vol = _get_endpoint_volume()
        current_vol = round(vol.GetMasterVolumeLevelScalar() * 100)
        is_muted = bool(vol.GetMute())
        return {"volume": current_vol, "muted": is_muted}
    except Exception as e:
        logger.debug(f"pycaw volume query fallback: {e}")
        return {"volume": 50, "muted": False}


def set_master_volume(level_pct: int) -> bool:
    """Sets master volume percentage (0-100)."""
    try:
        vol = _get_endpoint_volume()
        clamped = max(0, min(100, level_pct)) / 100.0
        vol.SetMasterVolumeLevelScalar(clamped, None)
        return True
    except Exception as e:
        logger.error(f"Failed to set volume: {e}")
        return False
        logger.error(f"Failed to set volume: {e}")
        return False


def type_text(text: str) -> bool:
    """Types out arbitrary text."""
    try:
        import pyautogui
        pyautogui.write(text, interval=0.01)
        return True
    except Exception as e:
        logger.error(f"Failed to type text: {e}")
        return False
