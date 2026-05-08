import 'package:universal_io/io.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  /// 导出为 CSV
  Future<File> exportToCsv({
    required List<Map<String, dynamic>> transactions,
    required String fileName,
  }) async {
    final List<List<dynamic>> csvData = [];

    // 添加表头
    csvData.add([
      '日期',
      '时间',
      '分类',
      '金额',
      '类型',
      '账户',
      '备注',
    ]);

    // 添加数据行
    for (final tx in transactions) {
      final dateStr = tx['date']?.toString() ?? '';
      // 提取日期和时间部分
      String date = dateStr;
      String time = '';
      if (dateStr.contains('T')) {
        final parts = dateStr.split('T');
        date = parts[0];
        time = parts.length > 1 ? parts[1].split('.').first : '';
      } else if (dateStr.contains(' ')) {
        final parts = dateStr.split(' ');
        date = parts[0];
        time = parts.length > 1 ? parts[1] : '';
      }

      final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
      final isExpense = tx['is_expense'] == 1;

      csvData.add([
        date,
        time,
        tx['category_name'] ?? tx['category'] ?? '',
        amount.toStringAsFixed(2),
        isExpense ? '支出' : '收入',
        tx['account_name'] ?? tx['account'] ?? '',
        tx['note'] ?? tx['title'] ?? '',
      ]);
    }

    final csv = const ListToCsvConverter().convert(csvData);

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.csv');
    await file.writeAsString('﻿$csv', flush: true); // 添加 BOM 头，防止中文乱码

    return file;
  }

  /// 导出为 Excel
  Future<File> exportToExcel({
    required List<Map<String, dynamic>> transactions,
    required String fileName,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['交易记录'];

    // 删除默认的 Sheet1
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // 定义表头样式
    final headerStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Calibri),
    );

    // 添加表头
    final headers = ['日期', '时间', '分类', '金额', '类型', '账户', '备注'];
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // 添加数据行
    for (int i = 0; i < transactions.length; i++) {
      final tx = transactions[i];
      final dateStr = tx['date']?.toString() ?? '';
      String date = dateStr;
      String time = '';
      if (dateStr.contains('T')) {
        final parts = dateStr.split('T');
        date = parts[0];
        time = parts.length > 1 ? parts[1].split('.').first : '';
      } else if (dateStr.contains(' ')) {
        final parts = dateStr.split(' ');
        date = parts[0];
        time = parts.length > 1 ? parts[1] : '';
      }

      final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
      final isExpense = tx['is_expense'] == 1;
      final rowIndex = i + 1;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(date);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(time);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(tx['category_name'] ?? tx['category'] ?? '');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = DoubleCellValue(amount);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(isExpense ? '支出' : '收入');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(tx['account_name'] ?? tx['account'] ?? '');
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(tx['note'] ?? tx['title'] ?? '');
    }

    // 设置列宽
    sheet.setColumnWidth(0, 15);
    sheet.setColumnWidth(1, 12);
    sheet.setColumnWidth(2, 15);
    sheet.setColumnWidth(3, 12);
    sheet.setColumnWidth(4, 8);
    sheet.setColumnWidth(5, 15);
    sheet.setColumnWidth(6, 30);

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.xlsx');
    final bytes = excel.save();
    if (bytes != null) {
      await file.writeAsBytes(bytes, flush: true);
    }

    return file;
  }

  /// 分享文件
  Future<void> shareFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '记账数据导出',
    );
  }

  /// 获取默认文件名
  String getDefaultFileName({String? startDate, String? endDate}) {
    final now = DateTime.now();
    if (startDate != null && endDate != null) {
      return '记账数据_${startDate}_至_$endDate';
    }
    return '记账数据_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  /// 格式化日期为字符串 (yyyy-MM-dd)
  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
