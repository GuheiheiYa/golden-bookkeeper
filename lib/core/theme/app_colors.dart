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
  // 霓虹氛围光（深色模式 - 温暖色调）
  // ═══════════════════════════════════════════════
  static const Color neonGlow = Color(0xFFD4A574);
  static const Color neonGlowDim = Color(0x40D4A574);

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
  static const Color bgGradientTop = Color(0xFF1E1B4B);
  static const Color bgGradientMid = Color(0xFFF5D5C8);
  static const Color bgGradientBottom = Color(0xFFF0E6F6);

  // ═══════════════════════════════════════════════
  // 深色模式表面与文字（温暖暗色调）
  // ═══════════════════════════════════════════════
  static const Color darkBackground = Color(0xFF1C1618);
  static const Color darkSurface = Color(0xFF2A2225);
  static const Color darkSurfaceVariant = Color(0xFF332A2D);
  static const Color darkOnBackground = Color(0xFFF5EDE8);
  static const Color darkOnSurface = Color(0xFFF5EDE8);
  static const Color darkOnSurfaceVariant = Color(0xFFBEB0A8);
  static const Color darkTextTertiary = Color(0xFF8A7E78);
  static const Color darkOutline = Color(0xFF3D3235);
  static const Color darkShadow = Color(0x66000000);
  static const Color darkCardBorder = Color(0xFF3D3235);

  // ═══════════════════════════════════════════════
  // 深色模式页面背景渐变（温暖暗色）
  // ═══════════════════════════════════════════════
  static const Color bgGradientTopDark = Color(0xFF1C1618);
  static const Color bgGradientMidDark = Color(0xFF201A1C);
  static const Color bgGradientBottomDark = Color(0xFF251E20);

  // ═══════════════════════════════════════════════
  // 余额卡片渐变（浅色模式 - 梦幻紫）
  // ═══════════════════════════════════════════════
  static const Color balanceGradientStart = Color(0xFFB8A9E8);
  static const Color balanceGradientEnd = Color(0xFF9B8AC4);

  // ═══════════════════════════════════════════════
  // 余额卡片渐变（深色模式 - 深沉暗色）
  // ═══════════════════════════════════════════════
  static const Color balanceGradientStartDark = Color(0xFF2A2225);
  static const Color balanceGradientEndDark = Color(0xFF1C1618);

  // ═══════════════════════════════════════════════
  // Deep Purple Finance 头部渐变（明细页专用）
  // ═══════════════════════════════════════════════
  static const Color headerGradientStart = Color(0xFF1E1B4B); // rgb(30, 27, 75)
  static const Color headerGradientEnd = Color(0xFF312E81);   // rgb(49, 46, 129)

  // ═══════════════════════════════════════════════
  // Glassmorphism 卡片色
  // ═══════════════════════════════════════════════
  static const Color glassCardBg = Color(0xB8FFFFFF);          // 72% 白色
  static const Color glassSummaryCardBg = Color(0xE6FFFFFF);   // 90% 白色
  static const Color glassBorder = Color(0x99FFFFFF);          // 60% 白色
  static const Color glassSummaryBorder = Color(0xB3FFFFFF);   // 70% 白色
  static const Color glassNavBg = Color(0x99FFFFFF);           // 60% 白色

  // ═══════════════════════════════════════════════
  // 深靛蓝文字色（交易金额用）
  // ═══════════════════════════════════════════════
  static const Color indigo950 = Color(0xFF1E1B4B);  // rgb(30, 27, 75)
  static const Color indigo900_80 = Color(0xCC312E81); // rgba(49, 46, 129, 0.8)
  static const Color indigo400_80 = Color(0xCC818CF8); // rgba(129, 140, 248, 0.8)
  static const Color indigo200_60 = Color(0x99C7D2FE); // rgba(199, 210, 254, 0.6)

  // ═══════════════════════════════════════════════
  // 琥珀金色（收入汇总金额用）
  // ═══════════════════════════════════════════════
  static const Color amber500 = Color(0xFFF59E0B);    // rgb(245, 158, 11)

  // ═══════════════════════════════════════════════
  // Emerald-600（收入金额用）
  // ═══════════════════════════════════════════════
  static const Color emerald600 = Color(0xFF059669);   // rgb(5, 150, 105)

  // ═══════════════════════════════════════════════
  // 淡薰衣白→淡紫丁香 渐变（明细页背景）
  // ═══════════════════════════════════════════════
  static const Color bgDetailTop = Color(0xFFfdf4ff);   // rgb(253, 244, 255)
  static const Color bgDetailBottom = Color(0xFFe9d5ff); // rgb(233, 213, 255)

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
