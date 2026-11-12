import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// [AppTheme] EduPulse'un Material 3 açık ve koyu temalarını üretir.
///
/// Her iki [ColorScheme] de Akademik Lacivert / İndigo tohum renginden
/// ([AppColors.seedColor]) `ColorScheme.fromSeed` ile türetilir; ardından
/// tasarım sistemindeki marka rolleri (primary, secondary, error, surface …)
/// `copyWith` ile sabitlenir. Başlık ve gövde tipografisi hiyerarşik olarak tanımlanır.
abstract final class AppTheme {
  // ---------------------------------------------------------------------------
  // STATUS BAR (iOS + Android): açık temada koyu ikonlar, koyu temada açık ikonlar
  // ---------------------------------------------------------------------------
  static const SystemUiOverlayStyle lightSystemOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Android
    statusBarBrightness: Brightness.light, // iOS: açık zemin → koyu metin
  );

  static const SystemUiOverlayStyle darkSystemOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  /// Aktif temaya uygun status bar stili.
  static SystemUiOverlayStyle systemOverlayFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkSystemOverlay : lightSystemOverlay;

  // ---------------------------------------------------------------------------
  // COLOR SCHEMES (ColorScheme.fromSeed)
  // ---------------------------------------------------------------------------
  static ColorScheme get lightColorScheme =>
      ColorScheme.fromSeed(seedColor: AppColors.seedColor, brightness: Brightness.light).copyWith(
        primary: AppColors.primaryLight,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFDBEAFE),
        onPrimaryContainer: const Color(0xFF1E40AF),
        secondary: AppColors.secondaryLight,
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFD1FAE5),
        onSecondaryContainer: const Color(0xFF065F46),
        tertiary: AppColors.accentLight,
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xFFFEF3C7),
        onTertiaryContainer: const Color(0xFF92400E),
        error: AppColors.criticalAbsenceRed,
        onError: Colors.white,
        errorContainer: const Color(0xFFFEE2E2),
        onErrorContainer: const Color(0xFF991B1B),
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        surfaceContainerHighest: const Color(0xFFF1F5F9),
        onSurfaceVariant: AppColors.textSecondaryLight,
        outline: AppColors.borderLight,
        outlineVariant: AppColors.dividerLight,
      );

  static ColorScheme get darkColorScheme =>
      ColorScheme.fromSeed(seedColor: AppColors.seedColor, brightness: Brightness.dark).copyWith(
        primary: AppColors.primaryDark,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFF1E3A8A),
        onPrimaryContainer: const Color(0xFFDBEAFE),
        secondary: AppColors.secondaryDark,
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFF134E4A),
        onSecondaryContainer: const Color(0xFFCCFBF1),
        tertiary: AppColors.accentDark,
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xFF5B21B6),
        onTertiaryContainer: const Color(0xFFEDE9FE),
        error: AppColors.criticalAbsenceRed,
        onError: Colors.white,
        errorContainer: const Color(0xFF7F1D1D),
        onErrorContainer: const Color(0xFFFEE2E2),
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        surfaceContainerHighest: const Color(0xFF1E293B),
        onSurfaceVariant: AppColors.textSecondaryDark,
        outline: AppColors.borderDark,
        outlineVariant: AppColors.dividerDark,
      );

  // ---------------------------------------------------------------------------
  // THEMES
  // ---------------------------------------------------------------------------
  static ThemeData get lightTheme => _buildTheme(
    scheme: lightColorScheme,
    palette: const _ThemePalette(
      primary: AppColors.primaryLight,
      background: AppColors.backgroundLight,
      surface: AppColors.surfaceLight,
      card: AppColors.cardLight,
      inputFill: Colors.white,
      textPrimary: AppColors.textPrimaryLight,
      textSecondary: AppColors.textSecondaryLight,
      textMuted: AppColors.textMutedLight,
      border: AppColors.borderLight,
      divider: AppColors.dividerLight,
      navBar: Colors.white,
      navIndicator: Color(0xFFDBEAFE),
      navSelected: AppColors.accentWarm,
      cardShadow: AppColors.softShadowLight,
      cardElevation: AppDimensions.elevationLow,
      navElevation: 2,
      overlay: lightSystemOverlay,
    ),
  );

  static ThemeData get darkTheme => _buildTheme(
    scheme: darkColorScheme,
    palette: const _ThemePalette(
      primary: AppColors.primaryDark,
      background: AppColors.backgroundDark,
      surface: AppColors.surfaceDark,
      card: AppColors.cardDark,
      inputFill: AppColors.cardDark,
      textPrimary: AppColors.textPrimaryDark,
      textSecondary: AppColors.textSecondaryDark,
      textMuted: AppColors.textMutedDark,
      border: AppColors.borderDark,
      divider: AppColors.dividerDark,
      navBar: AppColors.navBarDark,
      navIndicator: Color(0xFF1E293B),
      navSelected: AppColors.primaryDark,
      cardShadow: Colors.transparent,
      cardElevation: AppDimensions.elevationNone,
      navElevation: 0,
      overlay: darkSystemOverlay,
    ),
  );

  static ThemeData _buildTheme({required ColorScheme scheme, required _ThemePalette palette}) {
    final p = palette;

    OutlineInputBorder inputBorder(Color color, double width) => OutlineInputBorder(
      borderRadius: AppDimensions.radius12,
      borderSide: BorderSide(color: color, width: width),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.surface,
      dividerColor: p.divider,

      // Typography: Headings and Body
      textTheme: _buildTextTheme(headingColor: p.textPrimary, bodyColor: p.textSecondary),

      // AppBar Theme — şeffaf AppBar'da Flutter ikon rengini yanlış tahmin
      // eder; status bar stili açıkça verilir.
      appBarTheme: AppBarTheme(
        systemOverlayStyle: p.overlay,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: p.surface,
        foregroundColor: p.textPrimary,
        centerTitle: false,
        titleTextStyle: _headingStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.textPrimary),
        iconTheme: IconThemeData(color: p.textPrimary, size: AppDimensions.iconMd),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: p.card,
        elevation: p.cardElevation,
        shadowColor: p.cardShadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.radius20,
          side: BorderSide(color: scheme.brightness == Brightness.dark ? p.border : p.divider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.inputFill,
        contentPadding: AppDimensions.paddingH16V12,
        hintStyle: _bodyStyle(fontSize: 14, color: p.textMuted, fontWeight: FontWeight.w400),
        labelStyle: _bodyStyle(fontSize: 14, color: p.textSecondary, fontWeight: FontWeight.w500),
        prefixIconColor: p.textSecondary,
        suffixIconColor: p.textSecondary,
        border: inputBorder(p.border, 1.2),
        enabledBorder: inputBorder(p.border, 1.2),
        focusedBorder: inputBorder(p.primary, 2),
        errorBorder: inputBorder(AppColors.criticalAbsenceRed, 1.2),
        focusedErrorBorder: inputBorder(AppColors.criticalAbsenceRed, 2),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          shape: const RoundedRectangleBorder(borderRadius: AppDimensions.radius12),
          textStyle: _headingStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          side: BorderSide(color: p.primary, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: AppDimensions.radius12),
          textStyle: _headingStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: _headingStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: Colors.white,
        elevation: AppDimensions.elevationMedium,
        shape: const RoundedRectangleBorder(borderRadius: AppDimensions.radius16),
      ),

      // Kalıcı alt menü (MainScaffoldShell → BottomNavigationBar)
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: p.navBar,
        elevation: 0,
        selectedItemColor: p.navSelected,
        unselectedItemColor: p.textSecondary,
        showUnselectedLabels: true,
        selectedLabelStyle: _bodyStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: _bodyStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),

      // Navigation Bar (Material 3 alternatifi)
      navigationBarTheme: NavigationBarThemeData(
        height: AppDimensions.bottomNavHeight,
        backgroundColor: p.navBar,
        elevation: p.navElevation,
        indicatorColor: p.navIndicator,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return _bodyStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? p.primary : p.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(size: AppDimensions.iconMd, color: isSelected ? p.primary : p.textSecondary);
        }),
      ),

      // TabBar Theme
      tabBarTheme: TabBarThemeData(
        indicatorColor: p.primary,
        labelColor: p.primary,
        unselectedLabelColor: p.textSecondary,
        labelStyle: _headingStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: _headingStyle(fontSize: 14, fontWeight: FontWeight.w400),
      ),

      // -------------------------------------------------------------------------
      // Alt paneller (Modal Bottom Sheet):
      // Açık ve koyu temada varsayılan olarak opak yüzey (p.surface) ve 24dp yuvarlatılmış
      // üst köşeler atanır. Böylece doğrudan açılan bottom sheet pencereleri beyaz modda
      // şeffaf görünmez, yüksek kontrastlı ve okunabilir bir arka planla açılır.
      // Kendi özel kabını çizen formlar ise `backgroundColor: Colors.transparent` geçebilir.
      // -------------------------------------------------------------------------
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.r24)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppDimensions.radius12),
        contentTextStyle: _bodyStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
      ),
    );
  }

  static TextStyle _headingStyle({required double fontSize, required FontWeight fontWeight, Color? color}) =>
      TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color, letterSpacing: -0.2);

  static TextStyle _bodyStyle({required double fontSize, required FontWeight fontWeight, Color? color}) =>
      TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color);

  // ---------------------------------------------------------------------------
  // TEXT THEME BUILDER
  // ---------------------------------------------------------------------------
  static TextTheme _buildTextTheme({required Color headingColor, required Color bodyColor}) {
    return TextTheme(
      displayLarge: _headingStyle(fontSize: 32, fontWeight: FontWeight.w800, color: headingColor),
      displayMedium: _headingStyle(fontSize: 28, fontWeight: FontWeight.w700, color: headingColor),
      displaySmall: _headingStyle(fontSize: 24, fontWeight: FontWeight.w700, color: headingColor),
      headlineLarge: _headingStyle(fontSize: 22, fontWeight: FontWeight.w700, color: headingColor),
      headlineMedium: _headingStyle(fontSize: 20, fontWeight: FontWeight.w600, color: headingColor),
      headlineSmall: _headingStyle(fontSize: 18, fontWeight: FontWeight.w600, color: headingColor),
      titleLarge: _headingStyle(fontSize: 16, fontWeight: FontWeight.w600, color: headingColor),
      titleMedium: _headingStyle(fontSize: 15, fontWeight: FontWeight.w600, color: headingColor),
      titleSmall: _headingStyle(fontSize: 14, fontWeight: FontWeight.w600, color: headingColor),
      bodyLarge: _bodyStyle(fontSize: 16, fontWeight: FontWeight.w400, color: headingColor),
      bodyMedium: _bodyStyle(fontSize: 14, fontWeight: FontWeight.w400, color: bodyColor),
      bodySmall: _bodyStyle(fontSize: 12, fontWeight: FontWeight.w400, color: bodyColor),
      labelLarge: _bodyStyle(fontSize: 14, fontWeight: FontWeight.w600, color: headingColor),
      labelMedium: _bodyStyle(fontSize: 12, fontWeight: FontWeight.w500, color: bodyColor),
      labelSmall: _bodyStyle(fontSize: 11, fontWeight: FontWeight.w500, color: bodyColor),
    );
  }
}

/// Açık / koyu temada farklılaşan ham renk ve yükseklik değerleri.
class _ThemePalette {
  const _ThemePalette({
    required this.primary,
    required this.background,
    required this.surface,
    required this.card,
    required this.inputFill,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.divider,
    required this.navBar,
    required this.navIndicator,
    required this.navSelected,
    required this.cardShadow,
    required this.cardElevation,
    required this.navElevation,
    required this.overlay,
  });

  final Color primary;
  final Color background;
  final Color surface;
  final Color card;
  final Color inputFill;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color divider;
  final Color navBar;
  final Color navIndicator;
  final Color navSelected;
  final Color cardShadow;
  final double cardElevation;
  final double navElevation;
  final SystemUiOverlayStyle overlay;
}
