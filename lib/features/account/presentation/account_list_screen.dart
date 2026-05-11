import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/utils/icon_utils.dart';

// ========== 账户数据 Provider ==========

/// 账户列表数据 Provider
final accountsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = AppDatabase();
  return await db.getAccounts();
});

/// 总资产 Provider
final totalBalanceProvider = FutureProvider<double>((ref) async {
  final db = AppDatabase();
  return await db.getTotalBalance();
});

// ========== 账户管理页面 ==========

class AccountListScreen extends ConsumerWidget {
  const AccountListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final totalBalanceAsync = ref.watch(totalBalanceProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('账户管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddAccountDialog(context, ref),
          ),
        ],
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('加载失败: $error'),
        ),
        data: (accounts) {
          final totalBalance = totalBalanceAsync.valueOrNull ?? 0.0;

          if (accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '暂无账户',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右上角 + 添加第一个账户',
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
                // 总资产卡片
                AppCard(
                  child: Column(
                    children: [
                      Text(
                        '总资产',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¥ ${totalBalance.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 24),
                // 账户列表
                Text(
                  '我的账户',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...accounts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final account = entry.value;
                  final iconName = account['icon'] as String? ?? 'payments';
                  final colorValue = account['color'] as int? ?? AppColors.primary.value;
                  final balance = (account['balance'] as num?)?.toDouble() ?? 0.0;

                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    onTap: () => _showEditAccountDialog(context, ref, account),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(colorValue).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            IconUtils.fromName(iconName),
                            color: Color(colorValue),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account['name'] as String,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                _getAccountTypeName(account['type'] as String? ?? 'other'),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '¥ ${balance.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
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

  String _getAccountTypeName(String type) {
    switch (type) {
      case 'cash':
        return '现金账户';
      case 'bank':
        return '银行账户';
      case 'alipay':
        return '支付宝';
      case 'wechat':
        return '微信支付';
      case 'credit':
        return '信用卡';
      default:
        return '其他';
    }
  }

  /// 账户类型对应的图标名称
  String _getIconForType(String type) {
    switch (type) {
      case 'cash':
        return 'payments';
      case 'bank':
        return 'account_balance';
      case 'alipay':
        return 'account_balance_wallet';
      case 'wechat':
        return 'chat';
      case 'credit':
        return 'credit_card';
      default:
        return 'payments';
    }
  }

  /// 刷新账户数据
  void _refreshData(WidgetRef ref) {
    ref.invalidate(accountsProvider);
    ref.invalidate(totalBalanceProvider);
  }

  // ========== 添加账户对话框 ==========

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedType = 'cash';
    String selectedIcon = 'payments';
    int selectedColor = 0xFFF59E0B;

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
                        '添加账户',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),
                      // 账户名称
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: '账户名称',
                          hintText: '请输入账户名称',
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 初始余额
                      TextField(
                        controller: balanceController,
                        decoration: const InputDecoration(
                          labelText: '初始余额',
                          hintText: '0.00',
                          prefixText: '¥ ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      // 账户类型
                      Text(
                        '账户类型',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildTypeChip('现金', 'cash', Icons.payments, selectedType, (v) {
                            setModalState(() {
                              selectedType = v;
                              selectedIcon = _getIconForType(v);
                            });
                          }),
                          _buildTypeChip('银行卡', 'bank', Icons.account_balance, selectedType, (v) {
                            setModalState(() {
                              selectedType = v;
                              selectedIcon = _getIconForType(v);
                            });
                          }),
                          _buildTypeChip('支付宝', 'alipay', Icons.account_balance_wallet, selectedType, (v) {
                            setModalState(() {
                              selectedType = v;
                              selectedIcon = _getIconForType(v);
                            });
                          }),
                          _buildTypeChip('微信', 'wechat', Icons.chat, selectedType, (v) {
                            setModalState(() {
                              selectedType = v;
                              selectedIcon = _getIconForType(v);
                            });
                          }),
                          _buildTypeChip('信用卡', 'credit', Icons.credit_card, selectedType, (v) {
                            setModalState(() {
                              selectedType = v;
                              selectedIcon = _getIconForType(v);
                            });
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 选择颜色
                      Text(
                        '选择颜色',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: AppColors.categoryColors.map((color) {
                          final colorVal = color.value;
                          final isSelected = selectedColor == colorVal;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() => selectedColor = colorVal);
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withOpacity(0.5),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                                  : null,
                            ),
                          );
                        }).toList(),
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
                                  const SnackBar(content: Text('请输入账户名称')),
                                );
                                return;
                              }
                              final balance = double.tryParse(balanceController.text) ?? 0.0;
                              final db = AppDatabase();
                              await db.insertAccount({
                                'name': name,
                                'type': selectedType,
                                'balance': balance,
                                'icon': selectedIcon,
                                'color': selectedColor,
                              });
                              Navigator.pop(context);
                              _refreshData(ref);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('账户添加成功')),
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

  // ========== 编辑账户对话框 ==========

  void _showEditAccountDialog(
      BuildContext context, WidgetRef ref, Map<String, dynamic> account) {
    final nameController = TextEditingController(text: account['name'] as String);
    final balanceController = TextEditingController(
      text: ((account['balance'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2),
    );
    String selectedType = account['type'] as String? ?? 'cash';

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
                        Text(
                          '编辑账户',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            _showDeleteConfirmation(context, ref, account);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '账户名称',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: balanceController,
                      decoration: const InputDecoration(
                        labelText: '余额',
                        prefixText: '¥ ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '账户类型',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildTypeChip('现金', 'cash', Icons.payments, selectedType, (v) {
                          setModalState(() => selectedType = v);
                        }),
                        _buildTypeChip('银行卡', 'bank', Icons.account_balance, selectedType, (v) {
                          setModalState(() => selectedType = v);
                        }),
                        _buildTypeChip('支付宝', 'alipay', Icons.account_balance_wallet, selectedType, (v) {
                          setModalState(() => selectedType = v);
                        }),
                        _buildTypeChip('微信', 'wechat', Icons.chat, selectedType, (v) {
                          setModalState(() => selectedType = v);
                        }),
                        _buildTypeChip('信用卡', 'credit', Icons.credit_card, selectedType, (v) {
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
                                const SnackBar(content: Text('请输入账户名称')),
                              );
                              return;
                            }
                            final balance = double.tryParse(balanceController.text) ?? 0.0;
                            final db = AppDatabase();
                            await db.updateAccount(account['id'] as int, {
                              'name': name,
                              'type': selectedType,
                              'balance': balance,
                            });
                            Navigator.pop(context);
                            _refreshData(ref);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('账户更新成功')),
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

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, Map<String, dynamic> account) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<int>(
          future: AppDatabase().getTransactionCountForAccount(account['id'] as int),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return AlertDialog(
              title: const Text('删除账户'),
              content: Text(
                count > 0
                    ? '该账户下有 $count 条交易记录，确定删除吗？\n删除后相关交易记录不会被删除。'
                    : '确定要删除账户"${account['name']}"吗？',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final db = AppDatabase();
                    await db.deleteAccount(account['id'] as int);
                    Navigator.pop(context); // 关闭确认对话框
                    Navigator.pop(context); // 关闭编辑对话框
                    _refreshData(ref);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('账户已删除')),
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
      onSelect