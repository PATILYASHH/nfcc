class TodoCompletion {
  final int? id;
  final int todoId;
  final String? tagUid;
  final DateTime completedAt;
  final String dateKey; // YYYY-MM-DD for daily dedup

  TodoCompletion({
    this.id,
    required this.todoId,
    this.tagUid,
    required this.completedAt,
    required this.dateKey,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'todo_id': todoId,
        'tag_uid': tagUid,
        'completed_at': completedAt.toIso8601String(),
        'date_key': dateKey,
      };

  static TodoCompletion fromMap(Map<String, dynamic> m) => TodoCompletion(
        id: m['id'] as int?,
        todoId: m['todo_id'] as int,
        tagUid: m['tag_uid'] as String?,
        completedAt: DateTime.parse(m['completed_at'] as String),
        dateKey: m['date_key'] as String,
      );

  static String dateKeyFor(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
