import 'package:flutter/material.dart';
import '../../models/action_item.dart';
import '../theme/app_theme.dart';

/// Bottom sheet for building a PC `launchApp` action.
///
/// Shows a grid of common PC apps (VS Code, Chrome, Terminal, Explorer, …)
/// and, for apps that accept a target argument (editors, browsers, file
/// managers), lets the user type a folder / file path / URL that will be
/// passed as argv[1]. For anything not in the preset list, there's a
/// "Custom" row at the bottom.
///
/// Returned [ActionItem] has actionType `launchApp`, target = PC, and
/// params = { name?, path?, target? } consumed by `actions/apps.py::launch_app`.
class PcAppPickerSheet extends StatefulWidget {
  const PcAppPickerSheet({super.key});

  static Future<ActionItem?> show(BuildContext context) {
    return showModalBottomSheet<ActionItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PcAppPickerSheet(),
    );
  }

  @override
  State<PcAppPickerSheet> createState() => _PcAppPickerSheetState();
}

class _PcAppPickerSheetState extends State<PcAppPickerSheet> {
  _PcApp? _selected;
  final _targetCtrl = TextEditingController();
  final _customNameCtrl = TextEditingController();
  final _customTargetCtrl = TextEditingController();
  bool _customMode = false;

  static const _apps = <_PcApp>[
    // Editors / IDEs
    _PcApp('vscode', 'VS Code', Icons.code_rounded, Color(0xFF007ACC),
        acceptsTarget: true, targetHint: r'Folder or file, e.g. C:\code\myrepo'),
    _PcApp('cursor', 'Cursor', Icons.keyboard_rounded, Color(0xFF22D3EE),
        acceptsTarget: true, targetHint: r'Folder or file'),
    _PcApp('sublime', 'Sublime Text', Icons.edit_note_rounded, Color(0xFFFF9800),
        acceptsTarget: true, targetHint: r'File path'),
    _PcApp('notepad', 'Notepad', Icons.note_alt_rounded, Color(0xFF60A5FA),
        acceptsTarget: true, targetHint: r'File path (optional)'),

    // Browsers
    _PcApp('chrome', 'Chrome', Icons.public_rounded, Color(0xFF4285F4),
        acceptsTarget: true, targetHint: 'URL (optional)'),
    _PcApp('edge', 'Edge', Icons.public_rounded, Color(0xFF0078D4),
        acceptsTarget: true, targetHint: 'URL (optional)'),
    _PcApp('firefox', 'Firefox', Icons.local_fire_department_rounded,
        Color(0xFFFF6B00),
        acceptsTarget: true, targetHint: 'URL (optional)'),

    // Terminals
    _PcApp('terminal', 'Terminal', Icons.terminal_rounded,
        Color(0xFFA78BFA),
        acceptsTarget: true, targetHint: 'Start directory (optional)'),
    _PcApp('powershell', 'PowerShell', Icons.terminal_rounded,
        Color(0xFF012456), acceptsTarget: false),
    _PcApp('cmd', 'Command Prompt', Icons.chevron_right_rounded,
        Color(0xFFA0A4AE), acceptsTarget: false),

    // Files / utilities
    _PcApp('explorer', 'File Explorer', Icons.folder_rounded,
        Color(0xFFFFA726),
        acceptsTarget: true, targetHint: r'Folder to open, e.g. C:\Users'),
    _PcApp('calc', 'Calculator', Icons.calculate_rounded,
        Color(0xFF9CA3AF), acceptsTarget: false),
    _PcApp('paint', 'Paint', Icons.brush_rounded, Color(0xFFEC4899),
        acceptsTarget: true, targetHint: 'Image file (optional)'),
    _PcApp('settings', 'Settings', Icons.settings_rounded,
        Color(0xFF3B82F6), acceptsTarget: false),

    // Communication
    _PcApp('discord', 'Discord', Icons.chat_bubble_rounded,
        Color(0xFF5865F2), acceptsTarget: false),
    _PcApp('telegram', 'Telegram', Icons.send_rounded,
        Color(0xFF0088CC), acceptsTarget: false),
    _PcApp('whatsapp', 'WhatsApp', Icons.chat_rounded,
        Color(0xFF25D366), acceptsTarget: false),
    _PcApp('spotify', 'Spotify', Icons.music_note_rounded,
        Color(0xFF1DB954), acceptsTarget: false),

    // Office
    _PcApp('word', 'Word', Icons.description_rounded,
        Color(0xFF2B579A),
        acceptsTarget: true, targetHint: 'Document path (optional)'),
    _PcApp('excel', 'Excel', Icons.table_chart_rounded,
        Color(0xFF217346),
        acceptsTarget: true, targetHint: 'Spreadsheet path (optional)'),
    _PcApp('outlook', 'Outlook', Icons.email_rounded,
        Color(0xFF0072C6), acceptsTarget: false),
    _PcApp('teams', 'Teams', Icons.groups_rounded,
        Color(0xFF6264A7), acceptsTarget: false),
    _PcApp('tally', 'Tally', Icons.account_balance_rounded,
        Color(0xFF00BAF2), acceptsTarget: false),
  ];

