"""Windows auto-start management via registry."""

import logging
import os
import sys
import winreg

logger = logging.getLogger("nfcc")

APP_NAME = "NFCC"
REG_PATH = r"Software\Microsoft\Windows\CurrentVersion\Run"


def get_exe_path() -> str:
    """Get the path to the current executable."""
    if getattr(sys, "frozen", False):
        return sys.executable
    return os.path.abspath(sys.argv[0])


def is_autostart_enabled() -> bool:
    try:
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, REG_PATH, 0, winreg.KEY_READ)
        value, _ = winreg.QueryValueEx(key, APP_NAME)
        winreg.CloseKey(key)
        return True
    except FileNotFoundError:
        return False


def enable_autostart():
    try:
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, REG_PATH, 0, winreg.KEY_WRITE)
        winreg.SetValueEx(key, APP_NAME, 0, winreg.REG_SZ, f'"{get_exe_path()}"')
        winreg.CloseKey(key)
        logger.info("Auto-start enabled")
    except Exception as e:
        logger.error(f"Failed to enable auto-start: {e}")


def disable_autostart():
    try:
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, REG_PATH, 0, winreg.KEY_WRITE)
        winreg.DeleteValue(key, APP_NAME)
        winreg.CloseKey(key)
        logger.info("Auto-start disabled")
    except FileNotFoundError:
        pass
    except Exception as e:
        logger.error(f"Failed to disable auto-start: {e}")
