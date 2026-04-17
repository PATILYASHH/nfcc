"""Message models for WebSocket communication."""

import json
import uuid
from dataclasses import dataclass, field, asdict
from typing import Optional


@dataclass
class AuthMessage:
    token: str
    device_name: str
    type: str = "auth"

    def to_json(self) -> str:
        return json.dumps({"type": self.type, "token": self.token, "deviceName": self.device_name})


@dataclass
class AuthResult:
    success: bool
    pc_name: str
    type: str = "auth_result"

    def to_json(self) -> str:
        return json.dumps({"type": self.type, "success": self.success, "pcName": self.pc_name})


@dataclass
class ActionMessage:
    action: str
    params: dict = field(default_factory=dict)
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    type: str = "action"

    @classmethod
    def from_dict(cls, data: dict) -> Optional["ActionMessage"]:
        action = data.get("action")
        if not action or not isinstance(action, str):
            return None
        return cls(
            action=action,
            params=data.get("params", {}),
            id=data.get("id", str(uuid.uuid4())),
        )


@dataclass
class ActionResult:
    id: str
    success: bool
    error: Optional[str] = None
    message: Optional[str] = None
    data: Optional[dict] = None
    type: str = "action_result"

    def to_json(self) -> str:
        payload = {
            "type": self.type,
            "id": self.id,
            "success": self.success,
            "error": self.error,
            "message": self.message,
        }
        if self.data:
            payload["data"] = self.data
        return json.dumps(payload)


def parse_message(raw: str) -> Optional[dict]:
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return None
