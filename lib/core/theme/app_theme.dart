import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ─────────────────────────────────────────────────────────────────────────
  // OM Finance — Rich Indigo/Violet Banking Palette
  // Inspired by PhonePe / Paytm modern fintech design language
  // ─────────────────────────────────────────────────────────────────────────

  /// Deep indigo — primary brand
  static const Color primaryColor = Color(0xFF5C35C9);

  /// Lighter indigo for gradients
  static const Color primaryLight = Color(0xFF7C5CE4);

  /// Deep violet for dark header background
  static const Color primaryDark = Color(0xFF3D1FA8);

  /// Soft lavender background (scaffold)
  static const Color surfaceLight = Color(0xFFF4F2FF);

  /// Pure white cards
  static const Color cardWhite = Color(0xFFFFFFFF);

  /// Accent: vibrant violet-pink for CTAs
  static const Color accentColor = Color(0xFF9B59B6);

  /// Lime-yellow secondary highlight (kept from reference)
  static const Color accentLime = Color(0xFFE3F87A);

  /// Jet-black for secondary buttons
  static const Color buttonBlack = Color(0xFF1A1D23);

  /// Success green
  static const Color successColor = Color(0xFF27AE60);

  /// Error red
  static const Color errorColor = Color(0xFFE53935);

  /// Orange for pending
  static const Color warningColor = Color(0xFFFF9100);

  /// Charcoal text
  static const Color textDark = Color(0xFF1A1D23);

  /// Muted subtext
  static const Color textMuted = Color(0xFF7D8FA4);

  // ─────────────────────────────────────────────────────────────────────────
  // Gradients
  // ─────────────────────────────────────────────────────────────────────────

  /// Primary indigo header gradient
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3D1FA8), // deep violet
      Color(0xFF5C35C9), // brand indigo
      Color(0xFF7C5CE4), // lighter indigo
    ],
  );

  /// Dark login background gradient
  static const Gradient loginGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A0A4A), // very deep violet
      Color(0xFF2E1480), // deep indigo
      Color(0xFF3D1FA8), // brand primary dark
    ],
  );

  /// Accent violet-pink gradient for CTA
  static const Gradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7C5CE4),
      Color(0xFF9B59B6),
    ],
  );

  /// Lime-yellow gradient (secondary highlight)
  static const Gradient limeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEBF97C),
      Color(0xFFD4F562),
    ],
  );

  /// Teal-green gradient for customer role
  static const Gradient customerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0D7A6E), // deep teal
      Color(0xFF12A98D), // teal-green mid
      Color(0xFF1DC9A4), // bright mint
    ],
  );

  /// Dark button gradient
  static const Gradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF252932),
      Color(0xFF1A1D23),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // ThemeData
  // ─────────────────────────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        error: errorColor,
        surface: cardWhite,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: surfaceLight,
    );

    return base.copyWith(
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          textStyle: base.textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w800, color: textDark, letterSpacing: -0.5,
          ),
        ),
        titleLarge: GoogleFonts.outfit(
          textStyle: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700, color: textDark, letterSpacing: 0.1,
          ),
        ),
        titleMedium: GoogleFonts.outfit(
          textStyle: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600, color: textDark,
          ),
        ),
        bodyLarge: GoogleFonts.outfit(
          textStyle: base.textTheme.bodyLarge?.copyWith(
            color: textDark, fontSize: 15,
          ),
        ),
        bodyMedium: GoogleFonts.outfit(
          textStyle: base.textTheme.bodyMedium?.copyWith(
            color: textMuted, fontSize: 13,
          ),
        ),
      ),

      // ── AppBar ─────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.outfit(
          textStyle: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700,
            color: Colors.white, letterSpacing: 0.2,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // ── Cards ───────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        shadowColor: primaryColor.withOpacity(0.10),
      ),

      // ── Input ───────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: const TextStyle(color: textMuted, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: textMuted),
        prefixIconColor: primaryColor,
        suffixIconColor: textMuted,
      ),

      // ── Elevated Button ─────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.3,
          ),
        ),
      ),

      // ── Outlined Button ─────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.8),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2,
          ),
        ),
      ),

      // ── Text Button ─────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // ── Chip ────────────────────────────────────────────────────────────
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        selectedColor: primaryColor.withOpacity(0.12),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        side: BorderSide(color: Colors.grey.shade200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── TabBar ──────────────────────────────────────────────────────────
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        dividerColor: Colors.transparent,
      ),

      // ── Bottom Navigation ───────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        unselectedItemColor: textMuted,
        showUnselectedLabels: true,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: cardWhite,
      ),

      // ── FAB ─────────────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // ── ListTile ────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: Colors.white,
      ),

      // ── Divider ─────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade100, thickness: 1, space: 0,
      ),

      // ── SnackBar ────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1A1D23),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Dialog ──────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: cardWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700, color: textDark,
        ),
        contentTextStyle: TextStyle(fontSize: 14, color: Colors.grey.shade700),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Status color helper
  // ─────────────────────────────────────────────────────────────────────────

  static Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'SUCCESS':
      case 'ACTIVE':
      case 'COMPLETED':
        return successColor;
      case 'MISSED':
      case 'FAILED':
      case 'OVERDUE':
      case 'SUSPENDED':
      case 'DEFAULTED':
        return errorColor;
      case 'PENDING':
      case 'INITIATED':
      case 'PARTIAL':
      case 'PARTIALLY_PAID':
      default:
        return warningColor;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Reusable decoration helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Standard white card with indigo shadow (layered)
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 24, spreadRadius: 0, offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 2, offset: const Offset(0, 1),
          ),
        ],
      );

  /// Lime-yellow accent card
  static BoxDecoration get limeCardDecoration => BoxDecoration(
        color: accentLime,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentLime.withOpacity(0.45),
            blurRadius: 20, offset: const Offset(0, 8),
          ),
        ],
      );

  /// Indigo gradient card (hero card)
  static BoxDecoration get heroCardDecoration => BoxDecoration(
        gradient: primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.45),
            blurRadius: 28, offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 8, offset: const Offset(0, 4),
          ),
        ],
      );

  /// Teal hero card for customer role
  static BoxDecoration get customerHeroCardDecoration => BoxDecoration(
        gradient: customerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D7A6E).withOpacity(0.4),
            blurRadius: 28, offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFF12A98D).withOpacity(0.2),
            blurRadius: 8, offset: const Offset(0, 4),
          ),
        ],
      );

  /// Glassmorphism card (for overlays on gradient backgrounds)
  static BoxDecoration glassmorphismCard({
    double opacity = 0.12,
    double borderOpacity = 0.18,
    double radius = 20,
  }) =>
      BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withOpacity(borderOpacity),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16, offset: const Offset(0, 6),
          ),
        ],
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Status emoji helper
  // ─────────────────────────────────────────────────────────────────────────

  static String statusEmoji(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'SUCCESS':
      case 'COMPLETED':
        return '✅';
      case 'ACTIVE':
        return '🟢';
      case 'MISSED':
      case 'FAILED':
      case 'DEFAULTED':
        return '🔴';
      case 'OVERDUE':
      case 'SUSPENDED':
        return '⚠️';
      case 'PENDING':
      case 'INITIATED':
        return '⏳';
      case 'PARTIAL':
      case 'PARTIALLY_PAID':
        return '🔶';
      default:
        return '📋';
    }
  }
}
