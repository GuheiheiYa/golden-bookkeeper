import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/utils/icon_utils.dart';
import '../../profile/presentation/profile_provider.dart';

// ========== 账户数据 Provider ==========

/// 账户列表数据 Provider（排除贷款账户）
final accountsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = AppDatabase();
  final allAccounts = await db.getAccounts();
  return allAccounts.where((a) => !(a['type'] as String? ?? '').startsWith('loan')).toList();
});

/// 总资产 Provider（排除贷款账户）
final totalBalanceProvider = FutureProvider<double>((ref) async {
  final accounts = await ref.watch(accountsProvider.future);
  double total = 0;
  for (final account in accounts) {
    final balance = (account['balance'] as num?)?.toDouble() ?? 0;
    if (balance > 0) total += balance;
  }
  return total;
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
        foregroundColor: Colors.white,
        title: const Text('账户管理', style: TextStyle(color: Colors.white)),
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
    ref.read(accountRefreshProvider.notifier).state++;
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
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final screenHeight = MediaQuery.of(context).size.height;
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.lightOutline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('添加账户', style: Theme.of(context).textTheme.titleLarge),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRoundedInput(label: '账户名称', hint: '请输入账户名称', controller: nameController),
                            const SizedBox(height: 14),
                            _buildRoundedInput(label: '初始余额', hint: '0.00', controller: balanceController, prefix: '¥ ', keyboardType: TextInputType.number),
                            const SizedBox(height: 16),
                            Text('账户类型', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.lightOnSurfaceVariant, letterSpacing: 0.5)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: [
                                _buildTypeChip('现金', 'cash', Icons.payments, selectedType, (v) { setModalState(() { selectedType = v; selectedIcon = _getIconForType(v); }); }),
                                _buildTypeChip('银行卡', 'bank', Icons.account_balance, selectedType, (v) { setModalState(() { selectedType = v; selectedIcon = _getIconForType(v); }); }),
                                _buildTypeChip('支付宝', 'alipay', Icons.account_balance_wallet, selectedType, (v) { setModalState(() { selectedType = v; selectedIcon = _getIconForType(v); }); }),
                                _buildTypeChip('微信', 'wechat', Icons.chat, selectedType, (v) { setModalState(() { selectedType = v; selectedIcon = _getIconForType(v); }); }),
                                _buildTypeChip('信用卡', 'credit', Icons.credit_card, selectedType, (v) { setModalState(() { selectedType = v; selectedIcon = _getIconForType(v); }); }),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text('选择颜色', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.lightOnSurfaceVariant, letterSpacing: 0.5)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12, runSpacing: 12,
                              children: AppColors.categoryColors.map((color) {
                                final isSelected = selectedColor == color.value;
                                return GestureDetector(
                                  onTap: () => setModalState(() => selectedColor = color.value),
                                  child: Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: color, shape: BoxShape.circle,
                                      border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                                      boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)] : null,
                                    ),
                                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                                  ),
                                );
                              }).toList(),
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
                            gradient: LinearGradient(colors: [AppColors.warmYellow, AppColors.warmYellowDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              final name = nameController.text.trim();
                              if (name.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入账户名称'))); return; }
                              final balance = double.tryParse(balanceController.text) ?? 0.0;
                              final db = AppDatabase();
                              await db.insertAccount({'name': name, 'type': selectedType, 'balance': balance, 'icon': selectedIcon, 'color': selectedColor});
                              Navigator.pop(context);
                              _refreshData(ref);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('账户添加成功')));
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
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final screenHeight = MediaQuery.of(context).size.height;
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.lightOutline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('编辑账户', style: Theme.of(context).textTheme.titleLarge),
                          GestureDetector(
                            onTap: () => _showDeleteConfirmation(context, ref, account),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
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
                            _buildRoundedInput(label: '账户名称', hint: '请输入账户名称', controller: nameController),
                            const SizedBox(height: 14),
                            _buildRoundedInput(label: '余额', hint: '0.00', controller: balanceController, prefix: '¥ ', keyboardType: TextInputType.number),
                            const SizedBox(height: 16),
                            Text('账户类型', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.lightOnSurfaceVariant, letterSpacing: 0.5)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: [
                                _buildTypeChip('现金', 'cash', Icons.payments, selectedType, (v) { setModalState(() => selectedType = v); }),
                                _buildTypeChip('银行卡', 'bank', Icons.account_balance, selectedType, (v) { setModalState(() => selectedType = v); }),
                                _buildTypeChip('支付宝', 'alipay', Icons.account_balance_wallet, selectedType, (v) { setModalState(() => selectedType = v); }),
                                _buildTypeChip('微信', 'wechat', Icons.chat, selectedType, (v) { setModalState(() => selectedType = v); }),
                                _buildTypeChip('信用卡', 'credit', Icons.credit_card, selectedType, (v) { setModalState(() => selectedType = v); }),
                              ],
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
                              final name = nameController.text.trim();
                              if (name.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入账户名称'))); return; }
                              final balance = double.tryParse(balanceController.text) ?? 0.0;
                              final db = AppDatabase();
                              await db.updateAccount(account['id'] as int, {'name': name, 'type': selectedType, 'balance': balance});
                              Navigator.pop(context);
                              _refreshData(ref);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('账户更新成功')));
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
    final color = _getTypeColor(value);
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? color : AppColors.lightOnSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'cash': return const Color(0xFFF59E0B);
      case 'bank': return const Color(0xFF3B82F6);
      case 'alipay': return const Color(0xFF06B6D4);
      case 'wechat': return const Color(0xFF10B981);
      case 'credit': return const Color(0xFFEF4444);
      default: return AppColors.lightPrimary;
    }
  }

  Widget _buildRoundedInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    String prefix = '',
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.lightOnSurfaceVariant, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
