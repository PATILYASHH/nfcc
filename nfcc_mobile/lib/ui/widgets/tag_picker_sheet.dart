import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/nfc_tag.dart';
import '../../services/database_service.dart';
import '../theme/app_theme.dart';

/// Lets the user pick one or more known NFC tags (UIDs). Returns selected UIDs.
class TagPickerSheet extends StatefulWidget {
  final List<String> initialSelection;
  final bool multiSelect;
  final String title;

  const TagPickerSheet({
    super.key,
    this.initialSelection = const [],
    this.multiSelect = true,
    this.title = 'Pair NFC tags',
  });

  static Future<List<String>?> show(BuildContext context,
      {List<String> initial = const [],
      bool multiSelect = true,
      String title = 'Pair NFC tags'}) {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TagPickerSheet(
          initialSelection: initial, multiSelect: multiSelect, title: title),
    );
  }

  @override
  State<TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<TagPickerSheet> {
  List<NfcTag> _tags = [];
  late Set<String> _selected;
  bool _loading = true;
  final _manualCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initialSelection};
    _load();
  }

  @override
  void dispose() {
    _manualCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final tags = await context.read<DatabaseService>().getAllTags();
      if (mounted) setState(() { _tags = tags; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggle(String uid) {
    setState(() {
      if (widget.multiSelect) {
        if (_selected.contains(uid)) {
          _selected.remove(uid);
        } else {
          _selected.add(uid);
        }
      } else {
        _selected
          ..clear()
          ..add(uid);
      }
    });
    hapticLight();
  }

  void _addManual() {
    final uid = _manualCtrl.text.trim();
    if (uid.isEmpty) return;
    setState(() {
      if (widget.multiSelect) {
        _selected.add(uid);
      } else {
        _selected..clear()..add(uid);
      }
      _manualCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
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
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                  ),
                  Text('${_selected.length} selected',
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Manual UID entry
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_rounded, size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _manualCtrl,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontFamily: 'monospace'),
                        decoration: const InputDecoration(
                          hintText: 'Enter tag UID manually',
                          hintStyle: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                              fontFamily: 'monospace'),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addManual(),
                      ),
                    ),
                    TextButton(
                      onPressed: _addManual,
                      child: const Text('Add',
                          style: TextStyle(
                              color: AppColors.accentBlue,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('KNOWN TAGS',
                    style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accentBlue, strokeWidth: 2.5))
                  : _buildTagList(scrollCtrl),
            ),
            // Manual-selected UIDs not in known tags
            ..._buildManualChips(),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                        child: const Text('Cancel',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, _selected.toList()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentWhite,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Use ${_selected.length} tag${_selected.length == 1 ? '' : 's'}',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
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

  List<Widget> _buildManualChips() {
    final knownUids = _tags.map((t) => t.uid).toSet();
    final manual = _selected.where((u) => !knownUids.contains(u)).toList();
    if (manual.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 6, runSpacing: 6,
            children: manual.map((uid) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(uid,
                      style: const TextStyle(
                          color: AppColors.accentBlue,
                          fontSize: 11,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => setState(() => _selected.remove(uid)),
                    child: const Icon(Icons.close_rounded,
                        size: 12, color: AppColors.accentBlue),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ),
    ];
  }

  Widget _buildTagList(ScrollController ctrl) {
    if (_tags.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  color: AppColors.nfcGlow.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.nfc_rounded,
                    size: 28, color: AppColors.nfcGlow),
              ),
              const SizedBox(height: 14),
              const Text('No known tags yet',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Scan a tag with NFC Writer first\nor enter a UID manually above',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textTertiary, fontSize: 12)),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      controller: ctrl,
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: _tags.length,
      itemBuilder: (_, i) {
        final tag = _tags[i];
        final selected = _selected.contains(tag.uid);
        return InkWell(
          onTap: () => _toggle(tag.uid),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accentBlue.withValues(alpha: 0.15)
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? AppColors.accentBlue
                          : AppColors.border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Icon(
                    selected
                        ? Icons.check_rounded
                        : Icons.nfc_rounded,
                    size: 18,
                    color: selected
                        ? AppColors.accentBlue
                        : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tag.nickname ?? tag.tagType ?? 'Tag',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(tag.uid,
                          style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                              fontFamily: 'monospace')),
                    ],
                  ),
                ),
                Text('×${tag.scanCount}',
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );
  }
}
