"""
VibeDeck Host Server (v2.0)
Async WebSocket Server with native Windows integration:
- System media & hotkeys
- Core Audio speaker and microphone mute states
- Low-latency mouse trackpad and keyboard typing
- Live PC telemetry (CPU %, RAM %, volume)
- Screen-off, sleep, and system power commands
- UDP Auto-discovery beacon (port 8766)
"""

import asyncio
import json
import logging
import os
import socket
import sys
import threading
import time
import websockets

import actions
from discovery import DiscoveryBeacon

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("VibeDeckServer")

WS_HOST = "0.0.0.0"
WS_PORT = 8765
PROFILES_FILE = os.path.join(os.path.dirname(__file__), "profiles.json")

connected_clients = set()
_server_instance = None
_telemetry_running = True


def get_local_ip() -> str:
    """Returns local LAN IP address."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = "127.0.0.1"
    finally:
        s.close()
    return ip


def load_profiles() -> dict:
    if os.path.exists(PROFILES_FILE):
        try:
            with open(PROFILES_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"Failed to load profiles.json: {e}")
    return {"profiles": []}


def save_profiles(data: dict) -> bool:
    try:
        with open(PROFILES_FILE, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
        return True
    except Exception as e:
        logger.error(f"Failed to save profiles.json: {e}")
        return False


def print_banner(local_ip: str):
    print("=" * 60)
    print("             [+]   V I B E D E C K   S E R V E R   [+]         ")
    print("=" * 60)
    print(f"  Status        : ONLINE & LISTENING")
    print(f"  Local IP      : {local_ip}")
    print(f"  WebSocket Port: {WS_PORT}")
    print(f"  UDP Discovery : Active on port 8766")
    print(f"  Full WS URL   : ws://{local_ip}:{WS_PORT}")
    print("=" * 60)
    
    try:
        import qrcode
        qr = qrcode.QRCode(border=1)
        qr.add_data(f"vibedeck://{local_ip}:{WS_PORT}")
        print("\nScan with VibeDeck App to pair instantly:")
        qr.print_ascii(invert=True)
    except Exception:
        pass
    print("-" * 60)
    print("Ready for connections! Press Ctrl+C to stop.\n")


def free_port(port: int = WS_PORT):
    """Kills any previous dead process holding the port so server always starts."""
    try:
        import psutil
        for proc in psutil.process_iter(['pid', 'name']):
            try:
                for conn in proc.net_connections(kind='inet'):
                    if conn.laddr.port == port and conn.status == psutil.CONN_LISTEN:
                        if proc.pid != os.getpid():
                            logger.info(f"Freeing port {port}: terminating old process {proc.pid} ({proc.name()})")
                            proc.kill()
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass
    except Exception as e:
        logger.debug(f"free_port check: {e}")


async def broadcast_state(data: dict):
    """Broadcasts a message to all connected mobile clients."""
    if not connected_clients:
        return
    payload = json.dumps(data)
    dead_clients = []
    for client in list(connected_clients):
        try:
            await client.send(payload)
        except Exception:
            dead_clients.append(client)
    for dc in dead_clients:
        connected_clients.discard(dc)


async def telemetry_loop():
    """Periodically broadcasts PC telemetry (CPU, RAM, Audio states) every 2 seconds."""
    global _telemetry_running
    while _telemetry_running:
        try:
            await asyncio.sleep(2.0)
            if connected_clients:
                stats = actions.get_system_telemetry()
                await broadcast_state({
                    "type": "TELEMETRY",
                    **stats
                })
        except asyncio.CancelledError:
            break
        except Exception as e:
            logger.debug(f"Telemetry loop exception: {e}")


async def handle_message(websocket, message_str: str):
    try:
        msg = json.loads(message_str)
    except Exception:
        await websocket.send(json.dumps({"type": "ERROR", "message": "Invalid JSON"}))
        return

    msg_type = msg.get("type")
    
    if msg_type == "HELLO":
        client_name = msg.get("client_name", "Unknown Android")
        logger.info(f"Handshake from client: {client_name}")
        telemetry = actions.get_system_telemetry()
        profiles_data = load_profiles()
        installed_apps = actions.get_installed_apps()
        response = {
            "type": "HELLO_ACK",
            "server": "VibeDeck Host",
            "hostname": socket.gethostname(),
            "volume": telemetry.get("volume", 50),
            "muted": telemetry.get("is_muted", False),
            "is_mic_muted": telemetry.get("is_mic_muted", False),
            "cpu": telemetry.get("cpu", 0),
            "ram": telemetry.get("ram", 0),
            "profiles": profiles_data.get("profiles", []),
            "apps": installed_apps
        }
        await websocket.send(json.dumps(response))

    elif msg_type == "GET_APPS":
        installed_apps = actions.get_installed_apps()
        await websocket.send(json.dumps({
            "type": "APPS_DATA",
            "apps": installed_apps
        }))

    elif msg_type == "TRACKPAD_MOVE":
        dx = float(msg.get("dx", 0))
        dy = float(msg.get("dy", 0))
        actions.mouse_move(dx, dy)

    elif msg_type == "MOUSE_CLICK":
        button = str(msg.get("button", "left"))
        double = bool(msg.get("double", False))
        actions.mouse_click(button=button, double=double)

    elif msg_type == "MOUSE_SCROLL":
        dy = float(msg.get("dy", 0))
        actions.mouse_scroll(dy)

    elif msg_type == "KEY_TYPE":
        text = str(msg.get("text", ""))
        actions.type_text(text)

    elif msg_type == "KEY_PRESS":
        key = str(msg.get("key", ""))
        actions.press_special_key(key)

    elif msg_type == "KEY_DOWN":
        key = str(msg.get("key", ""))
        actions.key_down(key)

    elif msg_type == "KEY_UP":
        key = str(msg.get("key", ""))
        actions.key_up(key)

    elif msg_type == "MIC_MUTE":
        new_state = actions.toggle_mic_mute()
        await broadcast_state({
            "type": "STATE_UPDATE",
            "is_mic_muted": new_state
        })

    elif msg_type == "MUTE":
        new_state = actions.toggle_master_mute()
        vol_info = actions.get_master_volume()
        await broadcast_state({
            "type": "STATE_UPDATE",
            "volume": vol_info.get("volume", 50),
            "muted": new_state
        })

    elif msg_type == "POWER_ACTION":
        action = str(msg.get("action", "")).lower()
        if action == "screen_off":
            actions.turn_off_screen()
        elif action == "sleep":
            actions.sleep_pc()
        elif action == "lock":
            actions.execute_system_command("lock")

    elif msg_type == "ACTION":
        action_id = msg.get("action_id", "")
        action_kind = msg.get("action_kind", "")
        payload = msg.get("payload", {})
        logger.info(f"Executing action [{action_kind}]: {payload}")
        
        success = False
        if action_kind == "media":
            success = actions.press_media_key(payload.get("key", ""))
        elif action_kind == "hotkey":
            success = actions.execute_hotkey(payload.get("keys", []))
        elif action_kind == "app":
            success = actions.launch_application(payload.get("target", ""))
        elif action_kind == "url":
            success = actions.open_url(payload.get("url", ""))
        elif action_kind == "system":
            success = actions.execute_system_command(payload.get("command", ""))
        elif action_kind == "volume":
            success = actions.set_master_volume(int(payload.get("level", 50)))
        elif action_kind == "mute":
            actions.toggle_master_mute()
            success = True
        elif action_kind == "mic_mute":
            actions.toggle_mic_mute()
            success = True
        elif action_kind == "power":
            cmd = payload.get("command", "screen_off")
            if cmd == "screen_off":
                actions.turn_off_screen()
            elif cmd == "sleep":
                actions.sleep_pc()
            elif cmd == "lock":
                actions.execute_system_command("lock")
            success = True
        elif action_kind == "type":
            success = actions.type_text(payload.get("text", ""))
        else:
            logger.warning(f"Unknown action kind: {action_kind}")

        # Send fast ACK with current states
        telemetry = actions.get_system_telemetry()
        ack = {
            "type": "ACTION_ACK",
            "action_id": action_id,
            "status": "success" if success else "failed",
            "volume": telemetry.get("volume", 50),
            "muted": telemetry.get("is_muted", False),
            "is_mic_muted": telemetry.get("is_mic_muted", False),
            "cpu": telemetry.get("cpu", 0),
            "ram": telemetry.get("ram", 0),
        }
        await websocket.send(json.dumps(ack))

    elif msg_type == "GET_PROFILES":
        profiles_data = load_profiles()
        await websocket.send(json.dumps({
            "type": "PROFILES_DATA",
            "profiles": profiles_data.get("profiles", [])
        }))

    elif msg_type == "SAVE_PROFILES":
        new_profiles = msg.get("profiles", [])
        saved = save_profiles({"profiles": new_profiles})
        await websocket.send(json.dumps({
            "type": "SAVE_PROFILES_ACK",
            "status": "success" if saved else "failed"
        }))

    elif msg_type == "PING":
        await websocket.send(json.dumps({"type": "PONG", "time": msg.get("time")}))


async def client_handler(websocket):
    client_ip = websocket.remote_address[0]
    logger.info(f"Device connected from {client_ip}")
    connected_clients.add(websocket)
    try:
        async for message in websocket:
            await handle_message(websocket, message)
    except websockets.exceptions.ConnectionClosed:
        logger.info(f"Device {client_ip} disconnected.")
    finally:
        connected_clients.discard(websocket)


async def main():
    global _telemetry_running
    local_ip = get_local_ip()
    beacon = DiscoveryBeacon(ws_port=WS_PORT)
    beacon.start()
    
    print_banner(local_ip)

    # Free port 8765 if lingering
    free_port(WS_PORT)
    await asyncio.sleep(0.3)

    telemetry_task = asyncio.create_task(telemetry_loop())

    try:
        async with websockets.serve(client_handler, WS_HOST, WS_PORT):
            await asyncio.Future()  # Run forever
    except (KeyboardInterrupt, asyncio.CancelledError):
        pass
    finally:
        _telemetry_running = False
        telemetry_task.cancel()
        beacon.stop()
        logger.info("Server terminated.")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nExiting VibeDeck Server.")
