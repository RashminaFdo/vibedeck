"""
VibeDeck Windows System Tray Application
Runs quietly in the background next to the Windows clock.
Provides:
- Real-time status and connected client count
- Instant QR Code pairing dialog
- 1-Click USB Cable Mode (ADB Reverse)
- Start / Stop / Restart Server
- Windows Auto-Start Toggle
- Custom Logo support (assets/logo.png)
"""

import asyncio
import os
import subprocess
import sys
import threading
import time
import webbrowser

import pystray
from PIL import Image, ImageDraw

import actions
from discovery import DiscoveryBeacon
import server

# Directory configuration
SERVER_DIR = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.join(SERVER_DIR, "assets")
LOGO_PATH = os.path.join(ASSETS_DIR, "logo.png")
STARTUP_DIR = os.path.expandvars(r"%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup")
STARTUP_LNK = os.path.join(STARTUP_DIR, "VibeDeckServer.lnk")

# Global state
server_thread = None
server_loop = None
server_running = False
tray_icon = None
beacon_instance = None


def create_default_icon_image(size=(64, 64), color=(0, 242, 254)) -> Image.Image:
    """Generates a stylish neon VibeDeck logo icon if custom logo.png is not found."""
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    w, h = size
    
    # Outer dark rounded pill
    draw.rounded_rectangle([2, 2, w - 3, h - 3], radius=14, fill=(18, 20, 32, 255), outline=color, width=2)
    
    # Neon "V" shape in center
    points = [
        (w * 0.24, h * 0.28),
        (w * 0.50, h * 0.74),
        (w * 0.76, h * 0.28),
        (w * 0.64, h * 0.28),
        (w * 0.50, h * 0.56),
        (w * 0.36, h * 0.28),
    ]
    draw.polygon(points, fill=color)
    
    # Small green status dot
    draw.ellipse([w - 16, h - 16, w - 4, h - 4], fill=(0, 255, 136, 255), outline=(10, 10, 15, 255), width=2)
    return img


def get_tray_icon_image() -> Image.Image:
    """Loads custom logo.png if present, otherwise returns neon default."""
    if os.path.exists(LOGO_PATH):
        try:
            custom_img = Image.open(LOGO_PATH).convert("RGBA")
            return custom_img.resize((64, 64), Image.Resampling.LANCZOS)
        except Exception as e:
            print(f"Error loading {LOGO_PATH}: {e}")
    return create_default_icon_image()


def run_async_server():
    """Runs WebSocket server in its own asyncio loop on a background thread."""
    global server_loop, server_running, beacon_instance
    server_loop = asyncio.new_event_loop()
    asyncio.set_event_loop(server_loop)
    server_running = True
    
    # Start UDP discovery beacon
    beacon_instance = DiscoveryBeacon(ws_port=server.WS_PORT)
    beacon_instance.start()
    
    # Free port 8765 if lingering
    server.free_port(server.WS_PORT)
    
    async def _runner():
        import websockets
        telemetry_task = server_loop.create_task(server.telemetry_loop())
        try:
            async with websockets.serve(server.client_handler, server.WS_HOST, server.WS_PORT):
                while server_running:
                    await asyncio.sleep(1.0)
        except asyncio.CancelledError:
            pass
        finally:
            telemetry_task.cancel()
            if beacon_instance:
                beacon_instance.stop()

    try:
        server_loop.run_until_complete(_runner())
    except Exception as e:
        print(f"Server loop exited: {e}")
    finally:
        server_running = False


def start_server(icon=None, item=None):
    global server_thread, server_running
    if server_running:
        return
    server_thread = threading.Thread(target=run_async_server, daemon=True)
    server_thread.start()
    time.sleep(0.5)
    if tray_icon:
        tray_icon.title = f"VibeDeck Host (Online : {server.get_local_ip()})"


def stop_server(icon=None, item=None):
    global server_running, server_loop, beacon_instance
    if not server_running:
        return
    server_running = False
    if beacon_instance:
        beacon_instance.stop()
    if server_loop and server_loop.is_running():
        server_loop.call_soon_threadsafe(server_loop.stop)
    if tray_icon:
        tray_icon.title = "VibeDeck Host (Stopped)"


