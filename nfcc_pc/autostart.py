"""Windows auto-start management via HKCU\\…\\Run.

Run-on-login has to be **silent** — no console window flashing on every
boot. Two cases:

1. Frozen PyInstaller build (NFCC-Companion.exe) — the EXE was linked
   with `--windowed`, no console, just launch it directly.
2. Source / dev run — main.py must be launched with **pythonw.exe**
   (the console-less Python interpreter) and with the `serve` subcommand
   so it comes up as the tray service, not the bare "open the dashboard"
   flow. Using regular python.exe would pop a cmd window at boot.
"""

from __future__ import annotations

import logging
import os
import shutil
import sys
import winreg

logger = logging.getLogger("nfcc")

APP_NAME = "NFCC"
REG_PATH = r"Software\Microsoft\Windows\CurrentVersion\Run"


def _is_frozen() -> bool:
    return getattr(sys, "frozen", False)


def get_exe_path() -> str:
    """Absolute path to the launcher. For frozen builds, the .exe itself.
    For source runs, the source main.py."""
    if _is_frozen():
        return sys.executable
    return os.path.abspath(sys.argv[0])


def _autostart_command() -> str:
    """The exact string registered in HKCU\\…\\Run. Quoted correctly for
    Windows so paths with spaces (like `C:\\code\\NFCC automation\\…`)
    launch cleanly, and always silent (pythonw for source runs)."""
    if _is_frozen():
        return f'"{sys.executable}" serve'

    main_py = os.path.abspath(sys.argv[0])
    pythonw = shutil.which("pythonw") or shutil.which("pythonw.exe")
    if not pythonw:
        # Fallback: derive pythonw.exe from sys.executable
        pythonw = os.path.join(os.path.dirname(sys.executable), "pythonw.exe")
    return f'"{pythonw}" "{main_py}" serve'


def is_autostart_enabled() -> bool:
    try:
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, REG_PATH, 0, winreg.KEY_READ)
        winreg.QueryValueEx(key, APP_NAME)
        winreg.CloseKey(key)
        return True
    except FileNotFoundError:
        return False


def enable_autostart() -> None:
    try:
        cmd = _autostart_command()
        key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER, REG_PATH, 0, winreg.KEY_WRITE
        )
        winreg.SetValueEx(key, APP_NAME, 0, winreg.REG_SZ, cmd)
        winreg.CloseKey(key)
        logger.info(f"Auto-start enabled: {cmd}")
    except Exception as e:
        logger.error(f"Failed to enable auto-start: {e}")


def disable_autostart() -> None:
    try:
        key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER, REG_PATH, 0, winreg.KEY_WRITE
        )
        winreg.DeleteValue(key, APP_NAME)
        winreg.CloseKey(key)
        logger.info("Auto-start disabled")
    except FileNotFoundError:
        pass
    except Exception as e:
        logger.error(f"Failed to disable auto-start: {e}")
