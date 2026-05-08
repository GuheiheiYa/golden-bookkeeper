import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/utils/icon_utils.dart';

// ========== 周期记账数据 Provider ==========

/// 周期记账规则列表 Provider
final recurringRulesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = AppDatabase();
  final rules = await db.getRecurringRules();

  // 为每条规则附加分类和账户信息
  List<Map<String, dynamic>> enrichedRules = [];
  final categories = await db.getCategories();
  final accounts = await db.getAccounts();

  for (final rule in rules) {
    final categoryId = rule['category_id'] as int;
    final accountId = rule['account_id'] as int;
    final cat = categories.where((c) => c['id'] == categoryId).firstOrNull;
    final acc = accounts.where((a) => a['id'] == accountId).firstOrNull;

    enrichedRules.add({
      ...rule,
      'category_name': cat?['name'] ?? '未知分类',
      'category_icon': cat?['icon'],
      'category_color': cat?['color'],
      'account_name': acc?['name'] ?? '未知账户',
    });
  }
  return enrichedRules;
});

// ========== 周期记账页面 ==========

class RecurringScreen extends ConsumerStatefulWidget {
  const RecurringScreen({super.key});

  @override
  ConsumerState<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends ConsumerState<RecurringScreen> {
  /// 刷新数据
  void _refreshData() {
    ref.invalidate(recurringRulesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(recurringRulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('周期记账'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRecurringDialog(context),
          ),
        ],
      ),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('加载失败: $error')),
        data: (rules) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 说明卡片
                AppCard(
                  color: AppColors.primary.withOpacity(0.1),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '设置周期记账规则，系统会自动为你记录固定收支',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 24),
                // 规则列表
                Text(
                  '记账规则',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (rules.isEmpty)
                  AppCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.repeat_outlined,
                              size: 48,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '暂无周期记账规则',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '点击右上角 + 添加规则',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...rules.asMap().entries.map((entry) {
                    final index = entry.key;
                    final rule = entry.value;
                    final isActive = (rule['is_active'] as int?) == 1;
                    final isExpense = (rule['is_expense'] as int?) == 1;
                    final amount = (rule['amount'] as num).toDouble();
                    final iconName = rule['category_icon'] as String?;
                    final colorValue = rule['category_color'] as int? ?? 0xFF7C3AED;
                    final frequency = rule['frequency'] as String? ?? 'monthly';
                    final dayOfMonth = rule['day_of_month'] as int?;

                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      onTap: () => _showEditRecurringDialog(context, rule),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Color(colorValue).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  iconName != null
                                      ? IconUtils.fromName(iconName)
                                      : Icons.repeat,
                                  color: Color(colorValue),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rule['title'] as String,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    Text(
                                      '${_getFrequencyText(frequency)}${dayOfMonth != null ? ' · ${dayOfMonth}日' : ''} · ${rule['category_name']}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isExpense ? '-' : '+'}¥ ${amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isExpense
                                          ? AppColors.expense
                                          : AppColors.income,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Switch(
                                    value: isActive,
                                    onChanged: (value) =>
                                        _toggleActive(rule, value),
                                    activeColor: AppColors.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (isActive) ...[
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '账户',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  rule['account_name'] as String,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.primary,
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
                        .slideX(begin: 0.1, end: 0);
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 切换启用/禁用状态
  Future<void> _toggleActive(Map<String, dynamic> rule, bool value) async {
    final db = AppDatabase();
    await db.updateRecurringRule(rule['id'] as int, {
      'is_active': value ? 1 : 0,
    });
    _refreshData();
  }

  String _getFrequencyText(String frequency) {
    switch (frequency) {
      case 'minutely':
        return '每分钟';
      case 'hourly':
        return '每小时';
      case 'daily':
        return '每天';
      case 'weekly':
        return '每周';
      case 'monthly':
        return '每月';
      case 'yearly':
        return '每年';
      default:
        return frequency;
    }
  }

  // ========== 添加周期记账对话框 ==========

  void _showAddRecurringDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    bool isExpense = true;
    int? selectedCategoryId;
    String? selectedCategoryName;
    int? selectedAccountId;
    String? selectedAccountName;
    String selectedFrequency = 'monthly';
    int? selectedDayOfMonth = 1;
    DateTime startDate = DateTime.now();

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
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '添加周期记账',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),
                      // 名称
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: '名称',
                          hintText: '例如：房租、工资',
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 金额和类型
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: amountController,
                              decoration: const InputDecoration(
                                labelText: '金额',
                                prefixText: '¥ ',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(value: true, label: Text('支出')),
                              ButtonSegment(value: false, label: Text('收入')),
                            ],
                            selected: {isExpense},
                            onSelectionChanged: (values) {
                              setModalState(() => isExpense = values.first);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 选择分类
                      ListTile(
                        leading: Icon(Icons.category, color: AppColors.primary),
                        title: Text(selectedCategoryName ?? '选择分类'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _showCategoryPicker(context, isExpense, (catId, catName) {
                            setModalState(() {
                              selectedCategoryId = catId;
                              selectedCategoryName = catName;
                            });
                          });
                        },
                      ),
                      // 选择账户
                      ListTile(
                        leading: Icon(Icons.account_balance_wallet,
                            color: AppColors.primary),
                        title: Text(selectedAccountName ?? '选择账户'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _showAccountPicker(context, (accId, accName) {
                            setModalState(() {
                              selectedAccountId = accId;
                              selectedAccountName = accName;
                            });
                          });
                        },
                      ),
                      // 频率
                      ListTile(
                        leading: Icon(Icons.repeat, color: AppColors.primary),
                        title: const Text('频率'),
                        trailing: Text(_getFrequencyText(selectedFrequency)),
                        onTap: () {
                          _showFrequencyPicker(context, selectedFrequency, (value) {
                            setModalState(() => selectedFrequency = value);
                          });
                        },
                      ),
                      // 每月几号（仅月频率时显示）
                      if (selectedFrequency == 'monthly')
                        ListTile(
                          leading: Icon(Icons.calendar_today,
                              color: AppColors.primary),
                          title: const Text('每月几号'),
                          trailing: Text('${selectedDayOfMonth ?? 1}日'),
                          onTap: () {
                            _showDayPicker(context, selectedDayOfMonth ?? 1,
                                (day) {
                              setModalState(() => selectedDayOfMonth = day);
                            });
                          },
                        ),
                      // 开始日期
                      ListTile(
                        leading: Icon(Icons.event, color: AppColors.primary),
                        title: const Text('开始日期'),
                        trailing: Text(
                          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setModalState(() => startDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              // 验证输入
                              final title = titleController.text.trim();
                              if (title.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('请输入名称')),
                                );
                                return;
                              }
                              final amount = double.tryParse(amountController.text);
                              if (amount == null || amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('请输入有效金额')),
                                );
                                return;
                              }
                              if (selectedCategoryId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('请选择分类')),
                                );
                                return;
                              }
                              if (selectedAccountId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('请选择账户')),
                                );
                                return;
                              }

                              final db = AppDatabase();
                              await db.insertRecurringRule({
                                'title': title,
                                'amount': amount,
                                'is_expense': isExpense ? 1 : 0,
                                'category_id': selectedCategoryId,
                                'account_id': selectedAccountId,
                                'frequency': selectedFrequency,
                                'day_of_month': selectedFrequency == 'monthly'
                                    ? selectedDayOfMonth
                                    : null,
                                'start_date': startDate.toIso8601String(),
                                'is_active': 1,
                              });
                              Navigator.pop(context);
                              _refreshData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('周期记账规则添加成功')),
                              );
                            },
                            child: const Text('保存'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ========== 编辑周期记账对话框 ==========

  void _showEditRecurringDialog(
      BuildContext context, Map<String, dynamic> rule) {
    final titleController = TextEditingController(text: rule['title'] as String);
    final amountController = TextEditingController(
      text: (rule['amount'] as num).toDouble().toStringAsFixed(2),
    );
    bool isExpense = (rule['is_expense'] as int?) == 1;
    String selectedFrequency = rule['frequency'] as String? ?? 'monthly';
    int? selectedDayOfMonth = rule['day_of_month'] as int?;

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
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '编辑周期记账',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              _showDeleteConfirmation(context, rule);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // 名称
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: '名称',
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 金额和类型
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: amountController,
                              decoration: const InputDecoration(
                                labelText: '金额',
                                prefixText: '¥ ',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(value: true, label: Text('支出')),
                              ButtonSegment(value: false, label: Text('收入')),
                            ],
                            selected: {isExpense},
                            onSelectionChanged: (values) {
                              setModalState(() => isExpense = values.first);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 分类和账户信息
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(rule['category_color'] as int? ?? 0xFF7C3AED)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            rule['category_icon'] != null
                                ? IconUtils.fromName(rule['category_icon'] as String)
                                : Icons.category,
                            color: Color(rule['category_color'] as int? ?? 0xFF7C3AED),
                            size: 20,
                          ),
                        ),
                        title: Text(rule['category_name'] as String),
                        subtitle: Text(rule['account_name'] as String),
                      ),
                      // 频率
                      ListTile(
                        leading: Icon(Icons.repeat, color: AppColors.primary),
                        title: const Text('频率'),
                        trailing: Text(_getFrequencyText(selectedFrequency)),
                        onTap: () {
                          _showFrequencyPicker(context, selectedFrequency, (value) {
                            setModalState(() => selectedFrequency = value);
                          });
                        },
                      ),
                      // 每月几号
                      if (selectedFrequency == 'monthly')
                        ListTile(
                          leading: Icon(Icons.calendar_today,
                              color: AppColors.primary),
                          title: const Text('每月几号'),
                          trailing: Text('${selectedDayOfMonth ?? 1}日'),
                          onTap: () {
                            _showDayPicker(context, selectedDayOfMonth ?? 1,
                                (day) {
                              setModalState(() => selectedDayOfMonth = day);
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
                              final title = titleController.text.trim();
                              if (title.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('请输入名称')),
                                );
                                return;
                              }
                              final amount = double.tryParse(amountController.text);
                              if (amount == null || amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('请输入有效金额')),
                                );
                                return;
                              }

                              final db = AppDatabase();
                              await db.updateRecurringRule(rule['id'] as int, {
                                'title': title,
                                'amount': amount,
                                'is_expense': isExpense ? 1 : 0,
                                'frequency': selectedFrequency,
                                'day_of_month': selectedFrequency == 'monthly'
                                    ? selectedDayOfMonth
                                    : null,
                              });
                              Navigator.pop(context);
                              _refreshData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('规则更新成功')),
                              );
                            },
                            child: const Text('保存'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ========== 分类选择器 ==========

  void _showCategoryPicker(BuildContext context, bool isExpense,
      Function(int, String) onSelected) async {
    final db = AppDatabase();
    final categories = await db.getCategories(isExpense: isExpense);

    if (!context.mounted) return;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '选择分类',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
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

  // ========== 账户选择器 ==========

  void _showAccountPicker(
      BuildContext context, Function(int, String) onSelected) async {
    final db = AppDatabase();
    final accounts = await db.getAccounts();

    if (!context.mounted) return;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '选择账户',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...accounts.map((acc) {
                final iconName = acc['icon'] as String? ?? 'payments';
                final colorValue = acc['color'] as int? ?? 0xFF7C3AED;
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
                  title: Text(acc['name'] as String),
                  onTap: () {
                    onSelected(acc['id'] as int, acc['name'] as String);
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

  // ========== 频率选择器 ==========

  void _showFrequencyPicker(
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
                '选择频率',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildFrequencyOption(context, '每分钟', 'minutely', current, onSelected),
              _buildFrequencyOption(context, '每小时', 'hourly', current, onSelected),
              _buildFrequencyOption(context, '每天', 'daily', current, onSelected),
              _buildFrequencyOption(context, '每周', 'weekly', current, onSelected),
              _buildFrequencyOption(context, '每月', 'monthly', current, onSelected),
              _buildFrequencyOption(context, '每年', 'yearly', current, onSelected),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFrequencyOption(BuildContext context, String label, String value,
      String current, ValueChanged<String> onSelected) {
    return ListTile(
      title: Text(label),
      trailing: value == current
          ? Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: () {
        onSelected(value);
        Navigator.pop(context);
      },
    );
  }

  // ========== 日期选择器 ==========

  void _showDayPicker(BuildContext context, int current, ValueChanged<int> onSelected) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '选择每月几号',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: 28,
                  itemBuilder: (context, index) {
                    final day = index + 1;
                    final isSelected = day == current;
                    return GestureDetector(
                      onTap: () {
                        onSelected(day);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$day',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ========== 删除确认对话框 ==========

  void _showDeleteConfirmation(
      BuildContext context, Map<String, dynamic> rule) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除规则'),
          content: Text('确定要删除周期记账规则"${rule['title']}"吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final db = AppDatabase();
                await db.deleteRecurringRule(rule['id'] as int);
                Navigator.pop(context); // 关闭确认对话框
                Navigator.pop(context); // 关闭编辑对话框
                _refreshData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('规则已删除')),
                  );
                }
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
