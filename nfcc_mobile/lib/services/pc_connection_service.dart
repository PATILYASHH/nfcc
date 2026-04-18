import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/paired_pc.dart';
import '../models/action_item.dart';
import 'database_service.dart';

enum PcConnectionState { disconnected, connecting, connected, error }

class PcConnectionService extends ChangeNotifier {
  static final PcConnectionService _instance = PcConnectionService._();
  factory PcConnectionService() => _instance;
  PcConnectionService._();

  final DatabaseService _db = DatabaseService();

  WebSocketChannel? _channel;
  PairedPc? _currentPc;
  PcConnectionState _state = PcConnectionState.disconnected;
  String? _pcName;
  String? _errorMessage;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  final _actionCompleters = <String, Completer<Map<String, dynamic>>>{};

  PcConnectionState get state => _state;
  PairedPc? get currentPc => _currentPc;
  String? get pcName => _pcName;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _state == PcConnectionState.connected;

  /// Connect to a PC using stored pairing info
  Future<void> connectToPc(PairedPc pc) async {
    _currentPc = pc;
    _reconnectAttempts = 0;
    await _connect();
  }

  /// Called on app launch. If a PairedPc row exists in the DB, pick the
  /// most recently paired one and connect to it in the background.
  /// Never blocks the UI; failures silently fall into the reconnect loop
  /// so the connection eventually comes up when the LAN is reachable.
  Future<void> restoreStoredPairing() async {
    try {
      final pcs = await _db.getPairedPcs();
      if (pcs.isEmpty) return;
      debugPrint('NFCC: auto-connecting to stored PC ${pcs.first.name} '
          '(${pcs.first.ip}:${pcs.first.port})');
      await connectToPc(pcs.first);
    } catch (e) {
      debugPrint('NFCC: restoreStoredPairing error: $e');
    }
  }

  /// Connect using QR code data
  Future<void> connectFromQr(Map<String, dynamic> qrData) async {
    final pc = PairedPc(
      id: qrData['id'] as String,
      name: qrData['name'] as String,
      ip: qrData['ip'] as String,
      port: qrData['port'] as int,
      pairingToken: qrData['token'] as String,
      pairedAt: DateTime.now(),
    );
    await _db.insertPairedPc(pc);
    _currentPc = pc;
    _reconnectAttempts = 0;
    await _connect();
  }

  Future<void> _connect() async {
    if (_currentPc == null) return;

    _setState(PcConnectionState.connecting);
    _errorMessage = null;

    try {
      final uri = Uri.parse('ws://${_currentPc!.ip}:${_currentPc!.port}');
      _channel = WebSocketChannel.connect(uri);

      // Wait for connection
      await _channel!.ready;

      // Send auth
      _channel!.sink.add(jsonEncode({
        'type': 'auth',
        'token': _currentPc!.pairingToken,
        'deviceName': 'NFCC Mobile',
      }));

      // Listen for messages
      _channel!.stream.listen(
        _onMessage,
        onError: (error) {
          _onDisconnected('Connection error: $error');
        },
        onDone: () {
          _onDisconnected('Connection closed');
        },
      );

      // Start ping timer
      _startPingTimer();
    } catch (e) {
      _onDisconnected('Failed to connect: $e');
    }
  }

  void _onMessage(dynamic rawMessage) {
    final data = jsonDecode(rawMessage as String) as Map<String, dynamic>;
    final type = data['type'] as String?;

    switch (type) {
      case 'auth_result':
        if (data['success'] == true) {
          _pcName = data['pcName'] as String?;
          _setState(PcConnectionState.connected);
          _reconnectAttempts = 0;
        } else {
          _onDisconnected('Authentication failed');
        }
        break;

      case 'action_result':
        final id = data['id'] as String?;
        if (id != null && _actionCompleters.containsKey(id)) {
          _actionCompleters[id]!.complete(data);
          _actionCompleters.remove(id);
        }
        break;

      case 'pong':
        // Keepalive response received
        break;
    }
  }

