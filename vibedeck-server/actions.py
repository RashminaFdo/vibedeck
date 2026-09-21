"""
VibeDeck Action Dispatcher
Controls Windows media keys, hotkeys, volume, microphone, trackpad mouse, keyboard typing, system telemetry, and PC power commands.
"""

import sys
import os
import time
import ctypes
from ctypes import wintypes
import subprocess
import logging
import psutil

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("VibeDeckActions")

# Windows Virtual-Key Codes for Media, System, and PC Keys
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
    "control": 0x11,
    "shift": 0x10,
    "alt": 0x12,
    "win": 0x5B,
    "windows": 0x5B,
    "meta": 0x5B,
    "capslock": 0x14,
    "caps": 0x14,
    
    # Common keys
    "esc": 0x1B,
    "escape": 0x1B,
    "tab": 0x09,
    "enter": 0x0D,
    "return": 0x0D,
    "space": 0x20,
    "backspace": 0x08,
    "delete": 0x2E,
    "del": 0x2E,
    "insert": 0x2D,
    "ins": 0x2D,
    "up": 0x26,
    "down": 0x28,
    "left": 0x25,
    "right": 0x27,
    "home": 0x24,
    "end": 0x23,
    "pageup": 0x21,
    "pgup": 0x21,
    "pagedown": 0x22,
    "pgdn": 0x22,
    "printscreen": 0x2C,
    "prtsc": 0x2C,
    "numlock": 0x90,
    "scrolllock": 0x91,
    
    # Punctuation & standard OEM keys
    ";": 0xBA,
    "=": 0xBB,
    ",": 0xBC,
    "-": 0xBD,
    ".": 0xBE,
    "/": 0xBF,
    "`": 0xC0,
    "[": 0xDB,
    "\\": 0xDC,
    "]": 0xDD,
    "'": 0xDE,
    
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

# Shift-required symbols mapping to base key
SHIFT_SYMBOLS = {
    '~': '`', '!': '1', '@': '2', '#': '3', '$': '4', '%': '5', '^': '6',
    '&': '7', '*': '8', '(': '9', ')': '0', '_': '-', '+': '=', '{': '[',
    '}': ']', '|': '\\', ':': ';', '"': "'", '<': ',', '>': '.', '?': '/',
}

# Keyboard event flags
KEYEVENTF_KEYDOWN = 0x0000
KEYEVENTF_KEYUP = 0x0002
KEYEVENTF_EXTENDEDKEY = 0x0001
KEYEVENTF_UNICODE = 0x0004

# Mouse event flags
MOUSEEVENTF_MOVE = 0x0001
MOUSEEVENTF_LEFTDOWN = 0x0002
MOUSEEVENTF_LEFTUP = 0x0004
MOUSEEVENTF_RIGHTDOWN = 0x0008
MOUSEEVENTF_RIGHTUP = 0x0010
MOUSEEVENTF_MIDDLEDOWN = 0x0020
MOUSEEVENTF_MIDDLEUP = 0x0040
MOUSEEVENTF_WHEEL = 0x0800


def _send_key(vk_code: int, keyup: bool = False):
    """Sends a single virtual key event via Windows keybd_event."""
    flags = KEYEVENTF_KEYUP if keyup else KEYEVENTF_KEYDOWN
    if vk_code in (0xB3, 0xB0, 0xB1, 0xB2, 0xAD, 0xAE, 0xAF, 0x5B, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x2D, 0x2E, 0x2C):
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


def key_down(key_name: str) -> bool:
    """Holds a key down (useful for modifiers or held inputs)."""
    clean_k = key_name.lower().strip()
    code = VK_CODES.get(clean_k)
    if code is not None:
        _send_key(code, keyup=False)
        return True
    return False


def key_up(key_name: str) -> bool:
    """Releases a held key."""
    clean_k = key_name.lower().strip()
    code = VK_CODES.get(clean_k)
    if code is not None:
        _send_key(code, keyup=True)
        return True
    return False


