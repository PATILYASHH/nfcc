import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tracker.dart';
import '../../models/tracker_log.dart';
import '../../services/database_service.dart';
import '../../utils/icon_lookup.dart';
import '../theme/app_theme.dart';
import '../widgets/tag_picker_sheet.dart';

class TrackersScreen extends StatefulWidget {
  const TrackersScreen({super.key});

  @override
  State<TrackersScreen> createState() => _TrackersScreenState();
}

class _TrackersScreenState extends State<TrackersScreen> {
  List<Tracker> _trackers = [];
  final Map<int, double> _todayTotal = {};
  final Map<int, TrackerLog?> _lastLog = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = context.read<DatabaseService>();
    final trackers = await db.getAllTrackers();
    _todayTotal.clear();
    _lastLog.clear();
    for (final t in trackers) {
      if (t.id == null) continue;
      _todayTotal[t.id!] = await db.getTodayTotal(t.id!);
      _lastLog[t.id!] = await db.getLastLogForTracker(t.id!);
    }
    if (mounted) setState(() { _trackers = trackers; _loading = false; });
  }

  Future<void> _openEditor({Tracker? existing}) async {
    final result = await showModalBottomSheet<Tracker>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TrackerEditorSheet(existing: existing),
    );
    if (result == null) return;
    final db = context.read<DatabaseService>();
    if (existing == null) {
      await db.insertTracker(result);
    } else {
      await db.updateTracker(result);
    }
    _load();
  }

  Future<void> _deleteTracker(Tracker t) async {
    if (t.id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete tracker?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: Text('Delete "${t.name}"? All logs will be removed.',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (ok == true) {
      await context.read<DatabaseService>().deleteTracker(t.id!);
      _load();
    }
  }

  Future<void> _manualTap(Tracker t) async {
    if (t.id == null) return;
    hapticMedium();
    final db = context.read<DatabaseService>();
    if (t.isCounter) {
      await db.insertTrackerLog(TrackerLog(
        trackerId: t.id!,
        value: t.perTapAmount,
        ts: DateTime.now(),
      ));
    } else {
      final last = _lastLog[t.id!];
      final nextState = (last == null || last.state == 'out') ? 'in' : 'out';
      await db.insertTrackerLog(TrackerLog(
        trackerId: t.id!,
        value: nextState == 'in' ? 1 : 0,
        state: nextState,
        ts: DateTime.now(),
      ));
    }
    _load();
  }

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
        title: const Text('Tracking',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.accentBlue, strokeWidth: 2.5))
          : _trackers.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.accentBlue,
                  backgroundColor: AppColors.surfaceHigh,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: _trackers.length,
                    itemBuilder: (_, i) => _buildCard(_trackers[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          hapticMedium();
          _openEditor();
        },
        backgroundColor: AppColors.accentWhite,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New tracker',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.accentCyan.withValues(alpha: 0.1),
                  AppColors.accentBlue.withValues(alpha: 0.04),
                ]),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: AppColors.accentCyan.withValues(alpha: 0.15)),
              ),
              child: const Icon(Icons.timeline_rounded,
                  size: 38, color: AppColors.accentCyan),
            ),
            const SizedBox(height: 20),
            const Text('No trackers yet',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
              'Track water, coffee, IN/OUT, workouts —\neach tap on a paired tag adds one entry.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textTertiary, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Tracker t) {
    final color = Color(t.colorValue);
    final icon = iconFromCode(t.iconCode);
    final today = _todayTotal[t.id] ?? 0;
    final last = _lastLog[t.id];
    final isIn = t.isToggle && last?.state == 'in';

    String primaryText;
    String secondaryText;
    if (t.isCounter) {
      final goal = t.dailyGoal;
      primaryText = _formatAmount(today, t.unit);
      secondaryText = goal != null
          ? 'Goal ${_formatAmount(goal, t.unit)} · ${((today / goal) * 100).clamp(0, 999).toStringAsFixed(0)}%'
          : '${t.tagUids.length} tag${t.tagUids.length == 1 ? '' : 's'} paired';
    } else {
      primaryText = isIn ? 'IN' : 'OUT';
      if (last != null) {
        secondaryText = '${isIn ? "Since" : "Last out"} ${_timeAgo(last.ts)}';
      } else {
        secondaryText = 'No activity yet';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onLongPress: () => _deleteTracker(t),
          onTap: () => _openEditor(existing: t),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          color.withValues(alpha: 0.22),
                          color.withValues(alpha: 0.08),
                        ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, size: 22, color: color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.name,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(t.isCounter ? 'COUNTER' : 'IN / OUT',
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8)),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.nfc_rounded,
                                  size: 11, color: AppColors.textTertiary),
                              const SizedBox(width: 2),
                              Text('${t.tagUids.length}',
                                  style: const TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _tapButton(t, color),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    if (t.isToggle)
                      Container(
                        width: 12, height: 12,
                        margin: const EdgeInsets.only(right: 8, bottom: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isIn ? AppColors.success : AppColors.textTertiary,
                          boxShadow: isIn
                              ? [
                                  BoxShadow(
                                    color: AppColors.success.withValues(alpha: 0.6),
                                    blurRadius: 8,
                                  )
                                ]
                              : null,
                        ),
                      ),
                    Text(primaryText,
                        style: TextStyle(
                            color: t.isToggle
                                ? (isIn ? AppColors.success : AppColors.textSecondary)
                                : AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8)),
                    const Spacer(),
                    Text(secondaryText,
                        style: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 12)),
                  ],
                ),
                if (t.isCounter && t.dailyGoal != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (today / t.dailyGoal!).clamp(0, 1),
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceHigh,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tapButton(Tracker t, Color color) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _manualTap(t),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_rounded, size: 14, color: color),
              const SizedBox(width: 4),
              Text('Tap',
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(double v, String? unit) {
    final s = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return unit == null || unit.isEmpty ? s : '$s $unit';
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Tracker Editor Sheet ────────────────────────────────────────────────────

class _TrackerEditorSheet extends StatefulWidget {
  final Tracker? existing;
  const _TrackerEditorSheet({this.existing});

  @override
  State<_TrackerEditorSheet> createState() => _TrackerEditorSheetState();
}

class _TrackerEditorSheetState extends State<_TrackerEditorSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _unitCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _goalCtrl;
  String _type = 'counter';
  int _iconCode = Icons.water_drop_rounded.codePoint;
  int _colorValue = AppColors.accentBlue.value;
  List<String> _tagUids = [];

  static const _presets = <_TrackerPreset>[
    _TrackerPreset('Water', 'counter', 'ml', 250, goal: 3000,
        icon: Icons.water_drop_rounded, color: AppColors.accentBlue),
    _TrackerPreset('Coffee', 'counter', 'cup', 1, goal: 4,
        icon: Icons.coffee_rounded, color: AppColors.accentOrange),
    _TrackerPreset('Pushups', 'counter', 'rep', 10, goal: 100,
        icon: Icons.fitness_center_rounded, color: AppColors.accentPurple),
    _TrackerPreset('Cigarettes', 'counter', 'stick', 1,
        icon: Icons.smoking_rooms_rounded, color: AppColors.error),
    _TrackerPreset('Calories', 'counter', 'kcal', 100, goal: 2000,
        icon: Icons.local_fire_department_rounded, color: AppColors.warning),
    _TrackerPreset('Pomodoros', 'counter', 'session', 1, goal: 8,
        icon: Icons.timer_rounded, color: AppColors.accentPink),
    _TrackerPreset('Home', 'toggle', null, 1,
        icon: Icons.home_rounded, color: AppColors.success),
    _TrackerPreset('Office', 'toggle', null, 1,
        icon: Icons.work_rounded, color: AppColors.accentCyan),
    _TrackerPreset('Gym session', 'toggle', null, 1,
        icon: Icons.sports_gymnastics_rounded, color: AppColors.accentGreen),
  ];

  static const _iconChoices = <IconData>[
    Icons.water_drop_rounded,
    Icons.coffee_rounded,
    Icons.local_fire_department_rounded,
    Icons.fitness_center_rounded,
    Icons.timer_rounded,
    Icons.smoking_rooms_rounded,
    Icons.home_rounded,
    Icons.work_rounded,
    Icons.sports_gymnastics_rounded,
    Icons.book_rounded,
    Icons.medication_rounded,
    Icons.mood_rounded,
    Icons.pets_rounded,
    Icons.directions_walk_rounded,
    Icons.auto_awesome_rounded,
  ];

  static const _colorChoices = <Color>[
    AppColors.accentBlue,
    AppColors.accentPurple,
    AppColors.accentCyan,
    AppColors.accentPink,
    AppColors.accentOrange,
    AppColors.accentGreen,
    AppColors.success,
    AppColors.error,
    AppColors.warning,
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _unitCtrl = TextEditingController(text: e?.unit ?? '');
    _amountCtrl = TextEditingController(text: e?.perTapAmount.toString() ?? '1');
    _goalCtrl = TextEditingController(text: e?.dailyGoal?.toString() ?? '');
    _type = e?.type ?? 'counter';
    _iconCode = e?.iconCode ?? Icons.water_drop_rounded.codePoint;
    _colorValue = e?.colorValue ?? AppColors.accentBlue.value;
    _tagUids = [...(e?.tagUids ?? [])];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    _amountCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(_TrackerPreset p) {
    setState(() {
      _nameCtrl.text = p.name;
      _type = p.type;
      _unitCtrl.text = p.unit ?? '';
      _amountCtrl.text = p.perTap.toString();
      _goalCtrl.text = p.goal?.toString() ?? '';
      _iconCode = p.icon.codePoint;
      _colorValue = p.color.value;
    });
    hapticLight();
  }

  Future<void> _pickTags() async {
    final res = await TagPickerSheet.show(context,
        initial: _tagUids, title: 'Pair tags to this tracker');
    if (res != null) setState(() => _tagUids = res);
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a name')));
      return;
    }
    final now = DateTime.now();
    final tracker = Tracker(
      id: widget.existing?.id,
      name: name,
      type: _type,
      unit: _type == 'counter' ? _unitCtrl.text.trim() : null,
      perTapAmount: double.tryParse(_amountCtrl.text.trim()) ?? 1,
      dailyGoal: _type == 'counter'
          ? double.tryParse(_goalCtrl.text.trim())
          : null,
      iconCode: _iconCode,
      colorValue: _colorValue,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
      tagUids: _tagUids,
    );
    Navigator.pop(context, tracker);
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(_colorValue);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 10),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLit,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(widget.existing == null ? 'New tracker' : 'Edit tracker',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton(
                      onPressed: _save,
                      child: const Text('Save',
                          style: TextStyle(
                              color: AppColors.accentBlue,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    // Presets
                    const _SectionLabel('QUICK TEMPLATES'),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _presets.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final p = _presets[i];
                          return GestureDetector(
                            onTap: () => _applyPreset(p),
                            child: Container(
                              width: 96,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: p.color.withValues(alpha: 0.25)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(p.icon, size: 22, color: p.color),
                                  const SizedBox(height: 6),
                                  Text(p.name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(p.type == 'counter'
                                      ? '+${p.perTap.toStringAsFixed(0)}${p.unit != null ? " ${p.unit}" : ""}/tap'
                                      : 'IN / OUT',
                                      style: const TextStyle(
                                          color: AppColors.textTertiary,
                                          fontSize: 9)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Type
                    const _SectionLabel('TYPE'),
                    Row(
                      children: [
                        _typeChip('counter', 'Counter', Icons.add_circle_rounded),
                        const SizedBox(width: 8),
                        _typeChip('toggle', 'IN / OUT', Icons.swap_vert_rounded),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Name
                    const _SectionLabel('NAME'),
                    _inputField(_nameCtrl, 'e.g. Water, Coffee, Home'),
                    const SizedBox(height: 18),

                    if (_type == 'counter') ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionLabel('PER TAP'),
                                _inputField(_amountCtrl, '250',
                                    number: true),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionLabel('UNIT'),
                                _inputField(_unitCtrl, 'ml'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const _SectionLabel('DAILY GOAL (OPTIONAL)'),
                      _inputField(_goalCtrl, '3000', number: true),
                      const SizedBox(height: 18),
                    ],

                    // Icon
                    const _SectionLabel('ICON'),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _iconChoices.map((i) {
                        final sel = i.codePoint == _iconCode;
                        return GestureDetector(
                          onTap: () => setState(() => _iconCode = i.codePoint),
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: sel
                                  ? color.withValues(alpha: 0.18)
                                  : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: sel ? color : AppColors.border,
                                width: sel ? 1.5 : 1,
                              ),
                            ),
                            child: Icon(i,
                                size: 20,
                                color: sel ? color : AppColors.textSecondary),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Color
                    const _SectionLabel('COLOR'),
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      children: _colorChoices.map((c) {
                        final sel = c.value == _colorValue;
                        return GestureDetector(
                          onTap: () => setState(() => _colorValue = c.value),
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: sel ? Colors.white : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: sel
                                  ? [
                                      BoxShadow(
                                        color: c.withValues(alpha: 0.5),
                                        blurRadius: 12,
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Tags
                    const _SectionLabel('PAIRED TAGS'),
                    GestureDetector(
                      onTap: _pickTags,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.nfc_rounded,
                                size: 20, color: AppColors.nfcGlow),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _tagUids.isEmpty
                                    ? 'Tap to pair NFC tags'
                                    : '${_tagUids.length} tag${_tagUids.length == 1 ? '' : 's'} paired',
                                style: TextStyle(
                                    color: _tagUids.isEmpty
                                        ? AppColors.textTertiary
                                        : AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                size: 18, color: AppColors.textTertiary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String value, String label, IconData icon) {
    final sel = _type == value;
    final color = Color(_colorValue);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: sel
                ? color.withValues(alpha: 0.15)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: sel ? color : AppColors.border,
              width: sel ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: sel ? color : AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: sel ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint,
      {bool number = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      style: const TextStyle(
          color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5)),
    );
  }
}

class _TrackerPreset {
  final String name;
  final String type;
  final String? unit;
  final double perTap;
  final double? goal;
  final IconData icon;
  final Color color;
  const _TrackerPreset(this.name, this.type, this.unit, this.perTap,
      {this.goal, required this.icon, required this.color});
}
