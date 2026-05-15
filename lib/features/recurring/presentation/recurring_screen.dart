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
    final brightness = Theme.of(context).brightness;

    final isDark = brightness == Brightness.dark;
    final gradientColors = isDark
        ? const [AppColors.bgGradientTopDark, AppColors.bgGradientMidDark, AppColors.bgGradientBottomDark]
        : const [AppColors.bgGradientTop, AppColors.bgGradientMid, AppColors.bgGradientBottom];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('周期记账', style: TextStyle(color: Colors.white)),
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
                  color: AppColors.primaryOf(brightness).withOpacity(0.1),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primaryOf(brightness),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '设置周期记账规则，系统会自动为你记录固定收支',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.primaryOf(brightness),
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
                    final colorValue = rule['category_color'] as int? ?? AppColors.primary.value;
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
                                    activeColor: AppColors.primaryOf(brightness),
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
                                        color: AppColors.primaryOf(brightness),
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
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final screenHeight = MediaQuery.of(context).size.height;
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final brightness = Theme.of(context).brightness;
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screenHeight * 0.72),
              child: Container(
                padding: EdgeInsets.fromLTRB(0, 0, 0, bottomInset + bottomPadding),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 4),
                      child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightOutline, borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('添加周期记账', style: Theme.of(context).textTheme.titleLarge),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                      const SizedBox(height: 20),
                      // 名称
                      TextField(
                        controller: titleController,
                        style: TextStyle(fontSize: 15, color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground),
                        decoration: InputDecoration(
                          hintText: '例如：房租、工资',
                          hintStyle: TextStyle(color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary, fontSize: 15),
                          filled: true,
                          fillColor: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF3F4F6),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 金额和类型
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: amountController,
                              style: TextStyle(fontSize: 15, color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground),
                              decoration: InputDecoration(
                                hintText: '金额',
                                hintStyle: TextStyle(color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary, fontSize: 15),
                                prefixText: '¥ ',
                                prefixStyle: TextStyle(fontSize: 15, color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground),
                                filled: true,
                                fillColor: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF3F4F6),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.5)),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
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
                      const SizedBox(height: 8),
                      // 选择分类
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.category, color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant),
                        title: Text(selectedCategoryName ?? '选择分类', style: TextStyle(fontSize: 15, color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground)),
                        trailing: Icon(Icons.chevron_right, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                        onTap: () async {
                          final result = await _showCategoryPicker(context, isExpense);
                          if (result != null) {
                            setModalState(() {
                              selectedCategoryId = result['id'] as int;
                              selectedCategoryName = result['name'] as String;
                            });
                          }
                        },
                      ),
                      // 选择账户
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.account_balance_wallet, color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant),
                        title: Text(selectedAccountName ?? '选择账户', style: TextStyle(fontSize: 15, color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground)),
                        trailing: Icon(Icons.chevron_right, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                        onTap: () async {
                          final result = await _showAccountPicker(context);
                          if (result != null) {
                            setModalState(() {
                              selectedAccountId = result['id'] as int;
                              selectedAccountName = result['name'] as String;
                            });
                          }
                        },
                      ),
                      // 频率
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.repeat, color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant),
                        title: Text('频率', style: TextStyle(fontSize: 15, color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_getFrequencyText(selectedFrequency), style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant)),
                            Icon(Icons.chevron_right, size: 20, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                          ],
                        ),
                        onTap: () {
                          _showFrequencyPicker(context, selectedFrequency, (value) {
                            setModalState(() => selectedFrequency = value);
                          });
                        },
                      ),
                      // 每月几号（仅月频率时显示）
                      if (selectedFrequency == 'monthly')
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.calendar_today, color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant),
                          title: Text('每月几号', style: TextStyle(fontSize: 15, color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${selectedDayOfMonth ?? 1}日', style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant)),
                              Icon(Icons.chevron_right, size: 20, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                            ],
                          ),
                          onTap: () {
                            _showDayPicker(context, selectedDayOfMonth ?? 1,
                                (day) {
                              setModalState(() => selectedDayOfMonth = day);
                            });
                          },
                        ),
                      // 开始日期
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.event, color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant),
                        title: Text('开始日期', style: TextStyle(fontSize: 15, color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant)),
                            Icon(Icons.chevron_right, size: 20, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                          ],
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
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  border: Border(top: BorderSide(color: isDark ? AppColors.darkOutline : const Color(0xFFF0EBF5), width: 0.5)),
                ),
                child: SizedBox(
                  width: double.infinity, height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(colors: [AppColors.warmYellow, AppColors.warmYellowDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        if (title.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入名称'))); return; }
                        final amount = double.tryParse(amountController.text);
                        if (amount == null || amount <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入有效金额'))); return; }
                        if (selectedCategoryId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择分类'))); return; }
                        if (selectedAccountId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择账户'))); return; }

                        final db = AppDatabase();
                        final ruleId = await db.insertRecurringRule({
                                'title': title, 'amount': amount, 'is_expense': isExpense ? 1 : 0,
                                'category_id': selectedCategoryId, 'account_id': selectedAccountId,
                                'frequency': selectedFrequency,
                                'day_of_month': selectedFrequency == 'monthly' ? selectedDayOfMonth : null,
                                'start_date': startDate.toIso8601String(), 'is_active': 1,
                              });
                              if (selectedFrequency == 'minutely' || selectedFrequency == 'hourly') {
                                await db.executeDueRecurringRules();
                              }
                              Navigator.pop(context);
                              _refreshData();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('周期记账规则添加成功')));
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                            child: const Text('保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.warmYellowText)),
                          ),
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
    int? selectedCategoryId = rule['category_id'] as int?;
    String? selectedCategoryName = rule['category_name'] as String?;
    int? selectedAccountId = rule['account_id'] as int?;
    String? selectedAccountName = rule['account_name'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final screenHeight = MediaQuery.of(context).size.height;
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final brightness = Theme.of(context).brightness;
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screenHeight * 0.72),
              child: Container(
                padding: EdgeInsets.fromLTRB(0, 0, 0, bottomInset + bottomPadding),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 4),
                      child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightOutline, borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('编辑周期记账', style: Theme.of(context).textTheme.titleLarge),
                          GestureDetector(
                            onTap: () => _showDeleteConfirmation(context, rule),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                      const SizedBox(height: 8),
                      // 名称
                      TextField(
                        controller: titleController,
                        style: TextStyle(fontSize: 15, color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground),
                        decoration: InputDecoration(
                          hintText: '名称',
                          hintStyle: TextStyle(color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary, fontSize: 15),
                          filled: true,
                          fillColor: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF3F4F6),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 金额和类型
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: amountController,
                              style: TextStyle(fontSize: 15, color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground),
                              decoration: InputDecoration(
                                hintText: '金额',
                                hintStyle: TextStyle(color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary, fontSize: 15),
                                prefixText: '¥ ',
                                prefixStyle: TextStyle(fontSize: 15, color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground),
                                filled: true,
                                fillColor: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF3F4F6),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.5)),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
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
                      const SizedBox(height: 8),
                      // 选择分类
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.category, color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant),
                        title: Text(selectedCategoryName ?? '选择分类', style: TextStyle(fontSize: 15, color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground)),
                        trailing: Icon(Icons.chevron_right, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                        onTap: () async {
                          final result = await _showCategoryPicker(context, isExpense);
                          if (result != null) {
                            setModalState(() {
                              selectedCategoryId = result['id'] as int;
                              selectedCategoryName = result['name'] as String;
                            });
                          }
                        },
                      ),
                      // 选择账户
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.account_balance_wallet, color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant),
                        title: Text(selectedAccountName ?? '选择账户', style: TextStyle(fontSize: 15, color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground)),
                        trailing: Icon(Icons.chevron_right, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                        onTap: () async {
                          final result = await _showAccountPicker(context);
                          if (result != null) {
                            setModalState(() {
                              selectedAccountId = result['id'] as int;
                              selectedAccountName = result['name'] as String;
                            });
                          }
                        },
                      ),
                      // 频率
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.repeat, color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant),
                        title: Text('频率', style: TextStyle(fontSize: 15, color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_getFrequencyText(selectedFrequency), style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant)),
                            Icon(Icons.chevron_right, size: 20, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                          ],
                        ),
                        onTap: () {
                          _showFrequencyPicker(context, selectedFrequency, (value) {
                            setModalState(() => selectedFrequency = value);
                          });
                        },
                      ),
                      // 每月几号
                      if (selectedFrequency == 'monthly')
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.calendar_today, color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant),
                          title: Text('每月几号', style: TextStyle(fontSize: 15, color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${selectedDayOfMonth ?? 1}日', style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant)),
                              Icon(Icons.chevron_right, size: 20, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                            ],
                          ),
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
                              await db.updateRecurringRule(rule['id'] as int, {
                                'title': title,
                                'amount': amount,
                                'is_expense': isExpense ? 1 : 0,
                                'category_id': selectedCategoryId,
                                'account_id': selectedAccountId,
                                'frequency': selectedFrequency,
                                'day_of_month': selectedFrequency == 'monthly'
                                    ? selectedDayOfMonth
                                    : null,
                              });
                              Navigator.pop(context);
                              _refreshData();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('规则更新成功')));
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                            child: const Text('保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.warmYellowText)),
                          ),
                        ),
                      ),
                      ],
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

  // ========== 分类选择器 ==========

  /// 返回选中的分类 id 和名称，未选择返回 null
  Future<Map<String, dynamic>?> _showCategoryPicker(
      BuildContext context, bool isExpense) async {
    final db = AppDatabase();
    final categories = await db.getCategories(isExpense: isExpense);

    if (!context.mounted) return null;

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 4),
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightOutline, borderRadius: BorderRadius.circular(2))),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                final cat = categories[index];
                final iconName = cat['icon'] as String? ?? 'category';
                final colorValue = cat['color'] as int? ?? AppColors.primary.value;
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(colorValue).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(IconUtils.fromName(iconName), color: Color(colorValue), size: 20),
                  ),
                  title: Text(cat['name'] as String),
                  onTap: () {
                    Navigator.pop(context, {'id': cat['id'] as int, 'name': cat['name'] as String});
                  },
                );
              },
            ),
            ),
          ],
        ),
      );
    },
  );
  },
);
  }

  // ========== 账户选择器 ==========

  /// 返回选中的账户 id 和名称，未选择返回 null
  Future<Map<String, dynamic>?> _showAccountPicker(
      BuildContext context) async {
    final db = AppDatabase();
    final accounts = await db.getAccounts();

    if (!context.mounted) return null;

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 4),
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightOutline, borderRadius: BorderRadius.circular(2))),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemCount: accounts.length,
                      itemBuilder: (context, index) {
                final acc = accounts[index];
                final iconName = acc['icon'] as String? ?? 'payments';
                final colorValue = acc['color'] as int? ?? AppColors.primary.value;
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(colorValue).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(IconUtils.fromName(iconName), color: Color(colorValue), size: 20),
                  ),
                  title: Text(acc['name'] as String),
                  onTap: () {
                    Navigator.pop(context, {'id': acc['id'] as int, 'name': acc['name'] as String});
                  },
                );
              },
            ),
            ),
          ],
        ),
      );
    },
  );
  },
);
  }

  // ========== 频率选择器 ==========

  void _showFrequencyPicker(
      BuildContext context, String current, ValueChanged<String> onSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightOutline, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text('选择频率', style: Theme.of(context).textTheme.titleLarge),
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

  // ========== 日期选择器 ==========

  void _showDayPicker(BuildContext context, int current, ValueChanged<int> onSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final brightness = Theme.of(context).brightness;
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightOutline, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text('选择每月几号', style: Theme.of(context).textTheme.titleLarge),
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
                              ? AppColors.primaryOf(brightness)
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
      BuildContext outerContext, Map<String, dynamic> rule) {
    showDialog(
      context: outerContext,
      builder: (confirmContext) {
        return AlertDialog(
          title: const Text('删除规则'),
          content: Text('确定要删除周期记账规则"${rule['title']}"吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(confirmContext),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final db = AppDatabase();
                await db.deleteRecurringRule(rule['id'] as int);
                Navigator.pop(confirmContext); // 关闭确认对话框
                Navigator.pop(outerContext); // 关闭编辑对话框
                _refreshData();
                if (mounted) {
                  ScaffoldMessenger.of(outerContext).showSnackBar(
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
