import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/di/providers.dart';
import '../../../core/services/payment_notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../domain/category_matcher.dart';
import 'pending_confirm_sheet.dart';

/// 待确认记账列表页
///
/// 展示所有由 PaymentNotificationListenerService 检测到、但用户尚未确认的支付记录。
///
/// ## 数据来源
/// 调用 [PaymentNotificationService.getPendingPayments] 从 Android 原生 SQLite
/// 的 pending_payments 表读取 status='pending' 的记录。
///
/// ## 用户操作
/// - **确认记账**：弹出 [PendingConfirmSheet]，可编辑分类、商品、备注后确认
/// - **忽略**：将记录标记为已处理，不再显示
/// - **全部确认**：自动为所有记录创建交易（"其他"分类 + 匹配账户）
/// - **清空**：删除所有待确认记录
///
/// ## 进入方式
/// 首页 → 个人中心 → "待确认记账"按钮（带角标）
class PendingNotificationsScreen extends ConsumerStatefulWidget {
  const PendingNotificationsScreen({super.key});

  @override
  ConsumerState<PendingNotificationsScreen> createState() =>
      _PendingNotificationsScreenState();
}

class _PendingNotificationsScreenState
    extends ConsumerState<PendingNotificationsScreen>
    with WidgetsBindingObserver {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    final service = PaymentNotificationService();
    final notifications = await service.getPendingPayments();
    if (mounted) {
      setState(() {
        _notifications = notifications;
        _loading = false;
      });
      ref.read(transactionRefreshProvider.notifier).state++;
    }
  }

  /// 格式化时间：相对时间 + 具体时刻
  String _formatTime(int? millis) {
    if (millis == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    final diff = DateTime.now().millisecondsSinceEpoch - millis;

    String relative;
    if (diff < 60000) {
      relative = '刚刚';
    } else if (diff < 3600000) {
      relative = '${(diff / 60000).floor()}分钟前';
    } else if (diff < 86400000) {
      relative = '${(diff / 3600000).floor()}小时前';
    } else {
      relative = '${(diff / 86400000).floor()}天前';
    }

    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$relative $hh:$mm';
  }

  /// 格式化通知日期（今天显示时间，其他日期显示月日+时间）
  String _formatDate(int? millis) {
    if (millis == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    final now = DateTime.now();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');

    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '今天 $hh:$mm';
    }
    return '${dt.month}/${dt.day} $hh:$mm';
  }

  IconData _sourceIcon(String source) {
    switch (source) {
      case 'wechat':
        return Icons.chat_bubble_rounded;
      case 'alipay':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.account_balance_rounded;
    }
  }

  Color _sourceColor(String source) {
    switch (source) {
      case 'wechat':
        return const Color(0xFF07C160);
      case 'alipay':
        return const Color(0xFF1677FF);
      default:
        return AppColors.lightPrimary;
    }
  }

  String _sourceName(String source) {
    const names = {
      'wechat': '微信支付',
      'alipay': '支付宝',
      'cmb': '招商银行',
      'icbc': '工商银行',
      'boc': '中国银行',
      'abc': '农业银行',
      'ccb': '建设银行',
      'psbc': '邮储银行',
      'pingan': '平安银行',
      'citic': '中信银行',
      'cmbc': '民生银行',
      'xm': '厦门银行',
    };
    return names[source] ?? source;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('待确认记账', style: TextStyle(color: Colors.white)),
        actions: [
          if (_notifications.isNotEmpty) ...[
            TextButton(
              onPressed: _clearAll,
              child: const Text('清空'),
            ),
            TextButton(
              onPressed: _confirmAll,
              child: const Text('全部确认'),
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const EmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: '暂无待确认记账',
                  subtitle: '检测到支付后会自动出现在这里',
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) =>
                        _buildCard(_notifications[index], isDark),
                  ),
                ),
    );
  }

  Widget _buildCard(Map<String, dynamic> notification, bool isDark) {
    final amount = (notification['amount'] as num?)?.toDouble() ?? 0;
    final rawExpense = notification['isExpense'] ?? notification['is_expense'];
    final isExpense = rawExpense == true || rawExpense == 1;
    final merchant = notification['merchant'] as String? ?? '';
    final source = notification['source'] as String? ?? '';
    final rawText = notification['rawText'] as String? ?? notification['raw_text'] as String? ?? '';
    final time = notification['timestamp'] as int? ?? notification['notification_time'] as int?;
    final title = notification['title'] as String? ?? '';

    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：来源图标 + 来源名/商户 + 日期
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _sourceColor(source).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_sourceIcon(source), size: 20, color: _sourceColor(source)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _sourceName(source),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'nid:${notification['notificationId'] ?? ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                        ),
                      ],
                    ),
                    if (merchant.isNotEmpty)
                      Text(
                        merchant,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDate(time),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant,
                    ),
                  ),
                  Text(
                    _formatTime(time),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 金额
          Text(
            '${isExpense ? '-' : '+'}¥${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: isExpense ? AppColors.expense : AppColors.income,
            ),
          ),

          // 通知标题（如果有且和商户不同）
          if (title.isNotEmpty && title != merchant) ...[
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // 原始通知文本
          if (rawText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                rawText,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightTextTertiary,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 14),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _ignore(notification['id'] as int),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('忽略'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () => _confirmOne(notification),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.lightPrimary,
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('确认记账'),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  /// 打开确认弹窗，允许用户编辑分类、商品、备注后确认记账
  Future<void> _confirmOne(Map<String, dynamic> notification) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PendingConfirmSheet(data: notification),
    );
    if (result == 'confirmed' || result == 'ignore') {
      _loadNotifications();
    }
  }

  Future<void> _ignore(int id) async {
    final service = PaymentNotificationService();
    await service.deletePayment(id);
    _loadNotifications();
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空所有'),
        content: const Text('确定要清空所有待确认的记账吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final service = PaymentNotificationService();
      await service.clearPendingPayments();
      _loadNotifications();
    }
  }

  Future<void> _confirmAll() async {
    final db = ref.read(appDatabaseProvider);
    final service = PaymentNotificationService();
    int confirmed = 0;

    for (final notification in _notifications) {
      final amount = (notification['amount'] as num?)?.toDouble() ?? 0;
      final rawExp = notification['isExpense'] ?? notification['is_expense'];
      final isExpense = rawExp == true || rawExp == 1;
      final source = notification['source'] as String? ?? '';
      final merchant = notification['merchant'] as String? ?? '';
      final rawText = notification['rawText'] as String? ?? notification['raw_text'] as String? ?? '';

      final accountId = await db.getDefaultAccountBySource(source);
      if (accountId == null) continue;

      final categories = isExpense
          ? await db.getCategories(isExpense: true)
          : await db.getCategories(isExpense: false);

      // 优先使用解析器提取的精确字段（如 CMB 解析器拆分的商品名和备注）
      final parsedGoods = notification['goods'] as String? ?? '';
      final parsedNote = notification['note'] as String? ?? '';

      // 自动匹配分类：先用 goods 匹配，再用 merchant 匹配，最后兜底"其他"
      int? matchedCategoryId;
      if (parsedGoods.isNotEmpty) {
        matchedCategoryId = matchCategoryByKeywords(parsedGoods, categories);
      }
      if (matchedCategoryId == null && merchant.isNotEmpty) {
        matchedCategoryId = matchCategoryByKeywords(merchant, categories);
      }
      final otherCat = categories.firstWhere(
        (c) => c['name'] == '其他',
        orElse: () => categories.isNotEmpty ? categories.last : {'id': 1},
      );
      final categoryId = matchedCategoryId ?? (otherCat['id'] as int);
      await db.insertTransaction({
        'amount': amount,
        'is_expense': isExpense ? 1 : 0,
        'goods': parsedGoods.isNotEmpty ? parsedGoods : merchant,
        'note': parsedNote.isNotEmpty ? parsedNote : rawText,
        'date': DateTime.now().toIso8601String(),
        'category_id': categoryId,
        'account_id': accountId,
        'currency': 'CNY',
        'exchange_rate': 1.0,
      });

      await service.markPaymentProcessed(notification['id'] as int);
      confirmed++;

      final account = await db.getAccountById(accountId);
      if (account != null) {
        final balance = (account['balance'] as num?)?.toDouble() ?? 0;
        final newBalance = isExpense ? balance - amount : balance + amount;
        await db.updateAccount(accountId, {'balance': newBalance});
      }
    }

    ref.read(transactionRefreshProvider.notifier).state++;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已确认 $confirmed 笔记账')),
      );
      _loadNotifications();
    }
  }
}