def restart_server(icon=None, item=None):
    stop_server()
    time.sleep(1.0)
    start_server()


def setup_usb_mode(icon=None, item=None):
    """Executes ADB reverse for USB mode in a thread."""
    def _do_adb():
        try:
            res = subprocess.run(["adb", "reverse", "tcp:8765", "tcp:8765"], capture_output=True, text=True, timeout=5)
            if res.returncode == 0:
                show_message_window("USB Mode Ready!", "USB Cable Mode (ADB Reverse) is ACTIVE!\n\nConnect phone via USB and select 'USB Cable Mode' in the app.\nHost: 127.0.0.1:8765")
            else:
                show_message_window("USB Setup Result", f"Output:\n{res.stdout}\n{res.stderr}\n\nMake sure USB Debugging is ON in Android Settings.")
        except FileNotFoundError:
            show_message_window("ADB Not Found", "The 'adb' command was not found in PATH.\nInstall Android Platform Tools or connect over Wi-Fi.")
        except Exception as e:
            show_message_window("USB Setup Error", str(e))
    threading.Thread(target=_do_adb, daemon=True).start()


def show_message_window(title: str, message: str):
    """Shows a quick popup message."""
    def _gui():
        import tkinter as tk
        from tkinter import messagebox
        root = tk.Tk()
        root.withdraw()
        root.attributes("-topmost", True)
        messagebox.showinfo(title, message)
        root.destroy()
    threading.Thread(target=_gui, daemon=True).start()


def open_qr_window(icon=None, item=None):
    """Opens a sleek modern window with pairing QR code and connection details."""
    def _gui():
        import tkinter as tk
        from PIL import ImageTk
        import qrcode

        local_ip = server.get_local_ip()
        ws_url = f"ws://{local_ip}:{server.WS_PORT}"
        pairing_uri = f"vibedeck://{local_ip}:{server.WS_PORT}"

        # Generate QR code PIL Image
        qr = qrcode.QRCode(box_size=7, border=2)
        qr.add_data(pairing_uri)
        qr_img = qr.make_image(fill_color="#00f2fe", back_color="#121420").convert("RGBA")

        win = tk.Tk()
        win.title("VibeDeck - Pair with Phone")
        win.configure(bg="#0d0e15")
        win.resizable(False, False)
        win.attributes("-topmost", True)

        # Container
        frame = tk.Frame(win, bg="#0d0e15", padx=25, pady=20)
        frame.pack()

        # Title
        title_label = tk.Label(frame, text="VIBEDECK PAIRING", font=("Segoe UI", 16, "bold"), fg="#00f2fe", bg="#0d0e15")
        title_label.pack(pady=(0, 6))

        subtitle = tk.Label(frame, text="Scan with VibeDeck Mobile App to connect instantly", font=("Segoe UI", 9), fg="#8a8f9d", bg="#0d0e15")
        subtitle.pack(pady=(0, 15))

        # QR Image
        tk_img = ImageTk.PhotoImage(qr_img, master=win)
        img_label = tk.Label(frame, image=tk_img, bg="#121420", bd=2, relief="solid")
        img_label.image = tk_img
        img_label.pack(pady=(0, 15))

        # Info Box
        info_frame = tk.Frame(frame, bg="#181a24", padx=12, pady=10, relief="flat")
        info_frame.pack(fill="x", pady=(0, 15))

        ip_lbl = tk.Label(info_frame, text=f"Local IP: {local_ip}", font=("Segoe UI", 10, "bold"), fg="#ffffff", bg="#181a24")
        ip_lbl.pack(anchor="w")

        ws_lbl = tk.Label(info_frame, text=f"Port: {server.WS_PORT} (WebSocket)", font=("Segoe UI", 9), fg="#4facfe", bg="#181a24")
        ws_lbl.pack(anchor="w")

        # Buttons
        btn_row = tk.Frame(frame, bg="#0d0e15")
        btn_row.pack(fill="x")

        def copy_url():
            win.clipboard_clear()
            win.clipboard_append(ws_url)
            copy_btn.config(text="✓ Copied!", fg="#00ff88")

        copy_btn = tk.Button(btn_row, text="Copy WS URL", font=("Segoe UI", 9, "bold"), bg="#1f2233", fg="#ffffff", activebackground="#2c3047", relief="flat", padx=10, pady=5, command=copy_url)
        copy_btn.pack(side="left", expand=True, fill="x", padx=(0, 5))

        def trigger_usb():
            setup_usb_mode()
            usb_btn.config(text="✓ USB Started", fg="#00ff88")

        usb_btn = tk.Button(btn_row, text="Activate USB", font=("Segoe UI", 9, "bold"), bg="#1f2233", fg="#4facfe", activebackground="#2c3047", relief="flat", padx=10, pady=5, command=trigger_usb)
        usb_btn.pack(side="right", expand=True, fill="x", padx=(5, 0))

        win.mainloop()

    threading.Thread(target=_gui, daemon=True).start()


