import 'package:flutter/material.dart';

class AppColors {
  /// 交互主色：柔和蓝（链接、选中 Tab、底栏高亮）
  static const Color primary = Color(0xFF5EB8FF);
  static const Color primaryLight = Color(0xFF82C9FF);
  static const Color primaryDark = Color(0xFF3D9EE9);
  /// 次要渐变 / 点缀
  static const Color secondary = Color(0xFF26C6DA);
  static const Color secondaryLight = Color(0xFF4DD0E1);

  /// 铜 / 桃色氛围（顶部光晕、大字渐变，对齐金融类深色稿）
  static const Color accentCopper = Color(0xFFD4A574);
  static const Color accentPeach = Color(0xFFE8C4A8);

  // 功能色（深色 UI 上略提高饱和度）
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF448AFF);

  /// 收入 / 支出（金融类深色 App 常用绿 / 珊瑚红）
  static const Color income = Color(0xFF00E676);
  static const Color expense = Color(0xFFFF5252);

  // 亮色模式
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightOnBackground = Color(0xFF1E293B);
  static const Color lightOnSurface = Color(0xFF1E293B);
  static const Color lightOnSurfaceVariant = Color(0xFF64748B);
  static const Color lightOutline = Color(0xFFE2E8F0);
  static const Color lightShadow = Color(0x0D000000);

  /// 暗色：近纯黑底 + iOS 银行风卡片灰
  static const Color darkBackground = Color(0xFF0D0D0D);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2E);
  static const Color darkOnBackground = Color(0xFFFFFFFF);
  static const Color darkOnSurface = Color(0xFFFFFFFF);
  static const Color darkOnSurfaceVariant = Color(0xFF9E9E9E);
  static const Color darkOutline = Color(0xFF38383A);
  static const Color darkShadow = Color(0x66000000);

  /// 深色卡片边缘（轻内描边）
  static const Color darkCardBorder = Color(0x14FFFFFF);

  /// 主摘要卡片深色渐变（暖褐 → 深蓝黑）
  static const Color balanceGradientStart = Color(0xFF2A2420);
  static const Color balanceGradientEnd = Color(0xFF121826);

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
