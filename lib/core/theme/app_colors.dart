import 'package:flutter/material.dart';

class AppColors {
  /// 主色：偏亮紫，在深色底上更接近参考图的点缀色
  static const Color primary = Color(0xFF8B5CF6);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF7C3AED);
  static const Color secondary = Color(0xFF6366F1);
  static const Color secondaryLight = Color(0xFF818CF8);

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

  /// 暗色：近黑底 + 略亮一级卡片（对齐常见 premium dark / #121212 体系）
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2E);
  static const Color darkOnBackground = Color(0xFFFFFFFF);
  static const Color darkOnSurface = Color(0xFFFFFFFF);
  static const Color darkOnSurfaceVariant = Color(0xFF9E9E9E);
  static const Color darkOutline = Color(0xFF38383A);
  static const Color darkShadow = Color(0x66000000);

  /// 深色卡片边缘高光（轻层次，非重度玻璃模糊）
  static const Color darkCardBorder = Color(0x14FFFFFF);

  // 分类颜色
  static const List<Color> categoryColors = [
    Color(0xFF7C3AED),
    Color(0xFF6366F1),
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
