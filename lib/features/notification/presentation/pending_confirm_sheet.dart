import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/di/providers.dart';
import '../../../core/services/payment_notification_service.dart';
import '../../../core/theme/app_colors.dart';

/// 待确认支付 — 确认记账底部弹窗
///
/// 从待确认列表页打开，允许用户在确认前编辑：
/// - 分类选择（横向滚动 FilterChip）
/// - 账户选择（横向滚动 FilterChip，自动匹配来源）
/// - 商品名（默认为商户名）
/// - 备注（默认为原始通知文本）
///
/// ## 返回值
/// - `'confirmed'` — 用户确认记账
/// - `'ignore'` — 用户选择忽略
class PendingConfirmSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;
  const PendingConfirmSheet({super.key, required this.data});

  @override
  ConsumerState<PendingConfirmSheet> createState() => _PendingConfirmSheetState();
}

class _PendingConfirmSheetState extends ConsumerState<PendingConfirmSheet> {
  late double _amount;
  late bool _isExpense;
  late String _source;
  late String _merchant;
  late String _rawText;

  int? _selectedCategoryId;
  int? _selectedAccountId;
  late TextEditingController _goodsController;
  late TextEditingController _noteController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _amount = (widget.data['amount'] as num?)?.toDouble() ?? 0;
    final rawExpense = widget.data['isExpense'] ?? widget.data['is_expense'] ?? 0;
    _isExpense = rawExpense == true || rawExpense == 1;
    _source = widget.data['source'] as String? ?? '';
    _merchant = widget.data['merchant'] as String? ?? '';
    _rawText = widget.data['rawText'] as String? ?? widget.data['raw_text'] as String? ?? '';
    _goodsController = TextEditingController(text: _merchant);
    _noteController = TextEditingController(text: _rawText);
  }

  @override
  void dispose() {
    _goodsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _initialized = true;
      _initDefaults();
    }

    final categoriesAsync = _isExpense
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 拖拽手柄
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightOutline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 金额 + 来源
            Row(
              children: [
                Text(
                  '${_isExpense ? '-' : '+'}¥${_amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: _isExpense ? AppColors.expense : AppColors.income,
                  ),
                ),
                const SizedBox(width: 12),
                _buildSourceTag(),
              ],
            ),
            if (_merchant.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _merchant,
                style: TextStyle(fontSize: 14, color: AppColors.lightOnSurfaceVariant),
              ),
            ],
            const SizedBox(height: 20),

            // 分类选择
            Text('分类', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.lightOnSurfaceVariant)),
            const SizedBox(height: 8),
            categoriesAsync.when(
              loading: () => const SizedBox(height: 40),
              error: (_, __) => const SizedBox(height: 40),
              data: (categories) => SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = _selectedCategoryId == cat['id'];
                    return FilterChip(
                      label: Text(cat['name'] as String, style: const TextStyle(fontSize: 13)),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedCategoryId = cat['id'] as int),
                      selectedColor: AppColors.lightPrimary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.lightPrimary,
                      showCheckmark: true,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 账户选择
            Text('账户', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.lightOnSurfaceVariant)),
            const SizedBox(height: 8),
            accountsAsync.when(
              loading: () => const SizedBox(height: 40),
              error: (_, __) => const SizedBox(height: 40),
              data: (accounts) {
                final filtered = accounts.where((a) => !(a['type'] as String? ?? '').startsWith('loan')).toList();
                return SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final acc = filtered[index];
                      final isSelected = _selectedAccountId == acc['id'];
                      return FilterChip(
                        label: Text(acc['name'] as String, style: const TextStyle(fontSize: 13)),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedAccountId = acc['id'] as int),
                        selectedColor: AppColors.lightPrimary.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.lightPrimary,
                        showCheckmark: true,
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 商品名
            Text('商品', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.lightOnSurfaceVariant)),
            const SizedBox(height: 8),
            TextField(
              controller: _goodsController,
              decoration: InputDecoration(
                hintText: '商品名称（可选）',
                filled: true,
                fillColor: AppColors.lightInputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),

            // 备注
            Text('备注', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.lightOnSurfaceVariant)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '备注信息（可选）',
                filled: true,
                fillColor: AppColors.lightInputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),

            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, 'ignore'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('忽略'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: (_selectedCategoryId != null && _selectedAccountId != null)
                        ? () => _confirm(context)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lightPrimary,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('确认记账'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceTag() {
    const names = {
      'wechat': '微信', 'alipay': '支付宝', 'cmb': '招商银行',
      'icbc': '工商银行', 'boc': '中国银行', 'abc': '农业银行',
      'ccb': '建设银行', 'psbc': '邮储银行', 'pingan': '平安银行', 'citic': '中信银行',
      'cmbc': '民生银行', 'xm': '厦门银行',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.lightPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        names[_source] ?? _source,
        style: TextStyle(fontSize: 12, color: AppColors.lightPrimary, fontWeight: FontWeight.w500),
      ),
    );
  }

  Future<void> _initDefaults() async {
    final db = ref.read(appDatabaseProvider);

    // 自动匹配账户
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

    await db.insertTransaction({
      'amount': _amount,
      'is_expense': _isExpense ? 1 : 0,
      'goods': _goodsController.text.trim(),
      'note': _noteController.text.trim(),
      'date': DateTime.now().toIso8601String(),
      'category_id': _selectedCategoryId!,
      'account_id': _selectedAccountId!,
      'currency': 'CNY',
      'exchange_rate': 1.0,
    });

    if (pendingId != null) {
      await PaymentNotificationService().markPaymentProcessed(pendingId);
    }

    final account = await db.getAccountById(_selectedAccountId!);
    if (account != null) {
      final balance = (account['balance'] as num?)?.toDouble() ?? 0;
      final newBalance = _isExpense ? balance - _amount : balance + _amount;
      await db.updateAccount(_selectedAccountId!, {'balance': newBalance});
    }

    ref.read(transactionRefreshProvider.notifier).state++;

    if (context.mounted) {
      Navigator.pop(context, 'confirmed');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('记账成功')));
    }
  }
}
