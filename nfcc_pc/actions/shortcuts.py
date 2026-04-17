"""Common Windows shortcut launchers."""

from ._common import ActionResult, key_press, ok


def open_file_explorer(_: dict) -> ActionResult:
    key_press(0x5B, 0x45)  # Win+E
    return ok("File Explorer opened")


def open_task_manager(_: dict) -> ActionResult:
    key_press(0x11, 0xA0, 0x1B)  # Ctrl+Shift+Esc
    return ok("Task Manager opened")


def open_run_dialog(_: dict) -> ActionResult:
    key_press(0x5B, 0x52)  # Win+R
    return ok("Run dialog opened")


def open_action_center(_: dict) -> ActionResult:
    key_press(0x5B, 0x41)  # Win+A
    return ok("Action center / quick settings")


def open_notification_center(_: dict) -> ActionResult:
    key_press(0x5B, 0x4E)  # Win+N
    return ok("Notification center")


def open_start_menu(_: dict) -> ActionResult:
    key_press(0x5B)  # Win
    return ok("Start menu")


def open_search(_: dict) -> ActionResult:
    key_press(0x5B, 0x53)  # Win+S
    return ok("Opened search")


def open_widgets(_: dict) -> ActionResult:
    key_press(0x5B, 0x57)  # Win+W
    return ok("Widgets")


def emoji_picker(_: dict) -> ActionResult:
    key_press(0x5B, 0xBE)  # Win+.
    return ok("Emoji picker")
