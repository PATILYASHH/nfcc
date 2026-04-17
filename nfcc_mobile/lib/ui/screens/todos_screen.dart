import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/todo.dart';
import '../../services/database_service.dart';
import '../../services/nfc_service.dart';
import '../../utils/icon_lookup.dart';
import '../theme/app_theme.dart';
import '../widgets/tag_picker_sheet.dart';

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  List<Todo> _todos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = context.read<DatabaseService>();
    final todos = await db.getAllTodos();
    if (mounted) setState(() { _todos = todos; _loading = false; });
  }

  Future<void> _openEditor({Todo? existing}) async {
    final result = await showModalBottomSheet<Todo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TodoEditorSheet(existing: existing),
    );
    if (result == null) return;
    final db = context.read<DatabaseService>();
    if (existing == null) {
      await db.insertTodo(result);
    } else {
      await db.updateTodo(result);
    }
    _load();
  }

  Future<void> _delete(Todo t) async {
    if (t.id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete TODO?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: Text('Delete "${t.name}"? Streak will be lost.',
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
      await context.read<DatabaseService>().deleteTodo(t.id!);
      _load();
    }
  }

  Future<void> _writeTagForTodo(Todo t) async {
    if (t.id == null) return;
    hapticMedium();
    final nfc = context.read<NfcService>();
    if (!await nfc.isAvailable()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('NFC not available')));
      }
      return;
    }
    if (!mounted) return;

    final color = Color(t.colorValue);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.nfc_rounded, size: 32, color: color),
            ),
            const SizedBox(height: 20),
            const Text('Hold NFC tag near device',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Writing TODO "${t.name}" — tap the tag to mark it complete',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              nfc.stopSession();
              Navigator.pop(ctx);
            },
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );

    await nfc.startWriteSession(
      data: 'NFCC_D:${t.id}',
      onResult: (success, msg) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(success
                ? 'Tag written for "${t.name}"'
                : 'Failed: $msg'),
            backgroundColor:
                success ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ));
          if (success) _load();
        }
      },
    );
  }

  Future<void> _toggleToday(Todo t) async {
    if (t.id == null) return;
    hapticMedium();
    await context.read<DatabaseService>().toggleTodoCompletionToday(t.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = _todos.where((t) => t.doneToday).length;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('TODOs',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.accentBlue, strokeWidth: 2.5))
          : _todos.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.accentBlue,
                  backgroundColor: AppColors.surfaceHigh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    children: [
                      _todayHeader(doneCount, _todos.length),
                      const SizedBox(height: 12),
                      ..._todos.map(_buildCard),
                    ],
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
        label: const Text('New TODO',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _todayHeader(int done, int total) {
    final pct = total == 0 ? 0.0 : done / total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.accentBlue.withValues(alpha: 0.14),
          AppColors.accentPurple.withValues(alpha: 0.06),
        ], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 54, height: 54,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 54, height: 54,
                  child: CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 5,
                    backgroundColor: AppColors.surfaceHigh,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accentBlue),
                  ),
                ),
                Text('$done/$total',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done == total && total > 0
                      ? 'All done! 🔥'
                      : done == 0
                          ? 'Let\'s get started'
                          : 'Keep going',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3),
                ),
                const SizedBox(height: 2),
                Text(
                  'Today • ${(pct * 100).toStringAsFixed(0)}% complete',
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
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
                  AppColors.accentPurple.withValues(alpha: 0.12),
                  AppColors.accentBlue.withValues(alpha: 0.04),
                ]),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: AppColors.accentPurple.withValues(alpha: 0.15)),
              ),
              child: const Icon(Icons.checklist_rounded,
                  size: 38, color: AppColors.accentPurple),
            ),
            const SizedBox(height: 20),
            const Text('No TODOs yet',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
              'Create as many TODOs as you like.\n'
              'Set each as daily (with optional reminder time)\n'
              'or one-off. Tap a paired tag to complete.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textTertiary, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Todo t) {
    final color = Color(t.colorValue);
    final icon = iconFromCode(t.iconCode);
    final done = t.doneToday;
    return Dismissible(
      key: Key('todo_${t.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        _delete(t);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_rounded,
            color: AppColors.error, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: done
                ? color.withValues(alpha: 0.3)
                : AppColors.border,
            width: done ? 1.5 : 1,
          ),
          boxShadow: done
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 14,
                    spreadRadius: -3,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _openEditor(existing: t),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Check circle
                  GestureDetector(
                    onTap: () => _toggleToday(t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: done ? color : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: done ? color : color.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: done
                          ? const Icon(Icons.check_rounded,
                              size: 22, color: Colors.white)
                          : Icon(icon, size: 20, color: color),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.name,
                            style: TextStyle(
                                color: done
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                decoration: done
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: AppColors.textTertiary)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8, runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (t.streak > 0)
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.local_fire_department_rounded,
                                    size: 13, color: AppColors.warning),
                                const SizedBox(width: 2),
                                Text('${t.streak}d',
                                    style: const TextStyle(
                                        color: AppColors.warning,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                              ]),
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.nfc_rounded,
                                  size: 11, color: AppColors.textTertiary),
                              const SizedBox(width: 2),
                              Text('${t.tagUids.length} tag${t.tagUids.length == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: 11)),
                            ]),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(t.recurrence.toUpperCase(),
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6)),
                            ),
                            if (t.reminderTime != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.schedule_rounded,
                                          size: 10, color: color),
                                      const SizedBox(width: 3),
                                      Text(t.reminderTime!,
                                          style: TextStyle(
                                              color: color,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700)),
                                    ]),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (done)
                    Icon(Icons.check_circle_rounded,
                        color: color, size: 22)
                  else
                    Material(
                      color: AppColors.nfcGlow.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _writeTagForTodo(t),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.nfc_rounded,
                                  size: 13, color: AppColors.nfcGlow),
                              SizedBox(width: 4),
                              Text('Write',
                                  style: TextStyle(
                                      color: AppColors.nfcGlow,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Todo Editor Sheet ──────────────────────────────────────────────────────

class _TodoEditorSheet extends StatefulWidget {
  final Todo? existing;
  const _TodoEditorSheet({this.existing});

  @override
  State<_TodoEditorSheet> createState() => _TodoEditorSheetState();
}

class _TodoEditorSheetState extends State<_TodoEditorSheet> {
  late TextEditingController _nameCtrl;
  String _recurrence = 'daily';
  String? _reminderTime; // HH:MM
  int _iconCode = Icons.check_circle_rounded.codePoint;
  int _colorValue = AppColors.accentPurple.value;
  List<String> _tagUids = [];

  static const _presets = <_TodoPreset>[
    _TodoPreset('Brush teeth', Icons.brush_rounded, AppColors.accentBlue),
    _TodoPreset('Take medicine', Icons.medication_rounded, AppColors.error),
    _TodoPreset('Drink water', Icons.water_drop_rounded, AppColors.accentBlue),
    _TodoPreset('Workout', Icons.fitness_center_rounded, AppColors.accentPurple),
    _TodoPreset('Read', Icons.book_rounded, AppColors.accentOrange),
    _TodoPreset('Meditate', Icons.self_improvement_rounded, AppColors.accentCyan),
    _TodoPreset('Stretch', Icons.accessibility_new_rounded, AppColors.accentGreen),
    _TodoPreset('Study', Icons.school_rounded, AppColors.accentPink),
    _TodoPreset('Journal', Icons.edit_note_rounded, AppColors.warning),
  ];

  static const _iconChoices = <IconData>[
    Icons.check_circle_rounded,
    Icons.brush_rounded,
    Icons.medication_rounded,
    Icons.water_drop_rounded,
    Icons.fitness_center_rounded,
    Icons.book_rounded,
    Icons.self_improvement_rounded,
    Icons.school_rounded,
    Icons.edit_note_rounded,
    Icons.accessibility_new_rounded,
    Icons.nightlight_round,
    Icons.wb_sunny_rounded,
    Icons.local_fire_department_rounded,
    Icons.star_rounded,
    Icons.favorite_rounded,
  ];

  static const _colorChoices = <Color>[
    AppColors.accentPurple,
    AppColors.accentBlue,
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
    _recurrence = e?.recurrence ?? 'daily';
    _reminderTime = e?.reminderTime;
    _iconCode = e?.iconCode ?? Icons.check_circle_rounded.codePoint;
    _colorValue = e?.colorValue ?? AppColors.accentPurple.value;
    _tagUids = [...(e?.tagUids ?? [])];
  }

  Future<void> _pickReminderTime() async {
    hapticLight();
    TimeOfDay initial;
    if (_reminderTime != null) {
      final parts = _reminderTime!.split(':');
      initial = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 8,
          minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);
    } else {
      initial = const TimeOfDay(hour: 8, minute: 0);
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          timePickerTheme: TimePickerThemeData(
            backgroundColor: AppColors.surfaceHigh,
            hourMinuteColor: AppColors.surfaceElevated,
            dialBackgroundColor: AppColors.surfaceElevated,
            dialHandColor: Color(_colorValue),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _reminderTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTags() async {
    final res = await TagPickerSheet.show(context,
        initial: _tagUids, title: 'Pair tags to this TODO');
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
    Navigator.pop(
        context,
        Todo(
          id: widget.existing?.id,
          name: name,
          recurrence: _recurrence,
          reminderTime: _recurrence == 'daily' ? _reminderTime : null,
          streak: widget.existing?.streak ?? 0,
          bestStreak: widget.existing?.bestStreak ?? 0,
          iconCode: _iconCode,
          colorValue: _colorValue,
          createdAt: widget.existing?.createdAt ?? now,
          updatedAt: now,
          tagUids: _tagUids,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(_colorValue);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
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
                    Text(widget.existing == null ? 'New TODO' : 'Edit TODO',
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
                    const _SectionLabel('QUICK TEMPLATES'),
                    SizedBox(
                      height: 84,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _presets.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final p = _presets[i];
                          return GestureDetector(
                            onTap: () {
                              hapticLight();
                              setState(() {
                                _nameCtrl.text = p.name;
                                _iconCode = p.icon.codePoint;
                                _colorValue = p.color.value;
                              });
                            },
                            child: Container(
                              width: 88,
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),

                    const _SectionLabel('NAME'),
                    _inputField(_nameCtrl, 'e.g. Take medicine'),
                    const SizedBox(height: 18),

                    const _SectionLabel('RECURRENCE'),
                    Row(
                      children: [
                        _recChip('daily', 'Daily', Icons.repeat_rounded),
                        const SizedBox(width: 8),
                        _recChip('once', 'One-off', Icons.flag_rounded),
                      ],
                    ),
                    const SizedBox(height: 18),

                    if (_recurrence == 'daily') ...[
                      const _SectionLabel('REMINDER TIME (OPTIONAL)'),
                      _buildReminderTimeRow(color),
                      const SizedBox(height: 18),
                    ],

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

  Widget _buildReminderTimeRow(Color color) {
    final has = _reminderTime != null;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _pickReminderTime,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: has ? color : AppColors.border,
                  width: has ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 20, color: has ? color : AppColors.textTertiary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      has ? 'Remind at $_reminderTime' : 'Tap to set a time',
                      style: TextStyle(
                          color: has
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                          fontSize: 14,
                          fontWeight: has ? FontWeight.w600 : FontWeight.w400),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
        ),
        if (has) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => setState(() => _reminderTime = null),
            icon: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.textSecondary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceElevated,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(48, 48),
            ),
          ),
        ],
      ],
    );
  }

  Widget _recChip(String value, String label, IconData icon) {
    final sel = _recurrence == value;
    final color = Color(_colorValue);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _recurrence = value),
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

  Widget _inputField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
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

class _TodoPreset {
  final String name;
  final IconData icon;
  final Color color;
  const _TodoPreset(this.name, this.icon, this.color);
}
