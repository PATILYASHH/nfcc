import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// NFCC Dark Design System - Samsung-inspired minimal dark theme
class AppColors {
  AppColors._();

  // Backgrounds — barely-blue-tinted near-black so the app reads as
  // "deep dark UI" rather than "pitch-black void". The tint shifts at
  // higher levels give depth without compromising the minimal feel.
  static const Color background      = Color(0xFF05060A);
  static const Color surface         = Color(0xFF0B0C12);
  static const Color surfaceElevated = Color(0xFF12141B);
  static const Color surfaceHigh     = Color(0xFF1C1F29);
  static const Color surfaceGlass    = Color(0x15FFFFFF);

  // Borders
  static const Color border    = Color(0xFF1E1E1E);
  static const Color borderLit = Color(0xFF333333);
  static const Color divider   = Color(0xFF161616);

  // Accent palette
  static const Color accentBlue   = Color(0xFF3B82F6);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentCyan   = Color(0xFF22D3EE);
  static const Color accentPink   = Color(0xFFEC4899);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentWhite  = Color(0xFFFFFFFF);
  static const Color accentGreen  = Color(0xFF10B981);

  // NFC-specific colors
  static const Color nfcBlue    = Color(0xFF2196F3);
  static const Color nfcGlow    = Color(0xFF00B0FF);
  static const Color nfcSuccess = Color(0xFF00E676);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color error   = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Text
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textTertiary  = Color(0xFF4B5563);

  // Condition block colors
  static const Color conditionIf     = Color(0xFF3B82F6);
  static const Color conditionElseIf = Color(0xFF8B5CF6);
  static const Color conditionElse   = Color(0xFF6B7280);

  // UPI / Payments
  static const Color upiGreen = Color(0xFF00C853);

  // Gradients
  static const LinearGradient gradientNfc = LinearGradient(
    colors: [Color(0xFF2196F3), Color(0xFF00B0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientSuccess = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF10B981)],
  );

  static const LinearGradient gradientUpi = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF00BFA5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Light haptic feedback helper
void hapticLight() => HapticFeedback.lightImpact();
void hapticMedium() => HapticFeedback.mediumImpact();

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accentWhite,
          secondary: AppColors.accentBlue,
          tertiary: AppColors.accentCyan,
          surface: AppColors.surface,
          error: AppColors.error,
          onPrimary: Colors.black,
          onSecondary: Colors.white,
          onSurface: AppColors.textPrimary,
          onError: Colors.white,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 57,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
          ),
          displayMedium: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 45,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
          ),
          displaySmall: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 36,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
          headlineLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
          headlineMedium: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
          headlineSmall: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          titleLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          titleSmall: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          bodyLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
          labelLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentWhite,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.accentWhite,
          unselectedItemColor: AppColors.textTertiary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      );
}
