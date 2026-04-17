import 'package:flutter/material.dart';
import '../../models/condition_branch.dart';
import '../theme/app_theme.dart';

/// Full-page condition picker - Samsung style categorized list
class ConditionPickerScreen extends StatelessWidget {
  const ConditionPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add condition',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Time & Schedule ──
          _sectionLabel('Time & Schedule'),
          const SizedBox(height: 8),
          _ConditionItem(
            icon: Icons.schedule_rounded,
            color: AppColors.accentBlue,
            title: 'Time range',
            subtitle: 'Between specific hours',
            onTap: (ctx) => _pickTimeRange(ctx),
          ),
          _ConditionItem(
            icon: Icons.calendar_today_rounded,
            color: AppColors.accentPurple,
            title: 'Day of week',
            subtitle: 'On specific days',
            onTap: (ctx) => _pickDays(ctx),
          ),

          const SizedBox(height: 20),

          // ── Connections ──
          _sectionLabel('Connections'),
          const SizedBox(height: 8),
          _ConditionItem(
            icon: Icons.bluetooth_rounded,
            color: AppColors.accentCyan,
            title: 'Bluetooth device',
            subtitle: 'When connected to a BT device',
            onTap: (ctx) => _pickBluetooth(ctx),
          ),
          _ConditionItem(
            icon: Icons.wifi_rounded,
            color: AppColors.accentOrange,
            title: 'Wi-Fi network',
            subtitle: 'When connected to a Wi-Fi network',
            onTap: (ctx) => _pickWifi(ctx),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5)),
    );
  }

  // ── Time Range Picker ───────────────────────────────────────────────

  Future<void> _pickTimeRange(BuildContext context) async {
    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'START TIME',
    );
    if (start == null || !context.mounted) return;

    final end = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 17, minute: 0),
      helpText: 'END TIME',
    );
    if (end == null || !context.mounted) return;

    Navigator.pop(context, SubCondition(
      type: 'time',
      params: {
        'startHour': start.hour, 'startMinute': start.minute,
        'endHour': end.hour, 'endMinute': end.minute,
      },
    ));
  }

  // ── Day Picker ──────────────────────────────────────────────────────

  Future<void> _pickDays(BuildContext context) async {
    final selected = <int>{};
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final result = await showDialog<List<int>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppColors.surfaceHigh,
          title: const Text('Select days'),
          content: Wrap(
            spacing: 8, runSpacing: 8,
            children: List.generate(7, (i) {
              final day = i + 1;
              final on = selected.contains(day);
              return GestureDetector(
                onTap: () => setSt(() => on ? selected.remove(day) : selected.add(day)),
                child: Container(
                  width: 56, height: 40,
                  decoration: BoxDecoration(
                    color: on ? AppColors.accentPurple : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(dayNames[i],
                      style: TextStyle(
                          color: on ? Colors.white : AppColors.textSecondary,
                          fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              );
            }),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
            TextButton(
                onPressed: () => Navigator.pop(ctx, selected.toList()..sort()),
                child: const Text('Done', style: TextStyle(color: AppColors.accentPurple))),
          ],
        ),
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      Navigator.pop(context, SubCondition(type: 'day', params: {'days': result}));
    }
  }

  // ── Bluetooth Picker ────────────────────────────────────────────────

  Future<void> _pickBluetooth(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: const Text('Bluetooth device name'),
        content: TextField(
          controller: controller, autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Galaxy Buds, Car Speaker',
            hintStyle: const TextStyle(color: AppColors.textTertiary),
            filled: true, fillColor: AppColors.surfaceElevated,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Done', style: TextStyle(color: AppColors.accentCyan))),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && context.mounted) {
      Navigator.pop(context, SubCondition(type: 'btConnected', params: {'deviceName': result}));
    }
  }

  // ── WiFi Picker ─────────────────────────────────────────────────────

  Future<void> _pickWifi(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: const Text('Wi-Fi network name'),
        content: TextField(
          controller: controller, autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Office_WiFi, Home_5G',
            hintStyle: const TextStyle(color: AppColors.textTertiary),
            filled: true, fillColor: AppColors.surfaceElevated,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Done', style: TextStyle(color: AppColors.accentOrange))),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && context.mounted) {
      Navigator.pop(context, SubCondition(type: 'wifiConnected', params: {'ssid': result}));
    }
  }
}

/// A single condition item row - Samsung style
class _ConditionItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Future<void> Function(BuildContext) onTap;

  const _ConditionItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onTap(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: 20, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
