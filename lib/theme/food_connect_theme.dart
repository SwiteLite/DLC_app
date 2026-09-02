import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette FoodConnect
abstract final class FcColors {
  static const emerald = Color(0xFF60D394);
  static const lightGreen = Color(0xFFAAF683);
  static const jasmine = Color(0xFFFFD97D);
  static const salmon = Color(0xFFFF9B85);
  static const coral = Color(0xFFEE6055);

  /// Fond doux menthe — chaleur sans crème générique
  static const canvas = Color(0xFFF3FBF6);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFE8F8EE);
  static const ink = Color(0xFF1F3A2E);
  static const inkMuted = Color(0xFF5A7A68);
  static const outline = Color(0xFFC5E8D4);
}

abstract final class FcColorsDark {
  static const canvas = Color(0xFF0F1F18);
  static const surface = Color(0xFF1A2E24);
  static const surfaceSoft = Color(0xFF243B30);
  static const ink = Color(0xFFE8F5EC);
  static const inkMuted = Color(0xFF9BB8A8);
  static const outline = Color(0xFF3D5C4A);
}

abstract final class FoodConnectTheme {
  static const radiusSm = 14.0;
  static const radiusMd = 20.0;
  static const radiusLg = 28.0;
  static const radiusPill = 999.0;

  static ThemeData light() {
    final baseText = GoogleFonts.nunitoTextTheme();
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: FcColors.emerald,
      onPrimary: FcColors.ink,
      primaryContainer: FcColors.lightGreen,
      onPrimaryContainer: FcColors.ink,
      secondary: FcColors.jasmine,
      onSecondary: FcColors.ink,
      secondaryContainer: const Color(0xFFFFF0C2),
      onSecondaryContainer: FcColors.ink,
      tertiary: FcColors.salmon,
      onTertiary: FcColors.ink,
      tertiaryContainer: const Color(0xFFFFE4DC),
      onTertiaryContainer: FcColors.ink,
      error: FcColors.coral,
      onError: Colors.white,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
      surface: FcColors.surface,
      onSurface: FcColors.ink,
      onSurfaceVariant: FcColors.inkMuted,
      outline: FcColors.outline,
      outlineVariant: const Color(0xFFD7EFE2),
      shadow: FcColors.ink.withValues(alpha: 0.12),
      scrim: Colors.black54,
      inverseSurface: FcColors.ink,
      onInverseSurface: FcColors.canvas,
      inversePrimary: FcColors.lightGreen,
      surfaceTint: FcColors.emerald,
    );

    final shapeMd = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMd),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: FcColors.canvas,
      textTheme: baseText.apply(
        bodyColor: FcColors.ink,
        displayColor: FcColors.ink,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: FcColors.ink,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: FcColors.ink,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: FcColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shapeMd,
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: FcColors.surfaceSoft,
        selectedColor: FcColors.emerald,
        disabledColor: FcColors.surfaceSoft,
        secondarySelectedColor: FcColors.emerald,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        labelStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w600,
          color: FcColors.ink,
          fontSize: 13,
        ),
        secondaryLabelStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w700,
          color: FcColors.ink,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          side: BorderSide(color: FcColors.outline.withValues(alpha: 0.6)),
        ),
        side: BorderSide(color: FcColors.outline.withValues(alpha: 0.6)),
        checkmarkColor: FcColors.ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FcColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: FcColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: FcColors.outline.withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: FcColors.emerald, width: 2),
        ),
        hintStyle: GoogleFonts.nunito(color: FcColors.inkMuted),
        labelStyle: GoogleFonts.nunito(color: FcColors.inkMuted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FcColors.emerald,
          foregroundColor: FcColors.ink,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FcColors.inkMuted,
          textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: FcColors.emerald,
        foregroundColor: FcColors.ink,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: FcColors.ink,
        contentTextStyle: GoogleFonts.nunito(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: FcColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
        ),
        showDragHandle: true,
      ),
      dividerTheme: DividerThemeData(
        color: FcColors.outline.withValues(alpha: 0.5),
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        iconColor: FcColors.inkMuted,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: FcColors.ink,
          backgroundColor: FcColors.surfaceSoft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: FcColors.emerald,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: FcColors.emerald,
        thumbColor: FcColors.emerald,
        inactiveTrackColor: FcColors.outline,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: FcColors.surface,
        headerBackgroundColor: FcColors.emerald,
        headerForegroundColor: FcColors.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final baseText = GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme);
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: FcColors.emerald,
      onPrimary: FcColorsDark.ink,
      primaryContainer: const Color(0xFF2A5C40),
      onPrimaryContainer: FcColorsDark.ink,
      secondary: FcColors.jasmine,
      onSecondary: FcColorsDark.canvas,
      secondaryContainer: const Color(0xFF4A4020),
      onSecondaryContainer: FcColors.jasmine,
      tertiary: FcColors.salmon,
      onTertiary: FcColorsDark.canvas,
      tertiaryContainer: const Color(0xFF5C3A30),
      onTertiaryContainer: FcColors.salmon,
      error: FcColors.coral,
      onError: Colors.white,
      errorContainer: const Color(0xFF5C2820),
      onErrorContainer: FcColors.coral,
      surface: FcColorsDark.surface,
      onSurface: FcColorsDark.ink,
      onSurfaceVariant: FcColorsDark.inkMuted,
      outline: FcColorsDark.outline,
      outlineVariant: const Color(0xFF2A4034),
      shadow: Colors.black54,
      scrim: Colors.black87,
      inverseSurface: FcColorsDark.ink,
      onInverseSurface: FcColorsDark.canvas,
      inversePrimary: FcColors.emerald,
      surfaceTint: FcColors.emerald,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: FcColorsDark.canvas,
      textTheme: baseText.apply(
        bodyColor: FcColorsDark.ink,
        displayColor: FcColorsDark.ink,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: FcColorsDark.ink,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: FcColorsDark.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: FcColorsDark.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: FcColorsDark.surfaceSoft,
        selectedColor: FcColors.emerald,
        labelStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w600,
          color: FcColorsDark.ink,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          side: BorderSide(color: FcColorsDark.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FcColorsDark.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: FcColorsDark.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: FcColorsDark.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: FcColors.emerald, width: 2),
        ),
        hintStyle: GoogleFonts.nunito(color: FcColorsDark.inkMuted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FcColors.emerald,
          foregroundColor: FcColorsDark.canvas,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: FcColorsDark.surfaceSoft,
        contentTextStyle: GoogleFonts.nunito(color: FcColorsDark.ink),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: FcColorsDark.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusLg),
          ),
        ),
        showDragHandle: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: FcColors.emerald,
        foregroundColor: FcColorsDark.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: FcColors.emerald,
      ),
    );
  }

  static Color urgencyColor(int days, {bool active = true}) {
    if (!active) return FcColors.inkMuted;
    if (days < 0) return FcColors.coral;
    if (days <= 3) return FcColors.coral;
    if (days <= 7) return FcColors.salmon;
    if (days <= 14) return FcColors.jasmine;
    return FcColors.emerald;
  }

  static Color urgencySoft(int days, {bool active = true}) {
    final base = urgencyColor(days, active: active);
    return Color.lerp(base, Colors.white, 0.78)!;
  }
}
