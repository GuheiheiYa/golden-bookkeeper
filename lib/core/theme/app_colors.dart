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

  // ══════════════════