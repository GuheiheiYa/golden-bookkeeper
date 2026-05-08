import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      // Web 平台：使用内存数据库
      return await openDatabase(
        inMemoryDatabasePath,
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
    final dbFolder = await getApplicationDocumentsDirectory();
    final path = p.join(dbFolder.path, 'bookkeeper.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 账户表
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        currency TEXT DEFAULT 'CNY',
        balance REAL DEFAULT 0,
        icon TEXT,
        color INTEGER,
        include_in_total INTEGER DEFAULT 1,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 分类表
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        is_expense INTEGER NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER,
        parent_id INTEGER,
        sort_order INTEGER DEFAULT 0,
        is_system INTEGER DEFAULT 0
      )
    ''');

    // 交易记录表
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        currency TEXT DEFAULT 'CNY',
        exchange_rate REAL DEFAULT 1.0,
        is_expense INTEGER NOT NULL,
        note TEXT,
        goods TEXT,
        date TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        account_id INTEGER NOT NULL,
        recurring_rule_id INTEGER,
        image_path TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id),
        FOREIGN KEY (account_id) REFERENCES accounts (id)
      )
    ''');

    // 标签表
    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color INTEGER
      )
    ''');

    // 交易-标签关联表
    await db.execute('''
      CREATE TABLE transaction_tags (
        transaction_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (transaction_id, tag_id),
        FOREIGN KEY (transaction_id) REFERENCES transactions (id),
        FOREIGN KEY (tag_id) REFERENCES tags (id)
      )
    ''');

    // 预算表
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        amount REAL NOT NULL,
        period_type TEXT NOT NULL,
        year INTEGER NOT NULL,
        month INTEGER,
        currency TEXT DEFAULT 'CNY',
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // 周期记账规则表
    await db.execute('''
      CREATE TABLE recurring_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT DEFAULT 'CNY',
        is_expense INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        account_id INTEGER NOT NULL,
        frequency TEXT NOT NULL,
        day_of_month INTEGER,
        day_of_week INTEGER,
        start_date TEXT NOT NULL,
        end_date TEXT,
        is_active INTEGER DEFAULT 1,
        last_executed TEXT,
        note TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id),
        FOREIGN KEY (account_id) REFERENCES accounts (id)
      )
    ''');

    // 汇率缓存表
    await db.execute('''
      CREATE TABLE exchange_rates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        base_currency TEXT NOT NULL,
        target_currency TEXT NOT NULL,
        rate REAL NOT NULL,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 插入默认数据
    await _insertDefaultData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v2: transactions 表新增 goods 字段
      await db.execute('ALTER TABLE transactions ADD COLUMN goods TEXT');
    }
  }

  Future<void> _insertDefaultData(Database db) async {
    // 插入默认支出分类
    final expenseCategories = [
      {'name': '餐饮', 'icon': 'restaurant', 'color': 0xFFF97316},
      {'name': '交通', 'icon': 'directions_car', 'color': 0xFF3B82F6},
      {'name': '购物', 'icon': 'shopping_bag', 'color': 0xFFEC4899},
      {'name': '娱乐', 'icon': 'sports_esports', 'color': 0xFF8B5CF6},
      {'name': '居住', 'icon': 'home', 'color': 0xFF10B981},
      {'name': '医疗', 'icon': 'local_hospital', 'color': 0xFFEF4444},
      {'name': '教育', 'icon': 'school', 'color': 0xFF06B6D4},
      {'name': '通讯', 'icon': 'phone_android', 'color': 0xFF6366F1},
      {'name': '转账', 'icon': 'swap_horiz', 'color': 0xFFF59E0B},
      {'name': '其他', 'icon': 'more_horiz', 'color': 0xFF6B7280},
    ];

    for (int i = 0; i < expenseCategories.length; i++) {
      final cat = expenseCategories[i];
      await db.insert('categories', {
        'name': cat['name'],
        'is_expense': 1,
        'icon': cat['icon'],
        'color': cat['color'],
        'sort_order': i,
        'is_system': 1,
      });
    }

    // 插入默认收入分类
    final incomeCategories = [
      {'name': '工资', 'icon': 'work', 'color': 0xFF10B981},
      {'name': '奖金', 'icon': 'emoji_events', 'color': 0xFFF59E0B},
      {'name': '投资', 'icon': 'trending_up', 'color': 0xFF6366F1},
      {'name': '其他', 'icon': 'more_horiz', 'color': 0xFF6B7280},
    ];

    for (int i = 0; i < incomeCategories.length; i++) {
      final cat = incomeCategories[i];
      await db.insert('categories', {
        'name': cat['name'],
        'is_expense': 0,
        'icon': cat['icon'],
        'color': cat['color'],
        'sort_order': i,
        'is_system': 1,
      });
    }

    // 插入默认账户
    final accounts = [
      {'name': '现金', 'type': 'cash', 'icon': 'payments', 'color': 0xFFF59E0B},
      {'name': '银行卡', 'type': 'bank', 'icon': 'account_balance', 'color': 0xFF3B82F6},
      {'name': '支付宝', 'type': 'alipay', 'icon': 'account_balance_wallet', 'color': 0xFF06B6D4},
      {'name': '微信', 'type': 'wechat', 'icon': 'chat', 'color': 0xFF10B981},
    ];

    for (final account in accounts) {
      await db.insert('accounts', account);
    }
  }

  // ========== 交易记录操作 ==========

  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  /// 根据 ID 获取单条交易记录（含分类和账户信息）
  Future<Map<String, dynamic>?> getTransactionById(int id) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT t.*, c.name as category_name, c.icon as category_icon, c.color as category_color,
             a.name as account_name, a.icon as account_icon, a.color as account_color
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      LEFT JOIN accounts a ON t.account_id = a.id
      WHERE t.id = ?
    ''', [id]);
    return result.isNotEmpty ? result.first : null;
  }

  /// 更新交易记录
  Future<int> updateTransaction(int id, Map<String, dynamic> transaction) async {
    final db = await database;
    transaction['updated_at'] = DateTime.now().toIso8601String();
    return await db.update('transactions', transaction, where: 'id = ?', whereArgs: [id]);
  }

  /// 插入交易-标签关联记录
  Future<int> insertTransactionTag(int transactionId, int tagId) async {
    final db = await database;
    return await db.insert('transaction_tags', {
      'transaction_id': transactionId,
      'tag_id': tagId,
    });
  }

  /// 删除交易的所有标签关联
  Future<void> deleteTransactionTags(int transactionId) async {
    final db = await database;
    await db.delete('transaction_tags', where: 'transaction_id = ?', whereArgs: [transactionId]);
  }

  Future<List<Map<String, dynamic>>> getTransactions({
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
    List<int>? categoryIds,
    bool? isExpense,
    String? keyword,
    int? accountId,
  }) async {
    final db = await database;
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += ' AND t.date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClause += ' AND t.date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }
    if (categoryId != null) {
      whereClause += ' AND t.category_id = ?';
      whereArgs.add(categoryId);
    }
    // 多分类筛选
    if (categoryIds != null && categoryIds.isNotEmpty) {
      final placeholders = categoryIds.map((_) => '?').join(',');
      whereClause += ' AND t.category_id IN ($placeholders)';
      whereArgs.addAll(categoryIds);
    }
    if (isExpense != null) {
      whereClause += ' AND t.is_expense = ?';
      whereArgs.add(isExpense ? 1 : 0);
    }
    // 按备注关键字搜索
    if (keyword != null && keyword.isNotEmpty) {
      whereClause += ' AND t.note LIKE ?';
      whereArgs.add('%$keyword%');
    }
    // 按账户筛选
    if (accountId != null) {
      whereClause += ' AND t.account_id = ?';
      whereArgs.add(accountId);
    }

    final result = await db.rawQuery('''
      SELECT t.*, c.name as category_name, c.icon as category_icon, c.color as category_color,
             a.name as account_name, a.icon as account_icon, a.color as account_color
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      LEFT JOIN accounts a ON t.account_id = a.id
      WHERE $whereClause
      ORDER BY t.date DESC
      ${limit != null ? 'LIMIT $limit' : ''}
      ${offset != null ? 'OFFSET $offset' : ''}
    ''', whereArgs);

    return result;
  }

  /// 获取指定分类下的交易数量
  Future<int> getTransactionCountForCategory(int categoryId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions WHERE category_id = ?',
      [categoryId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// 获取指定账户下的交易数量
  Future<int> getTransactionCountForAccount(int accountId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions WHERE account_id = ?',
      [accountId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<double> getTotalIncome(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE is_expense = 0 AND date >= ? AND date <= ?
    ''', [start.toIso8601String(), end.toIso8601String()]);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalExpense(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE is_expense = 1 AND date >= ? AND date <= ?
    ''', [start.toIso8601String(), end.toIso8601String()]);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> getCategorySummary(
    DateTime start,
    DateTime end, {
    bool isExpense = true,
  }) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT c.id, c.name, c.icon, c.color, SUM(t.amount) as total
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      WHERE t.is_expense = ? AND t.date >= ? AND t.date <= ?
      GROUP BY c.id
      ORDER BY total DESC
    ''', [isExpense ? 1 : 0, start.toIso8601String(), end.toIso8601String()]);
  }

  // ========== 分类操作 ==========

  Future<List<Map<String, dynamic>>> getCategories({bool? isExpense}) async {
    final db = await database;
    if (isExpense != null) {
      return await db.query(
        'categories',
        where: 'is_expense = ?',
        whereArgs: [isExpense ? 1 : 0],
        orderBy: 'sort_order ASC',
      );
    }
    return await db.query('categories', orderBy: 'sort_order ASC');
  }

  Future<int> insertCategory(Map<String, dynamic> category) async {
    final db = await database;
    return await db.insert('categories', category);
  }

  Future<int> updateCategory(int id, Map<String, dynamic> category) async {
    final db = await database;
    return await db.update('categories', category, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ========== 账户操作 ==========

  Future<List<Map<String, dynamic>>> getAccounts() async {
    final db = await database;
    return await db.query('accounts', orderBy: 'sort_order ASC');
  }

  Future<int> insertAccount(Map<String, dynamic> account) async {
    final db = await database;
    return await db.insert('accounts', account);
  }

  Future<int> updateAccount(int id, Map<String, dynamic> account) async {
    final db = await database;
    return await db.update('accounts', account, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAccount(int id) async {
    final db = await database;
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalBalance() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(balance), 0) as total
      FROM accounts
      WHERE include_in_total = 1
    ''');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ========== 标签操作 ==========

  Future<List<Map<String, dynamic>>> getTags() async {
    final db = await database;
    return await db.query('tags');
  }

  Future<int> insertTag(Map<String, dynamic> tag) async {
    final db = await database;
    return await db.insert('tags', tag);
  }

  Future<int> updateTag(int id, Map<String, dynamic> tag) async {
    final db = await database;
    return await db.update('tags', tag, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTag(int id) async {
    final db = await database;
    return await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getTagsForTransaction(int transactionId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT t.* FROM tags t
      JOIN transaction_tags tt ON t.id = tt.tag_id
      WHERE tt.transaction_id = ?
    ''', [transactionId]);
  }

  Future<void> addTagToTransaction(int transactionId, int tagId) async {
    final db = await database;
    await db.insert('transaction_tags', {
      'transaction_id': transactionId,
      'tag_id': tagId,
    });
  }

  // ========== 预算操作 ==========

  Future<List<Map<String, dynamic>>> getBudgets({int? year, int? month}) async {
    final db = await database;
    if (year != null && month != null) {
      return await db.query(
        'budgets',
        where: 'year = ? AND month = ?',
        whereArgs: [year, month],
      );
    }
    return await db.query('budgets');
  }

  Future<int> insertBudget(Map<String, dynamic> budget) async {
    final db = await database;
    return await db.insert('budgets', budget);
  }

  Future<int> updateBudget(int id, Map<String, dynamic> budget) async {
    final db = await database;
    return await db.update('budgets', budget, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteBudget(int id) async {
    final db = await database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // 获取分类在指定时间段内的总支出
  Future<double> getCategoryExpense(int categoryId, DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE category_id = ? AND is_expense = 1 AND date >= ? AND date <= ?
    ''', [categoryId, start.toIso8601String(), end.toIso8601String()]);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ========== 周期记账操作 ==========

  Future<List<Map<String, dynamic>>> getRecurringRules({bool? isActive}) async {
    final db = await database;
    if (isActive != null) {
      return await db.query(
        'recurring_rules',
        where: 'is_active = ?',
        whereArgs: [isActive ? 1 : 0],
      );
    }
    return await db.query('recurring_rules');
  }

  Future<int> insertRecurringRule(Map<String, dynamic> rule) async {
    final db = await database;
    return await db.insert('recurring_rules', rule);
  }

  Future<int> updateRecurringRule(int id, Map<String, dynamic> rule) async {
    final db = await database;
    return await db.update('recurring_rules', rule, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteRecurringRule(int id) async {
    final db = await database;
    return await db.delete('recurring_rules', where: 'id = ?', whereArgs: [id]);
  }

  /// 检查并执行到期的周期记账规则
  Future<List<int>> executeDueRecurringRules() async {
    final db = await database;
    final now = DateTime.now();
    final executedIds = <int>[];

    // 查询所有激活的规则
    final rules = await db.query('recurring_rules', where: 'is_active = 1');

    for (final rule in rules) {
      final startDate = DateTime.parse(rule['start_date'] as String);
      final endDate = rule['end_date'] != null
          ? DateTime.parse(rule['end_date'] as String)
          : null;
      final lastExecuted = rule['last_executed'] != null
          ? DateTime.parse(rule['last_executed'] as String)
          : null;
      final frequency = rule['frequency'] as String;
      final dayOfMonth = rule['day_of_month'] as int?;

      // 检查是否在有效期内
      if (now.isBefore(startDate)) continue;
      if (endDate != null && now.isAfter(endDate)) continue;

      // 检查今天是否应该执行
      bool shouldExecute = false;

      if (lastExecuted == null) {
        // 从未执行过，检查是否到了首次执行时间
        shouldExecute =
            _shouldExecuteToday(frequency, dayOfMonth, startDate, now);
      } else {
        // 检查距离上次执行是否间隔足够
        shouldExecute =
            _isDueForExecution(frequency, dayOfMonth, lastExecuted, now);
      }

      if (shouldExecute) {
        // 插入交易记录
        await db.insert('transactions', {
          'amount': rule['amount'],
          'is_expense': rule['is_expense'],
          'note': rule['title'],
          'date': now.toIso8601String(),
          'category_id': rule['category_id'],
          'account_id': rule['account_id'],
          'currency': rule['currency'] ?? 'CNY',
          'recurring_rule_id': rule['id'],
        });

        // 更新最后执行时间
        await db.update(
          'recurring_rules',
          {'last_executed': now.toIso8601String()},
          where: 'id = ?',
          whereArgs: [rule['id']],
        );

        executedIds.add(rule['id'] as int);
      }
    }

    return executedIds;
  }

  /// 判断今天是否应该执行（首次执行）
  bool _shouldExecuteToday(
      String frequency, int? dayOfMonth, DateTime startDate, DateTime now) {
    switch (frequency) {
      case 'minutely':
        return true;
      case 'hourly':
        return true;
      case 'daily':
        return true;
      case 'weekly':
        return now.weekday == startDate.weekday;
      case 'monthly':
        final targetDay = dayOfMonth ?? startDate.day;
        return now.day == targetDay ||
            (now.day == _lastDayOfMonth(now) && targetDay > now.day);
      case 'yearly':
        return now.month == startDate.month && now.day == startDate.day;
      default:
        return false;
    }
  }

  /// 判断距上次执行是否已到期
  bool _isDueForExecution(
      String frequency, int? dayOfMonth, DateTime lastExecuted, DateTime now) {
    final diffMinutes = now.difference(lastExecuted).inMinutes;
    final diffDays = now.difference(lastExecuted).inDays;
    switch (frequency) {
      case 'minutely':
        return diffMinutes >= 1;
      case 'hourly':
        return diffMinutes >= 60;
      case 'daily':
        return diffDays >= 1;
      case 'weekly':
        return diffDays >= 7;
      case 'monthly':
        return diffDays >= 28; // 简化处理
      case 'yearly':
        return diffDays >= 365;
      default:
        return false;
    }
  }

  /// 获取某月的最后一天
  int _lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  // ========== 汇率操作 ==========

  /// 获取汇率（from -> to），如无记录则返回 1.0
  Future<double> getExchangeRate(String from, String to) async {
    if (from == to) return 1.0;
    final db = await database;
    final result = await db.query(
      'exchange_rates',
      where: 'base_currency = ? AND target_currency = ?',
      whereArgs: [from, to],
    );
    if (result.isNotEmpty) {
      return (result.first['rate'] as num).toDouble();
    }
    return 1.0; // 默认 1:1
  }

  /// 更新或插入汇率
  Future<void> upsertExchangeRate(
      String from, String to, double rate) async {
    final db = await database;
    final existing = await db.query(
      'exchange_rates',
      where: 'base_currency = ? AND target_currency = ?',
      whereArgs: [from, to],
    );
    if (existing.isNotEmpty) {
      await db.update(
        'exchange_rates',
        {
          'rate': rate,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'base_currency = ? AND target_currency = ?',
        whereArgs: [from, to],
      );
    } else {
      await db.insert('exchange_rates', {
        'base_currency': from,
        'target_currency': to,
        'rate': rate,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }
}
