"""
VibeDeck Discovery Service
Broadcasts UDP beacons on local network so Android devices can auto-discover the server.
"""

import socket
import json
import time
import threading
import logging

logger = logging.getLogger("VibeDeckDiscovery")

DISCOVERY_PORT = 8766
DEFAULT_WS_PORT = 8765


def get_local_ip() -> str:
    """Finds the local IPv4 address connected to the LAN."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Doesn't need to be reachable, just triggers OS routing table lookup
        s.connect(('8.8.8.8', 1))
        ip = s.getsockname()[0]
    except Exception:
        ip = '127.0.0.1'
    finally:
        s.close()
    return ip


class DiscoveryBeacon:
    def __init__(self, ws_port: int = DEFAULT_WS_PORT):
        self.ws_port = ws_port
        self.running = False
        self._thread = None
        self.hostname = socket.gethostname()

    def start(self):
        self.running = True
        self._thread = threading.Thread(target=self._broadcast_loop, daemon=True)
        self._thread.start()
        logger.info(f"UDP Discovery beacon started on port {DISCOVERY_PORT} (announcing WS port {self.ws_port})")

    def stop(self):
        self.running = False
        if self._thread:
            self._thread.join(timeout=1.0)
            logger.info("UDP Discovery beacon stopped.")

    def _broadcast_loop(self):
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        sock.settimeout(1.0)

        while self.running:
            try:
                local_ip = get_local_ip()
                payload = {
                    "service": "vibedeck",
                    "version": "1.0",
                    "host": self.hostname,
                    "ip": local_ip,
                    "port": self.ws_port,
                    "timestamp": time.time()
                }
                data = json.dumps(payload).encode("utf-8")
                
                # Broadcast to global broadcast
                sock.sendto(data, ('<broadcast>', DISCOVERY_PORT))
                
                # Also try direct 255.255.255.255
                sock.sendto(data, ('255.255.255.255', DISCOVERY_PORT))
            except Exception as e:
                logger.debug(f"Broadcast error: {e}")

            time.sleep(1.5)

        sock.close()
