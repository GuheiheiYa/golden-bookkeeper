import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/utils/icon_utils.dart';
import '../../../app/di/providers.dart';

// ========== 预算数据 Provider ==========

/// 当前年月
final currentYearProvider = StateProvider<int>((ref) => DateTime.now().year);
final currentMonthProvider = StateProvider<int>((ref) => DateTime.now().month);

/// 预算列表 Provider
final budgetsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // 监听交易刷新，确保交易更新后预算也会刷新
  ref.watch(transactionRefreshProvider);
  final year = ref.watch(currentYearProvider);
  final month = ref.watch(currentMonthProvider);
  final db = AppDatabase();
  return await db.getBudgets(year: year, month: month);
});

/// 预算使用情况 Provider（带分类信息和已用金额）
final budgetUsageProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // 监听交易刷新，确保交易更新后预算也会刷新
  ref.watch(transactionRefreshProvider);
  final budgets = await ref.watch(budgetsProvider.future);
  final db = AppDatabase();
  final now = DateTime.now();
  final year = ref.read(currentYearProvider);
  final month = ref.read(currentMonthProvider);
  final start = DateTime(year, month, 1);
  final end = DateTime(year, month + 1, 0, 23, 59, 59);

  List<Map<String, dynamic>> result = [];
  for (final budget in budgets) {
    final categoryId = budget['category_id'] as int?;
    double spent = 0;
    String categoryName = '总预算';
    String? categoryIcon;
    int? categoryColor;

    if (categoryId != null) {
      spent = await db.getCategoryExpense(categoryId, start, end);
      // 获取分类信息
      final categories = await db.getCategories();
      final cat = categories.where((c) => c['id'] == categoryId).firstOrNull;
      if (cat != null) {
        categoryName = cat['name'] as String;
        categoryIcon = cat['icon'] as String?;
        categoryColor = cat['color'] as int?;
      }
    } else {
      // 总预算 - 计算所有支出
      spent = await db.getTotalExpense(start, end);
    }

    result.add({
      'id': budget['id'],
      'category_id': categoryId,
      'category_name': categoryName,
      'category_icon': categoryIcon,
      'category_color': categoryColor,
      'amount': (budget['amount'] as num).toDouble(),
      'spent': spent,
      'period_type': budget['period_type'] as String? ?? 'monthly',
    });
  }
  return result;
});

