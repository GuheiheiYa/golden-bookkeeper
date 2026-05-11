import 'package:flutter/material.dart';

class AppColors {
  // ═══════════════════════════════════════════════
  // 深色模式主色：霓虹柠绿（保持兼容）
  // ═══════════════════════════════════════════════
  static const Color primary = Color(0xFFB8A9E8);
  static const Color primaryLight = Color(0xFFD8CEE8);
  static const Color primaryDark = Color(0xFF9B8AC4);
  static const Color secondary = Color(0xFFF5C6D0);
  static const Color secondaryLight = Color(0xFFFDE8EF);

  // ═══════════════════════════════════════════════
  // 浅色模式主色：梦幻紫 Peekaboo 风格
  // ═══════════════════════════════════════════════
  static const Color lightPrimary = Color(0xFFB8A9E8);
  static const Color lightPrimaryLight = Color(0xFFD8CEE8);
  static const Color lightPrimaryDark = Color(0xFF9B8AC4);
  static const Color lightSecondary = Color(0xFFF5C6D0);
  static const Color lightSecondaryLight = Color(0xFFFDE8EF);

  // ═══════════════════════════════════════════════
  // 动态主题色
  // ═══════════════════════════════════════════════
  static Color primaryOf(Brightness brightness) =>
      brightness == Brightness.dark ? primary : lightPrimary;
  static Color secondaryOf(Brightness brightness) =>
      brightness == Brightness.dark ? secondary : lightSecondary;

  // ═══════════════════════════════════════════════
  // 霓虹氛围光（深色模式）
  // ═══════════════════════════════════════════════
  static const Color neonGlow = Color(0xFFB8A9E8);
  static const Color neonGlowDim = Color(0x40B8A9E8);

  // ═══════════════════════════════════════════════
  // 功能色（柔和版）
  // ═══════════════════════════════════════════════
  static const Color success = Color(0xFF7EC8A0);
  static const Color warning = Color(0xFFF0C87A);
  static const Color error = Color(0xFFE88B8B);
  static const Color info = Color(0xFF8BB8E8);

  static const Color income = Color(0xFF7EC8A0);
  static const Color expense = Color(0xFFE88B8B);

  // ═══════════════════════════════════════════════
  // 按钮色
  // ═══════════════════════════════════════════════
  static const Color warmYellow = Color(0xFFFFD93D);
  static const Color warmYellowDark = Color(0xFFF0C87A);
  static const Color warmYellowText = Color(0xFF5A4E2A);

  // ═══════════════════════════════════════════════
  // 浅色模式表面与文字
  // ═══════════════════════════════════════════════
  static const Color lightBackground = Color(0xFFEDE4F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xF0FFFFFF); // 半透明白，渐变背景微微透出
  static const Color lightSurfaceVariant = Color(0xFFF5F0FA);
  static const Color lightInputFill = Color(0xFFF5F0FA);
  static const Color lightOnBackground = Color(0xFF2D2D3F);
  static const Color lightOnSurface = Color(0xFF2D2D3F);
  static const Color lightOnSurfaceVariant = Color(0xFF6B6B80);
  static const Color lightTextTertiary = Color(0xFF9B9BB0);
  static const Color lightOutline = Color(0xFFE8E0F0);
  static const Color lightShadow = Color(0x10B8A9E8);

  // ═══════════════════════════════════════════════
  // 浅色模式页面背景渐变
  // ═══════════════════════════════════════════════
  static const Color bgGradientTop = Color(0xFFE8DFF5);
  static const Color bgGradientMid = Color(0xFFF3EEF8);
  static const Color bgGradientBottom = Color(0xFFFDE8EF);

  // ═══════════════════════════════════════════════
  // 深色模式表面与文字
  // ═══════════════════════════════════════════════
  static const Color darkBackground = Color(0xFF1A1525);
  static const Color darkSurface = Color(0xFF252035);
  static const Color darkSurfaceVariant = Color(0xFF2A2535);
  static const Color darkOnBackground = Color(0xFFF0ECF5);
  static const Color darkOnSurface = Color(0xFFF0ECF5);
  static const Color darkOnSurfaceVariant = Color(0xFFB0A8C0);
  static const Color darkTextTertiary = Color(0xFF7A7090);
  static const Color darkOutline = Color(0xFF353045);
  static const Color darkShadow = Color(0x66000000);
  static const Color darkCardBorder = Color(0xFF353045);

  // ═══════════════════════════════════════════════
  // 深色模式页面背景渐变
  // ═══════════════════════════════════════════════
  static const Color bgGradientTopDark = Color(0xFF1A1525);
  static const Color bgGradientMidDark = Color(0xFF1F1A2D);
  static const Color bgGradientBottomDark = Color(0xFF251F30);

  // ═══════════════════════════════════════════════
  // 余额卡片渐变
  // ═══════════════════════════════════════════════
  static const Color balanceGradientStart = Color(0xFFB8A9E8);
  static const Color balanceGradientEnd = Color(0xFF9B8AC4);

  // ═══════════════════════════════════════════════
  // 分类颜色（柔和梦幻色系）
  // ═══════════════════════════════════════════════
  static const List<Color> categoryColors = [
    Color(0xFFB8A9E8), // 紫
    Color(0xFF8BB8E8), // 蓝
    Color(0xFF7EC8A0), // 绿
    Color(0xFFF0C87A), // 橙黄
    Color(0xFFE88B8B), // 红
    Color(0xFFF5C6D0), // 粉
    Color(0xFF81D4C8), // 青
    Color(0xFFC4B5E0), // 淡紫
    Color(0xFFA8D8EA), // 浅蓝
    Color(0xFFFFD93D), // 黄
    Color(0xFFB5EAD7), // 薄荷
    Color(0xFFE2B6CF), // 玫瑰
  ];
}
