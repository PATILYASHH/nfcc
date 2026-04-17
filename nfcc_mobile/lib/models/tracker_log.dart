class TrackerLog {
  final int? id;
  final int trackerId;
  final String? tagUid;
  final double value;
  final String? state; // 'in' | 'out' for toggles
  final DateTime ts;

  TrackerLog({
    this.id,
    required this.trackerId,
    this.tagUid,
    required this.value,
    this.state,
    required this.ts,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'tracker_id': trackerId,
        'tag_uid': tagUid,
        'value': value,
        'state': state,
        'ts': ts.toIso8601String(),
      };

  static TrackerLog fromMap(Map<String, dynamic> m) => TrackerLog(
        id: m['id'] as int?,
        trackerId: m['tracker_id'] as int,
        tagUid: m['tag_uid'] as String?,
        value: (m['value'] as num).toDouble(),
        state: m['state'] as String?,
        ts: DateTime.parse(m['ts'] as String),
      );
}
