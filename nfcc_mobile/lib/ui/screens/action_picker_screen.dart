import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import '../../models/action_item.dart';
import '../theme/app_theme.dart';
import '../widgets/pc_app_picker_sheet.dart';

/// Full-page action picker - Samsung style categorized list
class ActionPickerScreen extends StatelessWidget {
  const ActionPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent, elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Add action',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: AppColors.accentWhite,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(3),
                labelColor: Colors.black,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Phone'),
                  Tab(text: 'PC'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _PhoneActionsPage(),
            _PcActionsPage(),
          ],
        ),
      ),
    );
  }
}

// ── Phone Actions ─────────────────────────────────────────────────────────

class _PhoneActionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _sectionLabel('Connectivity'),
        const SizedBox(height: 8),
        _ActionItem(icon: Icons.wifi_rounded, color: AppColors.accentBlue,
            title: 'Wi-Fi ON', subtitle: 'Turn Wi-Fi on',
            onTap: (ctx) => _returnAction(ctx, 'wifiOn', ActionTarget.phone)),
        _ActionItem(icon: Icons.wifi_off_rounded, color: AppColors.accentBlue,
            title: 'Wi-Fi OFF', subtitle: 'Turn Wi-Fi off',
            onTap: (ctx) => _returnAction(ctx, 'wifiOff', ActionTarget.phone)),
        _WifiConnectItem(),
        _ActionItem(icon: Icons.bluetooth_rounded, color: AppColors.accentCyan,
            title: 'Bluetooth ON', subtitle: 'Turn Bluetooth on',
            onTap: (ctx) => _returnAction(ctx, 'btOn', ActionTarget.phone)),
        _ActionItem(icon: Icons.bluetooth_disabled_rounded, color: AppColors.accentCyan,
            title: 'Bluetooth OFF', subtitle: 'Turn Bluetooth off',
            onTap: (ctx) => _returnAction(ctx, 'btOff', ActionTarget.phone)),
        _BtConnectItem(),
        _ActionItem(icon: Icons.signal_cellular_alt_rounded, color: AppColors.accentPurple,
            title: 'Mobile data ON', subtitle: 'Turn mobile data on',
            onTap: (ctx) => _returnAction(ctx, 'mobileDataOn', ActionTarget.phone)),
        _ActionItem(icon: Icons.signal_cellular_off_rounded, color: AppColors.accentPurple,
            title: 'Mobile data OFF', subtitle: 'Turn mobile data off',
            onTap: (ctx) => _returnAction(ctx, 'mobileDataOff', ActionTarget.phone)),

        const SizedBox(height: 20),
        _sectionLabel('Sound & Media'),
        const SizedBox(height: 8),
        _ActionItem(icon: Icons.play_arrow_rounded, color: AppColors.accentPink,
            title: 'Play / Pause music', subtitle: 'Toggle media playback',
            onTap: (ctx) => _returnAction(ctx,'musicPlayPause', ActionTarget.phone)),
        _ActionItem(icon: Icons.skip_next_rounded, color: AppColors.accentPink,
            title: 'Next track', subtitle: 'Skip to next song',
            onTap: (ctx) => _returnAction(ctx,'musicNext', ActionTarget.phone)),
        _ActionItem(icon: Icons.shuffle_rounded, color: AppColors.accentPink,
            title: 'Shuffle music', subtitle: 'Shuffle current playlist',
            onTap: (ctx) => _returnAction(ctx,'musicShuffle', ActionTarget.phone)),
        _SliderItem(icon: Icons.volume_up_rounded, color: AppColors.accentOrange,
            title: 'Set volume', actionType: 'setVolume', target: ActionTarget.phone),
        _SliderItem(icon: Icons.brightness_6_rounded, color: AppColors.accentOrange,
            title: 'Set brightness', actionType: 'setBrightness', target: ActionTarget.phone),

        const SizedBox(height: 20),
        _sectionLabel('Device'),
        const SizedBox(height: 8),
        _ActionItem(icon: Icons.do_not_disturb_rounded, color: AppColors.warning,
            title: 'Toggle DND', subtitle: 'Do Not Disturb mode',
            onTap: (ctx) => _returnAction(ctx,'toggleDnd', ActionTarget.phone)),
        _ActionItem(icon: Icons.flashlight_on_rounded, color: AppColors.warning,
            title: 'Toggle flashlight', subtitle: 'Turn flashlight on or off',
            onTap: (ctx) => _returnAction(ctx,'toggleFlashlight', ActionTarget.phone)),

        const SizedBox(height: 20),
        _sectionLabel('Apps'),
        const SizedBox(height: 8),
        const _InstalledAppPicker(),
      ],
    );
  }
}

