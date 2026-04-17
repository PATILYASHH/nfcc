import 'package:flutter/services.dart';

/// Checks real device state via native Android platform channel.
/// Used by SubCondition.evaluate() to check BT/WiFi conditions.
class DeviceStateService {
  static final DeviceStateService _instance = DeviceStateService._();
  factory DeviceStateService() => _instance;
  DeviceStateService._();

  static const _channel = MethodChannel('com.nfccontrol/device_state');

  /// Get list of currently connected Bluetooth device names
  Future<List<String>> getConnectedBtDevices() async {
    try {
      final result = await _channel.invokeMethod<List>('getConnectedBtDevices');
      return result?.cast<String>() ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Get current WiFi network SSID (null if not connected)
  Future<String?> getCurrentWifiSsid() async {
    try {
      return await _channel.invokeMethod<String>('getCurrentWifiSsid');
    } catch (_) {
      return null;
    }
  }

  /// Check if Bluetooth is enabled
  Future<bool> isBluetoothOn() async {
    try {
      return await _channel.invokeMethod<bool>('isBluetoothOn') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Check if WiFi is enabled
  Future<bool> isWifiOn() async {
    try {
      return await _channel.invokeMethod<bool>('isWifiOn') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Check if connected to any WiFi network
  Future<bool> isWifiConnected() async {
    try {
      return await _channel.invokeMethod<bool>('isWifiConnected') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Check if a specific BT device is connected (case-insensitive partial match)
  Future<bool> isBtDeviceConnected(String deviceName) async {
    if (deviceName.isEmpty) return true;
    final devices = await getConnectedBtDevices();
    final lower = deviceName.toLowerCase();
    return devices.any((d) => d.toLowerCase().contains(lower));
  }

  /// Check if connected to a specific WiFi network (case-insensitive)
  Future<bool> isConnectedToWifi(String ssid) async {
    if (ssid.isEmpty) return true;
    final current = await getCurrentWifiSsid();
    if (current == null) return false;
    return current.toLowerCase() == ssid.toLowerCase();
  }
}
