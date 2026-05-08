import 'package:universal_io/io.dart';

/// 账单解析器抽象接口
abstract class BillParser {
  /// 解析账单文件，返回待导入的交易记录列表
  Future<List<ParsedTransaction>> parse(File file);

  /// 验证文件格式是否正确
  bool canParse(File file);

  /// 获取来源名称（微信/支付宝）
  String get sourceName;
}

/// 解析后的交易记录（未入库）
class ParsedTransaction {
  final double amount;
  final bool isExpense;
  final DateTime date;
  final String description; // 商户名/描述
  final String? category; // 原始分类
  final String? orderId; // 订单号
  final String? paymentMethod; // 支付方式
  final Map<String, dynamic>? rawData; // 原始数据

  ParsedTransaction({
    required this.amount,
    required this.isExpense,
    required this.date,
    required this.description,
    this.category,
    this.orderId,
    this.paymentMethod,
    this.rawData,
  });

  @override
  String toString() {
    return 'ParsedTransaction(amount: $amount, isExpense: $isExpense, date: $date, description: $description)';
  }
}