// ── PC Actions ────────────────────────────────────────────────────────────

class _PcActionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── Window Management ──
        _sectionLabel('WINDOW MANAGEMENT'),
        const SizedBox(height: 8),
        _ActionItem(icon: Icons.minimize_rounded, color: AppColors.accentPurple,
            title: 'Minimize all', subtitle: 'Show desktop (Win+D)',
            onTap: (ctx) => _returnAction(ctx, 'minimizeAll', ActionTarget.pc)),
        _ActionItem(icon: Icons.open_in_full_rounded, color: AppColors.accentPurple,
            title: 'Maximize window', subtitle: 'Maximize active window',
            onTap: (ctx) => _returnAction(ctx, 'maximizeWindow', ActionTarget.pc)),
        _ActionItem(icon: Icons.align_horizontal_left_rounded, color: AppColors.accentPurple,
            title: 'Snap left', subtitle: 'Snap window to left half',
            onTap: (ctx) => _returnAction(ctx, 'snapLeft', ActionTarget.pc)),
        _ActionItem(icon: Icons.align_horizontal_right_rounded, color: AppColors.accentPurple,
            title: 'Snap right', subtitle: 'Snap window to right half',
            onTap: (ctx) => _returnAction(ctx, 'snapRight', ActionTarget.pc)),
        _ActionItem(icon: Icons.close_rounded, color: AppColors.error,
            title: 'Close window', subtitle: 'Close active window (Alt+F4)',
            onTap: (ctx) => _returnAction(ctx, 'closeWindow', ActionTarget.pc)),
        _ActionItem(icon: Icons.swap_horiz_rounded, color: AppColors.accentBlue,
            title: 'Switch window', subtitle: 'Alt+Tab',
            onTap: (ctx) => _returnAction(ctx, 'switchWindow', ActionTarget.pc)),
        _ActionItem(icon: Icons.view_carousel_rounded, color: AppColors.accentBlue,
            title: 'Task view', subtitle: 'Win+Tab - show all windows',
            onTap: (ctx) => _returnAction(ctx, 'taskView', ActionTarget.pc)),

        const SizedBox(height: 20),

        // ── Sound & Media ──
        _sectionLabel('SOUND & MEDIA'),
        const SizedBox(height: 8),
        _ActionItem(icon: Icons.volume_off_rounded, color: AppColors.accentPink,
            title: 'Toggle mute', subtitle: 'Mute / unmute PC audio',
            onTap: (ctx) => _returnAction(ctx, 'toggleMute', ActionTarget.pc)),
        _ActionItem(icon: Icons.volume_up_rounded, color: AppColors.accentPink,
            title: 'Volume up', subtitle: 'Increase volume one step',
            onTap: (ctx) => _returnAction(ctx, 'volumeUp', ActionTarget.pc)),
        _ActionItem(icon: Icons.volume_down_rounded, color: AppColors.accentPink,
            title: 'Volume down', subtitle: 'Decrease volume one step',
            onTap: (ctx) => _returnAction(ctx, 'volumeDown', ActionTarget.pc)),
        _SliderItem(icon: Icons.tune_rounded, color: AppColors.accentOrange,
            title: 'Set volume', actionType: 'setVolume', target: ActionTarget.pc),
        _ActionItem(icon: Icons.play_arrow_rounded, color: AppColors.accentCyan,
            title: 'Play / Pause', subtitle: 'Media play/pause',
            onTap: (ctx) => _returnAction(ctx, 'mediaPlayPause', ActionTarget.pc)),
        _ActionItem(icon: Icons.skip_next_rounded, color: AppColors.accentCyan,
            title: 'Next track', subtitle: 'Skip to next media track',
            onTap: (ctx) => _returnAction(ctx, 'mediaNext', ActionTarget.pc)),
        _ActionItem(icon: Icons.skip_previous_rounded, color: AppColors.accentCyan,
            title: 'Previous track', subtitle: 'Go to previous track',
            onTap: (ctx) => _returnAction(ctx, 'mediaPrev', ActionTarget.pc)),
        _ActionItem(icon: Icons.stop_rounded, color: AppColors.accentCyan,
            title: 'Stop media', subtitle: 'Stop media playback',
            onTap: (ctx) => _returnAction(ctx, 'mediaStop', ActionTarget.pc)),

        const SizedBox(height: 20),

        // ── System ──
        _sectionLabel('SYSTEM'),
        const SizedBox(height: 8),
        _ActionItem(icon: Icons.lock_rounded, color: AppColors.warning,
            title: 'Lock PC', subtitle: 'Lock the workstation',
            onTap: (ctx) => _returnAction(ctx, 'lockPc', ActionTarget.pc)),
        _ActionItem(icon: Icons.bedtime_rounded, color: AppColors.accentPurple,
            title: 'Sleep PC', subtitle: 'Put PC to sleep',
            onTap: (ctx) => _returnAction(ctx, 'sleepPc', ActionTarget.pc)),
        _ActionItem(icon: Icons.restart_alt_rounded, color: AppColors.accentOrange,
            title: 'Restart PC', subtitle: 'Restart in 5 seconds',
            onTap: (ctx) => _returnAction(ctx, 'restartPc', ActionTarget.pc)),
        _ActionItem(icon: Icons.power_settings_new_rounded, color: AppColors.error,
            title: 'Shutdown PC', subtitle: 'Shutdown in 5 seconds',
            onTap: (ctx) => _returnAction(ctx, 'shutdownPc', ActionTarget.pc)),
        _ActionItem(icon: Icons.cancel_rounded, color: AppColors.success,
            title: 'Cancel shutdown', subtitle: 'Abort pending shutdown/restart',
            onTap: (ctx) => _returnAction(ctx, 'cancelShutdown', ActionTarget.pc)),
        _ActionItem(icon: Icons.settings_rounded, color: AppColors.textSecondary,
            title: 'Open Settings', subtitle: 'Windows Settings app',
            onTap: (ctx) => _returnAction(ctx, 'openSettings', ActionTarget.pc)),

        const SizedBox(height: 20),

        // ── Shortcuts ──
        _sectionLabel('SHORTCUTS'),
        const SizedBox(height: 8),
        _ActionItem(icon: Icons.screenshot_monitor_rounded, color: AppColors.accentCyan,
            title: 'Screenshot', subtitle: 'Snipping Tool (Win+Shift+S)',
            onTap: (ctx) => _returnAction(ctx, 'screenshot', ActionTarget.pc)),
        _ActionItem(icon: Icons.folder_open_rounded, color: AppColors.warning,
            title: 'File Explorer', subtitle: 'Open File Explorer (Win+E)',
            onTap: (ctx) => _returnAction(ctx, 'openFileExplorer', ActionTarget.pc)),
        _ActionItem(icon: Icons.monitor_heart_rounded, color: AppColors.error,
            title: 'Task Manager', subtitle: 'Open Task Manager',
            onTap: (ctx) => _returnAction(ctx, 'openTaskManager', ActionTarget.pc)),
        _ActionItem(icon: Icons.content_paste_rounded, color: AppColors.accentBlue,
            title: 'Clipboard history', subtitle: 'Open clipboard (Win+V)',
            onTap: (ctx) => _returnAction(ctx, 'clipboardHistory', ActionTarget.pc)),

        const SizedBox(height: 20),

        // ── Screen ──
        _sectionLabel('SCREEN'),
        const SizedBox(height: 8),
        _ActionItem(icon: Icons.monitor_rounded, color: AppColors.textSecondary,
            title: 'Screen off', subtitle: 'Turn off display',
            onTap: (ctx) => _returnAction(ctx, 'screenOff', ActionTarget.pc)),
        _ActionItem(icon: Icons.desktop_windows_rounded, color: AppColors.textSecondary,
            title: 'Screen on', subtitle: 'Wake display',
            onTap: (ctx) => _returnAction(ctx, 'screenOn', ActionTarget.pc)),
        _SliderItem(icon: Icons.brightness_6_rounded, color: AppColors.accentOrange,
            title: 'Set brightness', actionType: 'setBrightness', target: ActionTarget.pc),

        const SizedBox(height: 20),

        // ── Virtual Desktops ──
        _sectionLabel('VIRTUAL DESKTOPS'),
        const SizedBox(height: 8),
        _ActionItem(icon: Icons.add_to_queue_rounded, color: AppColors.accentPurple,
            title: 'New desktop', subtitle: 'Win+Ctrl+D',
            onTap: (ctx) => _returnAction(ctx, 'newVirtualDesktop', ActionTarget.pc)),
        _ActionItem(icon: Icons.close_rounded, color: AppColors.error,
            title: 'Close desktop', subtitle: 'Win+Ctrl+F4',
            onTap: (ctx) => _returnAction(ctx, 'closeVirtualDesktop', ActionTarget.pc)),
        _ActionItem(icon: Icons.chevron_right_rounded, color: AppColors.accentBlue,
            title: 'Next desktop', subtitle: 'Win+Ctrl+Right',
            onTap: (ctx) => _returnAction(ctx, 'nextVirtualDesktop', ActionTarget.pc)),
        _ActionItem(icon: Icons.chevron_left_rounded, color: AppColors.accentBlue,
            title: 'Previous desktop', subtitle: 'Win+Ctrl+Left',
            onTap: (ctx) => _returnAction(ctx, 'prevVirtualDesktop', ActionTarget.pc)),
        _ActionItem(icon: Icons.cast_connected_rounded, color: AppColors.accentCyan,
            title: 'Projection menu', subtitle: 'Win+P',
            onTap: (ctx) => _returnAction(ctx, 'projectMenu', ActionTarget.pc)),

        const SizedBox(height: 20),

        // ── Keyboard & Editing ──
        _sectionLabel('KEYBOARD & EDITING'),
        const SizedBox(height: 8),
        _TextInputItem(icon: Icons.keyboard_rounded, color: AppColors.accentBlue,
            title: 'Type text', hint: 'Text to type at cursor',
            actionType: 'typeText', paramKey: 'text', target: ActionTarget.pc),
        _TextInputItem(icon: Icons.keyboard_command_key_rounded, color: AppColors.accentPurple,
            title: 'Send key combo', hint: 'e.g. ctrl+shift+s',
            actionType: 'sendKeys', paramKey: 'combo', target: ActionTarget.pc),
        _TextInputItem(icon: Icons.content_paste_rounded, color: AppColors.accentCyan,
            title: 'Set clipboard', hint: 'Text to put on clipboard',
            actionType: 'setClipboard', paramKey: 'text', target: ActionTarget.pc),
        _ActionItem(icon: Icons.content_copy_rounded, color: AppColors.accentBlue,
            title: 'Copy', subtitle: 'Ctrl+C',
            onTap: (ctx) => _returnAction(ctx, 'copy', ActionTarget.pc)),
        _ActionItem(icon: Icons.content_paste_go_rounded, color: AppColors.accentBlue,
            title: 'Paste', subtitle: 'Ctrl+V',
            onTap: (ctx) => _returnAction(ctx, 'paste', ActionTarget.pc)),
        _ActionItem(icon: Icons.content_cut_rounded, color: AppColors.accentBlue,
            title: 'Cut', subtitle: 'Ctrl+X',
            onTap: (ctx) => _returnAction(ctx, 'cut', ActionTarget.pc)),
        _ActionItem(icon: Icons.select_all_rounded, color: AppColors.accentBlue,
            title: 'Select all', subtitle: 'Ctrl+A',
            onTap: (ctx) => _returnAction(ctx, 'selectAll', ActionTarget.pc)),
        _ActionItem(icon: Icons.undo_rounded, color: AppColors.accentOrange,
            title: 'Undo', subtitle: 'Ctrl+Z',
            onTap: (ctx) => _returnAction(ctx, 'undo', ActionTarget.pc)),
        _ActionItem(icon: Icons.redo_rounded, color: AppColors.accentOrange,
            title: 'Redo', subtitle: 'Ctrl+Y',
            onTap: (ctx) => _returnAction(ctx, 'redo', ActionTarget.pc)),
        _ActionItem(icon: Icons.zoom_in_rounded, color: AppColors.accentCyan,
            title: 'Zoom in', subtitle: 'Ctrl+=',
            onTap: (ctx) => _returnAction(ctx, 'zoomIn', ActionTarget.pc)),
        _ActionItem(icon: Icons.zoom_out_rounded, color: AppColors.accentCyan,
            title: 'Zoom out', subtitle: 'Ctrl+-',
            onTap: (ctx) => _returnAction(ctx, 'zoomOut', ActionTarget.pc)),
        _ActionItem(icon: Icons.emoji_emotions_rounded, color: AppColors.accentPink,
            title: 'Emoji picker', subtitle: 'Win+.',
            onTap: (ctx) => _returnAction(ctx, 'emojiPicker', ActionTarget.pc)),

        const SizedBox(height: 20),

        // ── Mouse ──
        _sectionLabel('MOUSE'),
        const SizedBox(height: 8),
        _ActionItem(icon: Icons.mouse_rounded, color: AppColors.accentBlue,
            title: 'Left click', subtitle: 'Click at cursor',
            onTap: (ctx) => _returnAction(ctx, 'mouseClick', ActionTarget.pc,
                params: {'button': 'left'})),
        _ActionItem(icon: Icons.mouse_rounded, color: AppColors.accentBlue,
            title: 'Right click', subtitle: 'Open context menu',
            onTap: (ctx) => _returnAction(ctx, 'mouseClick', ActionTarget.pc,
                params: {'button': 'right'})),
        _ActionItem(icon: Icons.mouse_rounded, color: AppColors.accentBlue,
            title: 'Double click', subtitle: 'Double left click',
            onTap: (ctx) => _returnAction(ctx, 'mouseDoubleClick', ActionTarget.pc)),
        _ActionItem(icon: Icons.keyboard_arrow_up_rounded, color: AppColors.accentCyan,
            title: 'Scroll up', subtitle: 'Wheel up 3 notches',
            onTap: (ctx) => _returnAction(ctx, 'scrollUp', ActionTarget.pc,
                params: {'amount': 3})),
        _ActionItem(icon: Icons.keyboard_arrow_down_rounded, color: AppColors.accentCyan,
            title: 'Scroll down', subtitle: 'Wheel down 3 notches',
            onTap: (ctx) => _returnAction(ctx, 'scrollDown', ActionTarget.pc,
                params: {'amount': 3})),

        const SizedBox(height: 20),

        // ── Network ──
        _sectionLabel('NETWORK'),
        const SizedBox(height: 8),
        _ActionItem(icon: Icons.wifi_rounded, color: AppColors.accentBlue,
            title: 'PC Wi-Fi ON', subtitle: 'Enable Wi-Fi adapter (admin)',
            onTap: (ctx) => _returnAction(ctx, 'wifiOn', ActionTarget.pc)),
        _ActionItem(icon: Icons.wifi_off_rounded, color: AppColors.accentBlue,
            title: 'PC Wi-Fi OFF', subtitle: 'Disable Wi-Fi adapter (admin)',
            onTap: (ctx) => _returnAction(ctx, 'wifiOff', ActionTarget.pc)),
        _TextInputItem(icon: Icons.wifi_lock_rounded, color: AppColors.accentBlue,
            title: 'Connect PC Wi-Fi', hint: 'Saved network SSID',
            actionType: 'wifiConnect', paramKey: 'ssid', target: ActionTarget.pc),
        _ActionItem(icon: Icons.wifi_tethering_off_rounded, color: AppColors.accentBlue,
            title: 'Disconnect Wi-Fi', subtitle: 'Drop current Wi-Fi',
            onTap: (ctx) => _returnAction(ctx, 'wifiDisconnect', ActionTarget.pc)),
        _ActionItem(icon: Icons.lan_rounded, color: AppColors.accentPurple,
            title: 'Ethernet ON', subtitle: 'Enable Ethernet (admin)',
            onTap: (ctx) => _returnAction(ctx, 'ethernetOn', ActionTarget.pc)),
        _ActionItem(icon: Icons.lan_outlined, color: AppColors.accentPurple,
            title: 'Ethernet OFF', subtitle: 'Disable Ethernet (admin)',
            onTap: (ctx) => _returnAction(ctx, 'ethernetOff', ActionTarget.pc)),
        _ActionItem(icon: Icons.airplanemode_active_rounded, color: AppColors.accentOrange,
            title: 'Airplane mode settings', subtitle: 'Open toggle page',
            onTap: (ctx) => _returnAction(ctx, 'flightMode', ActionTarget.pc)),

        const SizedBox(height: 20),

        // ── Recording & Capture ──
        _sectionLabel('RECORDING & CAPTURE'),
        const SizedBox(height: 8),
        _ActionItem(icon: Icons.videogame_asset_rounded, color: AppColors.accentPink,
            title: 'Game Bar', subtitle: 'Win+G',
            onTap: (ctx) => _returnAction(ctx, 'gameBar', ActionTarget.pc)),
        _ActionItem(icon: Icons.fiber_manual_record_rounded, color: AppColors.error,
            title: 'Toggle screen recording', subtitle: 'Win+Shift+R',
            onTap: (ctx) => _returnAction(ctx, 'toggleRecording', ActionTarget.pc)),
        _ActionItem(icon: Icons.print_rounded, color: AppColors.accentCyan,
            title: 'Print Screen', subtitle: 'Capture to clipboard',
            onTap: (ctx) => _returnAction(ctx, 'printScreen', ActionTarget.pc)),

        const SizedBox(height: 20),

        // ── System (advanced) ──
        _sectionLabel('SYSTEM (ADVANCED)'),
        const SizedBox(height: 8),
        _ActionItem(icon: Icons.logout_rounded, color: AppColors.warning,
            title: 'Sign out', subtitle: 'Log off current user',
            onTap: (ctx) => _returnAction(ctx, 'signOut', ActionTarget.pc)),
        _ActionItem(icon: Icons.bedtime_rounded, color: AppColors.accentPurple,
            title: 'Hibernate', subtitle: 'Save state + power off',
            onTap: (ctx) => _returnAction(ctx, 'hibernatePc', ActionTarget.pc)),
        _ActionItem(icon: Icons.battery_saver_rounded, color: AppColors.success,
            title: 'Power plan: Balanced', subtitle: 'Default plan',
            onTap: (ctx) => _returnAction(ctx, 'setPowerPlan', ActionTarget.pc,
                params: {'plan': 'balanced'})),
        _ActionItem(icon: Icons.speed_rounded, color: AppColors.accentOrange,
            title: 'Power plan: High performance', subtitle: 'Max power',
            onTap: (ctx) => _returnAction(ctx, 'setPowerPlan', ActionTarget.pc,
                params: {'plan': 'high'})),
        _ActionItem(icon: Icons.eco_rounded, color: AppColors.accentCyan,
            title: 'Power plan: Saver', subtitle: 'Maximum battery life',
            onTap: (ctx) => _returnAction(ctx, 'setPowerPlan', ActionTarget.pc,
                params: {'plan': 'power_saver'})),
        _ActionItem(icon: Icons.delete_sweep_rounded, color: AppColors.error,
            title: 'Empty recycle bin', subtitle: 'Delete permanently',
            onTap: (ctx) => _returnAction(ctx, 'emptyRecycleBin', ActionTarget.pc)),

        const SizedBox(height: 20),

        // ── Info (reads back to phone) ──
        _sectionLabel('INFO (READ-ONLY)'),
        const SizedBox(height: 8),
        _ActionItem(icon: Icons.monitor_heart_rounded, color: AppColors.success,
            title: 'System info', subtitle: 'CPU / RAM / disk snapshot',
            onTap: (ctx) => _returnAction(ctx, 'systemInfo', ActionTarget.pc)),
        _ActionItem(icon: Icons.battery_full_rounded, color: AppColors.success,
            title: 'Battery status', subtitle: 'Level + charging state',
            onTap: (ctx) => _returnAction(ctx, 'batteryStatus', ActionTarget.pc)),
        _ActionItem(icon: Icons.list_alt_rounded, color: AppColors.accentBlue,
            title: 'Top processes', subtitle: 'By memory usage',
            onTap: (ctx) => _returnAction(ctx, 'listProcesses', ActionTarget.pc,
                params: {'limit': 15})),
        _ActionItem(icon: Icons.language_rounded, color: AppColors.accentCyan,
            title: 'Get IP', subtitle: 'Local LAN address',
            onTap: (ctx) => _returnAction(ctx, 'getIp', ActionTarget.pc)),

        const SizedBox(height: 20),

        // ── Timing ──
        _sectionLabel('TIMING'),
        const SizedBox(height: 8),
        _SliderItem(icon: Icons.timer_rounded, color: AppColors.warning,
            title: 'Wait (seconds)',
            actionType: 'wait', target: ActionTarget.pc,
            paramKey: 'seconds', minValue: 0, maxValue: 30, initialValue: 1, unit: 's'),

        const SizedBox(height: 20),

        // ── Quick App Launchers ──
        _sectionLabel('QUICK APP LAUNCHERS'),
        const SizedBox(height: 8),
        _ActionItem(icon: Icons.note_alt_rounded, color: AppColors.accentBlue,
            title: 'Open Notepad', subtitle: 'Launch Notepad',
            onTap: (ctx) => _returnAction(ctx, 'openNotepad', ActionTarget.pc)),
        _ActionItem(icon: Icons.calculate_rounded, color: AppColors.accentPurple,
            title: 'Open Calculator', subtitle: 'Launch Calc',
            onTap: (ctx) => _returnAction(ctx, 'openCalculator', ActionTarget.pc)),
        _ActionItem(icon: Icons.public_rounded, color: AppColors.accentCyan,
            title: 'Open Browser', subtitle: 'Default browser -> Google',
            onTap: (ctx) => _returnAction(ctx, 'openBrowser', ActionTarget.pc)),
        _ActionItem(icon: Icons.terminal_rounded, color: AppColors.accentOrange,
            title: 'Open Terminal', subtitle: 'Windows Terminal / cmd',
            onTap: (ctx) => _returnAction(ctx, 'openTerminal', ActionTarget.pc)),
        _ActionItem(icon: Icons.play_circle_rounded, color: AppColors.accentPurple,
            title: 'Run dialog', subtitle: 'Win+R',
            onTap: (ctx) => _returnAction(ctx, 'openRunDialog', ActionTarget.pc)),
        _ActionItem(icon: Icons.search_rounded, color: AppColors.accentBlue,
            title: 'Open Search', subtitle: 'Win+S',
            onTap: (ctx) => _returnAction(ctx, 'openSearch', ActionTarget.pc)),
        _ActionItem(icon: Icons.notifications_rounded, color: AppColors.accentPink,
            title: 'Action Center', subtitle: 'Win+A quick settings',
            onTap: (ctx) => _returnAction(ctx, 'openActionCenter', ActionTarget.pc)),

        const SizedBox(height: 20),

        // ── Apps & Commands ──
        _sectionLabel('APPS & COMMANDS'),
        const SizedBox(height: 8),
        _ActionItem(icon: Icons.launch_rounded, color: AppColors.accentBlue,
            title: 'Launch app', subtitle: 'Pick from presets or open a folder in VS Code',
            onTap: (ctx) async {
              final item = await PcAppPickerSheet.show(ctx);
              if (item != null && ctx.mounted) Navigator.pop(ctx, item);
            }),
        _TextInputItem(icon: Icons.folder_open_rounded, color: AppColors.warning,
            title: 'Open file or folder', hint: 'C:\\Path\\to\\file-or-folder',
            actionType: 'openPath', paramKey: 'path', target: ActionTarget.pc),
        _TextInputItem(icon: Icons.language_rounded, color: AppColors.accentCyan,
            title: 'Open URL', hint: 'https://...',
            actionType: 'openUrl', paramKey: 'url', target: ActionTarget.pc),
        _TextInputItem(icon: Icons.terminal_rounded, color: AppColors.accentOrange,
            title: 'Run command', hint: 'Shell command',
            actionType: 'runCommand', paramKey: 'command', target: ActionTarget.pc),
        _TextInputItem(icon: Icons.close_rounded, color: AppColors.error,
            title: 'Close app', hint: 'Process name (e.g. chrome.exe)',
            actionType: 'closeApp', paramKey: 'processName', target: ActionTarget.pc),
        _TextInputItem(icon: Icons.dangerous_rounded, color: AppColors.error,
            title: 'Kill process', hint: 'Process name or PID',
            actionType: 'killProcess', paramKey: 'name', target: ActionTarget.pc),
      ],
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────

