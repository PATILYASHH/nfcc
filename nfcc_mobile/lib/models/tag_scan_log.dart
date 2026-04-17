class TagScanLog {
  final int? id;
  final String tagUid;
  final String? tagNickname;
  final DateTime scannedAt;
  final String? automationName;
  final String? branchMatched;
  final bool success;
  final String? errorMessage;

  TagScanLog({
    this.id,
    required this.tagUid,
    this.tagNickname,
    required this.scannedAt,
    this.automationName,
    this.branchMatched,
    this.success = true,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'tag_uid': tagUid,
        'tag_nickname': tagNickname,
        'scanned_at': scannedAt.toIso8601String(),
        'automation_name': automationName,
        'branch_matched': branchMatched,
        'success': success ? 1 : 0,
        'error_message': errorMessage,
      };

  factory TagScanLog.fromMap(Map<String, dynamic> map) => TagScanLog(
        id: map['id'] as int?,
        tagUid: map['tag_uid'] as String,
        tagNickname: map['tag_nickname'] as String?,
        scannedAt: DateTime.parse(map['scanned_at'] as String),
        automationName: map['automation_name'] as String?,
        branchMatched: map['branch_matched'] as String?,
        success: (map['success'] as int?) == 1,
        errorMessage: map['error_message'] as String?,
      );
}
