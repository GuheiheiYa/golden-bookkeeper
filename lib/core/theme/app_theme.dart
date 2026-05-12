import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

export 'app_colors.dart';

class AppTheme {
  AppTheme._();

  /// 浅色模式 - Peekaboo 柔和梦幻风格
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.lightPrimary,
        primaryContainer: const Color(0xFFF0ECF5),
        secondary: AppColors.lightSecondary,
        secondaryContainer: const Color(0xFFFDE8EF),
        surface: AppColors.lightSurface,
        surfaceContainerHighest: AppColors.lightSurfaceVariant,
        onPrimary: Colors.white,
        onSecondary: AppColors.lightOnSurface,
        onSurface: AppColors.lightOnSurface,
        onSurfaceVariant: AppColors.lightOnSurfaceVariant,
        outline: AppColors.lightOutline,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.bgGradientTop,
      shadowColor: AppColors.lightShadow,
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.lightOnSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSansSc(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.lightOnSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.lightPrimary,
        unselectedItemColor: AppColors.lightTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.warmYellow,
        foregroundColor: AppColors.warmYellowText,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightInputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.warmYellow,
          foregroundColor: AppColors.warmYellowText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.lightOutline,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// 深色模式 - 温暖暗色风格（适配设计稿）
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        primaryContainer: const Color(0xFF2A2225),
        secondary: AppColors.secondary,
        secondaryContainer: const Color(0xFF332A2D),
        surface: AppColors.darkSurface,
        surfaceContainerHighest: AppColors.darkSurfaceVariant,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkOnSurface,
        onSurfaceVariant: AppColors.darkOnSurfaceVariant,
        outline: AppColors.darkOutline,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      shadowColor: Colors.black.withOpacity(0.5),
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.darkOnSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSansSc(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkOnSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkOnSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.darkOnSurfaceVariant,
        indicatorColor: AppColors.primary,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.darkOutline),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.darkSurfaceVariant;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.darkOnSurface;
            }
            return AppColors.darkOnSurfaceVariant;
          }),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.warmYellow,
        foregroundColor: AppColors.warmYellowText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.warmYellow,
          foregroundColor: AppColors.warmYellowText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.darkOutline,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final color = brightness == Brightness.light
        ? AppColors.lightOnSurface
        : AppColors.darkOnSurface;
    final muted = brightness == Brightness.light
        ? AppColors.lightOnSurfaceVariant
        : AppColors.darkOnSurfaceVariant;
    final tertiary = brightness == Brightness.light
        ? AppColors.lightTextTertiary
        : AppColors.darkTextTertiary;

    return TextTheme(
      displayLarge: GoogleFonts.notoSansSc(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      displayMedium: GoogleFonts.notoSansSc(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      displaySmall: GoogleFonts.notoSansSc(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      headlineLarge: GoogleFonts.notoSansSc(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      headlineMedium: GoogleFonts.notoSansSc(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      headlineSmall: GoogleFonts.notoSansSc(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleLarge: GoogleFonts.notoSansSc(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      titleMedium: GoogleFonts.notoSansSc(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      titleSmall: GoogleFonts.notoSansSc(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: muted,
      ),
      bodyLarge: GoogleFonts.notoSansSc(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: color,
      ),
      bodyMedium: GoogleFonts.notoSansSc(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: color,
      ),
      bodySmall: GoogleFonts.notoSansSc(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: tertiary,
      ),
      labelLarge: GoogleFonts.notoSansSc(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      labelMedium: GoogleFonts.notoSansSc(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: muted,
      ),
      labelSmall: GoogleFonts.notoSansSc(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: tertiary,
      ),
    );
  }
}
