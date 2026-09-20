"""
VibeDeck Server - Windows Host Companion
Accepts WebSocket connections from VibeDeck Android app to execute system/media actions.
"""

import asyncio
import json
import logging
import os
import sys
import socket
from pathlib import Path
import websockets

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

import actions
from discovery import DiscoveryBeacon, get_local_ip

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S"
)
logger = logging.getLogger("VibeDeckServer")

WS_HOST = "0.0.0.0"
WS_PORT = 8765
PROFILES_FILE = Path(__file__).parent / "profiles.json"

# Connected client sockets
connected_clients = set()


def load_profiles() -> dict:
    if PROFILES_FILE.exists():
        try:
            with open(PROFILES_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"Error loading profiles: {e}")
    return {"profiles": []}


def save_profiles(data: dict) -> bool:
    try:
        with open(PROFILES_FILE, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
        return True
    except Exception as e:
        logger.error(f"Error saving profiles: {e}")
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
    
    # Try printing QR code in terminal safely
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
        vol_info = actions.get_master_volume()
        profiles_data = load_profiles()
        installed_apps = actions.get_installed_apps()
        response = {
            "type": "HELLO_ACK",
            "server": "VibeDeck Host",
            "hostname": socket.gethostname(),
            "volume": vol_info.get("volume", 50),
            "muted": vol_info.get("muted", False),
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
        elif action_kind == "type":
            success = actions.type_text(payload.get("text", ""))
        else:
            logger.warning(f"Unknown action kind: {action_kind}")

        # Send fast ACK
        vol_info = actions.get_master_volume()
        ack = {
            "type": "ACTION_ACK",
            "action_id": action_id,
            "status": "success" if success else "failed",
            "volume": vol_info.get("volume", 50),
            "muted": vol_info.get("muted", False)
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
    local_ip = get_local_ip()
    beacon = DiscoveryBeacon(ws_port=WS_PORT)
    beacon.start()
    
    print_banner(local_ip)

    # Ensure port 8765 is not held by a previous zombie instance
    free_port(WS_PORT)
    await asyncio.sleep(0.3)

    try:
        async with websockets.serve(client_handler, WS_HOST, WS_PORT):
            await asyncio.Future()  # Run forever
    except (KeyboardInterrupt, asyncio.CancelledError):
        pass
    finally:
        beacon.stop()
        logger.info("Server terminated.")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nExiting VibeDeck Server.")
