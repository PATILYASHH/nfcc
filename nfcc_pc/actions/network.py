"""Wi-Fi, Bluetooth, network toggles."""

import subprocess

from ._common import ActionResult, fail, ok


def _netsh(args: list[str]) -> tuple[int, str, str]:
    r = subprocess.run(["netsh", *args], capture_output=True, text=True)
    return r.returncode, r.stdout.strip(), r.stderr.strip()


def wifi_on(_: dict) -> ActionResult:
    code, _out, err = _netsh(["interface", "set", "interface", "Wi-Fi", "enable"])
    return ok("Wi-Fi on") if code == 0 else fail(err or "Failed (run as admin?)")


def wifi_off(_: dict) -> ActionResult:
    code, _out, err = _netsh(["interface", "set", "interface", "Wi-Fi", "disable"])
    return ok("Wi-Fi off") if code == 0 else fail(err or "Failed (run as admin?)")


def wifi_connect(params: dict) -> ActionResult:
    ssid = (params.get("ssid") or "").strip()
    if not ssid:
        return fail("No SSID")
    code, _out, err = _netsh(["wlan", "connect", f"name={ssid}"])
    return ok(f"Connecting to {ssid}") if code == 0 else fail(err or f"Could not connect to {ssid}")


def wifi_disconnect(_: dict) -> ActionResult:
    code, _out, err = _netsh(["wlan", "disconnect"])
    return ok("Wi-Fi disconnected") if code == 0 else fail(err or "Failed")


def ethernet_on(_: dict) -> ActionResult:
    code, _out, err = _netsh(["interface", "set", "interface", "Ethernet", "enable"])
    return ok("Ethernet on") if code == 0 else fail(err or "Failed")


def ethernet_off(_: dict) -> ActionResult:
    code, _out, err = _netsh(["interface", "set", "interface", "Ethernet", "disable"])
    return ok("Ethernet off") if code == 0 else fail(err or "Failed")


def flight_mode(_: dict) -> ActionResult:
    """Open network flyout where the user can toggle airplane mode."""
    subprocess.Popen(["cmd", "/c", "start", "ms-settings:network-airplanemode"])
    return ok("Opened airplane mode settings")
