import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/app_card.dart';
import '../../profile/presentation/profile_provider.dart';

// ========== 贷款数据 Provider ==========

/// 贷款列表数据 Provider（查询 type 以 loan 开头的账户）
final loanAccountsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = AppDatabase();
  final allAccounts = await db.getAccounts();
  return allAccounts.where((a) => (a['type'] as String? ?? '').startsWith('loan')).toList();
});

/// 总负债 Provider（所有贷款余额之和）
final totalLiabilitiesProvider = FutureProvider<double>((ref) async {
  final accounts = await ref.watch(loanAccountsProvider.future);
  double total = 0;
  for (final account in accounts) {
    total += (account['balance'] as num?)?.toDouble() ?? 0;
  }
  return total;
});

// ========== 贷款管理页面 ==========

class LoanListScreen extends ConsumerWidget {
  const LoanListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(loanAccountsProvider);
    final totalAsync = ref.watch(totalLiabilitiesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('贷款管理', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddLoanDialog(context, ref),
          ),
        ],
      ),
      body: loansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('加载失败: $error')),
        data: (loans) {
          final totalLiabilities = totalAsync.valueOrNull ?? 0.0;

          if (loans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '暂无贷款',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右上角 + 添加贷款记录',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 总负债卡片
                AppCard(
                  child: Column(
                    children: [
                      Text(
                        '总负债',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.format(totalLiabilities),
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFEF4444),
                            ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 24),
                // 贷款列表
                Text(
                  '我的贷款',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...loans.asMap().entries.map((entry) {
                  final index = entry.key;
                  final loan = entry.value;
                  final balance = (loan['balance'] as num?)?.toDouble() ?? 0.0;

                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    onTap: () => _showEditLoanDialog(context, ref, loan),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance,
                            color: Color(0xFFEF4444),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loan['name'] as String,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                _getLoanTypeName(loan['type'] as String? ?? 'loan'),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(balance),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFEF4444),
                              ),
                        ),
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

  String _getLoanTypeName(String type) {
    switch (type) {
      case 'loan_mortgage':
        return '房贷';
      case 'loan_auto':
        return '车贷';
      case 'loan_credit':
        return '信用贷';
      case 'loan_online':
        return '网贷';
      default:
        return '其他贷款';
    }
  }

  void _refreshData(WidgetRef ref) {
    ref.invalidate(loanAccountsProvider);
    ref.invalidate(totalLiabilitiesProvider);
    // 触发个人中心资产卡片刷新
    ref.read(loanRefreshProvider.notifier).state++;
  }

  // ========== 添加贷款对话框 ==========

  void _showAddLoanDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedType = 'loan_other';

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
                      const Text('添加贷款', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 20),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: '贷款名称',
                          hintText: '如：房贷、车贷',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: balanceController,
                        decoration: const InputDecoration(
                          labelText: '贷款金额',
                          hintText: '0.00',
                          prefixText: '¥ ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      Text('贷款类型', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildTypeChip('房贷', 'loan_mortgage', Icons.home, selectedType, (v) {
                            setModalState(() => selectedType = v);
                          }),
                          _buildTypeChip('车贷', 'loan_auto', Icons.directions_car, selectedType, (v) {
                            setModalState(() => selectedType = v);
                          }),
                          _buildTypeChip('信用贷', 'loan_credit', Icons.credit_card, selectedType, (v) {
                            setModalState(() => selectedType = v);
                          }),
                          _buildTypeChip('网贷', 'loan_online', Icons.language, selectedType, (v) {
                            setModalState(() => selectedType = v);
                          }),
                          _buildTypeChip('其他', 'loan_other', Icons.more_horiz, selectedType, (v) {
                            setModalState(() => selectedType = v);
                          }),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final name = nameController.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('请输入贷款名称')),
                                );
                                return;
                              }
                              final balance = double.tryParse(balanceController.text) ?? 0.0;
                              final db = AppDatabase();
                              await db.insertAccount({
                                'name': name,
                                'type': selectedType,
                                'balance': balance,
                                'icon': 'account_balance',
                                'color': 0xFFEF4444,
                              });
                              Navigator.pop(context);
                              _refreshData(ref);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('贷款添加成功')),
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

  // ========== 编辑贷款对话框 ==========

  void _showEditLoanDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> loan) {
    final nameController = TextEditingController(text: loan['name'] as String);
    final balanceController = TextEditingController(
      text: ((loan['balance'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2),
    );
    String selectedType = loan['type'] as String? ?? 'loan_other';

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('编辑贷款', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _showDeleteConfirmation(context, ref, loan),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: '贷款名称'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: balanceController,
                      decoration: const InputDecoration(labelText: '剩余金额', prefixText: '¥ '),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Text('贷款类型', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildTypeChip('房贷', 'loan_mortgage', Icons.home, selectedType, (v) {
                          setModalState(() => selectedType = v);
                        }),
                        _buildTypeChip('车贷', 'loan_auto', Icons.directions_car, selectedType, (v) {
                          setModalState(() => selectedType = v);
                        }),
                        _buildTypeChip('信用贷', 'loan_credit', Icons.credit_card, selectedType, (v) {
                          setModalState(() => selectedType = v);
                        }),
                        _buildTypeChip('网贷', 'loan_online', Icons.language, selectedType, (v) {
                          setModalState(() => selectedType = v);
                        }),
                        _buildTypeChip('其他', 'loan_other', Icons.more_horiz, selectedType, (v) {
                          setModalState(() => selectedType = v);
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('请输入贷款名称')),
                              );
                              return;
                            }
                            final balance = double.tryParse(balanceController.text) ?? 0.0;
                            final db = AppDatabase();
                            await db.updateAccount(loan['id'] as int, {
                              'name': name,
                              'type': selectedType,
                              'balance': balance,
                            });
                            Navigator.pop(context);
                            _refreshData(ref);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('贷款更新成功')),
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

  // ========== 删除确认对话框 ==========

  void _showDeleteConfirmation(BuildContext outerContext, WidgetRef ref, Map<String, dynamic> loan) {
    showDialog(
      context: outerContext,
      builder: (confirmContext) {
        return FutureBuilder<int>(
          future: AppDatabase().getTransactionCountForAccount(loan['id'] as int),
          builder: (builderContext, snapshot) {
            final count = snapshot.data ?? 0;
            return AlertDialog(
              title: const Text('删除贷款'),
              content: Text(
                count > 0
                    ? '该贷款下有 $count 条交易记录，确定删除吗？\n删除后相关交易记录不会被删除。'
                    : '确定要删除贷款"${loan['name']}"吗？',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(confirmContext),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final db = AppDatabase();
                    await db.deleteAccount(loan['id'] as int);
                    Navigator.pop(confirmContext); // 关闭确认对话框
                    Navigator.pop(outerContext); // 关闭编辑对话框
                    _refreshData(ref);
                    ScaffoldMessenger.of(outerContext).showSnackBar(
                      const SnackBar(content: Text('贷款已删除')),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                  child: const Text('删除'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ========== 类型选择 Chip ==========

  Widget _buildTypeChip(
    String label,
    String value,
    IconData icon,
    String selected,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = selected == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
    );
  }
}
