"""Screen power, brightness, screenshots, recording."""

import subprocess

from ._common import ActionResult, fail, key_press, ok, user32


def screenshot(_: dict) -> ActionResult:
    key_press(0x5B, 0xA0, 0x53)  # Win+Shift+S
    return ok("Screenshot tool opened")


def print_screen(_: dict) -> ActionResult:
    key_press(0x2C)  # PrintScreen
    return ok("PrintScreen sent")


def screen_off(_: dict) -> ActionResult:
    SC_MONITORPOWER = 0xF170
    HWND_BROADCAST = 0xFFFF
    WM_SYSCOMMAND = 0x0112
    user32.SendMessageW(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, 2)
    return ok("Screen off")


def screen_on(_: dict) -> ActionResult:
    user32.mouse_event(0x0001, 1, 0, 0, 0)
    return ok("Screen on")


def set_brightness(params: dict) -> ActionResult:
    try:
        level = int(params.get("level", 50))
        level = max(0, min(100, level))
    except (TypeError, ValueError):
        return fail("Invalid brightness level")
    cmd = (
        f"(Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods)"
        f".WmiSetBrightness(1,{level})"
    )
    r = subprocess.run(
        ["powershell", "-NoProfile", "-Command", cmd],
        capture_output=True, text=True,
    )
    if r.returncode != 0:
        return fail(r.stderr.strip() or "Failed to set brightness")
    return ok(f"Brightness: {level}%", {"level": level})


# ── Recording (Xbox Game Bar) ──────────────────────────────────────────────

def game_bar(_: dict) -> ActionResult:
    key_press(0x5B, 0x47)  # Win+G
    return ok("Game Bar")


def toggle_recording(_: dict) -> ActionResult:
    key_press(0x5B, 0xA0, 0x52)  # Win+Shift+R  (screen recorder on Win11)
    return ok("Toggled recording")
