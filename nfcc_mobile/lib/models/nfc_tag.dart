class NfcTag {
  final int? id;
  final String uid;
  final String? tagType;
  final String? technology;
  final String? nickname;
  final DateTime firstScanned;
  final DateTime lastScanned;
  final int scanCount;
  final int? automationId;

  NfcTag({
    this.id,
    required this.uid,
    this.tagType,
    this.technology,
    this.nickname,
    required this.firstScanned,
    required this.lastScanned,
    this.scanCount = 1,
    this.automationId,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'uid': uid,
        'tag_type': tagType,
        'technology': technology,
        'nickname': nickname,
        'first_scanned': firstScanned.toIso8601String(),
        'last_scanned': lastScanned.toIso8601String(),
        'scan_count': scanCount,
        'automation_id': automationId,
      };

  factory NfcTag.fromMap(Map<String, dynamic> map) => NfcTag(
        id: map['id'] as int?,
        uid: map['uid'] as String,
        tagType: map['tag_type'] as String?,
        technology: map['technology'] as String?,
        nickname: map['nickname'] as String?,
        firstScanned: DateTime.parse(map['first_scanned'] as String),
        lastScanned: DateTime.parse(map['last_scanned'] as String),
        scanCount: map['scan_count'] as int? ?? 1,
        automationId: map['automation_id'] as int?,
      );

  NfcTag copyWith({
    int? id,
    String? uid,
    String? tagType,
    String? technology,
    String? nickname,
    DateTime? firstScanned,
    DateTime? lastScanned,
    int? scanCount,
    int? automationId,
  }) =>
      NfcTag(
        id: id ?? this.id,
        uid: uid ?? this.uid,
        tagType: tagType ?? this.tagType,
        technology: technology ?? this.technology,
        nickname: nickname ?? this.nickname,
        firstScanned: firstScanned ?? this.firstScanned,
        lastScanned: lastScanned ?? this.lastScanned,
        scanCount: scanCount ?? this.scanCount,
        automationId: automationId ?? this.automationId,
      );
}
