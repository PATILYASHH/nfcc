"""Volume, mute, media transport."""

from ._common import ActionResult, fail, key_press, ok


def toggle_mute(_: dict) -> ActionResult:
    try:
        from pycaw.pycaw import AudioUtilities, IAudioEndpointVolume
        from comtypes import CLSCTX_ALL
        dev = AudioUtilities.GetSpeakers()
        iface = dev.Activate(IAudioEndpointVolume._iid_, CLSCTX_ALL, None)
        vol = iface.QueryInterface(IAudioEndpointVolume)
        muted = vol.GetMute()
        vol.SetMute(not muted, None)
        return ok(f"Audio {'unmuted' if muted else 'muted'}")
    except Exception as e:
        return fail(str(e))


def set_volume(params: dict) -> ActionResult:
    try:
        level = int(params.get("level", 50))
        level = max(0, min(100, level))
    except (TypeError, ValueError):
        return fail("Invalid volume level")
    try:
        from pycaw.pycaw import AudioUtilities, IAudioEndpointVolume
        from comtypes import CLSCTX_ALL
        dev = AudioUtilities.GetSpeakers()
        iface = dev.Activate(IAudioEndpointVolume._iid_, CLSCTX_ALL, None)
        vol = iface.QueryInterface(IAudioEndpointVolume)
        vol.SetMasterVolumeLevelScalar(level / 100.0, None)
        return ok(f"Volume: {level}%", {"level": level})
    except Exception as e:
        return fail(str(e))


def volume_up(_: dict) -> ActionResult:
    key_press(0xAF)
    return ok("Volume up")


def volume_down(_: dict) -> ActionResult:
    key_press(0xAE)
    return ok("Volume down")


def media_play_pause(_: dict) -> ActionResult:
    key_press(0xB3)
    return ok("Play/Pause")


def media_next(_: dict) -> ActionResult:
    key_press(0xB0)
    return ok("Next track")


def media_prev(_: dict) -> ActionResult:
    key_press(0xB1)
    return ok("Previous track")


def media_stop(_: dict) -> ActionResult:
    key_press(0xB2)
    return ok("Media stopped")
