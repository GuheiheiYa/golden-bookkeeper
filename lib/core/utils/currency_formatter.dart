import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '¥',
    decimalDigits: 2,
  );

  static final NumberFormat _compactFormat = NumberFormat.compact(
    locale: 'zh_CN',
  );

  /// 格式化金额
  static String format(double amount, {bool showSign = false}) {
    if (showSign) {
      final sign = amount >= 0 ? '+' : '-';
      return '$sign${_currencyFormat.format(amount.abs())}';
    }
    return _currencyFormat.format(amount);
  }

  /// 格式化金额（简短形式）
  static String formatCompact(double amount) {
    if (amount >= 10000) {
      return '¥${(amount / 10000).toStringAsFixed(1)}万';
    } else if (amount >= 1000) {
      return '¥${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '¥${amount.toStringAsFixed(2)}';
  }

  /// 格式化金额（带颜色标记）
  static String formatWithColor(double amount) {
    final prefix = amount >= 0 ? '+' : '-';
    return '$prefix${_currencyFormat.format(amount.abs())}';
  }

  /// 解析金额字符串
  static double? parse(String amountStr) {
    try {
      final cleaned = amountStr
          .replaceAll('¥', '')
          .replaceAll(',', '')
          .replaceAll(' ', '')
          .trim();
      return double.tryParse(cleaned);
    } catch (e) {
      return null;
    }
  }

  /// 验证金额格式
  static bool isValid(String amountStr) {
    final parsed = parse(amountStr);
    return parsed != null && parsed > 0;
  }
}