// ========== 预算管理页面 ==========

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetUsageAsync = ref.watch(budgetUsageProvider);
    final year = ref.watch(currentYearProvider);
    final month = ref.watch(currentMonthProvider);
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        title: const Text('预算管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddBudgetDialog(context, ref),
          ),
        ],
      ),
      body: budgetUsageAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('加载失败: $error')),
        data: (budgets) {
          // 计算总预算和总支出
          double totalBudget = 0;
          double totalSpent = 0;
          for (final b in budgets) {
            totalBudget += b['amount'] as double;
            totalSpent += b['spent'] as double;
          }
          final percentage = totalBudget > 0
              ? (totalSpent / totalBudget * 100).clamp(0, 100)
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 月份选择器
                _buildMonthSelector(context, ref, year, month),
                const SizedBox(height: 16),
                // 总预算卡片
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '本月预算',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 环形进度
                      SizedBox(
                        height: 150,
                        width: 150,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              height: 150,
                              width: 150,
                              child: CircularProgressIndicator(
                                value: percentage / 100,
                                strokeWidth: 12,
                                backgroundColor:
                                    Theme.of(context).colorScheme.surfaceVariant,
                                valueColor: AlwaysStoppedAnimation(
                                  percentage > 90
                                      ? AppColors.error
                                      : percentage > 70
                                          ? AppColors.warning
                                          : AppColors.primaryOf(brightness),
                                ),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${percentage.toStringAsFixed(0)}%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  '已使用',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildBudgetInfo(
                            context,
                            label: '预算',
                            amount: '¥ ${totalBudget.toStringAsFixed(0)}',
                            color: AppColors.primaryOf(brightness),
                          ),
                          _buildBudgetInfo(
                            context,
                            label: '已用',
                            amount: '¥ ${totalSpent.toStringAsFixed(0)}',
                            color: AppColors.warning,
                          ),
                          _buildBudgetInfo(
                            context,
                            label: '剩余',
                            amount: '¥ ${(totalBudget - totalSpent).toStringAsFixed(0)}',
                            color: totalBudget - totalSpent >= 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 24),
                // 分类预算
                Text(
                  '分类预算',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (budgets.isEmpty)
                  AppCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.savings_outlined,
                              size: 48,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '暂无预算',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '点击右上角 + 添加预算',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...budgets.asMap().entries.map((entry) {
                    final index = entry.key;
                    final budget = entry.value;
                    final spent = budget['spent'] as double;
                    final budgetAmount = budget['amount'] as double;
                    final percent = budgetAmount > 0
                        ? (spent / budgetAmount * 100).clamp(0, 100)
                        : 0.0;
                    final isOver = spent > budgetAmount;
                    final iconName = budget['category_icon'] as String?;
                    final colorValue = budget['category_color'] as int?;

                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      onTap: () => _showEditBudgetDialog(context, ref, budget),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Color(colorValue ?? 0xFF7C3AED)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  iconName != null
                                      ? IconUtils.fromName(iconName)
                                      : Icons.savings,
                                  color: Color(colorValue ?? 0xFF7C3AED),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      budget['category_name'] as String,
                                      style:
                                          Theme.of(context).textTheme.titleSmall,
                                    ),
                                    Text(
                                      '¥ ${spent.toStringAsFixed(0)} / ¥ ${budgetAmount.toStringAsFixed(0)}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${percent.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isOver
                                      ? AppColors.error
                                      : percent > 80
                                          ? AppColors.warning
                                          : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percent / 100,
                              minHeight: 6,
                              backgroundColor:
                                  Theme.of(context).colorScheme.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation(
                                isOver
                                    ? AppColors.error
                                    : percent > 80
                                        ? AppColors.warning
                                        : Color(colorValue ?? 0xFF7C3AED),
                              ),
                            ),
                          ),
                          if (isOver) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 16,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '已超支 ¥ ${(spent - budgetAmount).toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: 100 * (index + 1)),
                          duration: 300.ms,
                        )
                        .slideY(begin: 0.1, end: 0);
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 月份选择器
  Widget _buildMonthSelector(BuildContext context, WidgetRef ref, int year, int month) {
    return AppCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              if (month == 1) {
                ref.read(currentYearProvider.notifier).state = year - 1;
                ref.read(currentMonthProvider.notifier).state = 12;
              } else {
                ref.read(currentMonthProvider.notifier).state = month - 1;
              }
            },
          ),
          Text(
            '$year年$month月',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              if (month == 12) {
                ref.read(currentYearProvider.notifier).state = year + 1;
                ref.read(currentMonthProvider.notifier).state = 1;
              } else {
                ref.read(currentMonthProvider.notifier).state = month + 1;
              }
            },
          ),
        ],
      ),
    );
  }

  /// 刷新数据
  void _refreshData(WidgetRef ref) {
    ref.invalidate(budgetsProvider);
    ref.invalidate(budgetUsageProvider);
  }

  Widget _buildBudgetInfo(
    BuildContext context, {
    required String label,
    required String amount,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  // ========== 添加预算对话框 ==========

  void _showAddBudgetDialog(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    int? selectedCategoryId;
    String? selectedCategoryName;
    String selectedPeriod = 'monthly';
    final year = ref.read(currentYearProvider);
    final month = ref.read(currentMonthProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final brightness = Theme.of(context).brightness;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '添加预算',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    // 选择分类
                    ListTile(
                      leading: Icon(Icons.category, color: AppColors.primaryOf(brightness)),
                      title: Text(selectedCategoryName ?? '总预算（全部分类）'),
                      subtitle: const Text('点击选择分类'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _showCategoryPicker(context, (catId, catName) {
                          setModalState(() {
                            selectedCategoryId = catId;
                            selectedCategoryName = catName;
                          });
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    // 预算金额
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: '预算金额',
                        hintText: '请输入预算金额',
                        prefixText: '¥ ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    // 预算周期
                    ListTile(
                      leading: Icon(Icons.calendar_today, color: AppColors.primaryOf(brightness)),
                      title: const Text('预算周期'),
                      trailing: Text(_getPeriodText(selectedPeriod)),
                      onTap: () {
                        _showPeriodPicker(context, selectedPeriod, (value) {
                          setModalState(() => selectedPeriod = value);
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final amount = double.tryParse(amountController.text);
                            if (amount == null || amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('请输入有效的预算金额')),
                              );
                              return;
                            }
                            final db = AppDatabase();
                            await db.insertBudget({
                              'category_id': selectedCategoryId,
                              'amount': amount,
                              'period_type': selectedPeriod,
                              'year': year,
                              'month': selectedPeriod == 'monthly' ? month : null,
                            });
                            Navigator.pop(context);
                            _refreshData(ref);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('预算添加成功')),
                            );
                          },
                          child: const Text('保存'),
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

  // ========== 编辑预算对话框 ==========

  void _showEditBudgetDialog(
      BuildContext context, WidgetRef ref, Map<String, dynamic> budget) {
    final amountController = TextEditingController(
      text: (budget['amount'] as double).toStringAsFixed(0),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '编辑预算',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        _showDeleteConfirmation(context, ref, budget);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(budget['category_color'] as int? ?? 0xFF7C3AED)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      budget['category_icon'] != null
                          ? IconUtils.fromName(budget['category_icon'] as String)
                          : Icons.savings,
                      color: Color(budget['category_color'] as int? ?? 0xFF7C3AED),
                    ),
                  ),
                  title: Text(budget['category_name'] as String),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: '预算金额',
                    prefixText: '¥ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final amount = double.tryParse(amountController.text);
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('请输入有效的预算金额')),
                          );
                          return;
                        }
                        final db = AppDatabase();
                        await db.updateBudget(budget['id'] as int, {
                          'amount': amount,
                        });
                        Navigator.pop(context);
                        _refreshData(ref);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('预算更新成功')),
                        );
                      },
                      child: const Text('保存'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ========== 分类选择器 ==========

  void _showCategoryPicker(
      BuildContext context, Function(int?, String?) onSelected) async {
    final db = AppDatabase();
    final categories = await db.getCategories(isExpense: true);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final brightness = Theme.of(context).brightness;
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '选择分类',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              // 总预算选项
              ListTile(
                leading: Icon(Icons.savings, color: AppColors.primaryOf(brightness)),
                title: const Text('总预算（全部分类）'),
                onTap: () {
                  onSelected(null, null);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              // 分类列表
              ...categories.map((cat) {
                final iconName = cat['icon'] as String? ?? 'category';
                final colorValue = cat['color'] as int? ?? 0xFF7C3AED;
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(colorValue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      IconUtils.fromName(iconName),
                      color: Color(colorValue),
                      size: 20,
                    ),
                  ),
                  title: Text(cat['name'] as String),
                  onTap: () {
                    onSelected(cat['id'] as int, cat['name'] as String);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ========== 周期选择器 ==========

  void _showPeriodPicker(
      BuildContext context, String current, ValueChanged<String> onSelected) {
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
                '选择周期',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildPeriodOption(context, '每月', 'monthly', current, onSelected),
              _buildPeriodOption(context, '每年', 'yearly', current, onSelected),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodOption(BuildContext context, String label, String value,
      String current, ValueChanged<String> onSelected) {
    final brightness = Theme.of(context).brightness;
    return ListTile(
      title: Text(label),
      trailing: value == current
          ? Icon(Icons.check_circle, color: AppColors.primaryOf(brightness))
          : null,
      onTap: () {
        onSelected(value);
        Navigator.pop(context);
      },
    );
  }

  String _getPeriodText(String period) {
    switch (period) {
      case 'monthly':
        return '每月';
      case 'yearly':
        return '每年';
      default:
        return period;
    }
  }

  // ========== 删除确认对话框 ==========

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, Map<String, dynamic> budget) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除预算'),
          content: Text('确定要删除"${budget['category_name']}"的预算吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final db = AppDatabase();
                await db.deleteBudget(budget['id'] as int);
                Navigator.pop(context); // 关闭确认对话框
                Navigator.pop(context); // 关闭编辑对话框
                _refreshData(ref);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('预算已删除')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }
}
