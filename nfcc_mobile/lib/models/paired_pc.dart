class PairedPc {
  final String id;
  final String name;
  final String ip;
  final int port;
  final String pairingToken;
  final DateTime pairedAt;

  PairedPc({
    required this.id,
    required this.name,
    required this.ip,
    required this.port,
    required this.pairingToken,
    required this.pairedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'ip': ip,
        'port': port,
        'pairing_token': pairingToken,
        'paired_at': pairedAt.toIso8601String(),
      };

  factory PairedPc.fromMap(Map<String, dynamic> map) => PairedPc(
        id: map['id'] as String,
        name: map['name'] as String,
        ip: map['ip'] as String,
        port: map['port'] as int,
        pairingToken: map['pairing_token'] as String,
        pairedAt: DateTime.parse(map['paired_at'] as String),
      );
}
