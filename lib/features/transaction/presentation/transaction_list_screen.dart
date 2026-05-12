import 'dart:ui';
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

  // ═══════════════════════════════════════════
  // 主构建
  // ═══════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final groupedAsync = ref.watch(groupedTransactionsProvider);
    final filter = ref.watch(transactionFilterProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ═══ 全屏背景渐变 ═══
          _buildPageBackground(isDark),
          // ═══ 主内容 ═══
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ═══ 深紫渐变头部 ═══
                _buildHeader(context, isDark, filter),
                // ═══ 摘要卡片（向上偏移覆盖头部底部，搜索时隐藏） ═══
                if (!filter.hasFilters)
                Transform.translate(
                  offset: const Offset(0, -56),
                  child: groupedAsync.when(
                    loading: () => const SizedBox(height: 110),
                    error: (_, __) => const SizedBox(height: 110),
                    data: (groupedTransactions) {
                      final monthlyIncome = groupedTransactions.values
                          .expand((txs) => txs)
                          .where((tx) => (tx['is_expense'] as int) != 1)
                          .fold<double>(0, (sum, tx) => sum + (tx['amount'] as num).toDouble());
                      final monthlyExpense = groupedTransactions.values
                          .expand((txs) => txs)
                          .where((tx) => (tx['is_expense'] as int) == 1)
                          .fold<double>(0, (sum, tx) => sum + (tx['amount'] as num).toDouble());
                      return _buildSummaryCards(monthlyExpense, monthlyIncome);
                    },
                  ),
                ),
                // ═══ 筛选 Chips / 多选栏 ═══
                if (filter.hasFilters) _buildFilterChips(filter, brightness),
                if (_isMultiSelectMode) _buildMultiSelectBar(isDark),
                // ═══ 交易列表 ═══
                Expanded(
                  child: Transform.translate(
                    offset: Offset(0, filter.hasFilters || _isMultiSelectMode ? -8 : -16),
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
                        return _buildTransactionList(entries, isDark, brightness);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 页面背景（淡薰衣白→淡紫丁香渐变）
  // ═══════════════════════════════════════════

  Widget _buildPageBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [AppColors.bgGradientTopDark, AppColors.bgGradientMidDark, AppColors.bgGradientBottomDark]
              : const [AppColors.bgGradientTop, AppColors.bgGradientMid, AppColors.bgGradientBottom],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 深紫渐变头部（底部圆角48px）
  // ═══════════════════════════════════════════

  Widget _buildHeader(BuildContext context, bool isDark, TransactionFilter filter) {
    final now = DateTime.now();
    final monthStr = _getMonthStr(now.month);

    return Container(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(0.0, 0.6),
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [AppColors.darkBackground, AppColors.darkSurface]
              : const [AppColors.headerGradientStart, AppColors.headerGradientEnd],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(48),
          bottomRight: Radius.circular(48),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.headerGradientStart).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _isSearching
          ? _buildSearchHeader(isDark)
          : _buildNormalHeader(isDark, monthStr, filter),
    );
  }

  Widget _buildNormalHeader(bool isDark, String monthStr, TransactionFilter filter) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ═══ 左侧：月份 + 标题 ═══
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                monthStr,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3.2,
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant.withOpacity(0.6)
                      : AppColors.indigo200_60,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '收支明细',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // ═══ 右侧：4个毛玻璃功能按钮（保留原功能） ═══
        Row(
          children: [
            // 多选模式切换
            _buildGlassIconButton(
              icon: Icons.checklist,
              isDark: isDark,
              onTap: () => setState(() => _isMultiSelectMode = true),
            ),
            const SizedBox(width: 10),
            // 搜索
            _buildGlassIconButton(
              icon: _isSearching ? Icons.close : Icons.search,
              isDark: isDark,
              onTap: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    ref.read(transactionFilterProvider.notifier).state =
                        ref.read(transactionFilterProvider).copyWith(clearKeyword: true);
                  }
                });
              },
            ),
            const SizedBox(width: 10),
            // 筛选（带角标）
            _buildGlassIconButton(
              icon: Icons.filter_list,
              isDark: isDark,
              badgeCount: filter.filterCount,
              onTap: () => _showFilterPanel(context),
            ),
            const SizedBox(width: 10),
            // 添加
            _buildGlassIconButton(
              icon: Icons.add,
              isDark: isDark,
              onTap: () async {
                await context.push('/add-transaction');
                ref.read(transactionRefreshProvider.notifier).state++;
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchHeader(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.12)
                  : Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: '搜索备注、商品名、分类...',
                hintStyle: const TextStyle(
                  color: Color(0xFF9B9BB0),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 12, right: 4),
                  child: Icon(
                    Icons.search,
                    color: Color(0xFF9B9BB0),
                    size: 20,
                  ),
                ),
                contentPadding: const EdgeInsets.only(bottom: 10),
              ),
              onChanged: (value) {
                ref.read(transactionFilterProvider.notifier).state =
                    ref.read(transactionFilterProvider).copyWith(
                          keyword: value,
                          clearKeyword: value.isEmpty,
                        );
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildGlassIconButton(
          icon: Icons.close,
          isDark: isDark,
          onTap: () {
            setState(() {
              _isSearching = false;
              _searchController.clear();
              ref.read(transactionFilterProvider.notifier).state =
                  ref.read(transactionFilterProvider).copyWith(clearKeyword: true);
            });
          },
        ),
      ],
    );
  }

  /// 毛玻璃圆形按钮（深色背景上，白色10%透明 + blur）
  Widget _buildGlassIconButton({
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Center(
              child: badgeCount > 0
                  ? Badge(
                      isLabelVisible: true,
                      label: Text('$badgeCount', style: const TextStyle(fontSize: 9)),
                      child: Icon(icon, color: Colors.white, size: 20),
                    )
                  : Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 摘要卡片（毛玻璃，覆盖头部底边）
  // ═══════════════════════════════════════════

  Widget _buildSummaryCards(double expense, double income) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildGlassSummaryCard(
              label: '支出',
              amount: CurrencyFormatter.format(expense),
              amountColor: AppColors.indigo950,
              iconBg: const Color(0xFFFFF1F2),
              iconColor: const Color(0xFFF43F5E),
              icon: Icons.arrow_downward,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildGlassSummaryCard(
              label: '收入',
              amount: CurrencyFormatter.format(income),
              amountColor: AppColors.amber500,
              iconBg: const Color(0xFFECFDF5),
              iconColor: const Color(0xFF10B981),
              icon: Icons.arrow_upward,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
    );
  }

  Widget _buildGlassSummaryCard({
    required String label,
    required String amount,
    required Color amountColor,
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
  }) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF312E81).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.55),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 标签行
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 1.6,
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: iconColor, size: 12),
                    ),
                  ],
                ),
                // 金额
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: amountColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  // ═══════════════════════════════════════════
  // 交易列表
  // ═══════════════════════════════════════════

  Widget _buildTransactionList(
    List<MapEntry<String, List<Map<String, dynamic>>>> entries,
    bool isDark,
    Brightness brightness,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.read(transactionRefreshProvider.notifier).state++;
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
        itemCount: entries.length,
        itemBuilder: (context, groupIndex) {
          final entry = entries[groupIndex];
          final dateKey = entry.key;
          final transactions = entry.value;
          final dateLabel = _formatDateLabel(dateKey);

          final dailyTotal = transactions.fold<double>(0, (sum, tx) {
            final amount = (tx['amount'] as num).toDouble();
            final isExp = (tx['is_expense'] as int) == 1;
            return sum + (isExp ? -amount : amount);
          });

          return _buildDateGroup(
            dateLabel: dateLabel,
            dailyTotal: dailyTotal,
            transactions: transactions,
            isDark: isDark,
            brightness: brightness,
            animationDelay: Duration(milliseconds: 80 * groupIndex),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 日期分组（标题在外 + 独立毛玻璃卡片）
  // ═══════════════════════════════════════════

  Widget _buildDateGroup({
    required String dateLabel,
    required double dailyTotal,
    required List<Map<String, dynamic>> transactions,
    required bool isDark,
    required Brightness brightness,
    required Duration animationDelay,
  }) {
    final isToday = dateLabel == '今天';
    final labelColor = isToday
        ? (isDark ? AppColors.darkOnBackground : AppColors.indigo900_80)
        : (isDark ? AppColors.darkOnSurfaceVariant : const Color(0xFF94A3B8));
    final dotColor = isToday
        ? const Color(0xFF4F46E5)
        : const Color(0x8094A3B8);
    final dotShadow = isToday
        ? [BoxShadow(color: const Color(0xFFC7D2FE).withOpacity(0.5), blurRadius: 2, offset: const Offset(0, 1))]
        : <BoxShadow>[];
    final totalColor = dailyTotal >= 0
        ? const Color(0xB310B981)
        : const Color(0xB3F43F5E);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══ 日期标题行 ═══
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: dotShadow,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateLabel,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: labelColor),
                ),
                const Spacer(),
                Text(
                  '${dailyTotal >= 0 ? '+' : ''}${CurrencyFormatter.format(dailyTotal)}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: totalColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ═══ 独立毛玻璃交易卡片 ═══
          ...List.generate(transactions.length, (txIndex) {
            final tx = transactions[txIndex];
            final isExpense = (tx['is_expense'] as int) == 1;
            final amount = (tx['amount'] as num).toDouble();
            final categoryName = tx['category_name'] as String? ?? '未分类';
            final categoryColor = tx['category_color'] as int? ?? 0xFF6B7280;
            final categoryIcon = tx['category_icon'] as String?;
            final accountName = tx['account_name'] as String? ?? '';
            final note = tx['note'] as String? ?? '';
            final goods = tx['goods'] as String? ?? '';
            final txDate = DateTime.parse(tx['date'] as String);
            final timeStr = '${txDate.hour.toString().padLeft(2, '0')}:${txDate.minute.toString().padLeft(2, '0')}';
            final txId = tx['id'] as int;
            final displayName = goods.isNotEmpty
                ? goods
                : (note.isNotEmpty ? note : categoryName);

            final txWidget = _buildGlassTransactionCard(
              txId: txId,
              displayName: displayName,
              categoryName: categoryName,
              accountName: accountName,
              timeStr: timeStr,
              amount: amount,
              isExpense: isExpense,
              categoryColor: categoryColor,
              categoryIcon: categoryIcon,
              isDark: isDark,
              brightness: brightness,
              tx: tx,
            );

            if (_isMultiSelectMode) {
              return Padding(padding: const EdgeInsets.only(bottom: 12), child: txWidget);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Dismissible(
                key: ValueKey(txId),
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 24),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOf(brightness),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    context.push('/transaction/edit/$txId');
                    return false;
                  } else if (direction == DismissDirection.endToStart) {
                    return await _showDeleteConfirmation(txId, displayName);
                  }
                  return false;
                },
                child: txWidget,
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: animationDelay, duration: 300.ms);
  }

  // ═══════════════════════════════════════════
  // 单条毛玻璃交易卡片
  // ═══════════════════════════════════════════

  Widget _buildGlassTransactionCard({
    required int txId,
    required String displayName,
    required String categoryName,
    required String accountName,
    required String timeStr,
    required double amount,
    required bool isExpense,
    required int categoryColor,
    required String? categoryIcon,
    required bool isDark,
    required Brightness brightness,
    required Map<String, dynamic> tx,
  }) {
    final catColor = Color(categoryColor);

    return GestureDetector(
      onLongPress: _isMultiSelectMode ? null : () => _showQuickActions(tx),
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
          : () => _showTransactionDetail(tx),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.72),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.white.withOpacity(0.6),
                ),
              ),
              child: Row(
                children: [
                  // ═══ 图标（48x48圆角方形，20%透明度彩色背景） ═══
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
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(mapIconName(categoryIcon), color: catColor, size: 24),
                    ),
                  const SizedBox(width: 16),
                  // ═══ 文字 ═══
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkOnBackground : AppColors.indigo950,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$categoryName · $timeStr · $accountName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkOnSurfaceVariant.withOpacity(0.8)
                                : AppColors.indigo400_80,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ═══ 金额 ═══
                  Text(
                    '${isExpense ? '-' : '+'}${CurrencyFormatter.format(amount)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isExpense
                          ? (isDark ? AppColors.darkOnBackground : AppColors.indigo950)
                          : (isDark ? AppColors.success : AppColors.emerald600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 多选模式顶部栏
  // ═══════════════════════════════════════════

  Widget _buildMultiSelectBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryOf(isDark ? Brightness.dark : Brightness.light).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline,
              size: 18,
              color: AppColors.primaryOf(isDark ? Brightness.dark : Brightness.light)),
          const SizedBox(width: 8),
          Text(
            '已选择 ${_selectedIds.length} 项',
            style: TextStyle(
              color: AppColors.primaryOf(isDark ? Brightness.dark : Brightness.light),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.select_all, size: 20),
            onPressed: _toggleSelectAll,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: _selectedIds.isNotEmpty ? _batchDelete : null,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              setState(() {
                _isMultiSelectMode = false;
                _selectedIds.clear();
              });
            },
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 筛选 Chips
  // ═══════════════════════════════════════════

  Widget _buildFilterChips(TransactionFilter filter, Brightness brightness) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterTag(icon: Icons.clear_all, label: '清空', brightness: brightness, onTap: () {
              ref.read(transactionFilterProvider.notifier).state = const TransactionFilter();
              _searchController.clear();
            }),
            if (filter.keyword != null && filter.keyword!.isNotEmpty)
              _buildFilterTag(
                icon: Icons.search,
                label: '搜索: ${filter.keyword}',
                brightness: brightness,
                onDeleted: () {
                  ref.read(transactionFilterProvider.notifier).state = filter.copyWith(clearKeyword: true);
                  _searchController.clear();
                },
              ),
            if (filter.isExpense != null)
              _buildFilterTag(
                icon: filter.isExpense! ? Icons.arrow_downward : Icons.arrow_upward,
                iconColor: filter.isExpense! ? AppColors.expense : AppColors.income,
                label: filter.isExpense! ? '支出' : '收入',
                brightness: brightness,
                onDeleted: () {
                  ref.read(transactionFilterProvider.notifier).state = filter.copyWith(clearIsExpense: true);
                },
              ),
            if (filter.startDate != null || filter.endDate != null)
              _buildFilterTag(
                icon: Icons.date_range,
                label: _formatDateRange(filter.startDate, filter.endDate),
                brightness: brightness,
                onDeleted: () {
                  ref.read(transactionFilterProvider.notifier).state =
                      filter.copyWith(clearStartDate: true, clearEndDate: true);
                },
              ),
            if (filter.categoryIds != null && filter.categoryIds!.isNotEmpty)
              _buildFilterTag(
                icon: Icons.category,
                label: '${filter.categoryIds!.length}个分类',
                brightness: brightness,
                onDeleted: () {
                  ref.read(transactionFilterProvider.notifier).state = filter.copyWith(clearCategoryIds: true);
                },
              ),
            if (filter.accountId != null)
              _buildFilterTag(
                icon: Icons.account_balance_wallet,
                label: '指定账户',
                brightness: brightness,
                onDeleted: () {
                  ref.read(transactionFilterProvider.notifier).state = filter.copyWith(clearAccountId: true);
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: iconColor ?? primaryColor),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w500)),
              if (onDeleted != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onDeleted,
                  child: Icon(Icons.close, size: 14, color: primaryColor.withOpacity(0.6)),
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

  String _getMonthStr(int month) {
    const months = ['', 'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'];
    final now = DateTime.now();
    return '${months[month]} ${now.year}';
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start != null && end != null) return '${start.month}/${start.day} - ${end.month}/${end.day}';
    if (start != null) return '从 ${start.month}/${start.day}';
    return '至 ${end!.month}/${end.day}';
  }

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

  // ═══════════════════════════════════════════
  // 删除确认
  // ═══════════════════════════════════════════

  Future<bool> _showDeleteConfirmation(int txId, String label) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('删除交易'),
            content: Text('确定要删除这笔交易吗？\n$label'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
              ElevatedButton(
                onPressed: () async {
                  final db = ref.read(appDatabaseProvider);
                  try {
                    await db.deleteTransaction(txId);
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
          ),
        ) ??
        false;
  }

  // ═══════════════════════════════════════════
  // 交易详情底部弹窗
  // ═══════════════════════════════════════════

  void _showTransactionDetail(Map<String, dynamic> tx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpense = (tx['is_expense'] as int) == 1;
    final amount = (tx['amount'] as num).toDouble();
    final categoryName = tx['category_name'] as String? ?? '未分类';
    final categoryColor = tx['category_color'] as int? ?? 0xFF6B7280;
    final categoryIcon = tx['category_icon'] as String?;
    final accountName = tx['account_name'] as String? ?? '未知账户';
    final txDate = DateTime.parse(tx['date'] as String);
    final note = tx['note'] as String? ?? '';
    final goods = tx['goods'] as String? ?? '';
    final txId = tx['id'] as int;
    final displayName = goods.isNotEmpty ? goods : (note.isNotEmpty ? note : categoryName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Color(categoryColor).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(mapIconName(categoryIcon), color: Color(categoryColor), size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  isExpense ? '支出' : '收入',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${isExpense ? '-' : '+'}${CurrencyFormatter.format(amount)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: isExpense ? AppColors.indigo950 : AppColors.emerald600,
                  ),
                ),
                const SizedBox(height: 32),
                _buildDetailRow('分类', categoryName),
                _buildDetailRow('账户', accountName),
                _buildDetailRow('日期', '${txDate.year}-${txDate.month.toString().padLeft(2, '0')}-${txDate.day.toString().padLeft(2, '0')} ${txDate.hour.toString().padLeft(2, '0')}:${txDate.minute.toString().padLeft(2, '0')}'),
                if (goods.isNotEmpty) _buildDetailRow('商品', goods),
                _buildDetailRow('备注', note.isNotEmpty ? note : '无'),
                const SizedBox(height: 28),
                Row(
                  children: [
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
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _showDeleteConfirmation(txId, displayName);
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('删除'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
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
    final categoryName = tx['category_name'] as String? ?? '未分类';
    final note = tx['note'] as String? ?? '';
    final goods = tx['goods'] as String? ?? '';
    final txId = tx['id'] as int;
    final displayName = goods.isNotEmpty ? goods : (note.isNotEmpty ? note : categoryName);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20, top: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
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
                        child: Text(displayName, style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
                      ),
                      Text(
                        '${isExpense ? '-' : '+'}${CurrencyFormatter.format(amount)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isExpense ? AppColors.indigo950 : AppColors.emerald600,
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
                      color: AppColors.primaryOf(brightness).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.edit, color: AppColors.primaryOf(brightness), size: 20),
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
                    await _showDeleteConfirmation(txId, displayName);
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
    final currentFilter = ref.read(transactionFilterProvider);
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('筛选', style: Theme.of(context).textTheme.titleLarge),
                          TextButton(
                            onPressed: () => setModalState(() {
                              tempCategoryIds = [];
                              tempIsExpense = null;
                              tempStartDate = null;
                              tempEndDate = null;
                              tempAccountId = null;
                              tempAccountName = null;
                            }),
                            child: const Text('重置'),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('收支类型', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            SegmentedButton<int?>(
                              segments: const [
                                ButtonSegment(value: null, label: Text('全部')),
                                ButtonSegment(value: 0, label: Text('收入')),
                                ButtonSegment(value: 1, label: Text('支出')),
                              ],
                              selected: {tempIsExpense == null ? null : (tempIsExpense! ? 1 : 0)},
                              onSelectionChanged: (values) {
                                setModalState(() {
                                  final val = values.first;
                                  tempIsExpense = val == null ? null : val == 1;
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            Text('日期范围', style: Theme.of(context).textTheme.titleSmall),
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
                                      if (picked != null) setModalState(() => tempStartDate = picked);
                                    },
                                    icon: const Icon(Icons.calendar_today, size: 18),
                                    label: Text(tempStartDate != null ? '${tempStartDate!.month}/${tempStartDate!.day}' : '开始日期'),
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
                                      if (picked != null) setModalState(() => tempEndDate = picked);
                                    },
                                    icon: const Icon(Icons.calendar_today, size: 18),
                                    label: Text(tempEndDate != null ? '${tempEndDate!.month}/${tempEndDate!.day}' : '结束日期'),
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
                                    onPressed: () => setModalState(() { tempStartDate = null; tempEndDate = null; }),
                                    child: const Text('清除日期'),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            Text('分类筛选', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            _buildCategoryFilter(setModalState, tempCategoryIds, (ids) => setModalState(() => tempCategoryIds = ids)),
                            const SizedBox(height: 20),
                            Text('账户筛选', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            _buildAccountFilter(setModalState, tempAccountId, tempAccountName, (id, name) => setModalState(() { tempAccountId = id; tempAccountName = name; })),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.primaryDark.withOpacity(0.15)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(transactionFilterProvider.notifier).state = TransactionFilter(
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

  Widget _buildCategoryFilter(StateSetter setModalState, List<int> selectedIds, ValueChanged<List<int>> onChanged) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(appDatabaseProvider).getCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()));
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: snapshot.data!.map((cat) {
            final catId = cat['id'] as int;
            final colorValue = cat['color'] as int? ?? AppColors.primary.value;
            final isSelected = selectedIds.contains(catId);
            return FilterChip(
              avatar: Icon(IconUtils.fromName(cat['icon'] as String?), size: 16, color: isSelected ? Colors.white : Color(colorValue)),
              label: Text(cat['name'] as String),
              selected: isSelected,
              selectedColor: Color(colorValue),
              labelStyle: TextStyle(color: isSelected ? Colors.white : null, fontSize: 13),
              onSelected: (selected) {
                final newIds = selectedIds.toList();
                selected ? newIds.add(catId) : newIds.remove(catId);
                onChanged(newIds);
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAccountFilter(StateSetter setModalState, int? selectedId, String? selectedName, void Function(int?, String?) onChanged) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(appDatabaseProvider).getAccounts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()));
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              avatar: const Icon(Icons.all_inclusive, size: 16),
              label: const Text('全部'),
              selected: selectedId == null,
              onSelected: (_) => onChanged(null, null),
            ),
            ...snapshot.data!.map((acc) {
              final accId = acc['id'] as int;
              final colorValue = acc['color'] as int? ?? AppColors.primary.value;
              final isSelected = selectedId == accId;
              return FilterChip(
                avatar: Icon(IconUtils.fromName(acc['icon'] as String?), size: 16, color: isSelected ? Colors.white : Color(colorValue)),
                label: Text(acc['name'] as String),
                selected: isSelected,
                selectedColor: Color(colorValue),
                labelStyle: TextStyle(color: isSelected ? Colors.white : null, fontSize: 13),
                onSelected: (_) => onChanged(accId, acc['name'] as String),
              );
            }),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  // 多选操作
  // ═══════════════════════════════════════════

  void _toggleSelectAll() {
    final groupedAsync = ref.read(groupedTransactionsProvider);
    groupedAsync.whenData((grouped) {
      setState(() {
        final allIds = grouped.values.expand((txs) => txs).map((tx) => tx['id'] as int).toSet();
        if (_selectedIds.containsAll(allIds) && _selectedIds.length == allIds.length) {
          _selectedIds.clear();
        } else {
          _selectedIds.clear();
          _selectedIds.addAll(allIds);
        }
      });
    });
  }

  Future<void> _batchDelete() async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定要删除选中的 $count 条交易记录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final db = ref.read(appDatabaseProvider);
    int deletedCount = 0;
    for (final id in _selectedIds) {
      try {
        await db.deleteTransaction(id);
        deletedCount++;
      } catch (_) {}
    }
    ref.read(transactionRefreshProvider.notifier).state++;
    setState(() {
      _selectedIds.clear();
      _isMultiSelectMode = false;
    });
    if (mounted) _showCenterToast('已删除 $deletedCount 条记录');
  }

  void _showCenterToast(String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (context) => _ListToastWidget(message: message, isError: isError));
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (entry.mounted) entry.remove();
    });
  }
}

/// 居中提示组件
class _ListToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  const _ListToastWidget({required this.message, required this.isError});
  @override
  State<_ListToastWidget> createState() => _ListToastWidgetState();
}

class _ListToastWidgetState extends State<_ListToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.black26,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(opacity: _opacityAnimation.value, child: child),
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
                  color: isDark ? AppColors.primaryDark.withOpacity(0.15) : Colors.black.withOpacity(0.15),
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
                    color: widget.isError ? Colors.red.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: widget.isError ? Colors.red : AppColors.success,
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
                    color: widget.isError ? Colors.red : Theme.of(context).colorScheme.onSurface,
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
