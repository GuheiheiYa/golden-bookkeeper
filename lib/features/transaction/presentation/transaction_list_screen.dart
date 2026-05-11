import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../app/di/providers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/utils/icon_utils.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  bool _isSearching = false;
  bool _isMultiSelectMode = false;
  final Set<int> _selectedIds = {};
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final show = _scrollController.offset > 300;
    if (show != _showScrollToTop) {
      setState(() => _showScrollToTop = show);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final groupedAsync = ref.watch(groupedTransactionsProvider);
    final filter = ref.watch(transactionFilterProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '搜索交易备注',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                onChanged: (value) {
                  ref.read(transactionFilterProvider.notifier).state =
                      ref.read(transactionFilterProvider).copyWith(
                            keyword: value,
                            clearKeyword: value.isEmpty,
                          );
                },
              )
            : const Text('收支明细'),
        actions: _isMultiSelectMode
            ? [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: _toggleSelectAll,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed:
                      _selectedIds.isNotEmpty ? _batchDelete : null,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isMultiSelectMode = false;
                      _selectedIds.clear();
                    });
                  },
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.checklist),
                  onPressed: () {
                    setState(() => _isMultiSelectMode = true);
                  },
                ),
                IconButton(
                  icon:
                      Icon(_isSearching ? Icons.close : Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        ref
                            .read(
                                transactionFilterProvider.notifier)
                            .state = ref
                            .read(transactionFilterProvider)
                            .copyWith(clearKeyword: true);
                      }
                    });
                  },
                ),
                IconButton(
                  icon: Badge(
                    isLabelVisible: filter.filterCount > 0,
                    label: Text('${filter.filterCount}'),
                    child: const Icon(Icons.filter_list),
                  ),
                  onPressed: () => _showFilterPanel(context),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    await context.push('/add-transaction');
                    ref.read(transactionRefreshProvider.notifier)
                        .state++;
                  },
                ),
              ],
      ),
      body: Column(
        children: [
          // 筛选条件 Chips
          if (filter.hasFilters) _buildFilterChips(filter, brightness),
          // 多选模式顶部栏
          if (_isMultiSelectMode)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 18,
                      color:
                          Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '已选择 ${_selectedIds.length} 项',
                    style: TextStyle(
                      color:
                          Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          // 交易列表
          Expanded(
            child: groupedAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('加载失败: $e')),
              data: (groupedTransactions) {
                final entries =
                    groupedTransactions.entries.toList();

                if (entries.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long,
                    title: '暂无交易记录',
                    subtitle: '点击右下角按钮开始记账',
                  );
                }

                // 计算本月汇总（仅在无筛选条件时显示）
                final monthlyIncome = groupedTransactions.values
                    .expand((txs) => txs)
                    .where((tx) => (tx['is_expense'] as int) != 1)
                    .fold<double>(
                        0,
                        (sum, tx) =>
                            sum + (tx['amount'] as num).toDouble());
                final monthlyExpense = groupedTransactions.values
                    .expand((txs) => txs)
                    .where((tx) => (tx['is_expense'] as int) == 1)
                    .fold<double>(
                        0,
                        (sum, tx) =>
                            sum + (tx['amount'] as num).toDouble());

                return Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: () async {
                        ref
                            .read(
                                transactionRefreshProvider.notifier)
                            .state++;
                        await Future.delayed(
                            const Duration(milliseconds: 500));
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(
                            16, 8, 16, 100),
                        itemCount: entries.length + 1,
                        itemBuilder: (context, index) {
                          // 第一项：月度汇总卡片
                          if (index == 0) {
                            return _buildMonthlySummary(
                              monthlyIncome,
                              monthlyExpense,
                              isDark,
                            );
                          }

                          final entryIndex = index - 1;
                          final dateKey =
                              entries[entryIndex].key;
                          final transactions =
                              entries[entryIndex].value;
                          final dateLabel =
                              _formatDateLabel(dateKey);

                          // 计算当日合计
                          final dailyTotal =
                              transactions.fold<double>(
                                  0, (sum, tx) {
                            final amount =
                                (tx['amount'] as num).toDouble();
                            final isExp =
                                (tx['is_expense'] as int) == 1;
                            return sum +
                                (isExp ? -amount : amount);
                          });

                          return _buildDateGroup(
                            dateLabel: dateLabel,
                            dailyTotal: dailyTotal,
                            transactions: transactions,
                            isDark: isDark,
                            brightness: brightness,
                            animationDelay:
                                Duration(milliseconds: 80 * entryIndex),
                          );
                        },
                      ),
                    ),
                    // 回到顶部按钮
                    if (_showScrollToTop)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton.small(
                          heroTag: 'scrollToTop',
                          backgroundColor: isDark
                              ? AppColors.darkSurface
                              : Colors.white,
                          onPressed: () {
                            _scrollController.animateTo(
                              0,
                              duration: const Duration(
                                  milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          },
                          child: Icon(
                            Icons.keyboard_arrow_up,
                            color: AppColors.primaryOf(brightness),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 月度汇总卡片
  // ═══════════════════════════════════════════

  Widget _buildMonthlySummary(
      double income, double expense, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // 本月支出
          Expanded(
            child: _buildSummaryCard(
              label: '本月支出',
              amount: CurrencyFormatter.format(expense),
              iconColor: AppColors.expense,
              icon: Icons.arrow_downward_rounded,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          // 本月收入
          Expanded(
            child: _buildSummaryCard(
              label: '本月收入',
              amount: CurrencyFormatter.format(income),
              iconColor: AppColors.income,
              icon: Icons.arrow_upward_rounded,
              isDark: isDark,
              isIncome: true,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildSummaryCard({
    required String label,
    required String amount,
    required Color iconColor,
    required IconData icon,
    required bool isDark,
    bool isIncome = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface
            : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.15)
                : AppColors.lightPrimary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.lightOnSurfaceVariant,
                ),
              ),
              Icon(icon, color: iconColor, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            amount,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isIncome
                  ? AppColors.income
                  : (isDark
                      ? AppColors.darkOnBackground
                      : AppColors.lightOnBackground),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 日期分组卡片
  // ═══════════════════════════════════════════

  Widget _buildDateGroup({
    required String dateLabel,
    required double dailyTotal,
    required List<Map<String, dynamic>> transactions,
    required bool isDark,
    required Brightness brightness,
    required Duration animationDelay,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期标题行
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 4, vertical: 6),
            child: Row(
              children: [
                // 彩色圆点
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOf(brightness),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkOnBackground
                        : AppColors.lightOnBackground,
                  ),
                ),
                const Spacer(),
                Text(
                  '${dailyTotal >= 0 ? '+' : ''}${CurrencyFormatter.format(dailyTotal)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: dailyTotal >= 0
                        ? AppColors.income
                        : AppColors.expense,
                  ),
                ),
              ],
            ),
          ),
          // 交易列表卡片
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurface
                  : AppColors.lightCard,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.12)
                      : AppColors.lightPrimary
                          .withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: List.generate(transactions.length,
                  (txIndex) {
                final tx = transactions[txIndex];
                final isExpense =
                    (tx['is_expense'] as int) == 1;
                final amount =
                    (tx['amount'] as num).toDouble();
                final categoryName =
                    tx['category_name'] as String? ?? '未分类';
                final categoryColor =
                    tx['category_color'] as int? ??
                        0xFF6B7280;
                final categoryIcon =
                    tx['category_icon'] as String?;
                final accountName =
                    tx['account_name'] as String? ?? '';
                final note = tx['note'] as String? ?? '';
                final goods =
                    tx['goods'] as String? ?? '';
                final txDate =
                    DateTime.parse(tx['date'] as String);
                final timeStr =
                    '${txDate.hour.toString().padLeft(2, '0')}:${txDate.minute.toString().padLeft(2, '0')}';
                final txId = tx['id'] as int;
                final displayName = goods.isNotEmpty
                    ? goods
                    : (note.isNotEmpty
                        ? note
                        : categoryName);

                final txWidget = _buildTransactionRow(
                  txId: txId,
                  displayName: displayName,
                  categoryName: categoryName,
                  categoryColor: categoryColor,
                  categoryIcon: categoryIcon,
                  accountName: accountName,
                  timeStr: timeStr,
                  amount: amount,
                  isExpense: isExpense,
                  isDark: isDark,
                  brightness: brightness,
                  tx: tx,
                );

                if (_isMultiSelectMode) {
                  return txWidget;
                }

                return Dismissible(
                  key: ValueKey(txId),
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          AppColors.primaryOf(brightness),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit,
                        color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    alignment: Alignment.centerRight,
                    padding:
                        const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete,
                        color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction ==
                        DismissDirection.startToEnd) {
                      context.push(
                          '/transaction/edit/$txId');
                      return false;
                    } else if (direction ==
                        DismissDirection.endToStart) {
                      return await _showDeleteConfirmation(
                          txId, displayName);
                    }
                    return false;
                  },
                  child: txWidget,
                );
              }),
            ),
          ).animate().fadeIn(
              delay: animationDelay, duration: 300.ms),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 交易行
  // ═══════════════════════════════════════════

  Widget _buildTransactionRow({
    required int txId,
    required String displayName,
    required String categoryName,
    required int categoryColor,
    required String? categoryIcon,
    required String accountName,
    required String timeStr,
    required double amount,
    required bool isExpense,
    required bool isDark,
    required Brightness brightness,
    required Map<String, dynamic> tx,
  }) {
    final isLast = _isMultiSelectMode;

    return GestureDetector(
      onLongPress: _isMultiSelectMode
          ? null
          : () => _showQuickActions(tx),
      onTap: _isMultiSelectMode
          ? () {
              setState(() {
                if (_selectedIds.contains(txId)) {
                  _selectedIds.remove(txId);
                } else {
                  _selectedIds.add(txId);
                }
              });
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 多选复选框 or 分类图标
            if (_isMultiSelectMode)
              Checkbox(
                value: _selectedIds.contains(txId),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedIds.add(txId);
                    } else {
                      _selectedIds.remove(txId);
                    }
                  });
                },
                activeColor: AppColors.primaryOf(brightness),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(categoryColor)
                      .withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  mapIconName(categoryIcon),
                  color: Color(categoryColor),
                  size: 20,
                ),
              ),
            const SizedBox(width: 12),
            // 名称 + 时间·账户
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkOnBackground
                          : AppColors.lightOnBackground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$categoryName · $timeStr · $accountName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 金额
            Text(
              '${isExpense ? '-' : '+'}${CurrencyFormatter.format(amount)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isExpense
                    ? AppColors.expense
                    : AppColors.income,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 筛选 Chips
  // ═══════════════════════════════════════════

  Widget _buildFilterChips(
      TransactionFilter filter, Brightness brightness) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterTag(
              icon: Icons.clear_all,
              label: '清空',
              brightness: brightness,
              onTap: () {
                ref
                    .read(transactionFilterProvider.notifier)
                    .state = const TransactionFilter();
                _searchController.clear();
              },
            ),
            if (filter.keyword != null &&
                filter.keyword!.isNotEmpty)
              _buildFilterTag(
                icon: Icons.search,
                label: '搜索: ${filter.keyword}',
                brightness: brightness,
                onDeleted: () {
                  ref
                      .read(
                          transactionFilterProvider.notifier)
                      .state = filter
                      .copyWith(clearKeyword: true);
                  _searchController.clear();
                },
              ),
            if (filter.isExpense != null)
              _buildFilterTag(
                icon: filter.isExpense!
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                iconColor: filter.isExpense!
                    ? AppColors.expense
                    : AppColors.income,
                label:
                    filter.isExpense! ? '支出' : '收入',
                brightness: brightness,
                onDeleted: () {
                  ref
                      .read(
                          transactionFilterProvider.notifier)
                      .state = filter
                      .copyWith(clearIsExpense: true);
                },
              ),
            if (filter.startDate != null ||
                filter.endDate != null)
              _buildFilterTag(
                icon: Icons.date_range,
                label: _formatDateRange(
                    filter.startDate, filter.endDate),
                brightness: brightness,
                onDeleted: () {
                  ref
                      .read(
                          transactionFilterProvider.notifier)
                      .state = filter.copyWith(
                    clearStartDate: true,
                    clearEndDate: true,
                  );
                },
              ),
            if (filter.categoryIds != null &&
                filter.categoryIds!.isNotEmpty)
              _buildFilterTag(
                icon: Icons.category,
                label:
                    '${filter.categoryIds!.length}个分类',
                brightness: brightness,
                onDeleted: () {
                  ref
                      .read(
                          transactionFilterProvider.notifier)
                      .state = filter
                      .copyWith(clearCategoryIds: true);
                },
              ),
            if (filter.accountId != null)
              _buildFilterTag(
                icon: Icons.account_balance_wallet,
                label: '指定账户',
                brightness: brightness,
                onDeleted: () {
                  ref
                      .read(
                          transactionFilterProvider.notifier)
                      .state = filter
                      .copyWith(clearAccountId: true);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTag({
    required IconData icon,
    required String label,
    required Brightness brightness,
    Color? iconColor,
    VoidCallback? onTap,
    VoidCallback? onDeleted,
  }) {
    final primaryColor = AppColors.primaryOf(brightness);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 14,
                  color: iconColor ?? primaryColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (onDeleted != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onDeleted,
                  child: Icon(Icons.close,
                      size: 14,
                      color:
                          primaryColor.withOpacity(0.6)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 工具方法
  // ═══════════════════════════════════════════

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start != null && end != null) {
      return '${start.month}/${start.day} - ${end.month}/${end.day}';
    } else if (start != null) {
      return '从 ${start.month}/${start.day}';
    } else {
      return '至 ${end!.month}/${end.day}';
    }
  }

  String _formatDateLabel(String dateKey) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target =
        DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    if (diff == 2) return '前天';
    return '${date.month}月${date.day}日';
  }

  // ═══════════════════════════════════════════
  // 删除确认
  // ═══════════════════════════════════════════

  Future<bool> _showDeleteConfirmation(
      int txId, String label) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('删除交易'),
              content:
                  Text('确定要删除这笔交易吗？\n$label'),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final db =
                        ref.read(appDatabaseProvider);
                    try {
                      await db.deleteTransaction(txId);
                      ref
                          .read(transactionRefreshProvider
                              .notifier)
                          .state++;
                      if (context.mounted) {
                        Navigator.pop(context, true);
                        _showCenterToast('已删除');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context, false);
                        _showCenterToast('删除失败: $e',
                            isError: true);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error),
                  child: const Text('删除'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // ═══════════════════════════════════════════
  // 交易详情底部弹窗
  // ═══════════════════════════════════════════

  void _showTransactionDetail(
      Map<String, dynamic> tx) {
    final isExpense = (tx['is_expense'] as int) == 1;
    final amount = (tx['amount'] as num).toDouble();
    final categoryName =
        tx['category_name'] as String? ?? '未分类';
    final categoryColor =
        tx['category_color'] as int? ?? 0xFF6B7280;
    final categoryIcon =
        tx['category_icon'] as String?;
    final accountName =
        tx['account_name'] as String? ?? '未知账户';
    final txDate =
        DateTime.parse(tx['date'] as String);
    final note = tx['note'] as String? ?? '';
    final goods = tx['goods'] as String? ?? '';
    final txId = tx['id'] as int;
    final displayName = goods.isNotEmpty
        ? goods
        : (note.isNotEmpty ? note : categoryName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(categoryColor)
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    mapIconName(categoryIcon),
                    color: Color(categoryColor),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isExpense ? '支出' : '收入',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${isExpense ? '-' : '+'}${CurrencyFormatter.format(amount)}',
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(
                        color: isExpense
                            ? AppColors.expense
                            : AppColors.income,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                _buildDetailRow('分类', categoryName),
                _buildDetailRow('账户', accountName),
                _buildDetailRow(
                    '日期',
                    '${txDate.year}-${txDate.month.toString().padLeft(2, '0')}-${txDate.day.toString().padLeft(2, '0')} ${txDate.hour.toString().padLeft(2, '0')}:${txDate.minute.toString().padLeft(2, '0')}'),
                if (goods.isNotEmpty)
                  _buildDetailRow('商品', goods),
                _buildDetailRow(
                    '备注', note.isNotEmpty ? note : '无'),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push(
                              '/transaction/edit/$txId');
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('编辑'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _showDeleteConfirmation(
                            txId,
                            displayName,
                          );
                        },
                        icon:
                            const Icon(Icons.delete),
                        label: const Text('删除'),
                        style: ElevatedButton
                            .styleFrom(
                          backgroundColor:
                              AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
          ),
          Flexible(
            child: Text(
              value,
              style:
                  Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 长按快捷操作
  // ═══════════════════════════════════════════

  void _showQuickActions(Map<String, dynamic> tx) {
    final brightness = Theme.of(context).brightness;
    final isExpense = (tx['is_expense'] as int) == 1;
    final amount = (tx['amount'] as num).toDouble();
    final categoryName =
        tx['category_name'] as String? ?? '未分类';
    final note = tx['note'] as String? ?? '';
    final goods = tx['goods'] as String? ?? '';
    final txId = tx['id'] as int;
    final displayName = goods.isNotEmpty
        ? goods
        : (note.isNotEmpty ? note : categoryName);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.only(bottom: 20, top: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                    borderRadius:
                        BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6),
                        decoration: BoxDecoration(
                          color: (isExpense
                                  ? AppColors.expense
                                  : AppColors.income)
                              .withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          isExpense ? '支出' : '收入',
                          style: TextStyle(
                            fontSize: 12,
                            color: isExpense
                                ? AppColors.expense
                                : AppColors.income,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          displayName,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium,
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${isExpense ? '-' : '+'}${CurrencyFormatter.format(amount)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isExpense
                              ? AppColors.expense
                              : AppColors.income,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOf(
                              brightness)
                          .withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.edit,
                        color: AppColors.primaryOf(
                            brightness),
                        size: 20),
                  ),
                  title: const Text('编辑'),
                  subtitle:
                      const Text('修改交易信息'),
                  trailing:
                      const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(
                        '/transaction/edit/$txId');
                  },
                ),
                const Divider(
                    height: 1, indent: 56),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error
                          .withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.delete,
                        color: AppColors.error,
                        size: 20),
                  ),
                  title: Text('删除',
                      style: TextStyle(
                          color: AppColors.error)),
                  subtitle:
                      const Text('删除此交易记录'),
                  trailing:
                      const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.pop(context);
                    await _showDeleteConfirmation(
                      txId,
                      displayName,
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  // 筛选面板
  // ═══════════════════════════════════════════

  void _showFilterPanel(BuildContext context) {
    final currentFilter =
        ref.read(transactionFilterProvider);
    List<int> tempCategoryIds =
        currentFilter.categoryIds?.toList() ?? [];
    bool? tempIsExpense = currentFilter.isExpense;
    DateTime? tempStartDate = currentFilter.startDate;
    DateTime? tempEndDate = currentFilter.endDate;
    int? tempAccountId = currentFilter.accountId;
    String? tempAccountName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.of(context).size.height *
                          0.75,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          20, 20, 20, 0),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '筛选',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge,
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempCategoryIds = [];
                                tempIsExpense = null;
                                tempStartDate = null;
                                tempEndDate = null;
                                tempAccountId = null;
                                tempAccountName = null;
                              });
                            },
                            child: const Text('重置'),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                            20, 16, 20, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              '收支类型',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall,
                            ),
                            const SizedBox(height: 8),
                            SegmentedButton<int?>(
                              segments: const [
                                ButtonSegment(
                                    value: null,
                                    label:
                                        Text('全部')),
                                ButtonSegment(
                                    value: 0,
                                    label:
                                        Text('收入')),
                                ButtonSegment(
                                    value: 1,
                                    label:
                                        Text('支出')),
                              ],
                              selected: {
                                tempIsExpense == null
                                    ? null
                                    : (tempIsExpense!
                                        ? 1
                                        : 0)
                              },
                              onSelectionChanged:
                                  (values) {
                                setModalState(() {
                                  final val =
                                      values.first;
                                  tempIsExpense =
                                      val == null
                                          ? null
                                          : val == 1;
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '日期范围',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child:
                                      OutlinedButton.icon(
                                    onPressed:
                                        () async {
                                      final picked =
                                          await showDatePicker(
                                        context:
                                            context,
                                        initialDate:
                                            tempStartDate ??
                                                DateTime
                                                    .now(),
                                        firstDate:
                                            DateTime(
                                                2020),
                                        lastDate:
                                            DateTime(
                                                2030),
                                      );
                                      if (picked !=
                                          null) {
                                        setModalState(() =>
                                            tempStartDate =
                                                picked);
                                      }
                                    },
                                    icon: const Icon(
                                        Icons
                                            .calendar_today,
                                        size: 18),
                                    label: Text(
                                      tempStartDate !=
                                              null
                                          ? '${tempStartDate!.month}/${tempStartDate!.day}'
                                          : '开始日期',
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets
                                      .symmetric(
                                          horizontal:
                                              8),
                                  child: Text('-'),
                                ),
                                Expanded(
                                  child:
                                      OutlinedButton.icon(
                                    onPressed:
                                        () async {
                                      final picked =
                                          await showDatePicker(
                                        context:
                                            context,
                                        initialDate:
                                            tempEndDate ??
                                                DateTime
                                                    .now(),
                                        firstDate:
                                            DateTime(
                                                2020),
                                        lastDate:
                                            DateTime(
                                                2030),
                                      );
                                      if (picked !=
                                          null) {
                                        setModalState(() =>
                                            tempEndDate =
                                                picked);
                                      }
                                    },
                                    icon: const Icon(
                                        Icons
                                            .calendar_today,
                                        size: 18),
                                    label: Text(
                                      tempEndDate !=
                                              null
                                          ? '${tempEndDate!.month}/${tempEndDate!.day}'
                                          : '结束日期',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (tempStartDate !=
                                    null ||
                                tempEndDate != null)
                              Padding(
                                padding:
                                    const EdgeInsets
                                        .only(
                                            top: 8),
                                child: Align(
                                  alignment: Alignment
                                      .centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      setModalState(
                                          () {
                                        tempStartDate =
                                            null;
                                        tempEndDate =
                                            null;
                                      });
                                    },
                                    child: const Text(
                                        '清除日期'),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            Text(
                              '分类筛选',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall,
                            ),
                            const SizedBox(height: 8),
                            _buildCategoryFilter(
                              setModalState,
                              tempCategoryIds,
                              (ids) => setModalState(
                                  () => tempCategoryIds =
                                      ids),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '账户筛选',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall,
                            ),
                            const SizedBox(height: 8),
                            _buildAccountFilter(
                              setModalState,
                              tempAccountId,
                              tempAccountName,
                              (id, name) =>
                                  setModalState(() {
                                tempAccountId = id;
                   