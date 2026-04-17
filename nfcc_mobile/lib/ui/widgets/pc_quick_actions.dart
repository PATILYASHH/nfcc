import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/action_item.dart';
import '../../services/pc_connection_service.dart';
import '../screens/pc_connect_screen.dart';
import '../theme/app_theme.dart';

/// Compact PC live-control bar shown at the top of the routines screen.
/// Tapping an action fires it directly over the WebSocket — no tag tap needed.
class PcQuickActions extends StatelessWidget {
  const PcQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PcConnectionService>(
      builder: (context, pc, _) {
        final connected = pc.isConnected;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: connected
                  ? AppColors.success.withValues(alpha: 0.25)
                  : AppColors.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(context, pc),
                const SizedBox(height: 10),
                if (connected)
                  _actionsScroller(context, pc)
                else
                  _disconnectedHint(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext ctx, PcConnectionService pc) {
    final connected = pc.isConnected;
    return Row(
      children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: connected
                ? AppColors.success.withValues(alpha: 0.14)
                : AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.desktop_windows_rounded,
            size: 18,
            color: connected ? AppColors.success : AppColors.textTertiary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                connected ? (pc.pcName ?? 'PC') : 'PC not connected',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: connected ? AppColors.success : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    connected
                        ? 'Live control'
                        : (pc.state == PcConnectionState.connecting
                            ? 'Connecting...'
                            : 'Tap to pair'),
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.push(
            ctx,
            MaterialPageRoute(builder: (_) => const PcConnectScreen()),
          ),
          icon: const Icon(Icons.settings_rounded,
              size: 18, color: AppColors.textTertiary),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: 'PC pairing',
        ),
      ],
    );
  }

  Widget _disconnectedHint(BuildContext ctx) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => const PcConnectScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: const [
            Icon(Icons.qr_code_scanner_rounded, size: 16, color: AppColors.accentBlue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Scan the PC dashboard QR to enable live control',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _actionsScroller(BuildContext ctx, PcConnectionService pc) {
    final items = <_Quick>[
      _Quick(Icons.lock_rounded, 'Lock', 'lockPc', AppColors.warning),
      _Quick(Icons.bedtime_rounded, 'Sleep', 'sleepPc', AppColors.accentPurple),
      _Quick(Icons.volume_off_rounded, 'Mute', 'toggleMute', AppColors.accentPink),
      _Quick(Icons.volume_up_rounded, 'Vol +', 'volumeUp', AppColors.accentPink),
      _Quick(Icons.volume_down_rounded, 'Vol -', 'volumeDown', AppColors.accentPink),
      _Quick(Icons.play_arrow_rounded, 'Play', 'mediaPlayPause', AppColors.accentCyan),
      _Quick(Icons.skip_next_rounded, 'Next', 'mediaNext', AppColors.accentCyan),
      _Quick(Icons.skip_previous_rounded, 'Prev', 'mediaPrev', AppColors.accentCyan),
      _Quick(Icons.minimize_rounded, 'Desktop', 'minimizeAll', AppColors.accentPurple),
      _Quick(Icons.view_carousel_rounded, 'Task view', 'taskView', AppColors.accentBlue),
      _Quick(Icons.screenshot_monitor_rounded, 'Snip', 'screenshot', AppColors.accentCyan),
      _Quick(Icons.folder_open_rounded, 'Files', 'openFileExplorer', AppColors.warning),
      _Quick(Icons.monitor_heart_rounded, 'Task Mgr', 'openTaskManager', AppColors.error),
      _Quick(Icons.content_paste_rounded, 'Clipboard', 'clipboardHistory', AppColors.accentBlue),
      _Quick(Icons.monitor_rounded, 'Screen off', 'screenOff', AppColors.textSecondary),
      _Quick(Icons.monitor_heart_rounded, 'Stats', 'systemInfo', AppColors.success),
    ];

    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _QuickChip(
          data: items[i],
          onTap: () => _fire(ctx, pc, items[i]),
        ),
      ),
    );
  }

  Future<void> _fire(
      BuildContext ctx, PcConnectionService pc, _Quick q) async {
    hapticLight();
    final action = ActionItem(
      orderIndex: 0,
      target: ActionTarget.pc,
      actionType: q.actionType,
    );
    final res = await pc.sendAction(action);
    if (!ctx.mounted) return;
    final ok = res != null && res['success'] == true;
    final detail = _resultLine(res);
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(detail ?? (ok ? '${q.label} sent' : 'Failed: ${q.label}')),
      backgroundColor: ok ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  String? _resultLine(Map<String, dynamic>? res) {
    if (res == null) return null;
    if (res['success'] == true) {
      final data = res['data'];
      if (data is Map && data.isNotEmpty) {
        if (data['ram'] is Map && data['cpu_percent'] != null) {
          final cpu = data['cpu_percent'];
          final ramPct = data['ram']['percent'];
          final diskPct = data['disk']?['percent'];
          return 'CPU $cpu% · RAM $ramPct% · Disk $diskPct%';
        }
        if (data['percent'] != null && data['plugged'] != null) {
          return 'Battery ${data['percent']}%'
              '${data['plugged'] == true ? ' (charging)' : ''}';
        }
        if (data['ip'] != null) return 'IP: ${data['ip']}';
      }
      return res['message'] as String?;
    }
    return res['error'] as String?;
  }
}

class _Quick {
  final IconData icon;
  final String label;
  final String actionType;
  final Color color;
  _Quick(this.icon, this.label, this.actionType, this.color);
}

class _QuickChip extends StatelessWidget {
  final _Quick data;
  final VoidCallback onTap;
  const _QuickChip({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: data.color.withValues(alpha: 0.18)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(data.icon, size: 20, color: data.color),
              const SizedBox(height: 6),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
