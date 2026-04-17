class Tracker {
  final int? id;
  final String name;
  final String type; // 'counter' | 'toggle'
  final String? unit;
  final double perTapAmount;
  final double? dailyGoal;
  final int iconCode;
  final int colorValue;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tagUids;

  Tracker({
    this.id,
    required this.name,
    required this.type,
    this.unit,
    this.perTapAmount = 1,
    this.dailyGoal,
    required this.iconCode,
    required this.colorValue,
    required this.createdAt,
    required this.updatedAt,
    this.tagUids = const [],
  });

  bool get isCounter => type == 'counter';
  bool get isToggle => type == 'toggle';

  Tracker copyWith({
    int? id,
    String? name,
    String? type,
    String? unit,
    double? perTapAmount,
    double? dailyGoal,
    int? iconCode,
    int? colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tagUids,
  }) =>
      Tracker(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        unit: unit ?? this.unit,
        perTapAmount: perTapAmount ?? this.perTapAmount,
        dailyGoal: dailyGoal ?? this.dailyGoal,
        iconCode: iconCode ?? this.iconCode,
        colorValue: colorValue ?? this.colorValue,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        tagUids: tagUids ?? this.tagUids,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'type': type,
        'unit': unit,
        'per_tap_amount': perTapAmount,
        'daily_goal': dailyGoal,
        'icon_code': iconCode,
        'color_value': colorValue,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  static Tracker fromMap(Map<String, dynamic> m, {List<String> tagUids = const []}) => Tracker(
        id: m['id'] as int?,
        name: m['name'] as String,
        type: m['type'] as String,
        unit: m['unit'] as String?,
        perTapAmount: (m['per_tap_amount'] as num?)?.toDouble() ?? 1,
        dailyGoal: (m['daily_goal'] as num?)?.toDouble(),
        iconCode: m['icon_code'] as int,
        colorValue: m['color_value'] as int,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
        tagUids: tagUids,
      );
}
