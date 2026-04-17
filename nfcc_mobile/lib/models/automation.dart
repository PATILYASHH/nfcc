import 'condition_branch.dart';

class Automation {
  final int? id;
  final String name;
  final String? tagUid;
  final bool isEnabled;
  final List<ConditionBranch> branches;
  final DateTime createdAt;
  final DateTime updatedAt;

  Automation({
    this.id,
    required this.name,
    this.tagUid,
    this.isEnabled = true,
    this.branches = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'tag_uid': tagUid,
        'is_enabled': isEnabled ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Automation.fromMap(Map<String, dynamic> map,
          [List<ConditionBranch> branches = const []]) =>
      Automation(
        id: map['id'] as int?,
        name: map['name'] as String,
        tagUid: map['tag_uid'] as String?,
        isEnabled: (map['is_enabled'] as int?) == 1,
        branches: branches,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Automation copyWith({
    int? id,
    String? name,
    String? tagUid,
    bool? isEnabled,
    List<ConditionBranch>? branches,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Automation(
        id: id ?? this.id,
        name: name ?? this.name,
        tagUid: tagUid ?? this.tagUid,
        isEnabled: isEnabled ?? this.isEnabled,
        branches: branches ?? this.branches,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
