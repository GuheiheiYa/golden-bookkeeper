import 'dart:convert';
import 'package:universal_io/io.dart';
import 'bill_parser.dart';

/// 支付宝账单解析器
class AlipayParser implements BillParser {
  @override
  String get sourceName => '支付宝';

  @override
  bool canParse(File file) {
    try {
      try {
        final content = file.readAsStringSync(encoding: utf8);
        if (content.contains('支付宝') ||
            (content.contains('交易时间') && content.contains('交易分类'))) {
          return true;
        }
      } catch (e) {
        final bytes = file.readAsBytesSync();
        final content = latin1.decode(bytes);
        if (content.contains('支付宝') || content.contains('交易时间')) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<ParsedTransaction>> parse(File file) async {
    String content;
    try {
      content = await file.readAsString(encoding: utf8);
    } catch (e) {
      final bytes = await file.readAsBytes();
      content = latin1.decode(bytes);
    }

    final lines = content.split('\n');
    final List<ParsedTransaction> transactions = [];

    bool isHeader = true;
    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      if (isHeader) {
        if (line.contains('交易时间') && line.contains('交易分类')) {
          isHeader = false;
          continue;
        }
        continue;
      }

      if (line.contains('共') && line.contains('笔')) continue;
      if (line.contains('以下是')) continue;

      final transaction = _parseLine(line);
      if (transaction != null) {
        transactions.add(transaction);
      }
    }

    return transactions;
  }

  ParsedTransaction? _parseLine(String line) {
    try {
      // 支付宝账单 CSV 格式：
      // 交易时间,交易分类,交易对方,商品说明,收/支,金额,收/付款方式,交易状态,交易订单号,商家订单号,备注
      final parts = _splitCsvLine(line);
      if (parts.length < 10) return null;

      final timeStr = parts[0].trim();
      final category = parts[1].trim();
      final target = parts[2].trim();
      final goods = parts[3].trim();
      final direction = parts[4].trim();
      final amountStr = parts[5].trim();
      final payMethod = parts[6].trim();
      final status = parts[7].trim();
      final orderId = parts[8].trim();
      final merchantOrderId = parts[9].trim();

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
        category: category,
        orderId: orderId,
        paymentMethod: payMethod,
        rawData: {
          'time': timeStr,
          'category': category,
          'target': target,
          'goods': goods,
          'direction': direction,
          'amount': amountStr,
          'payMethod': payMethod,
          'status': status,
          'orderId': orderId,
          'merchantOrderId': merchantOrderId,
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
      final normalized = timeStr.replaceAll('/', '-');
      return DateTime.parse(normalized);
    } catch (e) {
      return null;
    }
  }
}
