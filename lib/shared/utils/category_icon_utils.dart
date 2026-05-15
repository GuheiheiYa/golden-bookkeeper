import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// 分类图标信息（使用 Font Awesome 圆润图标）
class CategoryIconInfo {
  final IconData icon;
  final Color color;

  const CategoryIconInfo({required this.icon, required this.color});
}

/// 分类名称 → Font Awesome 图标 + 颜色映射
/// 用于待确认记账弹窗、记账页面等需要圆润图标的场景
class CategoryIconUtils {
  /// 默认支出分类图标映射
  static const Map<String, CategoryIconInfo> categoryIcons = {
    '餐饮': CategoryIconInfo(icon: FontAwesomeIcons.utensils, color: Color(0xFFF97316)),
    '交通': CategoryIconInfo(icon: FontAwesomeIcons.car, color: Color(0xFF3B82F6)),
    '购物': CategoryIconInfo(icon: FontAwesomeIcons.bagShopping, color: Color(0xFFEC4899)),
    '娱乐': CategoryIconInfo(icon: FontAwesomeIcons.gamepad, color: Color(0xFF8B5CF6)),
    '居住': CategoryIconInfo(icon: FontAwesomeIcons.house, color: Color(0xFF10B981)),
    '医疗': CategoryIconInfo(icon: FontAwesomeIcons.briefcaseMedical, color: Color(0xFFEF4444)),
    '教育': CategoryIconInfo(icon: FontAwesomeIcons.graduationCap, color: Color(0xFF06B6D4)),
    '通讯': CategoryIconInfo(icon: FontAwesomeIcons.mobileScreen, color: Color(0xFF6366F1)),
    '转账': CategoryIconInfo(icon: FontAwesomeIcons.arrowRightArrowLeft, color: Color(0xFFF59E0B)),
    '其他': CategoryIconInfo(icon: FontAwesomeIcons.ellipsis, color: Color(0xFF6B7280)),
  };

  /// 默认收入分类图标映射
  static const Map<String, CategoryIconInfo> incomeIcons = {
    '工资': CategoryIconInfo(icon: FontAwesomeIcons.briefcase, color: Color(0xFF10B981)),
    '奖金': CategoryIconInfo(icon: FontAwesomeIcons.trophy, color: Color(0xFFF59E0B)),
    '投资': CategoryIconInfo(icon: FontAwesomeIcons.chartLine, color: Color(0xFF6366F1)),
    '其他': CategoryIconInfo(icon: FontAwesomeIcons.ellipsis, color: Color(0xFF6B7280)),
  };

  /// 支付来源图标（微信/支付宝等）
  static const Map<String, CategoryIconInfo> sourceIcons = {
    'wechat': CategoryIconInfo(icon: FontAwesomeIcons.weixin, color: Color(0xFF07C160)),
    'alipay': CategoryIconInfo(icon: FontAwesomeIcons.alipay, color: Color(0xFF1677FF)),
    'cmb': CategoryIconInfo(icon: FontAwesomeIcons.buildingColumns, color: Color(0xFFDC143C)),
    'icbc': CategoryIconInfo(icon: FontAwesomeIcons.buildingColumns, color: Color(0xFFC1232C)),
    'boc': CategoryIconInfo(icon: FontAwesomeIcons.buildingColumns, color: Color(0xFFC8102E)),
    'abc': CategoryIconInfo(icon: FontAwesomeIcons.buildingColumns, color: Color(0xFF377E22)),
    'ccb': CategoryIconInfo(icon: FontAwesomeIcons.buildingColumns, color: Color(0xFF003D88)),
    'psbc': CategoryIconInfo(icon: FontAwesomeIcons.buildingColumns, color: Color(0xFF00A650)),
    'pingan': CategoryIconInfo(icon: FontAwesomeIcons.buildingColumns, color: Color(0xFF007BFF)),
    'citic': CategoryIconInfo(icon: FontAwesomeIcons.buildingColumns, color: Color(0xFFE60012)),
    'cmbc': CategoryIconInfo(icon: FontAwesomeIcons.buildingColumns, color: Color(0xFF0059B3)),
    'xm': CategoryIconInfo(icon: FontAwesomeIcons.buildingColumns, color: Color(0xFF8B4513)),
  };

  /// 根据分类名称获取图标信息
  static CategoryIconInfo? getCategoryIcon(String categoryName, {bool isExpense = true}) {
    final icons = isExpense ? categoryIcons : incomeIcons;
    return icons[categoryName];
  }

  /// 根据来源获取图标信息
  static CategoryIconInfo? getSourceIcon(String source) {
    return sourceIcons[source];
  }

  /// 获取分类图标（如果未找到返回 null）
  static IconData? getCategoryIconData(String categoryName, {bool isExpense = true}) {
    return getCategoryIcon(categoryName, isExpense: isExpense)?.icon;
  }

  /// 获取分类颜色（如果未找到返回 null）
  static Color? getCategoryColor(String categoryName, {bool isExpense = true}) {
    return getCategoryIcon(categoryName, isExpense: isExpense)?.color;
  }
}
