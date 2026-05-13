import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/di/providers.dart';
import '../../../core/services/payment_notification_service.dart';
import '../../../core/theme/app_colors.dart';

class PaymentConfirmSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;
  const PaymentConfirmSheet({super.key, required this.data});

  @override
  ConsumerState<PaymentConfirmSheet> createState() => _PaymentConfirmSheetState();
}

class _PaymentConfirmSheetState extends ConsumerState<PaymentConfirmSheet> {
  late double _amount;
  late bool _isExpense;
  String? _merchant;
  String _source = '';
  int? _selectedCategoryId;
  int? _selectedAccountId;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _amount = (widget.data['amount'] as num?)?.toDouble() ?? 0;
    // 兼容 bool / int / double 多种格式
    final rawExpense = widget.data['isExpense'] ?? widget.data['is_expense'] ?? 0;
    if (rawExpense is bool) {
      _isExpense = rawExpense;
    } else {
      _isExpense = (rawExpense as num).toInt() == 1;
    }
    _merchant = widget.data['merchant'] as String?;
    _source = widget.data['source'] as String? ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _initDefaults();
    }

    final categoriesAsync = _isExpense
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽指示条
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // 金额
          Text(
            '${_isExpense ? '-' : '+'}¥${_amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: _isExpense ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
            ),
          ),
          const SizedBox(height: 8),

          // 来源和商户
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSourceTag(),
              if (_merchant != null && _merchant!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  _merchant!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // 分类选择
          categoriesAsync.when(
            loading: () => const SizedBox(height: 48),
            error: (_, __) => const SizedBox(height: 48),
            data: (categories) {
              return SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = _selectedCategoryId == cat['id'];
                    return FilterChip(
                      label: Text(cat['name'] as String),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedCategoryId = cat['id'] as int),
                      selectedColor: AppColors.lightPrimary.withOpacity(0.15),
                      checkmarkColor: AppColors.lightPrimary,
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // 账户选择
          accountsAsync.when(
            loading: () => const SizedBox(height: 48),
            error: (_, __) => const SizedBox(height: 48),
            data: (accounts) {
              final filteredAccounts = accounts
                  .where((a) => !(a['type'] as String? ?? '').startsWith('loan'))
                  .toList();
              return SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filteredAccounts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final acc = filteredAccounts[index];
                    final isSelected = _selectedAccountId == acc['id'];
                    return FilterChip(
                      label: Text(acc['name'] as String),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedAccountId = acc['id'] as int),
                      selectedColor: AppColors.lightPrimary.withOpacity(0.15),
                      checkmarkColor: AppColors.lightPrimary,
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, 'ignore'),
                  child: const Text('忽略'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: (_selectedCategoryId != null && _selectedAccountId != null)
                      ? () => _confirm(context)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.lightPrimary,
                  ),
                  child: const Text('确认记账'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourceTag() {
    final sourceNames = {
      'wechat': '微信支付',
      'alipay': '支付宝',
      'cmb': '招商银行',
      'icbc': '工商银行',
      'boc': '中国银行',
      'abc': '农业银行',
      'ccb': '建设银行',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.lightPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        sourceNames[_source] ?? _source,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.lightPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _initDefaults() async {
    _initialized = true;
    final db = ref.read(appDatabaseProvider);

    // 根据来源自动匹配账户
    if (_selectedAccountId == null) {
      final accountId = await db.getDefaultAccountBySource(_source);
      if (accountId != null && mounted) {
        setState(() => _selectedAccountId = accountId);
      }
    }

    // 自动选中"其他"分类
    if (_selectedCategoryId == null) {
      final categories = _isExpense
          ? await db.getCategories(isExpense: true)
          : await db.getCategories(isExpense: false);
      if (categories.isNotEmpty && mounted) {
        final otherCat = categories.firstWhere(
          (c) => c['name'] == '其他',
          orElse: () => categories.last,
        );
        setState(() => _selectedCategoryId = otherCat['id'] as int);
      }
    }
  }

  Future<void> _confirm(BuildContext context) async {
    if (_selectedCategoryId == null || _selectedAccountId == null) return;

    final db = ref.read(appDatabaseProvider);
    final pendingId = widget.data['id'] as int?;

    // 创建交易记录
    await db.insertTransaction({
      'amount': _amount,
      'is_expense': _isExpense ? 1 : 0,
      'note': _merchant,
      'date': DateTime.now().toIso8601String(),
      'category_id': _selectedCategoryId!,
      'account_id': _selectedAccountId!,
      'currency': 'CNY',
      'exchange_rate': 1.0,
    });

    // 标记原生 DB 中的通知为已处理
    if (pendingId != null) {
      await PaymentNotificationService().markPaymentProcessed(pendingId);
    }

    // 更新账户余额
    final account = await db.getAccountById(_selectedAccountId!);
    if (account != null) {
      final balance = (account['balance'] as num?)?.toDouble() ?? 0;
      final newBalance = _isExpense ? balance - _amount : balance + _amount;
      await db.updateAccount(_selectedAccountId!, {'balance': newBalance});
    }

    // 刷新数据
    ref.read(transactionRefreshProvider.notifier).state++;

    if (context.mounted) {
      Navigator.pop(context, 'confirmed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('记账成功')),
      );
    }
  }
}
