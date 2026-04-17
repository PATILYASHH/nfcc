package com.nfccontrol.nfcc_mobile

import android.app.NotificationManager
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.hardware.camera2.CameraAccessException
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.net.wifi.WifiManager
import android.os.Build
import android.provider.Settings
import android.util.Log
import android.view.KeyEvent
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class PhoneActionExecutor(private val context: Context) : MethodChannel.MethodCallHandler {

    private val TAG = "NFCC_Actions"
    private var flashOn = false

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "executeAction") {
            result.notImplemented()
            return
        }
        val actionType = call.argument<String>("actionType") ?: ""
        val params = call.argument<Map<String, Any>>("params") ?: emptyMap()

        Log.d(TAG, "Executing: $actionType params: $params")

        try {
            val res = when (actionType) {
                "toggleFlashlight" -> toggleFlashlight()
                "wifiOn" -> setWifi(true)
                "wifiOff" -> setWifi(false)
                "wifiConnect" -> connectWifi(params["ssid"] as? String ?: "")
                "toggleWifi" -> toggleWifi()
                "btOn" -> setBluetooth(true)
                "btOff" -> setBluetooth(false)
                "btConnect" -> connectBluetooth(params["deviceName"] as? String ?: "")
                "toggleBluetooth" -> toggleBluetooth()
                "mobileDataOn", "mobileDataOff", "toggleMobileData" ->
                    Pair(false, "Mobile data requires system permissions")
                "setVolume" -> setVolume((params["level"] as? Number)?.toInt() ?: 50)
                "setBrightness" -> setBrightness((params["level"] as? Number)?.toInt() ?: 50)
                "musicPlayPause" -> mediaKey(KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
                "musicNext" -> mediaKey(KeyEvent.KEYCODE_MEDIA_NEXT)
                "musicPrevious" -> mediaKey(KeyEvent.KEYCODE_MEDIA_PREVIOUS)
                "musicShuffle" -> toggleShuffle()
                "toggleDnd" -> toggleDnd()
                "openApp" -> openApp(params["packageName"] as? String ?: "")
                else -> Pair(false, "Unknown action: $actionType")
            }
            result.success(mapOf("success" to res.first, "message" to res.second))
        } catch (e: Exception) {
            Log.e(TAG, "Failed: $actionType - ${e.message}")
            result.success(mapOf("success" to false, "message" to (e.message ?: "Error")))
        }
    }

    // ── Flashlight ──────────────────────────────────────────────────────

    private fun toggleFlashlight(): Pair<Boolean, String> {
        val cam = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val cameraId = cam.cameraIdList.firstOrNull()
            ?: return Pair(false, "No camera found")
        flashOn = !flashOn
        cam.setTorchMode(cameraId, flashOn)
        return Pair(true, if (flashOn) "Flashlight ON" else "Flashlight OFF")
    }

    // ── WiFi ────────────────────────────────────────────────────────────

    @Suppress("DEPRECATION")
    private fun setWifi(on: Boolean): Pair<Boolean, String> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10+: open WiFi panel
            context.startActivity(
                Intent(Settings.Panel.ACTION_WIFI)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
            return Pair(true, "WiFi panel opened (turn ${if (on) "ON" else "OFF"} manually)")
        }
        val wm = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        wm.isWifiEnabled = on
        return Pair(true, "WiFi ${if (on) "ON" else "OFF"}")
    }

    @Suppress("DEPRECATION")
    private fun toggleWifi(): Pair<Boolean, String> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            context.startActivity(
                Intent(Settings.Panel.ACTION_WIFI)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
            return Pair(true, "WiFi panel opened")
        }
        val wm = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        wm.isWifiEnabled = !wm.isWifiEnabled
        return Pair(true, "WiFi toggled")
    }

    private fun connectWifi(ssid: String): Pair<Boolean, String> {
        if (ssid.isEmpty()) return Pair(false, "No SSID provided")
        // Open WiFi settings - user can select the network
        context.startActivity(
            Intent(Settings.ACTION_WIFI_SETTINGS)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
        return Pair(true, "WiFi settings opened - connect to $ssid")
    }

    // ── Bluetooth ───────────────────────────────────────────────────────

    @Suppress("DEPRECATION", "MissingPermission")
    private fun setBluetooth(on: Boolean): Pair<Boolean, String> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.startActivity(
                Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
            return Pair(true, "BT settings opened (turn ${if (on) "ON" else "OFF"} manually)")
        }
        val bm = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val adapter = bm.adapter ?: return Pair(false, "No Bluetooth adapter")
        if (on) adapter.enable() else adapter.disable()
        return Pair(true, "Bluetooth ${if (on) "ON" else "OFF"}")
    }

    @Suppress("DEPRECATION", "MissingPermission")
    private fun toggleBluetooth(): Pair<Boolean, String> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.startActivity(
                Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
            return Pair(true, "BT settings opened")
        }
        val bm = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val adapter = bm.adapter ?: return Pair(false, "No Bluetooth adapter")
        if (adapter.isEnabled) adapter.disable() else adapter.enable()
        return Pair(true, "Bluetooth toggled")
    }

    private fun connectBluetooth(deviceName: String): Pair<Boolean, String> {
        if (deviceName.isEmpty()) return Pair(false, "No device name")
        context.startActivity(
            Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
        return Pair(true, "BT settings opened - connect to $deviceName")
    }

    // ── Volume ──────────────────────────────────────────────────────────

    private fun setVolume(percent: Int): Pair<Boolean, String> {
        val am = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        val target = (max * percent.coerceIn(0, 100)) / 100
        am.setStreamVolume(AudioManager.STREAM_MUSIC, target, 0)
        return Pair(true, "Volume set to $percent%")
    }

    // ── Brightness ──────────────────────────────────────────────────────

    private fun setBrightness(percent: Int): Pair<Boolean, String> {
        return try {
            val value = (255 * percent.coerceIn(0, 100)) / 100
            Settings.System.putInt(context.contentResolver,
                Settings.System.SCREEN_BRIGHTNESS_MODE,
                Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL)
            Settings.System.putInt(context.contentResolver,
                Settings.System.SCREEN_BRIGHTNESS, value)
            Pair(true, "Brightness set to $percent%")
        } catch (e: SecurityException) {
            // Need WRITE_SETTINGS permission
            context.startActivity(
                Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
            Pair(false, "Need write settings permission")
        }
    }

    // ── Media Keys ──────────────────────────────────────────────────────

    private fun mediaKey(keyCode: Int): Pair<Boolean, String> {
        val am = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        am.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
        am.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_UP, keyCode))
        return Pair(true, "Media key sent")
    }

    // ── DND ─────────────────────────────────────────────────────────────

    private fun toggleDnd(): Pair<Boolean, String> {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (!nm.isNotificationPolicyAccessGranted) {
            context.startActivity(
                Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
            return Pair(false, "Need DND permission - settings opened")
        }
        val current = nm.currentInterruptionFilter
        if (current == NotificationManager.INTERRUPTION_FILTER_ALL) {
            nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_NONE)
            return Pair(true, "DND ON")
        } else {
            nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
            return Pair(true, "DND OFF")
        }
    }

    // ── Open App ────────────────────────────────────────────────────────

    private fun toggleShuffle(): Pair<Boolean, String> {
        return try {
            val intent = android.content.Intent("com.android.music.musicservicecommand")
            intent.putExtra("command", "toggleshuffle")
            context.sendBroadcast(intent)
            Pair(true, "Shuffle toggled")
        } catch (e: Exception) {
            Pair(false, "Shuffle not supported: ${e.message}")
        }
    }

    private fun openApp(packageName: String): Pair<Boolean, String> {
        if (packageName.isEmpty()) return Pair(false, "No package name")
        val intent = context.packageManager.getLaunchIntentForPackage(packageName)
            ?: return Pair(false, "App not found: $packageName")
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        return Pair(true, "Opened $packageName")
    }
}
