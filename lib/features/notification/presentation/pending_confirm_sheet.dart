import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../app/di/providers.dart';
import '../../../core/services/payment_notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/utils/category_icon_utils.dart';
import '../../../shared/utils/icon_utils.dart';
import '../domain/category_matcher.dart';

/// 待确认支付 — 确认记账底部弹窗
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
  late TextEditingController _merchantController;
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
    final parsedGoods = widget.data['goods'] as String? ?? '';
    final parsedNote = widget.data['note'] as String? ?? '';
    _merchantController = TextEditingController(text: parsedGoods.isNotEmpty ? parsedGoods : _merchant);
    _noteController = TextEditingController(text: parsedNote.isNotEmpty ? parsedNote : _rawText);
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════
  // 来源 → 名称/颜色 映射
  // ═══════════════════════════════════════════════

  String _sourceName(String source) {
    const names = {
      'wechat': '微信支付', 'alipay': '支付宝', 'cmb': '招商银行',
      'icbc': '工商银行', 'boc': '中国银行', 'abc': '农业银行',
      'ccb': '建设银行', 'psbc': '邮储银行', 'pingan': '平安银行',
      'citic': '中信银行', 'cmbc': '民生银行', 'xm': '厦门银行',
    };
    return names[source] ?? source;
  }

  Color _sourceColor(String source) {
    switch (source) {
      case 'wechat': return const Color(0xFF07C160);
      case 'alipay': return const Color(0xFF1677FF);
      case 'cmb': return const Color(0xFFDC143C);
      case 'citic': return const Color(0xFFE60012);
      case 'icbc': return const Color(0xFFC1232C);
      case 'boc': return const Color(0xFFC8102E);
      case 'abc': return const Color(0xFF377E22);
      case 'ccb': return const Color(0xFF003D88);
      case 'psbc': return const Color(0xFF00A650);
      case 'pingan': return const Color(0xFF007BFF);
      case 'cmbc': return const Color(0xFF0059B3);
      case 'xm': return const Color(0xFF8B4513);
      default: return AppColors.lightPrimary;
    }
  }

  IconData _sourceIcon(String source) {
    switch (source) {
      case 'wechat': return FontAwesomeIcons.weixin;
      case 'alipay': return FontAwesomeIcons.alipay;
      default: return FontAwesomeIcons.buildingColumns;
    }
  }

  IconData _getAccountIcon(String type) {
    switch (type) {
      case 'cash': return FontAwesomeIcons.moneyBill;
      case 'bank': return FontAwesomeIcons.buildingColumns;
      case 'alipay': return FontAwesomeIcons.alipay;
      case 'wechat': return FontAwesomeIcons.weixin;
      default: return FontAwesomeIcons.wallet;
    }
  }

  // ═══════════════════════════════════════════════
  // 构建
  // ═══════════════════════════════════════════════

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

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.72),
      child: Container(
        padding: EdgeInsets.fromLTRB(0, 0, 0, bottomInset + bottomPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 拖拽手柄 ──
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightOutline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ═══════════════════════════════════
                    // 金额区
                    // ═══════════════════════════════════
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _sourceColor(_source).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(_sourceIcon(_source), size: 24, color: _sourceColor(_source)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_isExpense ? '-' : '+'}¥${_amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: _isExpense ? AppColors.expense : AppColors.income,
                                ),
                              ),
                              if (_merchant.isNotEmpty)
                                Text(
                                  _merchant,
                                  style: TextStyle(fontSize: 13, color: AppColors.lightOnSurfaceVariant),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        _buildSourceBadge(),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ═══════════════════════════════════
                    // 分类选择 — 网格布局（3行完整展示）
                    // ═══════════════════════════════════
                    _buildSectionLabel('分类'),
                    const SizedBox(height: 10),
                    categoriesAsync.when(
                      loading: () => const SizedBox(height: 180),
                      error: (_, __) => const SizedBox(height: 180),
                      data: (categories) => LayoutBuilder(
                        builder: (ctx, constraints) {
                          final cardW = (constraints.maxWidth - 8 * 3) / 4;
                          final rows = (categories.length / 4).ceil();
                          final gridH = rows * (cardW * 0.85 + 4) + (rows - 1) * 8;
                          return SizedBox(
                            height: gridH.clamp(0, 230),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: categories.map((cat) {
                                final catName = cat['name'] as String;
                                final isSelected = _selectedCategoryId == cat['id'];
                                final catIconInfo = CategoryIconUtils.getCategoryIcon(catName, isExpense: _isExpense);
                                final catColor = catIconInfo?.color ?? Color(cat['color'] as int);
                                final iconData = catIconInfo?.icon ?? IconUtils.fromName(cat['icon'] as String?);

                                return GestureDetector(
                                  onTap: () => setState(() => _selectedCategoryId = cat['id'] as int),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: cardW,
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? catColor.withValues(alpha: 0.12)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          iconData,
                                          size: 22,
                                          color: catColor,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          catName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                            color: isSelected
                                                ? catColor
                                                : AppColors.lightOnSurfaceVariant,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ═══════════════════════════════════
                    // 账户选择 — 标签网格（无边框，带背景色）
                    // ═══════════════════════════════════
                    _buildSectionLabel('账户'),
                    const SizedBox(height: 10),
                    accountsAsync.when(
                      loading: () => const SizedBox(height: 80),
                      error: (_, __) => const SizedBox(height: 80),
                      data: (accounts) {
                        final filtered = accounts.where((a) => !(a['type'] as String? ?? '').startsWith('loan')).toList();
                        return ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 100),
                          child: filtered.length <= 6
                              ? _buildAccountGrid(filtered)
                              : SingleChildScrollView(
                                  child: _buildAccountGrid(filtered),
                                ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // ═══════════════════════════════════
                    // 商户
                    // ═══════════════════════════════════
                    _buildSectionLabel('商户'),
                    const SizedBox(height: 8),
                    _buildRoundedInput(
                      hint: '商户名称...',
                      controller: _merchantController,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 14),

                    // ═══════════════════════════════════
                    // 备注
                    // ═══════════════════════════════════
                    _buildSectionLabel('备注'),
                    const SizedBox(height: 8),
                    _buildRoundedInput(
                      hint: '添加备注...',
                      controller: _noteController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),

                  ],
                ),
              ),
            ),
            // ═══════════════════════════════════
            // 固定底部操作按钮（不随滚动）
            // ═══════════════════════════════════
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSurface
                    : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkOutline
                        : const Color(0xFFF0EBF5),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // 忽略
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => _ignore(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          side: BorderSide(color: AppColors.lightOutline),
                        ),
                        child: Text(
                          '忽略',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.lightOnSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // 确认记账
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            colors: [AppColors.warmYellow, AppColors.warmYellowDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.warmYellow.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: (_selectedCategoryId != null && _selectedAccountId != null)
                              ? () => _confirm(context)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: Text(
                            '确认记账',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: (_selectedCategoryId != null && _selectedAccountId != null)
                                  ? AppColors.warmYellowText
                                  : Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // 子组件
  // ═══════════════════════════════════════════════

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.lightOnSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSourceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _sourceColor(_source).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _sourceColor(_source).withValues(alpha: 0.2), width: 0.5),
      ),
      child: Text(
        _sourceName(_source),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _sourceColor(_source),
        ),
      ),
    );
  }

  Widget _buildRoundedInput({
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: 15,
        height: 1.5,
        color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 15, color: AppColors.lightTextTertiary),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildAccountGrid(List<Map<String, dynamic>> accounts) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: accounts.map((acc) {
        final isSelected = _selectedAccountId == acc['id'];
        final accColor = Color(acc['color'] as int);
        final accType = acc['type'] as String? ?? '';
        final accIcon = _getAccountIcon(accType);

        return GestureDetector(
          onTap: () => setState(() => _selectedAccountId = acc['id'] as int),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? accColor.withValues(alpha: 0.2)
                  : accColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  accIcon,
                  size: 14,
                  color: isSelected ? accColor : accColor.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    acc['name'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? accColor : AppColors.lightOnSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════
  // 逻辑
  // ═══════════════════════════════════════════════

  Future<void> _initDefaults() async {
    final db = ref.read(appDatabaseProvider);

    if (_selectedAccountId == null) {
      final accountId = await db.getDefaultAccountBySource(_source);
      if (accountId != null && mounted) {
        setState(() => _selectedAccountId = accountId);
      }
    }

    if (_selectedCategoryId == null) {
      final categories = _isExpense
          ? await db.getCategories(isExpense: true)
          : await db.getCategories(isExpense: false);
      if (categories.isNotEmpty && mounted) {
        int? matchedId;
        final goodsText = _merchantController.text.trim();
        if (goodsText.isNotEmpty) {
          matchedId = _matchCategoryByKeywords(goodsText, categories);
        }
        if (matchedId == null && _merchant.isNotEmpty) {
          matchedId = _matchCategoryByKeywords(_merchant, categories);
        }
        if (matchedId != null) {
          setState(() => _selectedCategoryId = matchedId);
        } else {
          final otherCat = categories.firstWhere(
            (c) => c['name'] == '其他',
            orElse: () => categories.last,
          );
          setState(() => _selectedCategoryId = otherCat['id'] as int);
        }
      }
    }
  }

  int? _matchCategoryByKeywords(String text, List<Map<String, dynamic>> categories) {
    return matchCategoryByKeywords(text, categories);
  }

  Future<void> _confirm(BuildContext context) async {
    if (_selectedCategoryId == null || _selectedAccountId == null) return;

    final db = ref.read(appDatabaseProvider);
    final pendingId = widget.data['id'] as int?;

    await db.insertTransaction({
      'amount': _amount,
      'is_expense': _isExpense ? 1 : 0,
      'goods': _merchantController.text.trim(),
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

  Future<void> _ignore(BuildContext context) async {
    final pendingId = widget.data['id'] as int?;
    if (pendingId != null) {
      await PaymentNotificationService().deletePayment(pendingId);
    }
    if (context.mounted) {
      Navigator.pop(context, 'ignore');
    }
  }
}
