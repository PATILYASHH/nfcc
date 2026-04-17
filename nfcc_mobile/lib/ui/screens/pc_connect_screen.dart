import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../models/paired_pc.dart';
import '../../services/database_service.dart';
import '../../services/pc_connection_service.dart';
import '../theme/app_theme.dart';

class PcConnectScreen extends StatefulWidget {
  const PcConnectScreen({super.key});

  @override
  State<PcConnectScreen> createState() => _PcConnectScreenState();
}

class _PcConnectScreenState extends State<PcConnectScreen> {
  List<PairedPc> _pairedPcs = [];
  bool _scanning = false;
  bool _discovering = false;
  List<Map<String, dynamic>> _discoveredPcs = [];

  @override
  void initState() {
    super.initState();
    _loadPairedPcs();
  }

  Future<void> _loadPairedPcs() async {
    final db = context.read<DatabaseService>();
    final pcs = await db.getPairedPcs();
    if (mounted) setState(() => _pairedPcs = pcs);
  }

  Future<void> _scanQr() async {
    setState(() => _scanning = true);
  }

  void _onQrDetected(BarcodeCapture capture) {
    if (!_scanning) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _scanning = false);

    try {
      final data =
          jsonDecode(barcode!.rawValue!) as Map<String, dynamic>;
      if (data.containsKey('id') &&
          data.containsKey('ip') &&
          data.containsKey('port') &&
          data.containsKey('token')) {
        _connectFromQr(data);
      } else {
        _showError('Invalid QR code');
      }
    } catch (_) {
      _showError('Could not read QR code');
    }
  }

  Future<void> _connectFromQr(Map<String, dynamic> data) async {
    final pcService = context.read<PcConnectionService>();
    await pcService.connectFromQr(data);
    _loadPairedPcs();
  }

  Future<void> _connectToPc(PairedPc pc) async {
    final pcService = context.read<PcConnectionService>();
    await pcService.connectToPc(pc);
  }

  Future<void> _discoverPcs() async {
    setState(() => _discovering = true);
    final pcService = context.read<PcConnectionService>();
    final results = await pcService.discoverPcs();
    if (mounted) {
      setState(() {
        _discoveredPcs = results;
        _discovering = false;
      });
    }
  }

  Future<void> _removePc(PairedPc pc) async {
    final db = context.read<DatabaseService>();
    await db.deletePairedPc(pc.id);
    _loadPairedPcs();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('PC Connection'),
      ),
      body: _scanning ? _buildQrScanner() : _buildContent(),
    );
  }

  Widget _buildQrScanner() {
    return Stack(
      children: [
        MobileScanner(onDetect: _onQrDetected),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'Scan the QR code shown on your PC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => setState(() => _scanning = false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Consumer<PcConnectionService>(
      builder: (context, pcService, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection status
              _buildStatusCard(pcService),

              const SizedBox(height: 24),

              // Scan QR button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _scanQr,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scan QR Code'),
                ),
              ),

              const SizedBox(height: 12),

              // Discover button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _discovering ? null : _discoverPcs,
                  icon: _discovering
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search_rounded),
                  label: Text(
                      _discovering ? 'Searching...' : 'Find PCs on Network'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentCyan,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              // Discovered PCs
              if (_discoveredPcs.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'DISCOVERED',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                ...(_discoveredPcs.map((pc) => _buildDiscoveredPcTile(pc))),
              ],

              // Paired PCs
              if (_pairedPcs.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'PAIRED DEVICES',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                ...(_pairedPcs.map((pc) => _buildPairedPcTile(pc, pcService))),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(PcConnectionService pcService) {
    final connected = pcService.isConnected;
    final statusText = switch (pcService.state) {
      PcConnectionState.connected => 'Connected to ${pcService.pcName ?? "PC"}',
      PcConnectionState.connecting => 'Connecting...',
      PcConnectionState.error => pcService.errorMessage ?? 'Error',
      PcConnectionState.disconnected => 'Not connected',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: connected
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: connected
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: connected
                  ? AppColors.success.withValues(alpha: 0.2)
                  : AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              connected
                  ? Icons.desktop_windows_rounded
                  : Icons.desktop_access_disabled_rounded,
              color: connected ? AppColors.success : AppColors.textTertiary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: connected
                        ? AppColors.success
                        : AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (pcService.state == PcConnectionState.connecting)
                  const SizedBox(
                    height: 2,
                    child: LinearProgressIndicator(
                      color: AppColors.accentBlue,
                      backgroundColor: AppColors.surfaceHigh,
                    ),
                  ),
              ],
            ),
          ),
          if (connected)
            IconButton(
              onPressed: () => pcService.disconnect(),
              icon: const Icon(Icons.link_off_rounded,
                  color: AppColors.error, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildDiscoveredPcTile(Map<String, dynamic> pc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.desktop_windows_rounded,
              color: AppColors.accentCyan, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pc['name'] as String? ?? 'Unknown PC',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${pc['ip']}:${pc['port']}',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _connectFromQr(pc),
            child: const Text('Connect',
                style: TextStyle(color: AppColors.accentCyan)),
          ),
        ],
      ),
    );
  }

  Widget _buildPairedPcTile(PairedPc pc, PcConnectionService pcService) {
    final isActive = pcService.currentPc?.id == pc.id && pcService.isConnected;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.success.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.desktop_windows_rounded,
            color: isActive ? AppColors.success : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pc.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${pc.ip}:${pc.port}',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!isActive)
            TextButton(
              onPressed: () => _connectToPc(pc),
              child: const Text('Connect',
                  style: TextStyle(color: AppColors.accentBlue)),
            ),
          IconButton(
            onPressed: () => _removePc(pc),
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.textTertiary, size: 18),
          ),
        ],
      ),
    );
  }
}
