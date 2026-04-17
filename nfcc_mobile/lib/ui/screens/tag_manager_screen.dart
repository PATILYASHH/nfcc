import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../models/nfc_tag.dart';
import '../theme/app_theme.dart';

class TagManagerScreen extends StatefulWidget {
  const TagManagerScreen({super.key});

  @override
  State<TagManagerScreen> createState() => _TagManagerScreenState();
}

class _TagManagerScreenState extends State<TagManagerScreen> {
  List<NfcTag> _tags = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final db = context.read<DatabaseService>();
    final tags = await db.getAllTags();
    if (mounted) {
      setState(() {
        _tags = tags;
        _loading = false;
      });
    }
  }

  String _relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '${m}m ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '${h}h ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '${d}d ago';
    }
    if (diff.inDays < 30) {
      final w = diff.inDays ~/ 7;
      return '${w}w ago';
    }
    if (diff.inDays < 365) {
      final mo = diff.inDays ~/ 30;
      return '${mo}mo ago';
    }
    final y = diff.inDays ~/ 365;
    return '${y}y ago';
  }

  Future<void> _editNickname(NfcTag tag) async {
    hapticMedium();
    final controller = TextEditingController(text: tag.nickname ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: const Text(
          'Edit Nickname',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          cursorColor: AppColors.nfcGlow,
          decoration: InputDecoration(
            hintText: 'Enter nickname',
            hintStyle: const TextStyle(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.surfaceElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.nfcGlow),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text(
              'Save',
              style: TextStyle(color: AppColors.nfcGlow),
            ),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      final db = context.read<DatabaseService>();
      final updated = tag.copyWith(
        nickname: result.isEmpty ? null : result,
      );
      await db.updateTag(updated);
      _loadTags();
    }
  }

  void _navigateToScanHistory(NfcTag tag) {
    hapticLight();
    // Navigate to scan history filtered for this tag.
    // When ScanHistoryScreen exists, replace with direct import.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _TagScanHistoryPlaceholder(tag: tag),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Tags',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.nfcGlow))
          : _tags.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: AppColors.nfcGlow,
                  backgroundColor: AppColors.surfaceElevated,
                  onRefresh: _loadTags,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _tags.length,
                    itemBuilder: (_, i) => _buildTagCard(_tags[i]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.nfc_rounded,
            size: 64,
            color: AppColors.textTertiary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'No tags scanned yet',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Scan an NFC tag to see it here',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTagCard(NfcTag tag) {
    final displayName = tag.nickname;
    final hasNickname = displayName != null && displayName.isNotEmpty;

    return Dismissible(
      key: ValueKey(tag.id ?? tag.uid),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_rounded, color: AppColors.error, size: 24),
      ),
      confirmDismiss: (_) async {
        hapticMedium();
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceHigh,
            title: const Text(
              'Delete Tag',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'Remove "${hasNickname ? displayName : tag.uid}" from your tags?',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        );
        return confirm == true;
      },
      onDismissed: (_) {
        if (tag.id != null) {
          final db = context.read<DatabaseService>();
          db.deleteTag(tag.id!);
          setState(() => _tags.removeWhere((t) => t.id == tag.id));
          hapticLight();
        }
      },
      child: GestureDetector(
        onTap: () => _navigateToScanHistory(tag),
        onLongPress: () => _editNickname(tag),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: icon + name + edit button
              Row(
                children: [
                  // NFC icon
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.nfcGlow.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.nfc_rounded,
                      color: AppColors.nfcGlow,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + UID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasNickname ? displayName : 'Unnamed Tag',
                          style: TextStyle(
                            color: hasNickname
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontStyle: hasNickname
                                ? FontStyle.normal
                                : FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tag.uid,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                            fontFamily: 'monospace',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Edit nickname button
                  GestureDetector(
                    onTap: () => _editNickname(tag),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: AppColors.textTertiary,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Info chips row
              Row(
                children: [
                  if (tag.tagType != null && tag.tagType!.isNotEmpty)
                    _buildChip(tag.tagType!),
                  _buildChip('\u00d7${tag.scanCount}'),
                  if (tag.technology != null && tag.technology!.isNotEmpty)
                    _buildChip(tag.technology!),
                  const Spacer(),
                  // Last scanned
                  Text(
                    'Last: ${_relativeTime(tag.lastScanned)}',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Temporary placeholder for scan history until the dedicated screen is created.
/// Replace this with the real ScanHistoryScreen import when available.
class _TagScanHistoryPlaceholder extends StatelessWidget {
  final NfcTag tag;

  const _TagScanHistoryPlaceholder({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tag.nickname ?? tag.uid,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<List>(
        future: context.read<DatabaseService>().getScansForTag(tag.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.nfcGlow),
            );
          }

          final scans = snapshot.data ?? [];
          if (scans.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 48,
                    color: AppColors.textTertiary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No scan history',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: scans.length,
            itemBuilder: (_, i) {
              final scan = scans[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.nfcGlow,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        scan.toString(),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
