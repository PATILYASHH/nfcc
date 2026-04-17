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

    // Auto-reconnect: fast burst (10 tries), then slow retry (every 60s)
    if (_currentPc != null) {
      _reconnectTimer?.cancel();
      if (_reconnectAttempts < 10) {
        final delay = Duration(
            seconds: [1, 2, 4, 8, 15, 30][_reconnectAttempts.clamp(0, 5)]);
        _reconnectAttempts++;
        _reconnectTimer = Timer(delay, () => _connect());
      } else {
        // Slow retry indefinitely
        _reconnectTimer = Timer(const Duration(seconds: 60), () {
          _reconnectAttempts = 5;
          _connect();
        });
      }
    }
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
