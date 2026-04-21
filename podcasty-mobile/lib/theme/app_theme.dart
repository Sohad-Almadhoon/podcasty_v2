import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Colors matching website ───
  static const Color accent = Color(0xFF7C3AED);
  static const Color accentLight = Color(0xFF8B5CF6);

  // Light
  static const Color _lightBg = Color(0xFFFAF8FF);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightRaised = Color(0xFFF3EEFF);
  static const Color _lightBorder = Color(0xFFE2D5F8);
  static const Color _lightText = Color(0xFF18103A);
  static const Color _lightMuted = Color(0xFF6D4FA0);
  static const Color _lightSubtle = Color(0xFFA98FCB);

  // Dark
  static const Color _darkBg = Color(0xFF0E0A1C);
  static const Color _darkSurface = Color(0xFF15102B);
  static const Color _darkRaised = Color(0xFF1E1640);
  static const Color _darkBorder = Color(0xFF2D1F5E);
  static const Color _darkText = Color(0xFFF0EAFF);
  static const Color _darkMuted = Color(0xFF9B7DBE);
  static const Color _darkSubtle = Color(0xFF5E4388);

  // ─── Shared helpers ───
  static TextTheme _textTheme(Color text, Color muted, Color subtle) {
    return TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 34, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.8, height: 1.15,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 28, fontWeight: FontWeight.w700, color: text, letterSpacing: -0.6, height: 1.2,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 22, fontWeight: FontWeight.w700, color: text, letterSpacing: -0.3,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 18, fontWeight: FontWeight.w600, color: text,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16, fontWeight: FontWeight.w600, color: text,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14, fontWeight: FontWeight.w600, color: text,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 13, fontWeight: FontWeight.w600, color: text,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15, color: muted, height: 1.6, fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13, color: muted, height: 1.55, fontWeight: FontWeight.w400,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 11, color: subtle, height: 1.4, fontWeight: FontWeight.w400,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w600, color: text, letterSpacing: 0.3,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w500, color: subtle, letterSpacing: 0.5,
      ),
    );
  }

  static InputDecorationTheme _inputTheme(Color fill, Color border, Color accent, Color text, Color subtle) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: accent, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(fontSize: 13, color: subtle),
      labelStyle: GoogleFonts.inter(fontSize: 13, color: subtle),
    );
  }

  // ─── Light Theme ───
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: accent,
    scaffoldBackgroundColor: _lightBg,
    colorScheme: const ColorScheme.light(
      primary: accent,
      secondary: accentLight,
      surface: _lightSurface,
      onSurface: _lightText,
      outline: _lightBorder,
      error: Color(0xFFDC2626),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _lightSurface,
      foregroundColor: _lightText,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 18, fontWeight: FontWeight.w700, color: _lightText,
      ),
      iconTheme: const IconThemeData(color: _lightMuted, size: 22),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: _lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _lightBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(color: _lightBorder, thickness: 1, space: 1),
    chipTheme: ChipThemeData(
      backgroundColor: _lightSurface,
      selectedColor: accent,
      labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
      side: const BorderSide(color: _lightBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _lightText,
        side: const BorderSide(color: _lightBorder),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accent,
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: accent,
      unselectedLabelColor: _lightSubtle,
      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
      indicatorColor: accent,
      indicatorSize: TabBarIndicatorSize.label,
      dividerHeight: 1,
      dividerColor: _lightBorder,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: _lightText),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: _lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _lightText,
      contentTextStyle: GoogleFonts.inter(fontSize: 13, color: _lightBg),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: _inputTheme(_lightRaised, _lightBorder, accent, _lightText, _lightSubtle),
    textTheme: _textTheme(_lightText, _lightMuted, _lightSubtle),
    iconTheme: const IconThemeData(color: _lightMuted, size: 20),
  );

  // ─── Dark Theme ───
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: accentLight,
    scaffoldBackgroundColor: _darkBg,
    colorScheme: const ColorScheme.dark(
      primary: accentLight,
      secondary: accent,
      surface: _darkSurface,
      onSurface: _darkText,
      outline: _darkBorder,
      error: Color(0xFFEF4444),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _darkSurface,
      foregroundColor: _darkText,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 18, fontWeight: FontWeight.w700, color: _darkText,
      ),
      iconTheme: const IconThemeData(color: _darkMuted, size: 22),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: _darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _darkBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(color: _darkBorder, thickness: 1, space: 1),
    chipTheme: ChipThemeData(
      backgroundColor: _darkSurface,
      selectedColor: accentLight,
      labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
      side: const BorderSide(color: _darkBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentLight,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkText,
        side: const BorderSide(color: _darkBorder),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentLight,
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentLight,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: accentLight,
      unselectedLabelColor: _darkSubtle,
      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
      indicatorColor: accentLight,
      indicatorSize: TabBarIndicatorSize.label,
      dividerHeight: 1,
      dividerColor: _darkBorder,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: _darkText),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: _darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _darkText,
      contentTextStyle: GoogleFonts.inter(fontSize: 13, color: _darkBg),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: _inputTheme(_darkRaised, _darkBorder, accentLight, _darkText, _darkSubtle),
    textTheme: _textTheme(_darkText, _darkMuted, _darkSubtle),
    iconTheme: const IconThemeData(color: _darkMuted, size: 20),
  );
}
