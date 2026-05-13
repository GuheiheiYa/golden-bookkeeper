import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/app_database.dart';
import '../../core/services/payment_notification_service.dart';

// 数据库 Provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// 主题模式 Provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('themeMode') ?? 0;
    state = ThemeMode.values[index];
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
  }
}

// SharedPreferences Provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

// ========== 刷新触发器 ==========

/// 交易数据刷新计数器，每次保存/删除交易后递增，触发依赖它的 provider 重新加载
final transactionRefreshProvider = StateProvider<int>((ref) => 0);

// ========== 分类 Provider ==========

/// 分类数据刷新触发器
final categoryRefreshProvider = StateProvider<int>((ref) => 0);

/// 支出分类列表
final expenseCategoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(categoryRefreshProvider);
  final db = ref.watch(appDatabaseProvider);
  return await db.getCategories(isExpense: true);
});

/// 收入分类列表
final incomeCategoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(categoryRefreshProvider);
  final db = ref.watch(appDatabaseProvider);
  return await db.getCategories(isExpense: false);
});

// ========== 账户 Provider ==========

/// 账户列表
final accountsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return await db.getAccounts();
});

// ========== 本月汇总 Provider ==========

/// 本月收入/支出/结余
final monthlySummaryProvider = FutureProvider<Map<String, double>>((ref) async {
  // 监听刷新触发器
  ref.watch(transactionRefreshProvider);
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  final income = await db.getTotalIncome(start, end);
  final expense = await db.getTotalExpense(start, end);
  return {
    'income': income,
    'expense': expense,
    'balance': income - expense,
  };
});

/// 指定月份的收入/支出/结余
final monthlySummaryByMonthProvider = FutureProvider.family<Map<String, double>, ({int year, int month})>((ref, params) async {
  ref.watch(transactionRefreshProvider);
  final db = ref.watch(appDatabaseProvider);
  final start = DateTime(params.year, params.month, 1);
  final end = DateTime(params.year, params.month + 1, 0, 23, 59, 59);
  final income = await db.getTotalIncome(start, end);
  final expense = await db.getTotalExpense(start, end);
  return {
    'income': income,
    'expense': expense,
    'balance': income - expense,
  };
});

/// 指定月份的分类汇总
final categorySummaryByMonthProvider = FutureProvider.family<List<Map<String, dynamic>>, ({bool isExpense, int year, int month})>((ref, params) async {
  ref.watch(transactionRefreshProvider);
  final db = ref.watch(appDatabaseProvider);
  final start = DateTime(params.year, params.month, 1);
  final end = DateTime(params.year, params.month + 1, 0, 23, 59, 59);
  return await db.getCategorySummary(start, end, isExpense: params.isExpense);
});

// ========== 最近交易 Provider ==========

/// 最近 5 笔交易
final recentTransactionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(transactionRefreshProvider);
  final db = ref.watch(appDatabaseProvider);
  return await db.getTransactions(limit: 5);
});

// ========== 全部交易记录 Provider ==========

/// 交易筛选条件
class TransactionFilter {
  final String? keyword;
  final List<int>? categoryIds;
  final bool? isExpense;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? accountId;

  const TransactionFilter({
    this.keyword,
    this.categoryIds,
    this.isExpense,
    this.startDate,
    this.endDate,
    this.accountId,
  });

  /// 是否有筛选条件
  bool get hasFilters =>
      (keyword != null && keyword!.isNotEmpty) ||
      (categoryIds != null && categoryIds!.isNotEmpty) ||
      isExpense != null ||
      startDate != null ||
      endDate != null ||
      accountId != null;

  /// 当前筛选条件数量
  int get filterCount {
    int count = 0;
    if (keyword != null && keyword!.isNotEmpty) count++;
    if (categoryIds != null && categoryIds!.isNotEmpty) count++;
    if (isExpense != null) count++;
    if (startDate != null) count++;
    if (endDate != null) count++;
    if (accountId != null) count++;
    return count;
  }

  TransactionFilter copyWith({
    String? keyword,
    List<int>? categoryIds,
    bool? isExpense,
    DateTime? startDate,
    DateTime? endDate,
    int? accountId,
    bool clearKeyword = false,
    bool clearCategoryIds = false,
    bool clearIsExpense = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearAccountId = false,
  }) {
    return TransactionFilter(
      keyword: clearKeyword ? null : (keyword ?? this.keyword),
      categoryIds: clearCategoryIds ? null : (categoryIds ?? this.categoryIds),
      isExpense: clearIsExpense ? null : (isExpense ?? this.isExpense),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
    );
  }
}

/// 交易筛选状态 Provider
final transactionFilterProvider = StateProvider<TransactionFilter>((ref) {
  return const TransactionFilter();
});

/// 按日期分组的交易记录
final groupedTransactionsProvider = FutureProvider<Map<String, List<Map<String, dynamic>>>>((ref) async {
  ref.watch(transactionRefreshProvider);
  final filter = ref.watch(transactionFilterProvider);
  final db = ref.watch(appDatabaseProvider);
  // 修正结束日期为当天末尾，确保当天交易能被筛选到
  DateTime? endDate = filter.endDate;
  if (endDate != null) {
    endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
  }
  final transactions = await db.getTransactions(
    keyword: filter.keyword,
    categoryIds: filter.categoryIds,
    isExpense: filter.isExpense,
    startDate: filter.startDate,
    endDate: endDate,
    accountId: filter.accountId,
  );
  final grouped = <String, List<Map<String, dynamic>>>{};
  for (final tx in transactions) {
    final date = DateTime.parse(tx['date'] as String);
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    grouped.putIfAbsent(key, () => []).add(tx);
  }
  return grouped;
});

// ========== 统计 Provider ==========

/// 指定时段的分类汇总（支出/收入）
final categorySummaryProvider = FutureProvider.family<List<Map<String, dynamic>>, bool>((ref, isExpense) async {
  ref.watch(transactionRefreshProvider);
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return await db.getCategorySummary(start, end, isExpense: isExpense);
});

// ========== 待确认支付通知 Provider ==========

/// 待确认支付通知数量（从原生 DB 读取）
final pendingNotificationCountProvider = FutureProvider<int>((ref) async {
  ref.watch(transactionRefreshProvider);
  final service = PaymentNotificationService();
  final pending = await service.getPendingPayments();
  return pending.length;
});

// ========== 图标映射工具 ==========

/// 将数据库中存储的图标名称映射为 IconData
IconData mapIconName(String? iconName) {
  const iconMap = <String, IconData>{
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'shopping_bag': Icons.shopping_bag,
    'sports_esports': Icons.sports_esports,
    'home': Icons.home,
    'local_hospital': Icons.local_hospital,
    'school': Icons.school,
    'more_horiz': Icons.more_horiz,
    'work': Icons.work,
    'emoji_events': Icons.emoji_events,
    'trending_up': Icons.trending_up,
    'payments': Icons.payments,
    'account_balance': Icons.account_balance,
    'account_balance_wallet': Icons.account_balance_wallet,
    'chat': Icons.chat,
    'local_taxi': Icons.local_taxi,
    'movie': Icons.movie,
    'coffee': Icons.coffee,
    'receipt_long': Icons.receipt_long,
  };
  return iconMap[iconName] ?? Icons.category;
}
