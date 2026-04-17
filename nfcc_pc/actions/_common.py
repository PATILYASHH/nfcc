"""Shared helpers for action modules."""

import ctypes
import time
from typing import Any, Dict, Tuple

# (success, message, optional_data)
ActionResult = Tuple[bool, str, Dict[str, Any]]

user32 = ctypes.windll.user32


def ok(msg: str, data: Dict[str, Any] | None = None) -> ActionResult:
    return True, msg, data or {}


def fail(msg: str) -> ActionResult:
    return False, msg, {}


def key_press(*keys: int) -> None:
    """Press and release a combination of virtual-key codes."""
    for k in keys:
        user32.keybd_event(k, 0, 0, 0)
    time.sleep(0.05)
    for k in reversed(keys):
        user32.keybd_event(k, 0, 2, 0)


# Virtual-key code map for friendly names used by sendKeys / typeKeys
VK_MAP: Dict[str, int] = {
    "ctrl": 0x11, "control": 0x11,
    "alt": 0xA4, "shift": 0xA0,
    "win": 0x5B, "super": 0x5B,
    "esc": 0x1B, "escape": 0x1B,
    "tab": 0x09, "enter": 0x0D, "return": 0x0D,
    "space": 0x20, "backspace": 0x08, "delete": 0x2E,
    "up": 0x26, "down": 0x28, "left": 0x25, "right": 0x27,
    "home": 0x24, "end": 0x23,
    "pageup": 0x21, "pagedown": 0x22,
    "f1": 0x70, "f2": 0x71, "f3": 0x72, "f4": 0x73,
    "f5": 0x74, "f6": 0x75, "f7": 0x76, "f8": 0x77,
    "f9": 0x78, "f10": 0x79, "f11": 0x7A, "f12": 0x7B,
    "capslock": 0x14, "printscreen": 0x2C,
    "volumeup": 0xAF, "volumedown": 0xAE, "volumemute": 0xAD,
    "medianext": 0xB0, "mediaprev": 0xB1,
    "mediastop": 0xB2, "mediaplay": 0xB3,
}


def resolve_key(key: Any) -> int | None:
    """Turn 'ctrl' or 0x11 or 'A' into a virtual-key code."""
    if isinstance(key, int):
        return key
    if not isinstance(key, str):
        return None
    k = key.strip().lower()
    if k in VK_MAP:
        return VK_MAP[k]
    if len(key) == 1:
        return ord(key.upper())
    # Allow '0x41' style strings
    try:
        return int(key, 0)
    except ValueError:
        return None