def press_special_key(key_name: str) -> bool:
    """
    Presses a single key (e.g. 'enter', 'esc', 'space', 'tab', 'a', 'A', '!', etc.).
    Fully handles uppercase shifted letters, symbols, and Unicode fallbacks.
    """
    if not key_name:
        return False

    # 1. Handle shifted symbols (e.g. '!', '@', '#', '{', etc.)
    if key_name in SHIFT_SYMBOLS:
        base_char = SHIFT_SYMBOLS[key_name]
        base_code = VK_CODES.get(base_char)
        if base_code is not None:
            _send_key(0x10, keyup=False)  # Shift down
            time.sleep(0.01)
            _send_key(base_code, keyup=False)
            time.sleep(0.01)
            _send_key(base_code, keyup=True)
            time.sleep(0.01)
            _send_key(0x10, keyup=True)   # Shift up
            return True

    # 2. Handle uppercase single letters (e.g. 'A', 'Z')
    if len(key_name) == 1 and key_name.isupper() and key_name.lower() in VK_CODES:
        base_code = VK_CODES[key_name.lower()]
        _send_key(0x10, keyup=False)  # Shift down
        time.sleep(0.01)
        _send_key(base_code, keyup=False)
        time.sleep(0.01)
        _send_key(base_code, keyup=True)
        time.sleep(0.01)
        _send_key(0x10, keyup=True)   # Shift up
        return True

    # 3. Direct VK lookup (case-insensitive for named keys like 'enter', 'tab', 'space', or 'a')
    clean_k = key_name.lower().strip()
    code = VK_CODES.get(clean_k)
    if code is not None:
        _send_key(code, keyup=False)
        time.sleep(0.015)
        _send_key(code, keyup=True)
        return True

    # 4. Fallback to hardware keybd_event Unicode scan for arbitrary characters
    if len(key_name) == 1:
        char_code = ord(key_name)
        ctypes.windll.user32.keybd_event(0, char_code, KEYEVENTF_UNICODE, 0)
        time.sleep(0.01)
        ctypes.windll.user32.keybd_event(0, char_code, KEYEVENTF_UNICODE | KEYEVENTF_KEYUP, 0)
        return True

    logger.warning(f"Unknown special key: {key_name}")
    return False


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
    for code in vk_list:
        _send_key(code, keyup=False)
        time.sleep(0.01)
        
    time.sleep(0.03)
    
    for code in reversed(vk_list):
        _send_key(code, keyup=True)
        time.sleep(0.01)
        
    return True


def type_text(text: str) -> bool:
    """
    Types arbitrary text (including newlines and Unicode) into active Windows focus.
    Uses universal keybd_event with KEYEVENTF_UNICODE to bypass SendInput 64-bit struct padding issues.
    """
    try:
        user32 = ctypes.windll.user32
        for char in text:
            if char == '\n':
                _send_key(0x0D, keyup=False)  # Enter down
                time.sleep(0.005)
                _send_key(0x0D, keyup=True)   # Enter up
                time.sleep(0.005)
            elif char == '\t':
                _send_key(0x09, keyup=False)
                time.sleep(0.005)
                _send_key(0x09, keyup=True)
                time.sleep(0.005)
            else:
                code = ord(char)
                user32.keybd_event(0, code, KEYEVENTF_UNICODE, 0)
                time.sleep(0.005)
                user32.keybd_event(0, code, KEYEVENTF_UNICODE | KEYEVENTF_KEYUP, 0)
                time.sleep(0.005)
        return True
    except Exception as e:
        logger.error(f"Failed to type text: {e}")
        return False


# Trackpad & Mouse simulation
def mouse_move(dx: float, dy: float) -> bool:
    """Relative cursor delta movement."""
    try:
        ctypes.windll.user32.mouse_event(MOUSEEVENTF_MOVE, int(dx), int(dy), 0, 0)
        return True
    except Exception as e:
        logger.error(f"mouse_move failed: {e}")
        return False


def mouse_click(button: str = "left", double: bool = False) -> bool:
    """Triggers mouse button click (left, right, middle)."""
    btn = button.lower().strip()
    try:
        user32 = ctypes.windll.user32
        if btn == "left":
            user32.mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0)
            user32.mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0)
            if double:
                time.sleep(0.05)
                user32.mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0)
                user32.mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0)
        elif btn == "right":
            user32.mouse_event(MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, 0)
            user32.mouse_event(MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0)
        elif btn == "middle":
            user32.mouse_event(MOUSEEVENTF_MIDDLEDOWN, 0, 0, 0, 0)
            user32.mouse_event(MOUSEEVENTF_MIDDLEUP, 0, 0, 0, 0)
        return True
    except Exception as e:
        logger.error(f"mouse_click failed: {e}")
        return False


