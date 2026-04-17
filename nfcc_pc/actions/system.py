"""System power & session actions."""

import ctypes
import subprocess

from ._common import ActionResult, fail, ok


def lock_pc(_: dict) -> ActionResult:
    ctypes.windll.user32.LockWorkStation()
    return ok("PC locked")


def _clamp_delay(raw) -> int:
    try:
        return max(0, min(3600, int(raw)))
    except (TypeError, ValueError):
        return 5


def shutdown_pc(params: dict) -> ActionResult:
    delay = _clamp_delay(params.get("delay", 5))
    subprocess.run(["shutdown", "/s", "/t", str(delay)])
    return ok(f"Shutting down in {delay}s")


def restart_pc(params: dict) -> ActionResult:
    delay = _clamp_delay(params.get("delay", 5))
    subprocess.run(["shutdown", "/r", "/t", str(delay)])
    return ok(f"Restarting in {delay}s")


def cancel_shutdown(_: dict) -> ActionResult:
    subprocess.run(["shutdown", "/a"])
    return ok("Shutdown cancelled")


def sign_out(_: dict) -> ActionResult:
    subprocess.run(["shutdown", "/l"])
    return ok("Signing out")


def sleep_pc(_: dict) -> ActionResult:
    subprocess.run(["rundll32.exe", "powrprof.dll,SetSuspendState", "0,1,0"])
    return ok("PC sleeping")


def hibernate_pc(_: dict) -> ActionResult:
    subprocess.run(["shutdown", "/h"])
    return ok("Hibernating")


# ── Power plan ──────────────────────────────────────────────────────────────

POWER_PLANS = {
    "balanced": "381b4222-f694-41f0-9685-ff5bb260df2e",
    "high": "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c",
    "power_saver": "a1841308-3541-4fab-bc81-f71556f20b4a",
}


def set_power_plan(params: dict) -> ActionResult:
    plan = (params.get("plan") or "balanced").lower()
    guid = POWER_PLANS.get(plan)
    if not guid:
        return fail(f"Unknown plan: {plan}")
    r = subprocess.run(["powercfg", "/setactive", guid], capture_output=True, text=True)
    if r.returncode != 0:
        return fail(r.stderr.strip() or "Failed")
    return ok(f"Power plan: {plan}")


# ── Misc ────────────────────────────────────────────────────────────────────

def empty_recycle_bin(_: dict) -> ActionResult:
    r = subprocess.run(
        ["powershell", "-NoProfile", "-Command", "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"],
        capture_output=True, text=True,
    )
    if r.returncode != 0:
        return fail(r.stderr.strip() or "Failed")
    return ok("Recycle bin emptied")
