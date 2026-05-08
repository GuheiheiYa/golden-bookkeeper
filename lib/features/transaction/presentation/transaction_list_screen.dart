import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../app/di/providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/utils/icon_utils.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 从数据库读取按日期分组的交易记录
    final groupedAsync = ref.watch(groupedTransactionsProvider);
    final filter = ref.watch(transactionFilterProvider);

    return Scaffold(
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
                  // 实时更新搜索关键字
                  ref.read(transactionFilterProvider.notifier).state =
                      ref.read(transactionFilterProvider).copyWith(
                        keyword: value,
                        clearKeyword: value.isEmpty,
                      );
                },
              )
            : const Text('交易明细'),
        actions: [
          // 搜索按钮
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  // 清除搜索关键字
                  ref.read(transactionFilterProvider.notifier).state =
                      ref.read(transactionFilterProvider).copyWith(clearKeyword: true);
                }
              });
            },
          ),
          // 筛选按钮
          IconButton(
            icon: Badge(
              isLabelVisible: filter.filterCount > 0,
              label: Text('${filter.filterCount}'),
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _showFilterPanel(context),
          ),
          // 添加按钮
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await context.push('/add-transaction');
              // 返回后刷新列表
              ref.read(transactionRefreshProvider.notifier).state++;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 筛选条件 Chips
          if (filter.hasFilters) _buildFilterChips(filter),
          // 交易列表
          Expanded(
            child: groupedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
              data: (groupedTransactions) {
                final entries = groupedTransactions.entries.toList();

                if (entries.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long,
                    title: '暂无交易记录',
                    subtitle: '点击右下角按钮开始记账',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final dateKey = entries[index].key;
                    final transactions = entries[index].value;

                    final dateLabel = _formatDateLabel(dateKey);

                    // 计算当日合计
                    final dailyTotal = transactions.fold<double>(0, (sum, tx) {
                      final amount = (tx['amount'] as num).toDouble();
                      final isExpense = (tx['is_expense'] as int) == 1;
                      return sum + (isExpense ? -amount : amount);
                    });

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 日期标题
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dateLabel,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              Text(
                                '${dailyTotal >= 0 ? '+' : ''}${CurrencyFormatter.format(dailyTotal)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: dailyTotal >= 0 ? AppColors.income : AppColors.expense,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 交易列表
                        AppCard(
                          padding: EdgeInsets.zero,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: transactions.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, indent: 60),
                            itemBuilder: (context, txIndex) {
                              final tx = transactions[txIndex];
                              final isExpense = (tx['is_expense'] as int) == 1;
                              final amount = (tx['amount'] as num).toDouble();
                              final categoryName = tx['category_name'] as String? ?? '未分类';
                              final categoryColor = tx['category_color'] as int? ?? 0xFF6B7280;
                              final categoryIcon = tx['category_icon'] as String?;
                              final accountName = tx['account_name'] as String? ?? '';
                              final note = tx['note'] as String? ?? '';
                              final txDate = DateTime.parse(tx['date'] as String);
                              final timeStr = '${txDate.hour.toString().padLeft(2, '0')}:${txDate.minute.toString().padLeft(2, '0')}';
                              final txId = tx['id'] as int;

                              return Dismissible(
                                key: ValueKey(txId),
                                background: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 20),
                                  color: AppColors.primary,
                                  child: const Icon(Icons.edit, color: Colors.white),
                                ),
                                secondaryBackground: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  color: AppColors.error,
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                confirmDismiss: (direction) async {
                                  if (direction == DismissDirection.startToEnd) {
                                    // 左滑编辑
                                    context.push('/transaction/edit/$txId');
                                    return false;
                                  } else if (direction == DismissDirection.endToStart) {
                                    // 右滑删除
                                    return await _showDeleteConfirmation(txId, note.isNotEmpty ? note : categoryName);
                                  }
                                  return false;
                                },
                                child: GestureDetector(
                                  onLongPress: () => _showQuickActions(tx),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Color(categoryColor).withOpacity(0.1),
                                      child: Icon(
                                        mapIconName(categoryIcon),
                                        color: Color(categoryColor),
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(note.isNotEmpty ? note : categoryName),
                                    subtitle: Text(
                                      '$categoryName · $timeStr · $accountName',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    trailing: Text(
                                      '${isExpense ? '-' : '+'}${CurrencyFormatter.format(amount)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isExpense ? AppColors.expense : AppColors.income,
                                      ),
                                    ),
                                    onTap: () => _showTransactionDetail(tx),
                                  ),
                                ),
                              );
                            },
                          ),
                        ).animate().fadeIn(
                              delay: Duration(milliseconds: 100 * index),
                              duration: 300.ms,
                            ).slideY(begin: 0.05, end: 0),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建筛选条件 Chips
  Widget _buildFilterChips(TransactionFilter filter) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 清空所有筛选
            _buildFilterTag(
              icon: Icons.clear_all,
              label: '清空',
              onTap: () {
                ref.read(transactionFilterProvider.notifier).state =
                    const TransactionFilter();
                _searchController.clear();
              },
            ),
            // 搜索关键字
            if (filter.keyword != null && filter.keyword!.isNotEmpty)
              _buildFilterTag(
                icon: Icons.search,
                label: '搜索: ${filter.keyword}',
                onDeleted: () {
                  ref.read(transactionFilterProvider.notifier).state =
                      filter.copyWith(clearKeyword: true);
                  _searchController.clear();
                },
              ),
            // 收支类型
            if (filter.isExpense != null)
              _buildFilterTag(
                icon: filter.isExpense! ? Icons.arrow_downward : Icons.arrow_upward,
                iconColor: filter.isExpense! ? AppColors.expense : AppColors.income,
                label: filter.isExpense! ? '支出' : '收入',
                onDeleted: () {
                  ref.read(transactionFilterProvider.notifier).state =
                      filter.copyWith(clearIsExpense: true);
                },
              ),
            // 日期范围
            if (filter.startDate != null || filter.endDate != null)
              _buildFilterTag(
                icon: Icons.date_range,
                label: _formatDateRange(filter.startDate, filter.endDate),
                onDeleted: () {
                  ref.read(transactionFilterProvider.notifier).state =
                      filter.copyWith(
                    clearStartDate: true,
                    clearEndDate: true,
                  );
                },
              ),
            // 分类
            if (filter.categoryIds != null && filter.categoryIds!.isNotEmpty)
              _buildFilterTag(
                icon: Icons.category,
                label: '${filter.categoryIds!.length}个分类',
                onDeleted: () {
                  ref.read(transactionFilterProvider.notifier).state =
                      filter.copyWith(clearCategoryIds: true);
                },
              ),
            // 账户
            if (filter.accountId != null)
              _buildFilterTag(
                icon: Icons.account_balance_wallet,
                label: '指定账户',
                onDeleted: () {
                  ref.read(transactionFilterProvider.notifier).state =
                      filter.copyWith(clearAccountId: true);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// 构建单个筛选标签
  Widget _buildFilterTag({
    required IconData icon,
    required String label,
    Color? iconColor,
    VoidCallback? onTap,
    VoidCallback? onDeleted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: iconColor ?? AppColors.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (onDeleted != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onDeleted,
                  child: Icon(Icons.close, size: 14, color: AppColors.primary.withOpacity(0.6)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 格式化日期范围显示
  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start != null && end != null) {
      return '${start.month}/${start.day} - ${end.month}/${end.day}';
    } else if (start != null) {
      return '从 ${start.month}/${start.day}';
    } else {
      return '至 ${end!.month}/${end.day}';
    }
  }

  /// 格式化日期标签
  String _formatDateLabel(String dateKey) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    if (diff == 2) return '前天';
    return '${date.month}月${date.day}日';
  }

  /// 删除确认对话框
  Future<bool> _showDeleteConfirmation(int txId, String label) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('删除交易'),
              content: Text('确定要删除这笔交易吗？\n$label'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final db = ref.read(appDatabaseProvider);
                    try {
                      // 删除交易记录
                      await db.deleteTransaction(txId);
                      // 通知刷新
                      ref.read(transactionRefreshProvider.notifier).state++;
                      if (context.mounted) {
                        Navigator.pop(context, true);
                        _showCenterToast('已删除');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context, false);
                        _showCenterToast('删除失败: $e', isError: true);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                  child: const Text('删除'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// 显示交易详情底部弹窗
  void _showTransactionDetail(Map<String, dynamic> tx) {
    final isExpense = (tx['is_expense'] as int) == 1;
    final amount = (tx['amount'] as num).toDouble();
    final categoryName = tx['category_name'] as String? ?? '未分类';
    final categoryColor = tx['category_color'] as int? ?? 0xFF6B7280;
    final categoryIcon = tx['category_icon'] as String?;
    final accountName = tx['account_name'] as String? ?? '未知账户';
    final txDate = DateTime.parse(tx['date'] as String);
    final note = tx['note'] as String? ?? '';
    final txId = tx['id'] as int;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 分类图标
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(categoryColor).withOpacity(0.1),
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
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${isExpense ? '-' : '+'}${CurrencyFormatter.format(amount)}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: isExpense ? AppColors.expense : AppColors.income,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                _buildDetailRow('分类', categoryName),
                _buildDetailRow('账户', accountName),
                _buildDetailRow('日期',
                    '${txDate.year}-${txDate.month.toString().padLeft(2, '0')}-${txDate.day.toString().padLeft(2, '0')} ${txDate.hour.toString().padLeft(2, '0')}:${txDate.minute.toString().padLeft(2, '0')}'),
                _buildDetailRow('备注', note.isNotEmpty ? note : '无'),
                const SizedBox(height: 24),
                // 操作按钮
                Row(
                  children: [
                    // 编辑按钮
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/transaction/edit/$txId');
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('编辑'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 删除按钮
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _showDeleteConfirmation(
                            txId,
                            note.isNotEmpty ? note : categoryName,
                          );
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('删除'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  /// 长按显示快捷操作
  void _showQuickActions(Map<String, dynamic> tx) {
    final isExpense = (tx['is_expense'] as int) == 1;
    final amount = (tx['amount'] as num).toDouble();
    final categoryName = tx['category_name'] as String? ?? '未分类';
    final note = tx['note'] as String? ?? '';
    final txId = tx['id'] as int;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 拖拽指示条
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                // 交易信息摘要
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isExpense ? AppColors.expense : AppColors.income).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isExpense ? '支出' : '收入',
                          style: TextStyle(
                            fontSize: 12,
                            color: isExpense ? AppColors.expense : AppColors.income,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          note.isNotEmpty ? note : categoryName,
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${isExpense ? '-' : '+'}${CurrencyFormatter.format(amount)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isExpense ? AppColors.expense : AppColors.income,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                // 编辑按钮
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.edit, color: AppColors.primary, size: 20),
                  ),
                  title: const Text('编辑'),
                  subtitle: const Text('修改交易信息'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/transaction/edit/$txId');
                  },
                ),
                const Divider(height: 1, indent: 56),
                // 删除按钮
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.delete, color: AppColors.error, size: 20),
                  ),
                  title: Text('删除', style: TextStyle(color: AppColors.error)),
                  subtitle: const Text('删除此交易记录'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.pop(context);
                    await _showDeleteConfirmation(
                      txId,
                      note.isNotEmpty ? note : categoryName,
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

  /// 显示筛选面板
  void _showFilterPanel(BuildContext context) {
    final currentFilter = ref.read(transactionFilterProvider);
    // 临时筛选状态
    List<int> tempCategoryIds = currentFilter.categoryIds?.toList() ?? [];
    bool? tempIsExpense = currentFilter.isExpense;
    DateTime? tempStartDate = currentFilter.startDate;
    DateTime? tempEndDate = currentFilter.endDate;
    int? tempAccountId = currentFilter.accountId;
    String? tempAccountName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题栏
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '筛选',
                            style: Theme.of(context).textTheme.titleLarge,
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
                    // 可滚动内容区域
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 收支类型筛选
                            Text(
                              '收支类型',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            SegmentedButton<int?>(
                              segments: const [
                                ButtonSegment(value: null, label: Text('全部')),
                                ButtonSegment(value: 0, label: Text('收入')),
                                ButtonSegment(value: 1, label: Text('支出')),
                              ],
                              selected: {tempIsExpense == null
                                  ? null
                                  : (tempIsExpense! ? 1 : 0)},
                              onSelectionChanged: (values) {
                                setModalState(() {
                                  final val = values.first;
                                  tempIsExpense = val == null ? null : val == 1;
                                });
                              },
                            ),
                            const SizedBox(height: 20),

                            // 日期范围筛选
                            Text(
                              '日期范围',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: tempStartDate ?? DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        setModalState(() => tempStartDate = picked);
                                      }
                                    },
                                    icon: const Icon(Icons.calendar_today, size: 18),
                                    label: Text(
                                      tempStartDate != null
                                          ? '${tempStartDate!.month}/${tempStartDate!.day}'
                                          : '开始日期',
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('-'),
                                ),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: tempEndDate ?? DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        setModalState(() => tempEndDate = picked);
                                      }
                                    },
                                    icon: const Icon(Icons.calendar_today, size: 18),
                                    label: Text(
                                      tempEndDate != null
                                          ? '${tempEndDate!.month}/${tempEndDate!.day}'
                                          : '结束日期',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (tempStartDate != null || tempEndDate != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      setModalState(() {
                                        tempStartDate = null;
                                        tempEndDate = null;
                                      });
                                    },
                                    child: const Text('清除日期'),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),

                            // 分类筛选
                            Text(
                              '分类筛选',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            _buildCategoryFilter(
                              setModalState,
                              tempCategoryIds,
                              (ids) => setModalState(() => tempCategoryIds = ids),
                            ),
                            const SizedBox(height: 20),

                            // 账户筛选
                            Text(
                              '账户筛选',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            _buildAccountFilter(
                              setModalState,
                              tempAccountId,
                              tempAccountName,
                              (id, name) => setModalState(() {
                                tempAccountId = id;
                                tempAccountName = name;
                              }),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    // 应用按钮 - 固定在底部
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(transactionFilterProvider.notifier).state =
                                TransactionFilter(
                              keyword: currentFilter.keyword,
                              categoryIds: tempCategoryIds.isNotEmpty ? tempCategoryIds : null,
                              isExpense: tempIsExpense,
                              startDate: tempStartDate,
                              endDate: tempEndDate,
                              accountId: tempAccountId,
                            );
                            Navigator.pop(context);
                          },
                          child: const Text('应用筛选'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 构建分类筛选组件
  Widget _buildCategoryFilter(
    StateSetter setModalState,
    List<int> selectedIds,
    ValueChanged<List<int>> onChanged,
  ) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(appDatabaseProvider).getCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final categories = snapshot.data!;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((cat) {
            final catId = cat['id'] as int;
            final catName = cat['name'] as String;
            final colorValue = cat['color'] as int? ?? 0xFF7C3AED;
            final isSelected = selectedIds.contains(catId);
            return FilterChip(
              avatar: Icon(
                IconUtils.fromName(cat['icon'] as String?),
                size: 16,
                color: isSelected ? Colors.white : Color(colorValue),
              ),
              label: Text(catName),
              selected: isSelected,
              selectedColor: Color(colorValue),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontSize: 13,
              ),
              onSelected: (selected) {
                final newIds = selectedIds.toList();
                if (selected) {
                  newIds.add(catId);
                } else {
                  newIds.remove(catId);
                }
                onChanged(newIds);
              },
            );
          }).toList(),
        );
      },
    );
  }

  /// 构建账户筛选组件
  Widget _buildAccountFilter(
    StateSetter setModalState,
    int? selectedId,
    String? selectedName,
    void Function(int?, String?) onChanged,
  ) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(appDatabaseProvider).getAccounts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final accounts = snapshot.data!;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // 全部账户选项
            FilterChip(
              avatar: const Icon(Icons.all_inclusive, size: 16),
              label: const Text('全部'),
              selected: selectedId == null,
              onSelected: (_) => onChanged(null, null),
            ),
            ...accounts.map((acc) {
              final accId = acc['id'] as int;
              final accName = acc['name'] as String;
              final colorValue = acc['color'] as int? ?? 0xFF7C3AED;
              final isSelected = selectedId == accId;
              return FilterChip(
                avatar: Icon(
                  IconUtils.fromName(acc['icon'] as String?),
                  size: 16,
                  color: isSelected ? Colors.white : Color(colorValue),
                ),
                label: Text(accName),
                selected: isSelected,
                selectedColor: Color(colorValue),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontSize: 13,
                ),
                onSelected: (_) => onChanged(accId, accName),
              );
            }),
          ],
        );
      },
    );
  }

  /// 显示居中提示（替代 SnackBar，不遮挡底部按钮）
  void _showCenterToast(String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return _ListToastWidget(
          message: message,
          isError: isError,
        );
      },
    );
    overlay.insert(entry);

    // 自动关闭
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }
}

/// 居中提示组件
class _ListToastWidget extends StatefulWidget {
  final String message;
  final bool isError;

  const _ListToastWidget({
    required this.message,
    required this.isError,
  });

  @override
  State<_ListToastWidget> createState() => _ListToastWidgetState();
}

class _ListToastWidgetState extends State<_ListToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black26,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.isError
                        ? Colors.red.withOpacity(0.1)
                        : const Color(0xFF7C3AED).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isError
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    color: widget.isError
                        ? Colors.red
                        : const Color(0xFF7C3AED),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.isError
                        ? Colors.red
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