def mouse_scroll(dy: float) -> bool:
    """Scrolls vertical mouse wheel."""
    try:
        # Wheel delta is standard 120 per notch
        wheel_amount = int(dy * 120)
        ctypes.windll.user32.mouse_event(MOUSEEVENTF_WHEEL, 0, 0, wheel_amount, 0)
        return True
    except Exception as e:
        logger.error(f"mouse_scroll failed: {e}")
        return False


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
        if cmd in ("lock", "lock_pc"):
            ctypes.windll.user32.LockWorkStation()
            return True
        elif cmd == "screenshot":
            return execute_hotkey(["win", "shift", "s"])
        elif cmd == "show_desktop":
            return execute_hotkey(["win", "d"])
        elif cmd == "task_manager":
            return execute_hotkey(["ctrl", "shift", "esc"])
        elif cmd == "alt_tab":
            return execute_hotkey(["alt", "tab"])
        elif cmd == "screen_off":
            return turn_off_screen()
        elif cmd == "sleep":
            return sleep_pc()
        else:
            logger.warning(f"Unknown system command: {cmd}")
            return False
    except Exception as e:
        logger.error(f"System command failed: {e}")
        return False


# Core Audio Volume & Microphone Controls
def _get_speaker_volume_endpoint():
    """Helper to get speaker IAudioEndpointVolume."""
    from pycaw.pycaw import AudioUtilities, IAudioEndpointVolume
    devices = AudioUtilities.GetSpeakers()
    if hasattr(devices, 'EndpointVolume'):
        return devices.EndpointVolume
    else:
        from comtypes import CLSCTX_ALL
        interface = devices.Activate(IAudioEndpointVolume._iid_, CLSCTX_ALL, None)
        return ctypes.cast(interface, ctypes.POINTER(IAudioEndpointVolume))


def _get_mic_volume_endpoint():
    """Helper to get microphone IAudioEndpointVolume."""
    try:
        from pycaw.pycaw import AudioUtilities, IAudioEndpointVolume
        mic = AudioUtilities.GetMicrophone()
        if mic is None:
            return None
        if hasattr(mic, 'EndpointVolume'):
            return mic.EndpointVolume
        else:
            from comtypes import CLSCTX_ALL
            interface = mic.Activate(IAudioEndpointVolume._iid_, CLSCTX_ALL, None)
            return interface.QueryInterface(IAudioEndpointVolume)
    except Exception as e:
        logger.debug(f"Could not access microphone endpoint: {e}")
        return None


def get_master_volume() -> dict:
    """Gets the master speaker volume and mute status."""
    try:
        vol = _get_speaker_volume_endpoint()
        current_vol = round(vol.GetMasterVolumeLevelScalar() * 100)
        is_muted = bool(vol.GetMute())
        return {"volume": current_vol, "muted": is_muted}
    except Exception as e:
        logger.debug(f"pycaw volume query fallback: {e}")
        return {"volume": 50, "muted": False}


def set_master_volume(level_pct: int) -> bool:
    """Sets master speaker volume percentage (0-100)."""
    try:
        vol = _get_speaker_volume_endpoint()
        clamped = max(0, min(100, level_pct)) / 100.0
        vol.SetMasterVolumeLevelScalar(clamped, None)
        return True
    except Exception as e:
        logger.error(f"Failed to set volume: {e}")
        return False


def toggle_master_mute() -> bool:
    """Toggles speaker master mute and returns new mute state."""
    try:
        vol = _get_speaker_volume_endpoint()
        new_state = not bool(vol.GetMute())
        vol.SetMute(new_state, None)
        return new_state
    except Exception as e:
        logger.error(f"Failed to toggle mute: {e}")
        press_media_key("volume_mute")
        return False


def get_mic_mute() -> bool:
    """Checks if default microphone is currently muted."""
    try:
        endpoint = _get_mic_volume_endpoint()
        if endpoint:
            return bool(endpoint.GetMute())
    except Exception as e:
        logger.debug(f"Failed to get mic mute state: {e}")
    return False


def toggle_mic_mute() -> bool:
    """Toggles microphone mute state at Windows Core Audio level (also mutes Discord mic input)."""
    try:
        endpoint = _get_mic_volume_endpoint()
        if endpoint:
            new_mute = not bool(endpoint.GetMute())
            endpoint.SetMute(new_mute, None)
            logger.info(f"Microphone mute toggled. New state: {new_mute}")
            return new_mute
    except Exception as e:
        logger.error(f"Failed to toggle mic mute: {e}")
        
    # Fallback to common Discord mute hotkey (Ctrl + Shift + M)
    execute_hotkey(["ctrl", "shift", "m"])
    return False