Widget _sectionLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(text,
        style: const TextStyle(
            color: AppColors.textTertiary, fontSize: 12,
            fontWeight: FontWeight.w600, letterSpacing: 0.5)),
  );
}

void _returnAction(BuildContext ctx, String type, ActionTarget target,
    {Map<String, dynamic> params = const {}}) {
  Navigator.pop(ctx, ActionItem(
    orderIndex: 0, target: target, actionType: type, params: params,
  ));
}

// ── Action Item Row ───────────────────────────────────────────────────────

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final void Function(BuildContext) onTap;

  const _ActionItem({
    required this.icon, required this.color,
    required this.title, required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
          onTap: () => onTap(context),
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
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.add_circle_outline_rounded, size: 20, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Slider Item ───────────────────────────────────────────────────────────

// ── WiFi Connect picker ───────────────────────────────────────────────────

class _WifiConnectItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _TextInputItem(
      icon: Icons.wifi_lock_rounded,
      color: AppColors.accentBlue,
      title: 'Connect to Wi-Fi',
      hint: 'Network name (SSID)',
      actionType: 'wifiConnect',
      paramKey: 'ssid',
      target: ActionTarget.phone,
    );
  }
}

// ── Bluetooth Connect picker ──────────────────────────────────────────────

class _BtConnectItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _TextInputItem(
      icon: Icons.bluetooth_searching_rounded,
      color: AppColors.accentCyan,
      title: 'Connect to BT device',
      hint: 'Device name (e.g. Galaxy Buds)',
      actionType: 'btConnect',
      paramKey: 'deviceName',
      target: ActionTarget.phone,
    );
  }
}