def is_startup_enabled() -> bool:
    return os.path.exists(STARTUP_LNK)


def toggle_startup(icon=None, item=None):
    """Toggles VibeDeck auto-start on Windows boot."""
    if is_startup_enabled():
        try:
            os.remove(STARTUP_LNK)
            show_message_window("Auto-Start", "VibeDeck will no longer start automatically with Windows.")
        except Exception as e:
            show_message_window("Error", str(e))
    else:
        try:
            # Create shortcut in Startup folder pointing to start_silent.vbs
            vbs_path = os.path.join(SERVER_DIR, "start_silent.vbs")
            ps_cmd = f'$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut("{STARTUP_LNK}"); $s.TargetPath = "wscript.exe"; $s.Arguments = "`"{vbs_path}`""; $s.WorkingDirectory = "{SERVER_DIR}"; $s.Save()'
            subprocess.run(["powershell", "-NoProfile", "-Command", ps_cmd], check=True)
            show_message_window("Auto-Start Enabled", "VibeDeck is now configured to start quietly with Windows!")
        except Exception as e:
            show_message_window("Error", str(e))


def open_profiles_folder(icon=None, item=None):
    try:
        os.startfile(SERVER_DIR)
    except Exception as e:
        print(e)


def exit_app(icon=None, item=None):
    stop_server()
    if tray_icon:
        tray_icon.stop()
    sys.exit(0)


def get_menu_items():
    """Generates dynamic context menu items for tray icon."""
    local_ip = server.get_local_ip()
    status_text = f"🟢 Online: {local_ip}:{server.WS_PORT}" if server_running else "🔴 Server: Stopped"
    clients_count = len(server.connected_clients)
    clients_text = f"👥 Connected Devices: {clients_count}"

    return [
        pystray.MenuItem(status_text, lambda icon, item: None, enabled=False),
        pystray.MenuItem(clients_text, lambda icon, item: None, enabled=False),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem("📱 QR Code & Pairing Info", open_qr_window, default=True),
        pystray.MenuItem("🔌 Activate USB Mode (ADB Reverse)", setup_usb_mode),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem("▶️ Start Server", start_server, visible=lambda item: not server_running),
        pystray.MenuItem("⏹️ Stop Server", stop_server, visible=lambda item: server_running),
        pystray.MenuItem("🔄 Restart Server", restart_server),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem("🚀 Run on Windows Startup", toggle_startup, checked=lambda item: is_startup_enabled()),
        pystray.MenuItem("📁 Open Config Folder", open_profiles_folder),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem("❌ Exit VibeDeck", exit_app),
    ]


def main():
    global tray_icon

    # Create assets folder if not exists
    os.makedirs(ASSETS_DIR, exist_ok=True)

    # Start server in background thread immediately
    start_server()

    # Create and run System Tray Icon
    icon_image = get_tray_icon_image()
    tray_icon = pystray.Icon(
        name="VibeDeck",
        icon=icon_image,
        title=f"VibeDeck Host (:8765)",
        menu=pystray.Menu(get_menu_items)
    )

    print("VibeDeck System Tray App running.")
    tray_icon.run()


if __name__ == "__main__":
    main()
