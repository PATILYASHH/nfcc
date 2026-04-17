package com.nfccontrol.nfcc_mobile

import android.bluetooth.BluetoothManager
import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.Build
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Checks real device state for condition evaluation.
 * Tells Flutter if BT is connected to a specific device,
 * which WiFi network we're on, etc.
 */
class DeviceStateChecker(private val context: Context) : MethodChannel.MethodCallHandler {

    private val TAG = "NFCC_State"

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getConnectedBtDevices" -> {
                result.success(getConnectedBluetoothDevices())
            }
            "getCurrentWifiSsid" -> {
                result.success(getCurrentWifiSsid())
            }
            "isBluetoothOn" -> {
                result.success(isBluetoothEnabled())
            }
            "isWifiOn" -> {
                result.success(isWifiEnabled())
            }
            "isWifiConnected" -> {
                result.success(isWifiConnected())
            }
            else -> result.notImplemented()
        }
    }

    @Suppress("MissingPermission")
    private fun getConnectedBluetoothDevices(): List<String> {
        val names = mutableListOf<String>()
        try {
            val btManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
            val adapter = btManager.adapter ?: return names

            // Check bonded (paired) devices - synchronous via reflection
            for (device in adapter.bondedDevices) {
                try {
                    val method = device.javaClass.getMethod("isConnected")
                    val connected = method.invoke(device) as Boolean
                    if (connected) {
                        val name = device.name ?: device.address
                        if (!names.contains(name)) {
                            names.add(name)
                        }
                    }
                } catch (_: Exception) {}
            }
        } catch (e: Exception) {
            Log.e(TAG, "BT check failed: ${e.message}")
        }
        Log.d(TAG, "Connected BT devices: $names")
        return names
    }

    @Suppress("DEPRECATION")
    private fun getCurrentWifiSsid(): String? {
        try {
            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val info = wifiManager.connectionInfo
            var ssid = info?.ssid
            if (ssid != null) {
                // Remove quotes
                ssid = ssid.replace("\"", "")
                if (ssid == "<unknown ssid>" || ssid.isEmpty()) return null
                return ssid
            }
        } catch (e: Exception) {
            Log.e(TAG, "WiFi SSID check failed: ${e.message}")
        }
        return null
    }

    private fun isBluetoothEnabled(): Boolean {
        try {
            val btManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
            return btManager.adapter?.isEnabled == true
        } catch (_: Exception) { return false }
    }

    @Suppress("DEPRECATION")
    private fun isWifiEnabled(): Boolean {
        try {
            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            return wifiManager.isWifiEnabled
        } catch (_: Exception) { return false }
    }

    private fun isWifiConnected(): Boolean {
        try {
            val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val network = cm.activeNetwork ?: return false
            val caps = cm.getNetworkCapabilities(network) ?: return false
            return caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
        } catch (_: Exception) { return false }
    }
}