// ── Slider Item ───────────────────────────────────────────────────────────

class _SliderItem extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String actionType;
  final ActionTarget target;
  final String paramKey;
  final double minValue;
  final double maxValue;
  final double initialValue;
  final String unit;

  const _SliderItem({
    required this.icon, required this.color, required this.title,
    required this.actionType, required this.target,
    this.paramKey = 'level',
    this.minValue = 0,
    this.maxValue = 100,
    this.initialValue = 50,
    this.unit = '%',
  });

  @override
  State<_SliderItem> createState() => _SliderItemState();
}

class _SliderItemState extends State<_SliderItem> {
  late double _value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.icon, size: 22, color: widget.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: widget.color,
                    thumbColor: widget.color,
                    inactiveTrackColor: AppColors.surfaceHigh,
                  ),
                  child: Slider(
                    value: _value.clamp(widget.minValue, widget.maxValue),
                    min: widget.minValue,
                    max: widget.maxValue,
                    divisions: ((widget.maxValue - widget.minValue)).clamp(1, 100).toInt(),
                    onChanged: (v) => setState(() => _value = v),
                  ),
                ),
              ],
            ),
          ),
          Text('${_value.toInt()}${widget.unit}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () {
              Navigator.pop(context, ActionItem(
                orderIndex: 0, target: widget.target,
                actionType: widget.actionType,
                params: {widget.paramKey: _value.toInt()},
              ));
            },
            icon: Icon(Icons.add_circle_rounded, size: 24, color: widget.color),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
        ],
      ),
    );
  }
}

