"""Read-only system information actions (return data to mobile)."""

import platform
import shutil
import socket
import time

from ._common import ActionResult, fail, ok


def _try_psutil():
    try:
        import psutil  # type: ignore
        return psutil
    except ImportError:
        return None


def system_info(_: dict) -> ActionResult:
    """Return CPU, RAM, disk, hostname, uptime to the caller."""
    ps = _try_psutil()
    data: dict = {
        "hostname": socket.gethostname(),
        "platform": platform.platform(),
        "python": platform.python_version(),
    }
    total, used, free = shutil.disk_usage("C:\\")
    data["disk"] = {
        "total_gb": round(total / 1024**3, 1),
        "used_gb": round(used / 1024**3, 1),
        "free_gb": round(free / 1024**3, 1),
        "percent": round(used * 100 / total, 1),
    }
    if ps:
        data["cpu_percent"] = ps.cpu_percent(interval=0.3)
        vm = ps.virtual_memory()
        data["ram"] = {
            "total_gb": round(vm.total / 1024**3, 1),
            "used_gb": round(vm.used / 1024**3, 1),
            "percent": vm.percent,
        }
        data["uptime_sec"] = int(time.time() - ps.boot_time())
        try:
            bat = ps.sensors_battery()
            if bat is not None:
                data["battery"] = {
                    "percent": int(bat.percent),
                    "plugged": bool(bat.power_plugged),
                }
        except (AttributeError, NotImplementedError):
            pass
    return ok("system info", data)


def battery_status(_: dict) -> ActionResult:
    ps = _try_psutil()
    if ps is None:
        return fail("psutil not installed")
    bat = ps.sensors_battery()
    if bat is None:
        return ok("No battery detected", {"has_battery": False})
    return ok(
        f"Battery {int(bat.percent)}%{' (charging)' if bat.power_plugged else ''}",
        {
            "has_battery": True,
            "percent": int(bat.percent),
            "plugged": bool(bat.power_plugged),
            "secs_left": None if bat.secsleft < 0 else bat.secsleft,
        },
    )


def list_processes(params: dict) -> ActionResult:
    """Return top N processes sorted by memory usage."""
    ps = _try_psutil()
    if ps is None:
        return fail("psutil not installed")
    limit = int(params.get("limit") or 20)
    procs = []
    for p in ps.process_iter(["pid", "name", "memory_info"]):
        try:
            mem = p.info["memory_info"].rss if p.info["memory_info"] else 0
            procs.append({
                "pid": p.info["pid"],
                "name": p.info["name"] or "?",
                "memory_mb": round(mem / 1024**2, 1),
            })
        except (ps.NoSuchProcess, ps.AccessDenied):
            continue
    procs.sort(key=lambda x: x["memory_mb"], reverse=True)
    return ok(f"{len(procs)} processes", {"processes": procs[:limit]})


def kill_process(params: dict) -> ActionResult:
    """Kill a process by name or PID."""
    ps = _try_psutil()
    if ps is None:
        # Fall back to taskkill
        import subprocess
        name = (params.get("name") or "").strip()
        if not name:
            return fail("No name or PID")
        if not name.lower().endswith(".exe"):
            name += ".exe"
        r = subprocess.run(["taskkill", "/IM", name, "/F"], capture_output=True, text=True)
        return ok(f"Killed {name}") if r.returncode == 0 else fail(r.stderr.strip())

    pid = params.get("pid")
    name = (params.get("name") or "").strip()
    killed = 0
    try:
        if pid is not None:
            ps.Process(int(pid)).kill()
            killed = 1
        elif name:
            for p in ps.process_iter(["pid", "name"]):
                if (p.info["name"] or "").lower() == name.lower() or \
                   (p.info["name"] or "").lower() == f"{name.lower()}.exe":
                    try:
                        p.kill()
                        killed += 1
                    except (ps.NoSuchProcess, ps.AccessDenied):
                        pass
        else:
            return fail("No name or PID")
    except (ps.NoSuchProcess, ValueError):
        return fail("Process not found")
    except ps.AccessDenied:
        return fail("Access denied (admin?)")
    return ok(f"Killed {killed} process(es)") if killed else fail("No process matched")


def get_ip(_: dict) -> ActionResult:
    """Return the PC's local IP."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
    except OSError:
        ip = "127.0.0.1"
    finally:
        s.close()
    return ok(ip, {"ip": ip, "hostname": socket.gethostname()})
