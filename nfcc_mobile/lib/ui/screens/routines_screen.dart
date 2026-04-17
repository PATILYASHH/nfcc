import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/automation.dart';
import '../../models/action_item.dart';
import '../../models/condition_branch.dart';
import '../../models/tag_scan_log.dart';
import '../../services/database_service.dart';
import '../../services/nfc_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pc_quick_actions.dart';
import 'automation_editor_screen.dart';
import 'scan_history_screen.dart';

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  List<Automation> _routines = [];
  Map<String, TagScanLog> _lastScans = {};
  bool _loading = true;
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = context.read<DatabaseService>();
    final r = await db.getAllAutomations();
    final s = await db.getRecentScans(limit: 200);
    final map = <String, TagScanLog>{};
    for (final x in s) {
      if (x.automationName != null && !map.containsKey(x.automationName)) {
        map[x.automationName!] = x;
      }
    }
    if (mounted) {
      setState(() { _routines = r; _lastScans = map; _loading = false; });
    }
  }

  List<Automation> get _filtered {
    if (_query.isEmpty) return _routines;
    final q = _query.toLowerCase();
    return _routines.where((r) => r.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _toggle(Automation r) async {
    hapticLight();
    await context.read<DatabaseService>().updateAutomation(r.copyWith(
      isEnabled: !r.isEnabled,
      updatedAt: DateTime.now(),
    ));
    _load();
  }

  Future<void> _delete(Automation r) async {
    if (r.id == null) return;
    hapticMedium();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Smart NFC?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: Text('Delete "${r.name}"? This can\'t be undone.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (ok == true) {
      await context.read<DatabaseService>().deleteAutomation(r.id!);
      _load();
    }
  }

  Future<void> _duplicate(Automation r) async {
    hapticMedium();
    final db = context.read<DatabaseService>();
    final now = DateTime.now();
    final copy = Automation(
      name: '${r.name} (copy)',
      tagUid: null,
      isEnabled: r.isEnabled,
      branches: r.branches.map((b) => ConditionBranch(
        orderIndex: b.orderIndex,
        type: b.type,
        params: Map<String, dynamic>.from(b.params),
        subConditions: b.subConditions,
        actions: b.actions.map((a) => a.copyWith(id: null, conditionBranchId: null)).toList(),
      )).toList(),
      createdAt: now,
      updatedAt: now,
    );
    final id = await db.insertAutomation(copy);
    final fresh = await db.getAutomationById(id);
    _load();
    if (mounted && fresh != null) {
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => AutomationEditorScreen(automation: fresh)));
      _load();
    }
  }

  Future<void> _writeToTag(Automation r) async {
    if (r.id == null) return;
    hapticMedium();
    final nfc = context.read<NfcService>();
    if (!await nfc.isAvailable()) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('NFC not available')));
      }
      return;
    }
    if (!mounted) return;

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
                color: AppColors.nfcGlow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.nfc_rounded, size: 32, color: AppColors.nfcGlow),
            ),
            const SizedBox(height: 20),
            const Text('Hold NFC tag near device',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Writing "${r.name}"',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              nfc.stopSession();
              Navigator.pop(ctx);
            },
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );

    await nfc.startWriteSession(
      data: 'NFCC:${r.id}',
      onResult: (success, msg) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(success ? '"${r.name}" written to tag!' : 'Failed: $msg'),
            backgroundColor: success ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ));
        }
      },
    );
  }

  void _showMenu(Automation r) {
    hapticMedium();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLit,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(r.name,
                    style: const TextStyle(color: AppColors.textPrimary,
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              _menuItem(ctx, Icons.edit_rounded, AppColors.accentBlue, 'Edit', () async {
                Navigator.pop(ctx);
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => AutomationEditorScreen(automation: r)));
                _load();
              }),
              _menuItem(ctx, Icons.copy_rounded, AppColors.accentCyan, 'Duplicate', () {
                Navigator.pop(ctx);
                _duplicate(r);
              }),
              _menuItem(ctx, Icons.nfc_rounded, AppColors.nfcGlow, 'Write to Tag', () {
                Navigator.pop(ctx);
                _writeToTag(r);
              }),
              _menuItem(ctx, Icons.history_rounded, AppColors.accentPurple, 'Scan History', () {
                Navigator.pop(ctx);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ScanHistoryScreen()));
              }),
              _menuItem(ctx, Icons.delete_rounded, AppColors.error, 'Delete', () {
                Navigator.pop(ctx);
                _delete(r);
              }),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(BuildContext ctx, IconData icon, Color color, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () { hapticLight(); onTap(); },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 14),
              Text(label, style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Color _accent(Automation r) {
    if (r.branches.isEmpty) return AppColors.accentBlue;
    final first = r.branches.first;
    if (first.subConditions.isEmpty) return AppColors.accentBlue;
    switch (first.subConditions.first.type) {
      case 'time': return AppColors.accentBlue;
      case 'day': return AppColors.accentPurple;
      case 'btConnected': return AppColors.accentCyan;
      case 'wifiConnected': return AppColors.accentOrange;
      default: return AppColors.accentBlue;
    }
  }

  IconData _conditionIcon(String type) {
    switch (type) {
      case 'time': return Icons.schedule_rounded;
      case 'day': return Icons.calendar_today_rounded;
      case 'btConnected': return Icons.bluetooth_rounded;
      case 'wifiConnected': return Icons.wifi_rounded;
      default: return Icons.tune_rounded;
    }
  }

  IconData _actionIcon(String actionType, ActionTarget target) {
    if (target == ActionTarget.pc) return Icons.desktop_windows_rounded;
    switch (actionType) {
      case 'toggleWifi':
      case 'wifiOn':
      case 'wifiOff': return Icons.wifi_rounded;
      case 'toggleBluetooth':
      case 'btOn':
      case 'btOff': return Icons.bluetooth_rounded;
      case 'musicPlayPause':
      case 'musicNext': return Icons.music_note_rounded;
      case 'setVolume': return Icons.volume_up_rounded;
      case 'openApp': return Icons.apps_rounded;
      case 'toggleDnd': return Icons.do_not_disturb_rounded;
      case 'toggleFlashlight': return Icons.flashlight_on_rounded;
      default: return Icons.play_arrow_rounded;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
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
        title: const Text('Routines',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              color: AppColors.nfcGlow, strokeWidth: 2.5))
          : _routines.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.nfcGlow,
                  backgroundColor: AppColors.surfaceHigh,
                  child: Column(
                    children: [
                      const PcQuickActions(),
                      if (_routines.length >= 3)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _query = v),
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search routines...',
                              hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textTertiary),
                              isDense: true, filled: true,
                              fillColor: AppColors.surfaceElevated,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 100),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _buildCard(_filtered[i]),
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          hapticMedium();
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AutomationEditorScreen()));
          _load();
        },
        backgroundColor: AppColors.accentWhite,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New routine',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildEmpty() {
    return Column(
      children: [
        const PcQuickActions(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88, height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.nfcGlow.withValues(alpha: 0.08),
                  AppColors.accentBlue.withValues(alpha: 0.04),
                ]),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.nfcGlow.withValues(alpha: 0.15)),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 38, color: AppColors.nfcGlow),
            ),
            const SizedBox(height: 20),
            const Text('No routines yet',
                style: TextStyle(color: AppColors.textPrimary,
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
              'Create a routine and write it to an NFC tag.\nTap the tag anytime to trigger it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13, height: 1.5),
            ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(Automation r) {
    final color = _accent(r);
    final actionCount = r.branches.fold<int>(0, (s, b) => s + b.actions.length);
    final condTypes = <String>{};
    for (final b in r.branches) {
      for (final sc in b.subConditions) condTypes.add(sc.type);
    }
    final actionIcons = <IconData>[];
    for (final b in r.branches) {
      for (final a in b.actions) {
        if (actionIcons.length >= 3) break;
        actionIcons.add(_actionIcon(a.actionType, a.target));
      }
    }

    return Dismissible(
      key: Key('r_${r.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async { _delete(r); return false; },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.error, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: r.isEnabled ? color.withValues(alpha: 0.12) : AppColors.border,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onLongPress: () => _showMenu(r),
            onTap: () async {
              hapticLight();
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AutomationEditorScreen(automation: r)));
              _load();
            },
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
                          gradient: r.isEnabled
                              ? LinearGradient(colors: [
                                  color.withValues(alpha: 0.15),
                                  color.withValues(alpha: 0.06),
                                ], begin: Alignment.topLeft, end: Alignment.bottomRight)
                              : null,
                          color: r.isEnabled ? null : AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.auto_awesome_rounded, size: 22,
                            color: r.isEnabled ? color : AppColors.textTertiary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.name, style: TextStyle(
                                color: r.isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
                                fontSize: 16, fontWeight: FontWeight.w600)),
                            if (condTypes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  ...condTypes.take(3).map((t) => Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Icon(_conditionIcon(t), size: 13, color: AppColors.textTertiary),
                                  )),
                                  if (actionIcons.isNotEmpty) ...[
                                    Container(
                                      width: 1, height: 10,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      color: AppColors.border,
                                    ),
                                    const Icon(Icons.arrow_forward_rounded, size: 10, color: AppColors.textTertiary),
                                    const SizedBox(width: 4),
                                    ...actionIcons.map((a) => Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Icon(a, size: 13, color: AppColors.textTertiary),
                                    )),
                                    if (actionCount > 3)
                                      Text('+${actionCount - 3}',
                                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: r.isEnabled,
                        onChanged: (_) => _toggle(r),
                        activeTrackColor: color,
                        inactiveTrackColor: AppColors.surfaceHigh,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _chip(Icons.alt_route_rounded, '${r.branches.length}'),
                      const SizedBox(width: 6),
                      _chip(Icons.play_arrow_rounded, '$actionCount'),
                      const SizedBox(width: 6),
                      if (_lastScans.containsKey(r.name)) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _lastScans[r.name]!.success
                                ? AppColors.success.withValues(alpha: 0.08)
                                : AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5, height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _lastScans[r.name]!.success ? AppColors.success : AppColors.error,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(_timeAgo(_lastScans[r.name]!.scannedAt),
                                  style: TextStyle(
                                      color: _lastScans[r.name]!.success ? AppColors.success : AppColors.error,
                                      fontSize: 10, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      Material(
                        color: AppColors.nfcGlow.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _writeToTag(r),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.nfc_rounded, size: 14, color: AppColors.nfcGlow),
                                SizedBox(width: 6),
                                Text('Write', style: TextStyle(
                                    color: AppColors.nfcGlow, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(
              color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
