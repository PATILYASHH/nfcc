import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/todo.dart';
import '../../services/database_service.dart';
import '../../utils/icon_lookup.dart';
import '../theme/app_theme.dart';

/// Shown after a tap when multiple TODOs are paired to the same NFC tag.
/// User picks which ones to mark complete.
class TodoTapSheet extends StatefulWidget {
  final List<Todo> todos;
  final String? tagLabel;
  final String? trackerSummary;

  const TodoTapSheet({
    super.key,
    required this.todos,
    this.tagLabel,
    this.trackerSummary,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Todo> todos,
    String? tagLabel,
    String? trackerSummary,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => TodoTapSheet(
        todos: todos,
        tagLabel: tagLabel,
        trackerSummary: trackerSummary,
      ),
    );
  }

  @override
  State<TodoTapSheet> createState() => _TodoTapSheetState();
}

class _TodoTapSheetState extends State<TodoTapSheet> {
  late List<Todo> _todos;

  @override
  void initState() {
    super.initState();
    _todos = [...widget.todos];
  }

  Future<void> _toggle(int i) async {
    final t = _todos[i];
    if (t.id == null) return;
    hapticMedium();
    await context
        .read<DatabaseService>()
        .toggleTodoCompletionToday(t.id!, tagUid: null);
    final fresh = await context.read<DatabaseService>().getTodoById(t.id!);
    if (fresh != null && mounted) {
      setState(() => _todos[i] = fresh);
    }
  }

  Future<void> _markAllDone() async {
    hapticMedium();
    final db = context.read<DatabaseService>();
    for (var i = 0; i < _todos.length; i++) {
      final t = _todos[i];
      if (t.id == null || t.doneToday) continue;
      await db.toggleTodoCompletionToday(t.id!, tagUid: null);
    }
    final refreshed = <Todo>[];
    for (final t in _todos) {
      if (t.id == null) { refreshed.add(t); continue; }
      final f = await db.getTodoById(t.id!);
      refreshed.add(f ?? t);
    }
    if (mounted) setState(() => _todos = refreshed);
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = _todos.where((t) => t.doneToday).length;
    final allDone = _todos.isNotEmpty && doneCount == _todos.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLit,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppColors.nfcGlow,
                        AppColors.accentBlue,
                      ]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.nfcGlow.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.nfc_rounded,
                        size: 22, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tag detected',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3)),
                        const SizedBox(height: 2),
                        Text(
                          widget.tagLabel != null
                              ? widget.tagLabel!
                              : '${_todos.length} TODO${_todos.length == 1 ? "" : "s"} · $doneCount done',
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        size: 22, color: AppColors.textSecondary),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceElevated,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            // Tracker summary banner (if any)
            if (widget.trackerSummary != null && widget.trackerSummary!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          size: 15, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(widget.trackerSummary!,
                            style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('TAP TO TOGGLE COMPLETION',
                    style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _todos.isEmpty
                  ? const Center(
                      child: Text('No TODOs paired with this tag',
                          style: TextStyle(
                              color: AppColors.textTertiary, fontSize: 13)))
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _todos.length,
                      itemBuilder: (_, i) => _buildTile(i),
                    ),
            ),
            // Footer
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Done',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: allDone ? null : _markAllDone,
                        icon: const Icon(Icons.done_all_rounded, size: 18),
                        label: Text(allDone ? 'All done' : 'Mark all complete',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentWhite,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor:
                              AppColors.success.withValues(alpha: 0.2),
                          disabledForegroundColor: AppColors.success,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(int i) {
    final t = _todos[i];
    final color = Color(t.colorValue);
    final icon = iconFromCode(t.iconCode);
    final done = t.doneToday;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done
              ? color.withValues(alpha: 0.4)
              : AppColors.border,
          width: done ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _toggle(i),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42, height: 42,
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
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (t.streak > 0) ...[
                            const Icon(Icons.local_fire_department_rounded,
                                size: 12, color: AppColors.warning),
                            const SizedBox(width: 2),
                            Text('${t.streak}d streak',
                                style: const TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ] else
                            Text(t.recurrence.toUpperCase(),
                                style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (done)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('DONE',
                        style: TextStyle(
                            color: color,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
