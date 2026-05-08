import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
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
  @override
  void initState() {
    super.initState();
    // 每次进入首页时检查是否有到期的周期记账规则
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndExecuteRecurringRules();
    });
  }

  /// 检查并自动执行到期的周期记账规则
  Future<void> _checkAndExecuteRecurringRules() async {
    final db = ref.read(appDatabaseProvider);
    final executedIds = await db.executeDueRecurringRules();
    if (executedIds.isNotEmpty && mounted) {
      // 刷新交易数据
      ref.read(transactionRefreshProvider.notifier).state++;
      // 显示提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已自动执行 ${executedIds.length} 条周期记账'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: '查看',
            textColor: Colors.white,
            onPressed: () {
              GoRouter.of(context).go('/transactions');
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthlySummary = ref.watch(monthlySummaryProvider);
    final recentTransactions = ref.watch(recentTransactionsProvider);
    // 监听预算数据，确保交易更新后预算也会刷新
    ref.watch(budgetUsageProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 应用栏
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                '记账本',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.secondary.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
            ],
          ),
          // 内容
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 余额卡片（从数据库读取）
                  _buildBalanceCard(context, monthlySummary),
                  const SizedBox(height: 24),
                  // 快捷操作
                  _buildQuickActions(context, ref),
                  const SizedBox(height: 24),
                  // 预算进度
                  _buildBudgetProgress(context),
                  const SizedBox(height: 24),
                  // 最近交易（从数据库读取）
                  _buildRecentTransactions(context, recentTransactions),
                  // 底部留白
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 余额卡片 - 显示本月收入/支出/结余
  Widget _buildBalanceCard(BuildContext context, AsyncValue<Map<String, double>> summary) {
    final now = DateTime.now();
    final monthLabel = '${now.year}年${now.month}月';

    return summary.when(
      loading: () => AppCard(
        padding: EdgeInsets.zero,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      ),
      error: (e, _) => AppCard(
        child: Center(child: Text('加载失败: $e')),
      ),
      data: (data) {
        final balance = data['balance'] ?? 0;
        final income = data['income'] ?? 0;
        final expense = data['expense'] ?? 0;
        return AppCard(
          padding: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(16),
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
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        monthLabel,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  CurrencyFormatter.format(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildBalanceItem(
                      context,
                      label: '收入',
                      amount: CurrencyFormatter.format(income),
                      icon: Icons.arrow_downward,
                    ),
                    const SizedBox(width: 32),
                    _buildBalanceItem(
                      context,
                      label: '支出',
                      amount: CurrencyFormatter.format(expense),
                      icon: Icons.arrow_upward,
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

  Widget _buildBalanceItem(
    BuildContext context, {
    required String label,
    required String amount,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    final actions = [
      {'icon': Icons.receipt_long, 'label': '记账', 'color': AppColors.primary},
      {'icon': Icons.pie_chart, 'label': '统计', 'color': AppColors.secondary},
      {'icon': Icons.account_balance, 'label': '预算', 'color': AppColors.warning},
      {'icon': Icons.repeat, 'label': '周期', 'color': AppColors.info},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: actions.map((action) {
        return GestureDetector(
          onTap: () {
            final label = action['label'] as String;
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (action['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  action['icon'] as IconData,
                  color: action['color'] as Color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                action['label'] as String,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildBudgetProgress(BuildContext context) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('本月预算', style: Theme.of(context).textTheme.titleMedium),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BudgetScreen()),
                      ),
                      child: const Text('去设置'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.savings_outlined, size: 40, color: Colors.grey.withOpacity(0.5)),
                      const SizedBox(height: 8),
                      Text('暂未设置预算', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
        }

        // 计算总预算和总支出
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('本月预算', style: Theme.of(context).textTheme.titleMedium),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BudgetScreen()),
                    ),
                    child: const Text('查看详情'),
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
                        Text(
                          '已使用 ${percentage.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            minHeight: 8,
                            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOver
                                  ? AppColors.error
                                  : percentage > 80
                                      ? AppColors.warning
                                      : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isOver ? '超支' : '剩余',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '¥ ${remaining.abs().toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: isOver ? AppColors.error : AppColors.success,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
      },
    );
  }

  /// 最近交易 - 从数据库读取最近 5 笔
  Widget _buildRecentTransactions(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> recentTx,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '最近交易',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton(
              onPressed: () {
                // 切换到明细 Tab
                GoRouter.of(context).go('/transactions');
              },
              child: const Text('查看全部'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        recentTx.when(
          loading: () => const AppCard(
            child: Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )),
          ),
          error: (e, _) => AppCard(child: Center(child: Text('加载失败: $e'))),
          data: (transactions) {
            if (transactions.isEmpty) {
              return const AppCard(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      '暂无交易记录，快去记一笔吧',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              );
            }
            return AppCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  indent: 60,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  final isExpense = (tx['is_expense'] as int) == 1;
                  final amount = (tx['amount'] as num).toDouble();
                  final categoryName = tx['category_name'] as String? ?? '未分类';
                  final categoryColor = tx['category_color'] as int? ?? 0xFF6B7280;
                  final categoryIcon = tx['category_icon'] as String?;
                  final txDate = DateTime.parse(tx['date'] as String);
                  final timeStr = '${txDate.hour.toString().padLeft(2, '0')}:${txDate.minute.toString().padLeft(2, '0')}';
                  final note = tx['note'] as String? ?? categoryName;

                  return ListTile(
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
                      '$categoryName · $timeStr',
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
                    onTap: () => _showTransactionDetail(context, tx),
                  );
                },
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 300.ms);
  }

  /// 点击交易查看详情
  void _showTransactionDetail(BuildContext context, Map<String, dynamic> tx) {
    final isExpense = (tx['is_expense'] as int) == 1;
    final amount = (tx['amount'] as num).toDouble();
    final categoryName = tx['category_name'] as String? ?? '未分类';
    final accountName = tx['account_name'] as String? ?? '未知账户';
    final txDate = DateTime.parse(tx['date'] as String);
    final note = tx['note'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              _buildDetailRow(context, '分类', categoryName),
              _buildDetailRow(context, '账户', accountName),
              _buildDetailRow(context, '日期', '${txDate.year}-${txDate.month.toString().padLeft(2, '0')}-${txDate.day.toString().padLeft(2, '0')} ${txDate.hour.toString().padLeft(2, '0')}:${txDate.minute.toString().padLeft(2, '0')}'),
              _buildDetailRow(context, '备注', note.isNotEmpty ? note : '无'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('确定'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
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
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
