"""Window management & virtual desktops."""

from ._common import ActionResult, key_press, ok


def minimize_all(_: dict) -> ActionResult:
    key_press(0x5B, 0x44)  # Win+D
    return ok("Minimized all windows")


def maximize_window(_: dict) -> ActionResult:
    key_press(0x5B, 0x26)  # Win+Up
    return ok("Maximized window")


def snap_left(_: dict) -> ActionResult:
    key_press(0x5B, 0x25)  # Win+Left
    return ok("Snapped window left")


def snap_right(_: dict) -> ActionResult:
    key_press(0x5B, 0x27)  # Win+Right
    return ok("Snapped window right")


def close_window(_: dict) -> ActionResult:
    key_press(0xA4, 0x73)  # Alt+F4
    return ok("Closed active window")


def switch_window(_: dict) -> ActionResult:
    key_press(0xA4, 0x09)  # Alt+Tab
    return ok("Switched window")


def task_view(_: dict) -> ActionResult:
    key_press(0x5B, 0x09)  # Win+Tab
    return ok("Opened task view")


def show_desktop(_: dict) -> ActionResult:
    key_press(0x5B, 0x4D)  # Win+M
    return ok("Show desktop")


# ── Virtual desktops (Windows 10+) ──────────────────────────────────────────

def vd_new(_: dict) -> ActionResult:
    key_press(0x5B, 0x11, 0x44)  # Win+Ctrl+D
    return ok("New virtual desktop")


def vd_close(_: dict) -> ActionResult:
    key_press(0x5B, 0x11, 0x73)  # Win+Ctrl+F4
    return ok("Closed virtual desktop")


def vd_next(_: dict) -> ActionResult:
    key_press(0x5B, 0x11, 0x27)  # Win+Ctrl+Right
    return ok("Next virtual desktop")


def vd_prev(_: dict) -> ActionResult:
    key_press(0x5B, 0x11, 0x25)  # Win+Ctrl+Left
    return ok("Previous virtual desktop")


# ── Projection (Win+P) ──────────────────────────────────────────────────────

def open_project_menu(_: dict) -> ActionResult:
    key_press(0x5B, 0x50)  # Win+P
    return ok("Opened projection menu")
