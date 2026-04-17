class Todo {
  final int? id;
  final String name;
  final String recurrence; // 'daily' | 'once'
  final String? reminderTime; // "HH:MM" 24h, optional
  final int streak;
  final int bestStreak;
  final int iconCode;
  final int colorValue;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tagUids;
  final bool doneToday;

  Todo({
    this.id,
    required this.name,
    this.recurrence = 'daily',
    this.reminderTime,
    this.streak = 0,
    this.bestStreak = 0,
    required this.iconCode,
    required this.colorValue,
    required this.createdAt,
    required this.updatedAt,
    this.tagUids = const [],
    this.doneToday = false,
  });

  Todo copyWith({
    int? id,
    String? name,
    String? recurrence,
    String? reminderTime,
    int? streak,
    int? bestStreak,
    int? iconCode,
    int? colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tagUids,
    bool? doneToday,
  }) =>
      Todo(
        id: id ?? this.id,
        name: name ?? this.name,
        recurrence: recurrence ?? this.recurrence,
        reminderTime: reminderTime ?? this.reminderTime,
        streak: streak ?? this.streak,
        bestStreak: bestStreak ?? this.bestStreak,
        iconCode: iconCode ?? this.iconCode,
        colorValue: colorValue ?? this.colorValue,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        tagUids: tagUids ?? this.tagUids,
        doneToday: doneToday ?? this.doneToday,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'recurrence': recurrence,
        'reminder_time': reminderTime,
        'streak': streak,
        'best_streak': bestStreak,
        'icon_code': iconCode,
        'color_value': colorValue,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  static Todo fromMap(Map<String, dynamic> m,
          {List<String> tagUids = const [], bool doneToday = false}) =>
      Todo(
        id: m['id'] as int?,
        name: m['name'] as String,
        recurrence: m['recurrence'] as String? ?? 'daily',
        reminderTime: m['reminder_time'] as String?,
        streak: m['streak'] as int? ?? 0,
        bestStreak: m['best_streak'] as int? ?? 0,
        iconCode: m['icon_code'] as int,
        colorValue: m['color_value'] as int,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
        tagUids: tagUids,
        doneToday: doneToday,
      );
}