  @override
  void dispose() {
    _targetCtrl.dispose();
    _customNameCtrl.dispose();
    _customTargetCtrl.dispose();
    super.dispose();
  }

  void _pick(_PcApp app) {
    hapticLight();
    setState(() {
      _customMode = false;
      _selected = app;
      _targetCtrl.clear();
    });
  }

  void _submit() {
    hapticMedium();
    String? name;
    String? path;
    String? target;

    if (_customMode) {
      final raw = _customNameCtrl.text.trim();
      if (raw.isEmpty) return;
      // Treat as full path if it looks like one, else friendly name.
      if (raw.contains('\\') || raw.contains('/') || raw.endsWith('.exe')) {
        path = raw;
      } else {
        name = raw.toLowerCase();
      }
      final t = _customTargetCtrl.text.trim();
      if (t.isNotEmpty) target = t;
    } else {
      if (_selected == null) return;
      name = _selected!.id;
      final t = _targetCtrl.text.trim();
      if (t.isNotEmpty) target = t;
    }

    final params = <String, dynamic>{};
    if (name != null) params['name'] = name;
    if (path != null) params['path'] = path;
    if (target != null) params['target'] = target;

    Navigator.pop(
      context,
      ActionItem(
        orderIndex: 0,
        target: ActionTarget.pc,
        actionType: 'launchApp',
        params: params,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLit,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Launch PC app',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                    ),
                    TextButton(
                      onPressed: (_customMode || _selected != null) ? _submit : null,
                      child: const Text('Add',
                          style: TextStyle(
                              color: AppColors.accentBlue,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    const _Label('PRESETS'),
                    const SizedBox(height: 8),
                    _buildGrid(),
                    const SizedBox(height: 18),
                    if (!_customMode && _selected != null) _buildTargetForm(),
                    if (_customMode) _buildCustomForm(),
                    const SizedBox(height: 18),
                    _buildCustomToggle(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: _apps.map((a) {
        final sel = !_customMode && _selected?.id == a.id;
        return GestureDetector(
          onTap: () => _pick(a),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: (MediaQuery.of(context).size.width - 32 - 24) / 4,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel
                  ? a.color.withValues(alpha: 0.18)
                  : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: sel ? a.color : AppColors.border,
                width: sel ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(a.icon, size: 22, color: sel ? a.color : AppColors.textSecondary),
                const SizedBox(height: 6),
                Text(a.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: sel ? AppColors.textPrimary : AppColors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTargetForm() {
    final app = _selected!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: app.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(app.icon, size: 18, color: app.color),
              const SizedBox(width: 8),
              Text(app.name,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              if (!app.acceptsTarget)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('Ready',
                      style: TextStyle(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4)),
                ),
            ],
          ),
          if (app.acceptsTarget) ...[
            const SizedBox(height: 10),
            const Text('TARGET (OPTIONAL)',
                style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
            const SizedBox(height: 6),
            TextField(
              controller: _targetCtrl,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: app.targetHint,
                hintStyle: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 12),
                filled: true,
                fillColor: AppColors.surfaceHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              app.id == 'vscode'
                  ? 'Equivalent to:  code <target>'
                  : app.id == 'explorer'
                      ? 'Opens the folder in File Explorer'
                      : 'Passed to ${app.name} as argument on launch',
              style: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomToggle() {
    return InkWell(
      onTap: () => setState(() {
        _customMode = !_customMode;
        if (_customMode) _selected = null;
      }),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _customMode
              ? AppColors.accentBlue.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _customMode ? AppColors.accentBlue : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(_customMode ? Icons.check_circle_rounded : Icons.add_rounded,
                size: 18,
                color: _customMode
                    ? AppColors.accentBlue
                    : AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _customMode
                    ? 'Custom app selected'
                    : 'App not listed? Use a custom path…',
                style: TextStyle(
                    color: _customMode
                        ? AppColors.accentBlue
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomForm() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('APP NAME OR FULL PATH',
              style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
          const SizedBox(height: 6),
          TextField(
            controller: _customNameCtrl,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: r'code   |   C:\Program Files\Foo\bar.exe',
              hintStyle: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 12),
              filled: true,
              fillColor: AppColors.surfaceHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),
          const Text('TARGET (OPTIONAL — file / folder / URL)',
              style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
          const SizedBox(height: 6),
          TextField(
            controller: _customTargetCtrl,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: r'C:\code\myrepo   or   https://example.com',
              hintStyle: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 12),
              filled: true,
              fillColor: AppColors.surfaceHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
      );
}

class _PcApp {
  final String id; // matches APP_ALIASES on the PC side
  final String name;
  final IconData icon;
  final Color color;
  final bool acceptsTarget;
  final String targetHint;
  const _PcApp(
    this.id,
    this.name,
    this.icon,
    this.color, {
    this.acceptsTarget = false,
    this.targetHint = '',
  });
}
