import 'dart:convert';
import 'package:universal_io/io.dart';
import 'bill_parser.dart';

/// 微信账单解析器
class WechatParser implements BillParser {
  @override
  String get sourceName => '微信';

  @override
  bool canParse(File file) {
    try {
      final content = file.readAsStringSync(encoding: utf8);
      return content.contains('微信支付账单明细') ||
          (content.contains('交易时间') && content.contains('交易类型'));
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<ParsedTransaction>> parse(File file) async {
    final content = await file.readAsString(encoding: utf8);
    final lines = content.split('\n');

    final List<ParsedTransaction> transactions = [];

    bool isHeader = true;
    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      if (isHeader) {
        if (line.contains('交易时间') && line.contains('交易类型')) {
          isHeader = false;
          continue;
        }
        continue;
      }

      if (line.contains('共') && line.contains('笔')) continue;

      final transaction = _parseLine(line);
      if (transaction != null) {
        transactions.add(transaction);
      }
    }

    return transactions;
  }

  ParsedTransaction? _parseLine(String line) {
    try {
      // 微信账单 CSV 格式：
      // 交易时间,交易类型,交易对方,商品,收/支,金额,支付方式,当前状态,交易单号,商户单号,备注
      final parts = _splitCsvLine(line);
      if (parts.length < 10) return null;

      final timeStr = parts[0].trim();
      final type = parts[1].trim();
      final target = parts[2].trim();
      final goods = parts[3].trim();
      final direction = parts[4].trim();
      final amountStr = parts[5].trim();
      final payMethod = parts[6].trim();
      final status = parts[7].trim();
      final orderId = parts[8].trim();

      final date = _parseDateTime(timeStr);
      if (date == null) return null;

      final amount = double.tryParse(amountStr.replaceAll('¥', '').replaceAll(',', ''));
      if (amount == null || amount <= 0) return null;

      final isExpense = direction == '支出';
      final description = target.isNotEmpty ? target : goods;

      return ParsedTransaction(
        amount: amount,
        isExpense: isExpense,
        date: date,
        description: description,
        category: type,
        orderId: orderId,
        paymentMethod: payMethod,
        rawData: {
          'time': timeStr,
          'type': type,
          'target': target,
          'goods': goods,
          'direction': direction,
          'amount': amountStr,
          'payMethod': payMethod,
          'status': status,
          'orderId': orderId,
        },
      );
    } catch (e) {
      return null;
    }
  }

  List<String> _splitCsvLine(String line) {
    final List<String> result = [];
    StringBuffer current = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString());

    return result;
  }

  DateTime? _parseDateTime(String timeStr) {
    try {
      return DateTime.parse(timeStr);
    } catch (e) {
      return null;
    }
  }
}
