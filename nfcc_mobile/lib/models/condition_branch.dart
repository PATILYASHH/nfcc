import 'dart:convert';
import 'action_item.dart';
import '../services/device_state_service.dart';

enum ConditionType { timeRange, dayOfWeek, always }

/// A single sub-condition (e.g. "between 7-11 AM" or "connected to BT device")
class SubCondition {
  final String type; // 'time', 'day', 'btConnected', 'wifiConnected'
  final Map<String, dynamic> params;

  SubCondition({required this.type, this.params = const {}});

  String get label {
    switch (type) {
      case 'time':
        final sh = params['startHour'] ?? 0;
        final sm = params['startMinute'] ?? 0;
        final eh = params['endHour'] ?? 0;
        final em = params['endMinute'] ?? 0;
        return '${_fmt(sh, sm)} - ${_fmt(eh, em)}';
      case 'day':
        final days = (params['days'] as List?)?.cast<int>() ?? [];
        const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days.map((d) => names[d]).join(', ');
      case 'btConnected':
        return 'BT: ${params['deviceName'] ?? 'any'}';
      case 'wifiConnected':
        return 'WiFi: ${params['ssid'] ?? 'any'}';
      default:
        return type;
    }
  }

  /// Evaluate this condition against REAL device state (async)
  Future<bool> evaluate() async {
    final now = DateTime.now();
    switch (type) {
      case 'time':
        final startMin = ((params['startHour'] ?? 0) as int) * 60 +
            ((params['startMinute'] ?? 0) as int);
        final endMin = ((params['endHour'] ?? 0) as int) * 60 +
            ((params['endMinute'] ?? 0) as int);
        final nowMin = now.hour * 60 + now.minute;
        if (startMin <= endMin) {
          return nowMin >= startMin && nowMin < endMin;
        } else {
          return nowMin >= startMin || nowMin < endMin;
        }
      case 'day':
        final days = (params['days'] as List?)?.cast<int>() ?? [];
        return days.contains(now.weekday);
      case 'btConnected':
        final deviceName = params['deviceName'] as String? ?? '';
        return DeviceStateService().isBtDeviceConnected(deviceName);
      case 'wifiConnected':
        final ssid = params['ssid'] as String? ?? '';
        return DeviceStateService().isConnectedToWifi(ssid);
      default:
        return true;
    }
  }

  Map<String, dynamic> toMap() => {'type': type, 'params': params};

  factory SubCondition.fromMap(Map<String, dynamic> map) => SubCondition(
        type: map['type'] as String? ?? 'time',
        params: (map['params'] as Map<String, dynamic>?) ?? {},
      );

  static String _fmt(int h, int m) {
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour:${m.toString().padLeft(2, '0')} $period';
  }
}

/// A condition branch with AND logic: ALL sub-conditions must match.
class ConditionBranch {
  final int? id;
  final int? automationId;
  final int orderIndex;
  final ConditionType type;
  final Map<String, dynamic> params;
  final List<SubCondition> subConditions;
  final List<ActionItem> actions;

  ConditionBranch({
    this.id,
    this.automationId,
    required this.orderIndex,
    required this.type,
    this.params = const {},
    this.subConditions = const [],
    this.actions = const [],
  });

  String get label {
    if (type == ConditionType.always) return 'Otherwise';
    if (subConditions.isNotEmpty) {
      return subConditions.map((s) => s.label).join(' + ');
    }
    switch (type) {
      case ConditionType.timeRange:
        final sh = params['startHour'] ?? 0;
        final sm = params['startMinute'] ?? 0;
        final eh = params['endHour'] ?? 0;
        final em = params['endMinute'] ?? 0;
        return '${SubCondition._fmt(sh, sm)} - ${SubCondition._fmt(eh, em)}';
      case ConditionType.dayOfWeek:
        final days = (params['days'] as List?)?.cast<int>() ?? [];
        const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days.map((d) => names[d]).join(', ');
      case ConditionType.always:
        return 'Otherwise';
    }
  }

  /// Evaluate: ALL sub-conditions must be true (AND logic) - ASYNC
  Future<bool> evaluate() async {
    if (type == ConditionType.always) return true;

    if (subConditions.isNotEmpty) {
      for (final sub in subConditions) {
        if (!await sub.evaluate()) return false;
      }
      return true;
    }

    // Legacy: evaluate from params
    final now = DateTime.now();
    switch (type) {
      case ConditionType.timeRange:
        final startMin = ((params['startHour'] ?? 0) as int) * 60 +
            ((params['startMinute'] ?? 0) as int);
        final endMin = ((params['endHour'] ?? 0) as int) * 60 +
            ((params['endMinute'] ?? 0) as int);
        final nowMin = now.hour * 60 + now.minute;
        if (startMin <= endMin) {
          return nowMin >= startMin && nowMin < endMin;
        } else {
          return nowMin >= startMin || nowMin < endMin;
        }
      case ConditionType.dayOfWeek:
        final days = (params['days'] as List?)?.cast<int>() ?? [];
        return days.contains(now.weekday);
      case ConditionType.always:
        return true;
    }
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (automationId != null) 'automation_id': automationId,
        'order_index': orderIndex,
        'condition_type': type.name,
        'params': jsonEncode({
          ...params,
          'subConditions': subConditions.map((s) => s.toMap()).toList(),
        }),
      };

  factory ConditionBranch.fromMap(Map<String, dynamic> map,
          [List<ActionItem> actions = const []]) {
    final rawParams = map['params'] is String
        ? jsonDecode(map['params'] as String) as Map<String, dynamic>
        : (map['params'] as Map<String, dynamic>?) ?? {};

    final subs = (rawParams['subConditions'] as List?)
            ?.map((s) => SubCondition.fromMap(s as Map<String, dynamic>))
            .toList() ??
        [];

    final cleanParams = Map<String, dynamic>.from(rawParams)
      ..remove('subConditions');

    return ConditionBranch(
      id: map['id'] as int?,
      automationId: map['automation_id'] as int?,
      orderIndex: map['order_index'] as int? ?? 0,
      type: ConditionType.values.firstWhere(
        (e) => e.name == (map['condition_type'] as String?),
        orElse: () => ConditionType.always,
      ),
      params: cleanParams,
      subConditions: subs,
      actions: actions,
    );
  }

  ConditionBranch copyWith({
    int? id,
    int? automationId,
    int? orderIndex,
    ConditionType? type,
    Map<String, dynamic>? params,
    List<SubCondition>? subConditions,
    List<ActionItem>? actions,
  }) =>
      ConditionBranch(
        id: id ?? this.id,
        automationId: automationId ?? this.automationId,
        orderIndex: orderIndex ?? this.orderIndex,
        type: type ?? this.type,
        params: params ?? this.params,
        subConditions: subConditions ?? this.subConditions,
        actions: actions ?? this.actions,
      );
}
