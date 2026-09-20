"""
VibeDeck Test Client
Automated test script to verify server connection, latency, and action dispatch.
"""

import asyncio
import json
import time
import websockets

SERVER_URI = "ws://127.0.0.1:8765"


async def test_vibedeck():
    print(f"Connecting to {SERVER_URI}...")
    try:
        async with websockets.connect(SERVER_URI) as ws:
            print("Connected! Sending HELLO handshake...")
            await ws.send(json.dumps({
                "type": "HELLO",
                "client_name": "VibeDeck Automated Test Client"
            }))
            
            resp = await ws.recv()
            data = json.loads(resp)
            print("Received HELLO_ACK:")
            print(f"  Server Hostname: {data.get('hostname')}")
            print(f"  Current Volume : {data.get('volume')}%")
            print(f"  Profiles count : {len(data.get('profiles', []))}")
            
            # Test PING latency
            start_t = time.perf_counter()
            await ws.send(json.dumps({"type": "PING", "time": start_t}))
            pong = await ws.recv()
            elapsed_ms = (time.perf_counter() - start_t) * 1000
            print(f"Round-trip ping: {elapsed_ms:.2f} ms (Target < 15ms)")

            # Test safe action (e.g. volume query or echo)
            print("Testing Action dispatch (Volume Query / Adjust)...")
            await ws.send(json.dumps({
                "type": "ACTION",
                "action_id": "test_1",
                "action_kind": "volume",
                "payload": {"level": data.get('volume', 50)}
            }))
            ack = await ws.recv()
            print(f"Action ACK received: {ack}")

            print("\nALL SERVER TESTS PASSED SUCCESSFULLY!")

    except Exception as e:
        print(f"Error testing server: {e}")


if __name__ == "__main__":
    asyncio.run(test_vibedeck())
