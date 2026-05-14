import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/di/providers.dart';
import '../../../core/services/payment_notification_service.dart';
import '../../../core/theme/app_colors.dart';

/// 前台付款确认底部弹窗
///
/// 当 APP 处于前台且检测到支付通知时，由 [PaymentNotificationService.onPaymentDetected]
/// 回调触发，以 `showModalBottomSheet` 方式弹出。
///
/// ## 功能
/// - 展示检测到的金额、商户名、来源 APP
/// - 用户可选择分类和账户（支持左右滑动选择）
/// - 自动匹配：根据 source 匹配账户（wechat → 微信账户），根据关键词匹配"其他"分类
///
/// ## 数据来源
/// `data` 参数由 Android 端 PaymentNotificationListenerService 通过 MethodChannel 推送，
/// 包含字段：id, amount, isExpense, merchant, source, rawText, packageName, timestamp
///
/// ## 返回值
/// - `'confirmed'` — 用户确认记账
/// - `'ignore'` — 用户选择忽略
class PaymentConfirmSheet extends ConsumerStatefulWidget {
  /// 从 Android 端推送过来的支付检测数据
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
    // 兼容 Android 端可能传来的 bool / int / double 多种格式
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

  /// 自动匹配默认分类和账户
  ///
  /// 匹配策略：
  /// - 账户：根据 source 字段匹配（wechat → 微信账户，alipay → 支付宝账户）
  /// - 分类：默认选中"其他"分类（兜底策略，用户可手动切换）
  Future<void> _initDefaults() async {
    _initialized = true;
    final db = ref.read(appDatabaseProvider);

    // 根据来源自动匹配账户（wechat → 微信，alipay → 支付宝，cmb → 招商银行...）
    if (_selectedAccountId == null) {
      final accountId = await db.getDefaultAccountBySource(_source);
      if (accountId != null && mounted) {
        setState(() => _selectedAccountId = accountId);
      }
    }

    // 自动选中"其他"分类（兜底，用户可手动修改）
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

  /// 确认记账 — 创建交易记录并更新余额
  ///
  /// 流程：
  /// 1. 调用 db.insertTransaction() 写入交易记录
  /// 2. 调用 markPaymentProcessed() 将原生端 pending_payments 记录标记为已处理
  /// 3. 更新对应账户余额（支出 -amount，收入 +amount）
  /// 4. 通过 transactionRefreshProvider 刷新首页/明细页数据
  Future<void> _confirm(BuildContext context) async {
    if (_selectedCategoryId == null || _selectedAccountId == null) return;

    final db = ref.read(appDatabaseProvider);
    final pendingId = widget.data['id'] as int?;

    // 1. 创建交易记录到 Flutter 端数据库（sqflite）
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

    // 2. 标记原生端 pending_payments 记录为已处理（不再显示在待确认列表）
    if (pendingId != null) {
      await PaymentNotificationService().markPaymentProcessed(pendingId);
    }

    // 3. 更新账户余额
    final account = await db.getAccountById(_selectedAccountId!);
    if (account != null) {
      final balance = (account['balance'] as num?)?.toDouble() ?? 0;
      final newBalance = _isExpense ? balance - _amount : balance + _amount;
      await db.updateAccount(_selectedAccountId!, {'balance': newBalance});
    }

    // 4. 通知首页/明细页刷新数据
    ref.read(transactionRefreshProvider.notifier).state++;

    if (context.mounted) {
      Navigator.pop(context, 'confirmed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('记账成功')),
      );
    }
  }
}
