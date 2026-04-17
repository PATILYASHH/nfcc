import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'services/nfc_service.dart';
import 'services/nfc_intent_service.dart';
import 'services/silent_executor.dart';
import 'services/pc_connection_service.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseService().database;
  await SilentExecutor().init();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Start listening for NFC intents immediately (silent execution)
  // Start NFC listener - silent execution on tag tap
  NfcIntentService().startListening(
    onTagDetected: (uid, ndefText) {
      debugPrint('NFCC MAIN: Tag detected! UID=$uid NDEF=$ndefText');
      SilentExecutor().onTagDetected(uid, ndefText);
    },
  );

  runApp(const NfccApp());
}

class NfccApp extends StatelessWidget {
  const NfccApp({super.key});

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
        title: 'NFCC',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        ),
        home: const PermissionWrapper(),
      ),
    );
  }
}

class PermissionWrapper extends StatefulWidget {
  const PermissionWrapper({super.key});

  @override
  State<PermissionWrapper> createState() => _PermissionWrapperState();
}

class _PermissionWrapperState extends State<PermissionWrapper> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.camera,
      Permission.notification,
    ].request();
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('NFCC',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800)),
              SizedBox(height: 8),
              Text('NFC Control',
                  style: TextStyle(color: AppColors.textSecondary)),
              SizedBox(height: 32),
              CircularProgressIndicator(color: AppColors.accentBlue),
            ],
          ),
        ),
      );
    }
    return const HomeScreen();
  }
}