// ── Text Input Item ───────────────────────────────────────────────────────

class _TextInputItem extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String hint;
  final String actionType;
  final String paramKey;
  final ActionTarget target;

  const _TextInputItem({
    required this.icon, required this.color, required this.title,
    required this.hint, required this.actionType,
    required this.paramKey, required this.target,
  });

  @override
  State<_TextInputItem> createState() => _TextInputItemState();
}

class _TextInputItemState extends State<_TextInputItem> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _submit() {
    final val = _ctrl.text.trim();
    if (val.isEmpty) return;
    Navigator.pop(context, ActionItem(
      orderIndex: 0, target: widget.target,
      actionType: widget.actionType,
      params: {widget.paramKey: val},
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.icon, size: 22, color: widget.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                TextField(
                  controller: _ctrl,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                    isDense: true, border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _submit,
            icon: Icon(Icons.add_circle_rounded, size: 24, color: widget.color),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
        ],
      ),
    );
  }
}

// ── Installed App Picker ──────────────────────────────────────────────────

class _InstalledAppPicker extends StatefulWidget {
  const _InstalledAppPicker();

  @override
  State<_InstalledAppPicker> createState() => _InstalledAppPickerState();
}

class _InstalledAppPickerState extends State<_InstalledAppPicker> {
  List<AppInfo> _apps = [];
  List<AppInfo> _filtered = [];
  bool _loading = false;
  bool _expanded = false;
  final _searchCtrl = TextEditingController();

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final apps = await InstalledApps.getInstalledApps(true, true, '');
      apps.sort((a, b) => a.name.compareTo(b.name));
      if (mounted) setState(() { _apps = apps; _filtered = apps; _loading = false; _expanded = true; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter(String q) {
    setState(() {
      _filtered = _apps.where((a) => a.name.toLowerCase().contains(q.toLowerCase())).toList();
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _load,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.apps_rounded, size: 22, color: AppColors.success),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Open app',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
                        SizedBox(height: 2),
                        Text('Choose from installed apps',
                            style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (_loading)
                    const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentBlue))
                  else
                    const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              controller: _searchCtrl, onChanged: _filter,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search apps...',
                hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textTertiary),
                isDense: true, filled: true, fillColor: AppColors.surfaceHigh,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          SizedBox(
            height: 280,
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) {
                final app = _filtered[i];
                return ListTile(
                  dense: true,
                  leading: app.icon != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(app.icon!, width: 34, height: 34))
                      : Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.android_rounded, color: AppColors.success, size: 20)),
                  title: Text(app.name,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  subtitle: Text(app.packageName,
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                  trailing: const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.textTertiary),
                  onTap: () {
                    Navigator.pop(ctx, ActionItem(
                      orderIndex: 0, target: ActionTarget.phone,
                      actionType: 'openApp',
                      params: {'packageName': app.packageName, 'appName': app.name},
                    ));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
