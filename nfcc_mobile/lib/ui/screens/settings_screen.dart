import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/pc_connection_service.dart';
import '../theme/app_theme.dart';
import 'pc_connect_screen.dart';
import 'scan_history_screen.dart';
import 'tag_manager_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
        title: const Text('Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Connection ──
          _sectionLabel('CONNECTION'),
          const SizedBox(height: 8),
          Consumer<PcConnectionService>(
            builder: (context, pc, _) {
              final connected = pc.isConnected;
              return _tile(
                icon: Icons.desktop_windows_rounded,
                color: connected ? AppColors.success : AppColors.textSecondary,
                title: 'PC Connection',
                subtitle: connected
                    ? 'Connected to ${pc.pcName ?? "PC"}'
                    : 'Not connected',
                trailing: connected
                    ? Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success,
                          boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.4), blurRadius: 6)],
                        ),
                      )
                    : const Icon(Icons.chevron_right_rounded,
                        size: 20, color: AppColors.textTertiary),
                onTap: () {
                  hapticLight();
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PcConnectScreen()));
                },
              );
            },
          ),

          const SizedBox(height: 20),

          // ── NFC ──
          _sectionLabel('NFC'),
          const SizedBox(height: 8),
          _tile(
            icon: Icons.nfc_rounded,
            color: AppColors.nfcGlow,
            title: 'My Tags',
            subtitle: 'View, rename, and manage your NFC tags',
            trailing: const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textTertiary),
            onTap: () {
              hapticLight();
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TagManagerScreen()));
            },
          ),

          const SizedBox(height: 20),

          // ── History ──
          _sectionLabel('HISTORY'),
          const SizedBox(height: 8),
          _tile(
            icon: Icons.history_rounded,
            color: AppColors.accentBlue,
            title: 'Scan History',
            subtitle: 'View all NFC tag scan activity',
            trailing: const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textTertiary),
            onTap: () {
              hapticLight();
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ScanHistoryScreen()));
            },
          ),
          _tile(
            icon: Icons.delete_sweep_rounded,
            color: AppColors.warning,
            title: 'Clear Scan History',
            subtitle: 'Delete all scan logs',
            trailing: const SizedBox.shrink(),
            onTap: () => _confirmClear(
              context,
              title: 'Clear scan history?',
              message: 'All scan logs will be permanently deleted.',
              onConfirm: () async {
                final db = context.read<DatabaseService>();
                final dbInstance = await db.database;
                await dbInstance.delete('tag_scan_logs');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Scan history cleared'),
                      backgroundColor: AppColors.surfaceHigh,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
            ),
          ),

          const SizedBox(height: 20),

          // ── About ──
          _sectionLabel('ABOUT'),
          const SizedBox(height: 8),
          _tile(
            icon: Icons.info_outline_rounded,
            color: AppColors.accentPurple,
            title: 'NFCC - NFC Control',
            subtitle: 'Version 1.0.0',
            trailing: const SizedBox.shrink(),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _confirmClear(
    BuildContext context, {
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
  }) {
    hapticMedium();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: Text(message,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Clear',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1)),
    );
  }

  Widget _tile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
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
          onTap: onTap,
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
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
