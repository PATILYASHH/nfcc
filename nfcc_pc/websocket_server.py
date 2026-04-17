"""WebSocket server for receiving commands from the NFCC mobile app."""

import asyncio
import json
import logging
import socket
from typing import Optional, Set

import websockets
from websockets.asyncio.server import ServerConnection

from action_executor import execute_action
from models import ActionMessage, ActionResult, AuthResult, parse_message

logger = logging.getLogger("nfcc")


class NfccWebSocketServer:
    def __init__(self, config: dict, on_status_change=None, on_action_executed=None):
        self.config = config
        self.port = config.get("port", 9876)
        self.token = config.get("pairing_token", "")
        self.on_status_change = on_status_change
        self.on_action_executed = on_action_executed
        self._server = None
        self._authenticated_clients: Set[ServerConnection] = set()

    async def start(self):
        self._server = await websockets.serve(
            self._handle_client,
            "0.0.0.0",
            self.port,
        )
        logger.info(f"WebSocket server running on port {self.port}")
        if self.on_status_change:
            self.on_status_change(f"Listening on port {self.port}")

    async def stop(self):
        if self._server:
            self._server.close()
            await self._server.wait_closed()
            logger.info("WebSocket server stopped")

    @property
    def connected_count(self) -> int:
        return len(self._authenticated_clients)

    async def _handle_client(self, websocket: ServerConnection):
        client_addr = websocket.remote_address
        logger.info(f"New connection from {client_addr}")
        authenticated = False

        try:
            async for raw_message in websocket:
                data = parse_message(raw_message)
                if data is None:
                    continue

                msg_type = data.get("type")

                # Authentication
                if msg_type == "auth":
                    if data.get("token") == self.token:
                        authenticated = True
                        self._authenticated_clients.add(websocket)
                        device_name = data.get("deviceName", "Unknown")
                        logger.info(f"Device authenticated: {device_name} from {client_addr}")
                        result = AuthResult(
                            success=True,
                            pc_name=socket.gethostname(),
                        )
                        await websocket.send(result.to_json())
                        if self.on_status_change:
                            self.on_status_change(f"Connected: {device_name}")
                    else:
                        result = AuthResult(success=False, pc_name="")
                        await websocket.send(result.to_json())
                        logger.warning(f"Auth failed from {client_addr}")
                        break

                # Ping/pong keepalive (requires auth)
                elif msg_type == "ping" and authenticated:
                    await websocket.send(json.dumps({"type": "pong"}))

                # Action execution
                elif msg_type == "action" and authenticated:
                    action_msg = ActionMessage.from_dict(data)
                    if action_msg is None:
                        await websocket.send(json.dumps({"type": "action_result", "success": False, "error": "Invalid action message"}))
                        continue
                    logger.info(f"Executing: {action_msg.action} with params {action_msg.params}")

                    success, message, data = await asyncio.to_thread(
                        execute_action, action_msg.action, action_msg.params
                    )

                    result = ActionResult(
                        id=action_msg.id,
                        success=success,
                        error=None if success else message,
                        message=message if success else None,
                        data=data or None,
                    )
                    await websocket.send(result.to_json())
                    logger.info(f"Action result: {action_msg.action} -> {'OK' if success else message}")

                    if self.on_action_executed:
                        self.on_action_executed(action_msg.action, success, message)

                elif not authenticated:
                    logger.warning(f"Unauthenticated message from {client_addr}")
                    break

        except websockets.exceptions.ConnectionClosed:
            logger.info(f"Connection closed: {client_addr}")
        except Exception as e:
            logger.error(f"Error handling client {client_addr}: {e}")
        finally:
            self._authenticated_clients.discard(websocket)
            if self.on_status_change:
                count = self.connected_count
                status = f"{count} device(s) connected" if count > 0 else "Waiting for connection..."
                self.on_status_change(status)
