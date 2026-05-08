/// 币种信息
class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;
  const CurrencyInfo(this.code, this.symbol, this.name);
}

/// 支持的币种列表
const supportedCurrencies = [
  CurrencyInfo('CNY', '¥', '人民币'),
  CurrencyInfo('USD', '\$', '美元'),
  CurrencyInfo('EUR', '€', '欧元'),
  CurrencyInfo('GBP', '£', '英镑'),
  CurrencyInfo('JPY', '¥', '日元'),
  CurrencyInfo('KRW', '₩', '韩元'),
  CurrencyInfo('HKD', 'HK\$', '港币'),
  CurrencyInfo('TWD', 'NT\$', '新台币'),
];

/// 根据币种代码获取币种符号
String getCurrencySymbol(String code) {
  final match = supportedCurrencies.where((c) => c.code == code);
  return match.isNotEmpty ? match.first.symbol : code;
}

/// 根据币种代码获取币种名称
String getCurrencyName(String code) {
  final match = supportedCurrencies.where((c) => c.code == code);
  return match.isNotEmpty ? match.first.name : code;
}