  void _onDisconnected(String reason) {
    _channel = null;
    _pingTimer?.cancel();
    _errorMessage = reason;
    _setState(PcConnectionState.disconnected);

    if (_currentPc == null) return;

    _reconnectTimer?.cancel();
    final delay = _reconnectDelay(_reconnectAttempts);
    _reconnectTimer = Timer(delay, () async {
      // Every 3rd attempt (and always after 10+), re-run UDP discovery
      // to pick up a new IP/port — handles WiFi changes + DHCP renewal.
      if (_reconnectAttempts > 0 && _reconnectAttempts % 3 == 0) {
        await _rediscoverAndUpdate();
      }
      _reconnectAttempts++;
      _connect();
    });
  }

  Duration _reconnectDelay(int attempts) {
    // Fast at first, then back off up to 60 s.
    const seconds = [1, 2, 4, 8, 15, 30, 45, 60];
    return Duration(seconds: seconds[attempts.clamp(0, seconds.length - 1)]);
  }

  /// Broadcast a UDP discover packet and, if a PC with the same pairing
  /// token responds, update the stored IP/port. Called periodically by
  /// the reconnect loop and publicly via [refreshConnection].
  Future<void> _rediscoverAndUpdate() async {
    if (_currentPc == null) return;
    debugPrint('NFCC: rediscovering PC (current IP ${_currentPc!.ip}:${_currentPc!.port})');
    final found = await discoverPcs(timeout: const Duration(seconds: 3));
    for (final pc in found) {
      if (pc['token'] == _currentPc!.pairingToken) {
        final newIp = pc['ip'] as String?;
        final newPort = (pc['port'] as num?)?.toInt();
        if (newIp == null || newPort == null) break;
        if (newIp == _currentPc!.ip && newPort == _currentPc!.port) {
          debugPrint('NFCC: rediscovery confirmed same endpoint');
          break;
        }
        debugPrint('NFCC: PC moved to $newIp:$newPort — updating stored pairing');
        _currentPc = PairedPc(
          id: _currentPc!.id,
          name: (pc['name'] as String?) ?? _currentPc!.name,
          ip: newIp,
          port: newPort,
          pairingToken: _currentPc!.pairingToken,
          pairedAt: _currentPc!.pairedAt,
        );
        await _db.insertPairedPc(_currentPc!); // upsert on id
        break;
      }
    }
  }

  /// Manually force a rediscovery + reconnect — e.g. after the user
  /// changed WiFi networks or restarted the PC companion.
  Future<void> refreshConnection() async {
    if (_currentPc == null) return;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _reconnectAttempts = 0;
    await _rediscoverAndUpdate();
    await _connect();
  }

  /// Send a PC action and wait for result
  Future<Map<String, dynamic>?> sendAction(ActionItem action,
      {Duration timeout = const Duration(seconds: 10)}) async {
    if (!isConnected || _channel == null) return null;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final completer = Completer<Map<String, dynamic>>();
    _actionCompleters[id] = completer;

    _channel!.sink.add(jsonEncode({
      'type': 'action',
      'id': id,
      'action': action.actionType,
      'params': action.params,
    }));

    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      _actionCompleters.remove(id);
      return {'success': false, 'error': 'Timeout'};
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (isConnected && _channel != null) {
        try {
          _channel!.sink.add(jsonEncode({'type': 'ping'}));
        } catch (_) {
          _onDisconnected('Ping failed');
        }
      }
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _currentPc = null;
    _pcName = null;
    _reconnectAttempts = 0;
    _setState(PcConnectionState.disconnected);
  }

  void _setState(PcConnectionState newState) {
    _state = newState;
    notifyListeners();
  }

  /// UDP discovery to find PCs on the network
  Future<List<Map<String, dynamic>>> discoverPcs(
      {Duration timeout = const Duration(seconds: 3)}) async {
    final results = <Map<String, dynamic>>[];
    try {
      final socket =
          await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      final magic = utf8.encode('NFCC_DISCOVER');
      socket.send(magic, InternetAddress('255.255.255.255'), 9877);

      await for (final event in socket.timeout(timeout)) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            try {
              final data = jsonDecode(utf8.decode(datagram.data))
                  as Map<String, dynamic>;
              results.add(data);
            } catch (_) {}
          }
        }
      }
      socket.close();
    } catch (_) {}
    return results;
  }
}
