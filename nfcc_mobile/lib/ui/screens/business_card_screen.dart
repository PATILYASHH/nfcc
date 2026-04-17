import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/nfc_service.dart';
import '../../utils/card_html_generator.dart';
import '../theme/app_theme.dart';

const _accentColors = <_AccentOption>[
  _AccentOption('Blue', Color(0xFF00B0FF), '#00B0FF'),
  _AccentOption('Purple', Color(0xFF8B5CF6), '#8B5CF6'),
  _AccentOption('Green', Color(0xFF22C55E), '#22C55E'),
  _AccentOption('Orange', Color(0xFFF97316), '#F97316'),
  _AccentOption('Pink', Color(0xFFEC4899), '#EC4899'),
];

class _AccentOption {
  final String label;
  final Color color;
  final String hex;
  const _AccentOption(this.label, this.color, this.hex);
}

class BusinessCardScreen extends StatefulWidget {
  const BusinessCardScreen({super.key});

  @override
  State<BusinessCardScreen> createState() => _BusinessCardScreenState();
}

class _BusinessCardScreenState extends State<BusinessCardScreen> {
  final _nameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();
  final _twitterCtrl = TextEditingController();

  int _selectedColor = 0;
  bool _darkMode = true;
  String? _statusMsg;
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _linkedinCtrl.dispose();
    _instagramCtrl.dispose();
    _githubCtrl.dispose();
    _twitterCtrl.dispose();
    super.dispose();
  }

  bool get _isValid => _nameCtrl.text.trim().isNotEmpty;

  String _val(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? '' : v;
  }

  String? _opt(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  void _setStatus(String msg, {bool busy = false}) {
    if (mounted) setState(() { _statusMsg = msg; _busy = busy; });
  }

  // ── Write Modes ─────────────────────────────────────────────────────────

  Future<void> _writeEmbedded() async {
    if (!_isValid) return;
    hapticMedium();

    final nfc = context.read<NfcService>();
    if (!await nfc.isAvailable()) {
      _setStatus('NFC not available');
      return;
    }

    // Generate compact HTML and base64 encode
    final html = generateCompactCardHtml(
      name: _val(_nameCtrl),
      title: _opt(_titleCtrl),
      phone: _opt(_phoneCtrl),
      email: _opt(_emailCtrl),
      accentColor: _accentColors[_selectedColor].hex,
    );

    final b64 = base64Encode(utf8.encode(html));
    final dataUri = 'data:text/html;base64,$b64';

    // Check size
    final uriBytes = utf8.encode(dataUri);
    if (uriBytes.length > 700) {
      _setStatus('Card too large for tag (${uriBytes.length} bytes). Remove some fields or use "Host on PC" mode.');
      return;
    }

    _setStatus('Hold NFC tag near device...', busy: true);

    final payload = Uint8List(1 + uriBytes.length);
    payload[0] = 0; // no URI prefix
    payload.setRange(1, payload.length, uriBytes);

    final record = NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList([0x55]),
      identifier: Uint8List(0),
      payload: payload,
    );

    await nfc.startRawWriteSession(
      records: [record],
      onResult: (success, msg) {
        _setStatus(success ? 'Business card written to tag!' : 'Write failed: $msg');
      },
    );
  }

  Future<void> _shareAsFile() async {
    if (!_isValid) return;
    hapticMedium();

    final html = generateBusinessCardHtml(
      name: _val(_nameCtrl),
      title: _opt(_titleCtrl),
      company: _opt(_companyCtrl),
      phone: _opt(_phoneCtrl),
      email: _opt(_emailCtrl),
      website: _opt(_websiteCtrl),
      linkedin: _opt(_linkedinCtrl),
      instagram: _opt(_instagramCtrl),
      github: _opt(_githubCtrl),
      twitter: _opt(_twitterCtrl),
      accentColor: _accentColors[_selectedColor].hex,
      darkMode: _darkMode,
    );

    try {
      final dir = await getTemporaryDirectory();
      final name = _val(_nameCtrl).replaceAll(RegExp(r'[^\w]'), '_').toLowerCase();
      final file = File('${dir.path}/${name}_card.html');
      await file.writeAsString(html);
      _setStatus('Card saved to: ${file.path}\nShare it via any app!');
    } catch (e) {
      _setStatus('Error: $e');
    }
  }

  Future<void> _publishToWeb() async {
    if (!_isValid) return;
    hapticMedium();

    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('vercel_url') ?? '';
    final token = prefs.getString('vercel_token') ?? '';

    if (baseUrl.isEmpty || token.isEmpty) {
      _showVercelSetup();
      return;
    }

    _setStatus('Publishing card...', busy: true);

    final html = generateBusinessCardHtml(
      name: _val(_nameCtrl),
      title: _opt(_titleCtrl),
      company: _opt(_companyCtrl),
      phone: _opt(_phoneCtrl),
      email: _opt(_emailCtrl),
      website: _opt(_websiteCtrl),
      linkedin: _opt(_linkedinCtrl),
      instagram: _opt(_instagramCtrl),
      github: _opt(_githubCtrl),
      twitter: _opt(_twitterCtrl),
      accentColor: _accentColors[_selectedColor].hex,
      darkMode: _darkMode,
    );

    final slug = _val(_nameCtrl)
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    try {
      final url = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
      final resp = await http.post(
        Uri.parse('${url}api/publish'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'slug': slug,
          'html': html,
          'name': _val(_nameCtrl),
          'token': token,
        }),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final cardUrl = data['url'] as String;
        _setStatus('Published! URL: $cardUrl');

        // Ask to write URL to NFC tag
        if (mounted) {
          final writeTag = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surfaceHigh,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Card Published!',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your card is live at:',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(cardUrl,
                        style: const TextStyle(
                            color: AppColors.accentCyan, fontSize: 13, fontFamily: 'monospace')),
                  ),
                  const SizedBox(height: 12),
                  const Text('Write this URL to an NFC tag?',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Later', style: TextStyle(color: AppColors.textSecondary))),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Write to Tag',
                        style: TextStyle(color: AppColors.nfcGlow, fontWeight: FontWeight.w600))),
              ],
            ),
          );

          if (writeTag == true) {
            await _writeUrlToTag(cardUrl);
          }
        }
      } else {
        final err = jsonDecode(resp.body)['error'] ?? 'Unknown error';
        _setStatus('Publish failed: $err');
      }
    } catch (e) {
      _setStatus('Network error: $e');
    }
  }

  Future<void> _writeUrlToTag(String url) async {
    final nfc = context.read<NfcService>();
    if (!await nfc.isAvailable()) {
      _setStatus('NFC not available');
      return;
    }
    _setStatus('Hold NFC tag near device...', busy: true);

    // Use prefix 4 = "https://"
    int prefix = 0;
    String stripped = url;
    if (url.startsWith('https://')) {
      prefix = 4;
      stripped = url.substring(8);
    } else if (url.startsWith('http://')) {
      prefix = 3;
      stripped = url.substring(7);
    }

    final strippedBytes = utf8.encode(stripped);
    final payload = Uint8List(1 + strippedBytes.length);
    payload[0] = prefix;
    payload.setRange(1, payload.length, strippedBytes);

    final record = NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList([0x55]),
      identifier: Uint8List(0),
      payload: payload,
    );

    await nfc.startRawWriteSession(
      records: [record],
      onResult: (success, msg) {
        _setStatus(success ? 'Card URL written to tag!' : 'Write failed: $msg');
      },
    );
  }

  void _showVercelSetup() {
    final urlCtrl = TextEditingController();
    final tokenCtrl = TextEditingController();

    // Pre-fill from saved values
    SharedPreferences.getInstance().then((prefs) {
      urlCtrl.text = prefs.getString('vercel_url') ?? '';
      tokenCtrl.text = prefs.getString('vercel_token') ?? '';
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderLit,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text('Web Hosting Setup',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text(
                    'Connect your Vercel project to publish cards online.',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  const Text('Project URL',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: urlCtrl,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'https://nfcc-cards.vercel.app',
                      hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('API Token',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: tokenCtrl,
                    obscureText: true,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Your NFCC_API_TOKEN',
                      hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () async {
                        final url = urlCtrl.text.trim();
                        final token = tokenCtrl.text.trim();
                        if (url.isEmpty || token.isEmpty) return;
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('vercel_url', url);
                        await prefs.setString('vercel_token', token);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _setStatus('Web hosting configured!');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentWhite,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

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
        title: const Text('Business Card',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Header Info ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _accentColors[_selectedColor].color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _accentColors[_selectedColor].color.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _accentColors[_selectedColor].color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.badge_rounded, size: 22,
                      color: _accentColors[_selectedColor].color),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Design your digital card',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('Fill in details, then write to NFC tag or share',
                          style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Personal Info ──
          _sectionLabel('PERSONAL'),
          const SizedBox(height: 8),
          _field(_nameCtrl, 'Full Name *', 'Yash Patil', Icons.person_rounded),
          _field(_titleCtrl, 'Job Title', 'Software Developer', Icons.work_rounded),
          _field(_companyCtrl, 'Company', 'TechCorp', Icons.business_rounded),

          const SizedBox(height: 20),

          // ── Contact ──
          _sectionLabel('CONTACT'),
          const SizedBox(height: 8),
          _field(_phoneCtrl, 'Phone', '+91 98765 43210', Icons.phone_rounded,
              keyboard: TextInputType.phone),
          _field(_emailCtrl, 'Email', 'name@example.com', Icons.email_rounded,
              keyboard: TextInputType.emailAddress),
          _field(_websiteCtrl, 'Website', 'portfolio.com', Icons.language_rounded,
              keyboard: TextInputType.url),

          const SizedBox(height: 20),

          // ── Social ──
          _sectionLabel('SOCIAL'),
          const SizedBox(height: 8),
          _field(_linkedinCtrl, 'LinkedIn', 'username', Icons.link_rounded),
          _field(_instagramCtrl, 'Instagram', '@handle', Icons.camera_alt_rounded),
          _field(_githubCtrl, 'GitHub', 'username', Icons.code_rounded),
          _field(_twitterCtrl, 'Twitter / X', '@handle', Icons.alternate_email_rounded),

          const SizedBox(height: 20),

          // ── Theme ──
          _sectionLabel('THEME'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Color picker
                const Text('Accent Color',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(_accentColors.length, (i) {
                    final selected = _selectedColor == i;
                    return GestureDetector(
                      onTap: () {
                        hapticLight();
                        setState(() => _selectedColor = i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 38, height: 38,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: _accentColors[i].color,
                          borderRadius: BorderRadius.circular(12),
                          border: selected
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                          boxShadow: selected
                              ? [BoxShadow(
                                  color: _accentColors[i].color.withValues(alpha: 0.4),
                                  blurRadius: 8)]
                              : null,
                        ),
                        child: selected
                            ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                            : null,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                // Dark/Light toggle
                Row(
                  children: [
                    const Text('Dark Mode',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const Spacer(),
                    Switch.adaptive(
                      value: _darkMode,
                      onChanged: (v) => setState(() => _darkMode = v),
                      activeTrackColor: _accentColors[_selectedColor].color,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Action Buttons ──
          _sectionLabel('PUBLISH & WRITE'),
          const SizedBox(height: 8),

          // Publish to web (primary action)
          _actionButton(
            icon: Icons.language_rounded,
            color: AppColors.accentCyan,
            title: 'Publish to Web',
            subtitle: 'Upload to your website — get a link & write to NFC tag',
            onTap: _busy ? null : _publishToWeb,
          ),

          const SizedBox(height: 8),

          // Embed on tag
          _actionButton(
            icon: Icons.nfc_rounded,
            color: AppColors.nfcGlow,
            title: 'Embed on Tag',
            subtitle: 'Basic card stored directly on tag (name, title, phone, email only)',
            onTap: _busy ? null : _writeEmbedded,
          ),

          const SizedBox(height: 8),

          // Share as file
          _actionButton(
            icon: Icons.share_rounded,
            color: AppColors.accentPurple,
            title: 'Share as File',
            subtitle: 'Full card HTML — share via WhatsApp, email, Drive',
            onTap: _busy ? null : _shareAsFile,
          ),

          // ── Status ──
          if (_statusMsg != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _busy
                      ? AppColors.nfcGlow.withValues(alpha: 0.2)
                      : _statusMsg!.contains('written') || _statusMsg!.contains('saved')
                          ? AppColors.success.withValues(alpha: 0.2)
                          : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  if (_busy)
                    const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.nfcGlow))
                  else
                    Icon(
                      _statusMsg!.contains('written') || _statusMsg!.contains('saved')
                          ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      size: 16,
                      color: _statusMsg!.contains('written') || _statusMsg!.contains('saved')
                          ? AppColors.success : AppColors.textSecondary,
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_statusMsg!,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 12, height: 1.4)),
                  ),
                  if (!_busy)
                    GestureDetector(
                      onTap: () => setState(() => _statusMsg = null),
                      child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textTertiary),
                    ),
                ],
              ),
            ),
          ],
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
              letterSpacing: 0.8)),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint, IconData icon,
      {TextInputType? keyboard}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboard,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: AppColors.textTertiary),
          prefixIconConstraints: const BoxConstraints(minWidth: 44),
          filled: true,
          fillColor: AppColors.surfaceElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: _accentColors[_selectedColor].color, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap != null ? () {
            hapticLight();
            onTap();
          } : null,
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
                const Icon(Icons.chevron_right_rounded,
                    size: 20, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