def get_system_telemetry() -> dict:
    """Returns live PC telemetry (CPU %, RAM %, audio states)."""
    try:
        cpu = int(psutil.cpu_percent(interval=None))
        ram = int(psutil.virtual_memory().percent)
    except Exception:
        cpu = 0
        ram = 0

    audio = get_master_volume()
    mic_muted = get_mic_mute()

    return {
        "cpu": cpu,
        "ram": ram,
        "volume": audio["volume"],
        "is_muted": audio["muted"],
        "is_mic_muted": mic_muted,
    }


def turn_off_screen() -> bool:
    """Puts monitors to sleep immediately without sleeping the PC."""
    logger.info("Turning off PC monitors (low-power standby)...")
    try:
        # WM_SYSCOMMAND = 0x0112, SC_MONITORPOWER = 0xF170, 2 = Off
        HWND_BROADCAST = 0xFFFF
        ctypes.windll.user32.SendMessageW(HWND_BROADCAST, 0x0112, 0xF170, 2)
        return True
    except Exception as e:
        logger.error(f"Failed to turn off screen: {e}")
        return False


def sleep_pc() -> bool:
    """Puts PC into sleep mode."""
    logger.info("Putting PC to sleep...")
    try:
        subprocess.Popen("rundll32.exe powrprof.dll,SetSuspendState 0,1,0", shell=True)
        return True
    except Exception as e:
        logger.error(f"Failed to sleep PC: {e}")
        return False


def execute_spotify_action(action: str, payload: dict | None = None) -> bool:
    """Executes a specialized Spotify desktop action on Windows."""
    if payload is None:
        payload = {}
    act = action.lower().strip()
    logger.info(f"Executing Spotify action: {act} with payload: {payload}")
    try:
        if act in ("play_uri", "playlist", "track", "album"):
            uri = payload.get("uri", "").strip()
            if not uri:
                return False
            if "open.spotify.com" in uri:
                try:
                    parts = uri.split("open.spotify.com/")[1].split("?")[0].split("/")
                    if len(parts) >= 2:
                        uri = f"spotify:{parts[0]}:{parts[1]}"
                except Exception:
                    pass
            logger.info(f"Opening Spotify URI: {uri}")
            os.startfile(uri)
            if payload.get("shuffle", False):
                time.sleep(0.6)
                execute_hotkey(["ctrl", "s"])
            if payload.get("auto_play", True):
                time.sleep(0.6)
                press_media_key("media_play_pause")
            return True
        elif act == "shuffle":
            return execute_hotkey(["ctrl", "s"])
        elif act == "repeat":
            return execute_hotkey(["ctrl", "r"])
        elif act == "play_pause":
            return press_media_key("media_play_pause")
        elif act == "next":
            return press_media_key("media_next")
        elif act == "prev":
            return press_media_key("media_prev")
        elif act == "like":
            return execute_hotkey(["alt", "shift", "b"])
        elif act == "open":
            os.startfile("spotify:")
            return True
        elif act == "close":
            subprocess.Popen("taskkill /f /im spotify.exe", shell=True)
            return True
        else:
            logger.warning(f"Unknown Spotify action: {act}")
            return False
    except Exception as e:
        logger.error(f"Spotify action failed: {e}")
        return False


def execute_discord_action(action: str, payload: dict | None = None) -> bool:
    """Executes a specialized Discord desktop action on Windows."""
    if payload is None:
        payload = {}
    act = action.lower().strip()
    logger.info(f"Executing Discord action: {act} with payload: {payload}")
    try:
        if act in ("join_voice", "open_channel", "channel"):
            url = payload.get("channel_url", "").strip()
            if not url:
                return False
            if "discord.com/channels/" in url:
                try:
                    channel_path = url.split("discord.com/channels/")[1].split("?")[0]
                    url = f"discord://-/channels/{channel_path}"
                except Exception:
                    pass
            elif not url.startswith("discord://") and not url.startswith("http"):
                url = f"discord://-/channels/{url}"
            logger.info(f"Opening Discord channel: {url}")
            os.startfile(url)
            return True
        elif act == "toggle_mute":
            execute_hotkey(["ctrl", "shift", "m"])
            toggle_mic_mute()
            return True
        elif act == "toggle_deafen":
            return execute_hotkey(["ctrl", "shift", "d"])
        elif act == "open":
            os.startfile("discord:")
            return True
        elif act == "close":
            subprocess.Popen("taskkill /im discord.exe", shell=True)
            return True
        else:
            logger.warning(f"Unknown Discord action: {act}")
            return False
    except Exception as e:
        logger.error(f"Discord action failed: {e}")
        return False

