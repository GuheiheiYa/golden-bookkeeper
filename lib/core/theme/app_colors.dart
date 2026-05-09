import 'package:flutter/material.dart';

class AppColors {
  /// 深色模式主色：霓虹柠绿（Neon Fintech）
  static const Color primary = Color(0xFFC6FF00);
  static const Color primaryLight = Color(0xFFD4FF00);
  static const Color primaryDark = Color(0xFF89C400);
  /// 深色模式次要：森绿渐变暗端
  static const Color secondary = Color(0xFF2E7D32);
  static const Color secondaryLight = Color(0xFF4CAF50);

  /// 浅色模式主色：森绿（自然与生活风格）
  static const Color lightPrimary = Color(0xFF2D4F35);
  static const Color lightPrimaryLight = Color(0xFF3D6B48);
  static const Color lightPrimaryDark = Color(0xFF1A3328);
  /// 浅色模式次要：哑光金
  static const Color lightSecondary = Color(0xFFC5A059);
  static const Color lightSecondaryLight = Color(0xFFD4B87A);

  /// 根据亮度返回当前主题的主色
  static Color primaryOf(Brightness brightness) =>
      brightness == Brightness.dark ? primary : lightPrimary;
  /// 根据亮度返回当前主题的次色
  static Color secondaryOf(Brightness brightness) =>
      brightness == Brightness.dark ? secondary : lightSecondary;

  /// 霓虹氛围光色（深色模式发光效果）
  static const Color neonGlow = Color(0xFFC6FF00);
  static const Color neonGlowDim = Color(0x40C6FF00);

  // 功能色
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF448AFF);

  /// 收入 / 支出
  static const Color income = Color(0xFF00C853);
  static const Color expense = Color(0xFFFF3B30);

  // 浅色模式（自然与生活风格）
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF7F8FA);
  static const Color lightInputFill = Color(0xFFF2F2F2);
  static const Color lightOnBackground = Color(0xFF1A1A1A);
  static const Color lightOnSurface = Color(0xFF1A1A1A);
  static const Color lightOnSurfaceVariant = Color(0xFF666666);
  static const Color lightTextTertiary = Color(0xFF999999);
  static const Color lightOutline = Color(0xFFEEEEEE);
  static const Color lightShadow = Color(0x0D000000);

  /// 暗色：纯黑底 + 霓虹金融科技风
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkSurfaceVariant = Color(0xFF1A1A1A);
  static const Color darkOnBackground = Color(0xFFFFFFFF);
  static const Color darkOnSurface = Color(0xFFFFFFFF);
  static const Color darkOnSurfaceVariant = Color(0xFF8E8E93);
  static const Color darkOutline = Color(0xFF2A2A2A);
  static const Color darkShadow = Color(0x66000000);

  /// 深色卡片边缘（白色约 8% 透明度，模拟玻璃感）
  static const Color darkCardBorder = Color(0x14FFFFFF);

  /// Hero 余额卡片渐变（霓虹柠绿 → 深森绿）
  static const Color balanceGradientStart = Color(0xFFD4FF00);
  static const Color balanceGradientEnd = Color(0xFF1B5E20);

  // 分类颜色（保持区分度）
  static const List<Color> categoryColors = [
    Color(0xFF5EB8FF),
    Color(0xFF26C6DA),
    Color(0xFF3B82F6),
    Color(0xFF06B6D4),
    Color(0xFF10B981),
    Color(0xFF84CC16),
    Color(0xFFF59E0B),
    Color(0xFFF97316),
    Color(0xFFEF4444),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
  ];
}
