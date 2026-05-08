import 'dart:convert';
import 'package:universal_io/io.dart';
import 'package:excel/excel.dart';
import 'bill_parser.dart';

/// 微信账单解析器
class WechatParser implements BillParser {
  @override
  String get sourceName => '微信';

  @override
  bool canParse(File file) {
    try {
      final path = file.path.toLowerCase();
      if (path.endsWith('.xlsx')) {
        // xlsx 文件通过内容验证
        return true;
      }
      final content = file.readAsStringSync(encoding: utf8);
      return content.contains('微信支付账单明细') ||
          (content.contains('交易时间') && content.contains('交易类型'));
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<ParsedTransaction>> parse(File file) async {
    final path = file.path.toLowerCase();
    if (path.endsWith('.xlsx')) {
      return _parseXlsx(file);
    }
    return _parseCsv(file);
  }

  /// 解析 xlsx 格式
  Future<List<ParsedTransaction>> _parseXlsx(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    final List<ParsedTransaction> transactions = [];

    for (final table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null) continue;

      bool isHeader = true;
      List<String> headers = [];

      for (final row in sheet.rows) {
        if (row.isEmpty) continue;

        // 转换为字符串列表
        final cells = row.map((cell) => cell?.value?.toString() ?? '').toList();

        if (isHeader) {
          // 检测表头行
          if (cells.any((c) => c.contains('交易时间')) ||
              cells.any((c) => c.contains('交易类型'))) {
            headers = cells;
            isHeader = false;
            continue;
          }
          continue;
        }

        // 跳过汇总行
        if (cells.any((c) => c.contains('共') && c.contains('笔'))) continue;

        final transaction = _parseXlsxRow(cells, headers);
        if (transaction != null) {
          transactions.add(transaction);
        }
      }
    }

    return transactions;
  }

  /// 解析 xlsx 行
  ParsedTransaction? _parseXlsxRow(List<String> cells, List<String> headers) {
    try {
      if (cells.length < 6) return null;

      // 根据表头或默认顺序解析
      String timeStr = '';
      String type = '';
      String target = '';
      String goods = '';
      String direction = '';
      String amountStr = '';
      String payMethod = '';
      String status = '';
      String orderId = '';

      if (headers.isNotEmpty) {
        for (int i = 0; i < cells.length && i < headers.length; i++) {
          final header = headers[i];
          if (header.contains('交易时间')) timeStr = cells[i];
          else if (header.contains('交易类型')) type = cells[i];
          else if (header.contains('交易对方')) target = cells[i];
          else if (header.contains('商品')) goods = cells[i];
          else if (header.contains('收') && header.contains('支')) direction = cells[i];
          else if (header.contains('金额')) amountStr = cells[i];
          else if (header.contains('支付方式') || header.contains('付款方式')) payMethod = cells[i];
          else if (header.contains('当前状态')) status = cells[i];
          else if (header.contains('交易单号')) orderId = cells[i];
        }
      } else {
        // 默认顺序
        timeStr = cells[0];
        type = cells[1];
        target = cells[2];
        goods = cells[3];
        direction = cells[4];
        amountStr = cells[5];
        if (cells.length > 6) payMethod = cells[6];
        if (cells.length > 7) status = cells[7];
        if (cells.length > 8) orderId = cells[8];
      }

      final date = _parseDateTime(timeStr);
      if (date == null) return null;

      final amount = double.tryParse(amountStr.replaceAll('¥', '').replaceAll(',', ''));
      if (amount == null || amount <= 0) return null;

      final isExpense = direction == '支出';
      // 交易对方作为描述（用于分类匹配），商品作为备注
      final note = (goods.isNotEmpty && goods != '/') ? goods : null;

      return ParsedTransaction(
        amount: amount,
        isExpense: isExpense,
        date: date,
        description: target,
        note: note,
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

  /// 解析 csv 格式
  Future<List<ParsedTransaction>> _parseCsv(File file) async {
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
      // 交易对方作为描述（用于分类匹配），商品作为备注
      final note = (goods.isNotEmpty && goods != '/') ? goods : null;

      return ParsedTransaction(
        amount: amount,
        isExpense: isExpense,
        date: date,
        description: target,
        note: note,
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
