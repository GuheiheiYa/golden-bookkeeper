import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/services/notification_service.dart';
import '../../../app/di/providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../budget/presentation/budget_screen.dart';
import '../../recurring/presentation/recurring_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndExecuteRecurringRules();
    });
    _startRecurringTimer();
  }

  @override
  void dispose() {
    _recurringTimer?.cancel();
    super.dispose();
  }

  void _startRecurringTimer() {
    _recurringTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndExecuteRecurringRules();
    });
  }

  Timer? _recurringTimer;

  Future<void> _checkAndExecuteRecurringRules() async {
    final db = ref.read(appDatabaseProvider);
    final executedIds = await db.executeDueRecurringRules();
    if (executedIds.isNotEmpty && mounted) {
      ref.read(transactionRefreshProvider.notifier).state++;
      _notificationService.success(
        title: '周期记账执行',
        message: '已自动执行 ${executedIds.length} 条周期记账',
        onTap: () {
          GoRouter.of(context).go('/transactions');
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthlySummary = ref.watch(monthlySummaryProvider);
    final recentTransactions = ref.watch(recentTransactionsProvider);
    ref.watch(budgetUsageProvider);

    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // 问候语
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 6) {
      greeting = '夜深了，注意休息';
    } else if (hour < 12) {
      greeting = '早上好';
    } else if (hour < 18) {
      greeting = '下午好';
    } else {
      greeting = '晚上好';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // 固定顶部栏（不随滚动）
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _buildTopBar(context, isDark),
            ),
            // 可滚动内容
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // 问候语
                    _buildGreeting(context, greeting, isDark),
                    const SizedBox(height: 24),
                    // 余额卡片（Hero Card）
                    _buildBalanceCard(context, monthlySummary, isDark),
                    const SizedBox(height: 24),
                    // 快捷操作
                    _buildQuickActions(context, isDark),
                    const SizedBox(height: 24),
                    // 预算进度
                    _buildBudgetProgress(context, isDark),
                    const SizedBox(height: 24),
                    // 最近交易
                    _buildRecentTransactions(context, recentTransactions, isDark),
                    // 底部留白（给浮动导航栏）
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 顶部栏
  Widget _buildTopBar(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 左侧：头像
        GestureDetector(
          onTap: () => GoRouter.of(context).go('/settings'),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppColors.darkSurface : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : AppColors.lightPrimary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.person_rounded,
              color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightTextTertiary,
              size: 22,
            ),
          ),
        ),
        // 右侧：通知
        Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () => _showNotificationList(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.2)
                              : AppColors.lightPrimary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightTextTertiary,
                      size: 20,
                    ),
                  ),
                ),
                if (_notificationService.unreadCount > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  /// 问候语
  Widget _buildGreeting(BuildContext context, String greeting, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting，记账达人',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${DateTime.now().month}月${DateTime.now().day}日 星期${_weekday(DateTime.now().weekday)}',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightTextTertiary,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 50.ms, duration: 300.ms);
  }

  String _weekday(int day) {
    const days = ['一', '二', '三', '四', '五', '六', '日'];
    return days[day - 1];
  }

  /// 余额卡片 - 梦幻紫渐变
  Widget _buildBalanceCard(BuildContext context, AsyncValue<Map<String, double>> summary, bool isDark) {
    final now = DateTime.now();
    final monthLabel = '${now.month}月';

    return summary.when(
      loading: () => Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF2D1F4E), Color(0xFF1A1A2E)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (e, _) => AppCard(
        child: Center(child: Text('加载失败: $e')),
      ),
      data: (data) {
        final balance = data['balance'] ?? 0;
        final income = data['income'] ?? 0;
        final expense = data['expense'] ?? 0;

        // 深色模式使用深色卡片渐变（如设计图所示）
        final gradientColors = isDark
            ? [AppColors.balanceGradientStartDark, AppColors.balanceGradientEndDark]
            : [AppColors.balanceGradientStart, AppColors.balanceGradientEnd];
        final shadowColor = isDark
            ? Colors.black.withOpacity(0.4)
            : AppColors.lightPrimary.withOpacity(0.3);

        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A2E), Color(0xFF2D1F4E), Color(0xFF1A1A2E)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '本月结余',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      monthLabel,
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '¥${CurrencyFormatter.format(balance).replaceFirst('¥', '')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // 收入
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4ADE80),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '收入',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(income),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 支出
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFBBF24),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '支出',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(expense),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.05, end: 0, delay: 100.ms, duration: 400.ms);
      },
    );
  }

  Widget _buildBalanceItem({
    required String label,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 快捷操作
  Widget _buildQuickActions(BuildContext context, bool isDark) {
    final actions = [
      {'icon': Icons.edit_rounded, 'label': '记账', 'color': AppColors.lightPrimary},
      {'icon': Icons.pie_chart_outline_rounded, 'label': '统计', 'color': AppColors.info},
      {'icon': Icons.savings_outlined, 'label': '预算', 'color': AppColors.warning},
      {'icon': Icons.repeat_rounded, 'label': '周期', 'color': AppColors.success},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((action) {
        final accent = action['color'] as Color;
        final icon = action['icon'] as IconData;
        final label = action['label'] as String;

        return GestureDetector(
          onTap: () {
            if (label == '记账') {
              context.push('/add-transaction');
            } else if (label == '统计') {
              GoRouter.of(context).go('/statistics');
            } else if (label == '预算') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BudgetScreen()),
              );
            } else if (label == '周期') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RecurringScreen()),
              );
            }
          },
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withOpacity(isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 150.ms, duration: 300.ms);
  }

  /// 预算进度
  Widget _buildBudgetProgress(BuildContext context, bool isDark) {
    final budgetUsageAsync = ref.watch(budgetUsageProvider);

    return budgetUsageAsync.when(
      loading: () => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('本月预算', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
      error: (e, _) => AppCard(child: Text('预算加载失败: $e')),
      data: (budgets) {
        if (budgets.isEmpty) {
          return AppCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BudgetScreen()),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.lightPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.savings_outlined, color: AppColors.lightPrimary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('本月预算', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '暂未设置，点击去设置',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  size: 20,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
        }

        double totalBudget = 0;
        double totalSpent = 0;
        for (final b in budgets) {
          totalBudget += b['amount'] as double;
          totalSpent += b['spent'] as double;
        }
        final percentage = totalBudget > 0 ? (totalSpent / totalBudget * 100).clamp(0, 100) : 0.0;
        final remaining = totalBudget - totalSpent;
        final isOver = remaining < 0;

        return AppCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BudgetScreen()),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('本月预算', style: Theme.of(context).textTheme.titleMedium),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '已使用 ${percentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant,
                              ),
                            ),
                            Text(
                              isOver ? '超支' : '剩余',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            minHeight: 8,
                            backgroundColor: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOver
                                  ? AppColors.error
                                  : percentage > 80
                                      ? AppColors.warning
                                      : AppColors.lightPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '¥ ${remaining.abs().toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isOver ? AppColors.error : AppColors.lightPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
      },
    );
  }

  /// 最近交易
  Widget _buildRecentTransactions(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> recentTx,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '最近交易',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground,
              ),
            ),
            GestureDetector(
              onTap: () => GoRouter.of(context).go('/transactions'),
              child: Text(
                '查看全部',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.lightPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        recentTx.when(
          loading: () => AppCard(
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          error: (e, _) => AppCard(child: Center(child: Text('加载失败: $e'))),
          data: (transactions) {
            if (transactions.isEmpty) {
              return AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '暂无交易记录',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '点击下方 + 开始记账',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return AppCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: List.generate(transactions.length, (index) {
                  final tx = transactions[index];
                  final isExpense = (tx['is_expense'] as int) == 1;
                  final amount = (tx['amount'] as num).toDouble();
                  final categoryName = tx['category_name'] as String? ?? '未分类';
                  final categoryColor = tx['category_color'] as int? ?? 0xFFB8A9E8;
                  final categoryIcon = tx['category_icon'] as String?;
                  final txDate = DateTime.parse(tx['date'] as String);
                  final timeStr = '${txDate.hour.toString().padLeft(2, '0')}:${txDate.minute.toString().padLeft(2, '0')}';
                  final note = tx['note'] as String? ?? categoryName;

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Color(categoryColor).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            mapIconName(categoryIcon),
                            color: Color(categoryColor),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          note.isNotEmpty ? note : categoryName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground,
                          ),
                        ),
                        subtitle: Text(
                          '$categoryName · $timeStr',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                        ),
                        trailing: Text(
                          '${isExpense ? '-' : '+'}${CurrencyFormatter.format(amount)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isExpense ? AppColors.expense : AppColors.income,
                          ),
                        ),
                        onTap: () => _showTransactionDetail(context, tx),
                      ),
                      if (index < transactions.length - 1)
                        Divider(
                          height: 1,
                          indent: 68,
                          endIndent: 16,
                          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                        ),
                    ],
                  );
                }),
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 250.ms, duration: 300.ms);
  }

  /// 交易详情弹窗
  void _showTransactionDetail(BuildContext context, Map<String, dynamic> tx) {
    final isExpense = (tx['is_expense'] as int) == 1;
    final amount = (tx['amount'] as num).toDouble();
    final categoryName = tx['category_name'] as String? ?? '未分类';
    final accountName = tx['account_name'] as String? ?? '未知账户';
    final txDate = DateTime.parse(tx['date'] as String);
    final note = tx['note'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部拖拽条
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isExpense ? '支出' : '收入',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightTextTertiary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${isExpense ? '-' : '+'}${CurrencyFormatter.format(amount)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isExpense ? AppColors.expense : AppColors.income,
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow(context, '分类', categoryName),
              _buildDetailRow(context, '账户', accountName),
              _buildDetailRow(
                context,
                '日期',
                '${txDate.year}-${txDate.month.toString().padLeft(2, '0')}-${txDate.day.toString().padLeft(2, '0')} ${txDate.hour.toString().padLeft(2, '0')}:${txDate.minute.toString().padLeft(2, '0')}',
              ),
              _buildDetailRow(context, '备注', note.isNotEmpty ? note : '无'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('确定', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground,
            ),
          ),
        ],
      ),
    );
  }

  /// 通知列表弹窗
  void _showNotificationList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 顶部拖拽条
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '消息通知',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground,
                          ),
                        ),
                        if (_notificationService.notifications.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _notificationService.clearAll();
                              setModalState(() {});
                            },
                            child: Text(
                              '清空',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.lightPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: _notificationService.notifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_off_outlined,
                                  size: 56,
                                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '暂无消息',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _notificationService.notifications.length,
                            itemBuilder: (context, index) {
                              final notification = _notificationService.notifications[index];
                              return ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: notification.color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(notification.icon, color: notification.color, size: 20),
                                ),
                                title: Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground,
                                  ),
                                ),
                                subtitle: Text(
                                  notification.message,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                  ),
                                  onPressed: () {
                                    _notificationService.removeNotification(notification.id);
                                    setModalState(() {});
                                  },
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  notification.onTap?.call();
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() {});
    });
  }
}
