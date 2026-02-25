import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Renk Paleti — Figma piksel analizi ─────────────────────────────────────
class AppColors {
  AppColors._();

  // ── Ana renkler ─────────────────────────────────────────────────────────
  /// "HOŞGELDİNİZ!", save butonu, klasör detay başlığı → Figma teal
  static const Color primary = Color(0xFF3DC4B0);
  static const Color primaryDark = Color(0xFF2AAE9B);

  // ── Logo degradesi (sol → sağ) ──────────────────────────────────────────
  /// Sol: pembe-kırmızı
  static const Color logoStart = Color(0xFFE8456A);
  /// Sağ: mavi-mor + Klasör detay FAB rengi
  static const Color logoEnd = Color(0xFF4F72FF);

  // ── Arka planlar ────────────────────────────────────────────────────────
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);

  // ── Input / arama dolgusu ─────────────────────────────────────────────
  /// Hafif lavanta-gri — Figma arama çubuğu
  static const Color searchFill = Color(0xFFEEEEF8);

  // ── Metin renkleri ──────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF8888A0);
  /// Link kart tarihi — Figma'da belirgin mor/menekşe
  static const Color dateColor = Color(0xFF9B8EC4);
  /// Link URL metni — mavi-gri
  static const Color urlColor = Color(0xFF7B8EC8);

  // ── Drawer ──────────────────────────────────────────────────────────────
  /// "Klasörlerim" / "Favorilerim" bölüm başlıkları — Figma'da mor/indigo ton
  static const Color drawerSectionColor = Color(0xFF7B73C4);
  /// Klasör ikonu arka planı
  static const Color drawerItemBg = Color(0xFFF0F0FA);

  // ── Diğer ──────────────────────────────────────────────────────────────
  static const Color divider = Color(0xFFEAEAF5);
  static const Color cardShadow = Color(0x0A000000);

  // ── Sosyal medya marka renkleri ─────────────────────────────────────────
  static const Color instagram = Color(0xFFE1306C);
  static const Color youtube = Color(0xFFFF0000);
  static const Color twitter = Color(0xFF111111);
  static const Color facebook = Color(0xFF1877F2);
  static const Color tiktok = Color(0xFF010101);
  static const Color reddit = Color(0xFFFF4500);
  static const Color github = Color(0xFF181717);
  static const Color linkedin = Color(0xFF0A66C2);
  static const Color spotify = Color(0xFF1DB954);
  static const Color twitch = Color(0xFF9146FF);
}

// ─── Tema ────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final poppinsTextTheme =
        GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.logoEnd,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.poppins().fontFamily,
      textTheme: poppinsTextTheme,

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Color(0x1A000000),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),

      // ── Drawer ──────────────────────────────────────────────────────────
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.background,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
      ),

      // ── Input / TextField ────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.searchFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      // ── ElevatedButton ──────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 28),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // ── Card ─────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ── FloatingActionButton ─────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: StadiumBorder(),
      ),
    );
  }