"""Keyboard typing, keystrokes and mouse input."""

import ctypes
import subprocess
import time

from ._common import ActionResult, fail, key_press, ok, resolve_key, user32


# ── Keyboard ────────────────────────────────────────────────────────────────

def type_text(params: dict) -> ActionResult:
    """Type text by pasting from clipboard — handles Unicode reliably."""
    text = params.get("text") or ""
    if not text:
        return fail("No text")
    subprocess.run(["clip"], input=text.encode("utf-16le"), check=False)
    time.sleep(0.05)
    key_press(0x11, 0x56)  # Ctrl+V
    return ok(f"Typed {len(text)} chars")


def send_keys(params: dict) -> ActionResult:
    """Send a key combo.

    Accepts either `keys: [int|str]` (list) or `combo: "ctrl+shift+s"`.
    """
    combo = params.get("combo")
    keys = params.get("keys")

    if combo:
        keys = [k.strip() for k in str(combo).split("+") if k.strip()]

    if not keys:
        # Fallback: type free text via clipboard
        text = params.get("text", "")
        if text:
            return type_text({"text": text})
        return fail("No keys, combo or text")

    resolved = [resolve_key(k) for k in keys]
    if any(v is None for v in resolved):
        return fail(f"Unknown key in {keys}")

    key_press(*[v for v in resolved if v is not None])
    return ok(f"Keys sent: {keys}")


# ── Common editing shortcuts (syntactic sugar) ──────────────────────────────

def copy_selection(_: dict) -> ActionResult:
    key_press(0x11, 0x43)  # Ctrl+C
    return ok("Copied")


def paste(_: dict) -> ActionResult:
    key_press(0x11, 0x56)  # Ctrl+V
    return ok("Pasted")


def cut_selection(_: dict) -> ActionResult:
    key_press(0x11, 0x58)  # Ctrl+X
    return ok("Cut")


def select_all(_: dict) -> ActionResult:
    key_press(0x11, 0x41)  # Ctrl+A
    return ok("Select all")


def undo(_: dict) -> ActionResult:
    key_press(0x11, 0x5A)  # Ctrl+Z
    return ok("Undo")


def redo(_: dict) -> ActionResult:
    key_press(0x11, 0x59)  # Ctrl+Y
    return ok("Redo")


def zoom_in(_: dict) -> ActionResult:
    key_press(0x11, 0xBB)  # Ctrl+=
    return ok("Zoom in")


def zoom_out(_: dict) -> ActionResult:
    key_press(0x11, 0xBD)  # Ctrl+-
    return ok("Zoom out")


# ── Mouse ───────────────────────────────────────────────────────────────────

MOUSE_LEFT_DOWN = 0x0002
MOUSE_LEFT_UP = 0x0004
MOUSE_RIGHT_DOWN = 0x0008
MOUSE_RIGHT_UP = 0x0010
MOUSE_MIDDLE_DOWN = 0x0020
MOUSE_MIDDLE_UP = 0x0040
MOUSE_WHEEL = 0x0800


def _click(down: int, up: int, count: int = 1) -> None:
    for _ in range(max(1, count)):
        user32.mouse_event(down, 0, 0, 0, 0)
        user32.mouse_event(up, 0, 0, 0, 0)
        time.sleep(0.02)


def mouse_click(params: dict) -> ActionResult:
    btn = (params.get("button") or "left").lower()
    count = int(params.get("count") or 1)
    if btn == "right":
        _click(MOUSE_RIGHT_DOWN, MOUSE_RIGHT_UP, count)
    elif btn == "middle":
        _click(MOUSE_MIDDLE_DOWN, MOUSE_MIDDLE_UP, count)
    else:
        _click(MOUSE_LEFT_DOWN, MOUSE_LEFT_UP, count)
    return ok(f"{btn} click x{count}")


def mouse_double_click(_: dict) -> ActionResult:
    _click(MOUSE_LEFT_DOWN, MOUSE_LEFT_UP, 2)
    return ok("Double click")


def mouse_move(params: dict) -> ActionResult:
    """Move cursor to absolute (x, y) pixels or by delta (dx, dy)."""
    if "x" in params and "y" in params:
        try:
            x, y = int(params["x"]), int(params["y"])
        except (TypeError, ValueError):
            return fail("Invalid coordinates")
        user32.SetCursorPos(x, y)
        return ok(f"Cursor at ({x}, {y})")
    dx = int(params.get("dx") or 0)
    dy = int(params.get("dy") or 0)
    if dx == 0 and dy == 0:
        return fail("No movement specified")
    pt = _CursorPoint()
    user32.GetCursorPos(ctypes.byref(pt))
    user32.SetCursorPos(pt.x + dx, pt.y + dy)
    return ok(f"Moved cursor by ({dx}, {dy})")


class _CursorPoint(ctypes.Structure):
    _fields_ = [("x", ctypes.c_long), ("y", ctypes.c_long)]


def scroll(params: dict) -> ActionResult:
    """Scroll mouse wheel. amount > 0 scrolls up, < 0 scrolls down."""
    try:
        amount = int(params.get("amount") or params.get("delta") or 3)
    except (TypeError, ValueError):
        amount = 3
    # 120 = one notch
    user32.mouse_event(MOUSE_WHEEL, 0, 0, amount * 120, 0)
    direction = "up" if amount > 0 else "down"
    return ok(f"Scrolled {direction} ({abs(amount)})")


def scroll_up(params: dict) -> ActionResult:
    return scroll({"amount": abs(int(params.get("amount") or 3))})


def scroll_down(params: dict) -> ActionResult:
    return scroll({"amount": -abs(int(params.get("amount") or 3))})


# ── Clipboard ───────────────────────────────────────────────────────────────

def set_clipboard(params: dict) -> ActionResult:
    text = params.get("text") or ""
    subprocess.run(["clip"], input=text.encode("utf-16le"), check=False)
    return ok(f"Clipboard set ({len(text)} chars)")


def clipboard_history(_: dict) -> ActionResult:
    key_press(0x5B, 0x56)  # Win+V
    return ok("Clipboard history")


# ── Timing ──────────────────────────────────────────────────────────────────

def wait(params: dict) -> ActionResult:
    """Pause the action pipeline server-side for up to 30s."""
    try:
        secs = float(params.get("seconds") or params.get("delay") or 1)
    except (TypeError, ValueError):
        secs = 1.0
    secs = max(0.0, min(30.0, secs))
    time.sleep(secs)
    return ok(f"Waited {secs:.2f}s")
