import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/automation.dart';
import '../../services/database_service.dart';
import '../../services/nfc_service.dart';
import '../theme/app_theme.dart';
import 'automation_editor_screen.dart';

class AutomationsScreen extends StatefulWidget {
  const AutomationsScreen({super.key});

  @override
  State<AutomationsScreen> createState() => _AutomationsScreenState();
}

class _AutomationsScreenState extends State<AutomationsScreen> {
  List<Automation> _automations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAutomations();
  }

  Future<void> _loadAutomations() async {
    final db = context.read<DatabaseService>();
    final automations = await db.getAllAutomations();
    if (mounted) {
      setState(() {
        _automations = automations;
        _loading = false;
      });
    }
  }

  Future<void> _toggleAutomation(Automation automation) async {
    final db = context.read<DatabaseService>();
    final updated = automation.copyWith(
      isEnabled: !automation.isEnabled,
      updatedAt: DateTime.now(),
    );
    await db.updateAutomation(updated);
    _loadAutomations();
  }

  Future<void> _writeToTag(Automation automation) async {
    if (automation.id == null) return;

    final nfc = context.read<NfcService>();
    final available = await nfc.isAvailable();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NFC not available')),
        );
      }
      return;
    }

    // Show writing dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _WriteTagDialog(
        automationId: automation.id!,
        automationName: automation.name,
        onCancel: () {
          nfc.stopSession();
          Navigator.pop(ctx);
        },
      ),
    );

    // Start write session
    await nfc.startWriteSession(
      data: 'NFCC:${automation.id}',
      onResult: (success, message) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? 'Automation "${automation.name}" written to tag!'
                  : 'Write failed: $message'),
              backgroundColor:
                  success ? AppColors.success : AppColors.error,
            ),
          );
        }
      },
    );
  }

  Future<void> _deleteAutomation(Automation automation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: const Text('Delete Automation'),
        content: Text('Delete "${automation.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true && automation.id != null) {
      final db = context.read<DatabaseService>();
      await db.deleteAutomation(automation.id!);
      _loadAutomations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
            child: Row(
              children: [
                const Text('Automations',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800)),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AutomationEditorScreen()),
                    );
                    _loadAutomations();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.black, size: 22),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _automations.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadAutomations,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: _automations.length,
                          itemBuilder: (_, i) =>
                              _buildCard(_automations[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded,
              size: 56, color: AppColors.textTertiary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text('No automations yet',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Tap + to create your first automation',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCard(Automation automation) {
    final branchCount = automation.branches.length;
    final actionCount =
        automation.branches.fold<int>(0, (s, b) => s + b.actions.length);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          // Main row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: automation.isEnabled
                        ? AppColors.gradientNfc
                        : null,
                    color:
                        automation.isEnabled ? null : AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_awesome_rounded,
                      color: automation.isEnabled
                          ? Colors.white
                          : AppColors.textTertiary,
                      size: 20),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(automation.name,
                          style: TextStyle(
                              color: automation.isEnabled
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        '$branchCount conditions  ·  $actionCount actions',
                        style: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: automation.isEnabled,
                  onChanged: (_) => _toggleAutomation(automation),
                  activeThumbColor: AppColors.accentBlue,
                ),
              ],
            ),
          ),

          // Action buttons row
          Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                _actionButton(
                  Icons.nfc_rounded,
                  'Write to Tag',
                  AppColors.nfcGlow,
                  () => _writeToTag(automation),
                ),
                const SizedBox(width: 8),
                _actionButton(
                  Icons.edit_rounded,
                  'Edit',
                  AppColors.accentBlue,
                  () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AutomationEditorScreen(automation: automation),
                      ),
                    );
                    _loadAutomations();
                  },
                ),
                const SizedBox(width: 8),
                _actionButton(
                  Icons.delete_outline_rounded,
                  'Delete',
                  AppColors.error,
                  () => _deleteAutomation(automation),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog shown while waiting for user to tap NFC tag for writing
class _WriteTagDialog extends StatelessWidget {
  final int automationId;
  final String automationName;
  final VoidCallback onCancel;

  const _WriteTagDialog({
    required this.automationId,
    required this.automationName,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceHigh,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          const CircularProgressIndicator(color: AppColors.nfcGlow),
          const SizedBox(height: 20),
          const Text('Hold NFC tag near device',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Writing "$automationName"',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}
