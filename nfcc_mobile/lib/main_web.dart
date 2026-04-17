import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'services/database_service.dart';
import 'services/nfc_service.dart';
import 'services/pc_connection_service.dart';
import 'services/silent_executor.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      databaseFactory = databaseFactoryFfiWeb;
      await DatabaseService().database;
      debugPrint('WEB: DB initialized');
    } catch (e, s) {
      debugPrint('WEB: DB init error (continuing): $e\n$s');
    }

    runApp(const NfccWebApp());
  }, (error, stack) {
    debugPrint('WEB: Uncaught zone error: $error\n$stack');
  });
}

class NfccWebApp extends StatelessWidget {
  const NfccWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DatabaseService>(create: (_) => DatabaseService()),
        Provider<NfcService>(create: (_) => NfcService()),
        Provider<SilentExecutor>(create: (_) => SilentExecutor()),
        ChangeNotifierProvider<PcConnectionService>(
            create: (_) => PcConnectionService()),
      ],
      child: MaterialApp(
        title: 'NFCC · Web Preview',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        builder: (context, child) {
          ErrorWidget.builder = (details) => Material(
                color: const Color(0xFF000000),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Render error:\n${details.exceptionAsString()}',
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
            child: _PreviewFrame(child: child!),
          );
        },
        home: const HomeScreen(),
      ),
    );
  }
}

class _PreviewFrame extends StatelessWidget {
  final Widget child;
  const _PreviewFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 700) return child;
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Center(
        child: Container(
          width: 420,
          height: 860,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(42),
            border: Border.all(color: const Color(0xFF333333), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 60,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: child,
          ),
        ),
      ),
    );
  }
}
