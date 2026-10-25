import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light HSL Palette
  static const Color primaryIndigo = Color(0xFF4F46E5);   // Royal Indigo Primary
  static const Color primaryBlue = Color(0xFF2563EB);     // Oxford Blue Accent
  static const Color cyanAccent = Color(0xFF0891B2);      // Cyan Glow Accent
  static const Color amberAccent = Color(0xFFD97706);     // Amber Memory Accent
  static const Color softBlue = Color(0xFFEFF6FF);        // Light Blue Slate Container
  static const Color darkSlate = Color(0xFF0F172A);        // Navy Slate Primary Text
  static const Color textGray = Color(0xFF64748B);         // Muted Slate Secondary Text
  static const Color background = Color(0xFFF8FAFC);       // Crisp Surface Ground
  static const Color borderLight = Color(0xFFE2E8F0);       // Soft Border Stroke
  static const Color errorRed = Color(0xFFDC2626);
  static const Color successGreen = Color(0xFF059669);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentPurple = Color(0xFF8B5CF6);

  // Dark HSL Palette
  static const Color darkPrimaryIndigo = Color(0xFF6366F1);
  static const Color darkPrimaryBlue = Color(0xFF3B82F6);
  static const Color darkCyanAccent = Color(0xFF06B6D4);
  static const Color darkAmberAccent = Color(0xFFF59E0B);
  static const Color darkBackground = Color(0xFF0B0F19);   // Deep Space Background
  static const Color darkSurface = Color(0xFF151C2C);      // Card Dark Surface
  static const Color darkSoftBlue = Color(0xFF1E293B);     // Muted Blue Slate Container
  static const Color darkBorder = Color(0xFF2D3748);       // Dark Border Stroke
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkErrorRed = Color(0xFFEF4444);
  static const Color darkSuccessGreen = Color(0xFF10B981);

  // Dynamic Helpers
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color backgroundColor(BuildContext ctx) =>
      isDark(ctx) ? darkBackground : background;

  static Color surfaceColor(BuildContext ctx) =>
      isDark(ctx) ? darkSurface : Colors.white;

  static Color textSecondaryColor(BuildContext ctx) =>
      isDark(ctx) ? darkTextSecondary : textGray;

  static Color cardColor(BuildContext context) {
    return isDark(context) ? darkSurface : Colors.white;
  }

  static Color softBgColor(BuildContext context) {
    return isDark(context) ? darkSoftBlue : softBlue;
  }

  static Color borderColor(BuildContext context) {
    return isDark(context) ? darkBorder : borderLight;
  }

  static Color textColor(BuildContext context) {
    return isDark(context) ? darkTextPrimary : darkSlate;
  }

  static Color subTextColor(BuildContext context) {
    return isDark(context) ? darkTextSecondary : textGray;
  }

  static Color primaryColor(BuildContext context) {
    return isDark(context) ? darkPrimaryIndigo : primaryIndigo;
  }

  static Color accentColor(BuildContext context) {
    return isDark(context) ? darkCyanAccent : cyanAccent;
  }

  // Linear Gradient Helpers for Banners & Heros
  static LinearGradient primaryGradient(BuildContext context) {
    return isDark(context)
        ? const LinearGradient(
            colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF3730A3), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
  }

  static LinearGradient accentGradient(BuildContext context) {
    return isDark(context)
        ? const LinearGradient(
            colors: [Color(0xFF0E7490), Color(0xFF06B6D4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF0369A1), Color(0xFF0284C7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
  }

  // Glassmorphic Decoration
  static BoxDecoration glassDecoration(BuildContext context) {
    return BoxDecoration(
      color: isDark(context)
          ? darkSurface.withValues(alpha: 0.85)
          : Colors.white.withValues(alpha: 0.90),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark(context)
            ? Colors.white.withValues(alpha: 0.1)
            : borderLight.withValues(alpha: 0.8),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark(context)
              ? Colors.black.withValues(alpha: 0.3)
              : primaryIndigo.withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static ButtonStyle _baseElevatedButtonStyle(Color bgColor, Color fgColor) {
    return ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static ButtonStyle _baseOutlinedButtonStyle(Color color) {
    return OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // Light Theme Definition
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.outfitTextTheme();
    final bodyTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryIndigo,
        primary: primaryIndigo,
        secondary: primaryBlue,
        tertiary: cyanAccent,
        surface: Colors.white,
        error: errorRed,
      ),
      scaffoldBackgroundColor: background,
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkSlate,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: darkSlate,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: darkSlate,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: darkSlate,
        ),
        bodyLarge: bodyTextTheme.bodyLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: darkSlate,
          height: 1.5,
        ) ?? GoogleFonts.plusJakartaSans(
          fontSize: 16,
          color: darkSlate,
          height: 1.5,
        ),
        bodyMedium: bodyTextTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textGray,
          height: 1.4,
        ) ?? GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: textGray,
          height: 1.4,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textGray,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: darkSlate,
        ),
        iconTheme: const IconThemeData(color: darkSlate),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _baseElevatedButtonStyle(primaryIndigo, Colors.white),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _baseOutlinedButtonStyle(primaryIndigo),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryIndigo, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(color: textGray),
        hintStyle: GoogleFonts.plusJakartaSans(color: textGray.withValues(alpha: 0.6)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 2,
        indicatorColor: softBlue,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: primaryIndigo,
            );
          }
          return GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textGray,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryIndigo, size: 24);
          }
          return const IconThemeData(color: textGray, size: 24);
        }),
      ),
    );
  }

  // Dark Theme Definition
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.outfitTextTheme();
    final bodyTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkPrimaryIndigo,
        primary: darkPrimaryIndigo,
        secondary: darkPrimaryBlue,
        tertiary: darkCyanAccent,
        surface: darkSurface,
        error: darkErrorRed,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkBackground,
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        bodyLarge: bodyTextTheme.bodyLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: darkTextPrimary,
          height: 1.5,
        ) ?? GoogleFonts.plusJakartaSans(
          fontSize: 16,
          color: darkTextPrimary,
          height: 1.5,
        ),
        bodyMedium: bodyTextTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkTextSecondary,
          height: 1.4,
        ) ?? GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: darkTextSecondary,
          height: 1.4,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: darkTextSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
        iconTheme: const IconThemeData(color: darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _baseElevatedButtonStyle(darkPrimaryIndigo, Colors.white),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _baseOutlinedButtonStyle(darkPrimaryIndigo),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkPrimaryIndigo, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkErrorRed, width: 1.5),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(color: darkTextSecondary),
        hintStyle: GoogleFonts.plusJakartaSans(color: darkTextSecondary.withValues(alpha: 0.6)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        elevation: 2,
        indicatorColor: darkSoftBlue,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: darkPrimaryIndigo,
            );
          }
          return GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: darkTextSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: darkPrimaryIndigo, size: 24);
          }
          return const IconThemeData(color: darkTextSecondary, size: 24);
        }),
      ),
    );
  }
}
