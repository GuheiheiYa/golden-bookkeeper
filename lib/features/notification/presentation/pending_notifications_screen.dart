import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/di/providers.dart';
import '../../../core/services/payment_notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import 'payment_confirm_sheet.dart';

/// 待确认记账列表页
///
/// 展示所有由 PaymentNotificationListenerService 检测到、但用户尚未确认的支付记录。
///
/// ## 数据来源
/// 调用 [PaymentNotificationService.getPendingPayments] 从 Android 原生 SQLite
/// 的 pending_payments 表读取 status='pending' 的记录。
///
/// ## 用户操作
/// - **确认记账**：弹出 [PaymentConfirmSheet] 让用户选择分类和账户，确认后创建交易记录
/// - **忽略**：将记录标记为已处理，不再显示
/// - **全部确认**：自动为所有记录创建交易（使用"其他"分类 + 匹配账户）
/// - **清空**：删除所有待确认记录
///
/// ## 进入方式
/// 1. 首页 → 个人中心 → "待确认记账"按钮（带角标）
/// 2. 用户点击支付检测系统通知 → 自动跳转到此页面
class PendingNotificationsScreen extends ConsumerStatefulWidget {
  const PendingNotificationsScreen({super.key});

  @override
  ConsumerState<PendingNotificationsScreen> createState() =>
      _PendingNotificationsScreenState();
}

class _PendingNotificationsScreenState
    extends ConsumerState<PendingNotificationsScreen>
    with WidgetsBindingObserver {
  /// 待确认的支付记录列表，每条包含：id/amount/isExpense/merchant/source/rawText/timestamp
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

  /// APP 从后台恢复时自动刷新列表（用户可能在系统通知中点击了其他 APP 后返回）
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadNotifications();
    }
  }

  /// 从 Android 原生 SQLite 加载待确认记录
  Future<void> _loadNotifications() async {
    final service = PaymentNotificationService();
    final notifications = await service.getPendingPayments();
    if (mounted) {
      setState(() {
        _notifications = notifications;
        _loading = false;
      });
      // 刷新首页/明细页数据（记录被处理后余额会变化）
      ref.read(transactionRefreshProvider.notifier).state++;
    }
  }

  String _timeAgo(int? millis) {
    if (millis == null) return '';
    final diff = DateTime.now().millisecondsSinceEpoch - millis;
    if (diff < 60000) return '刚刚';
    if (diff < 3600000) return '${(diff / 60000).floor()}分钟前';
    if (diff < 86400000) return '${(diff / 3600000).floor()}小时前';
    return '${(diff / 86400000).floor()}天前';
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
              ? EmptyState(
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
    // 原生 DB 返回 isExpense (bool)，兼容 is_expense (int)
    final rawExpense = notification['isExpense'] ?? notification['is_expense'];
    final isExpense = rawExpense == true || rawExpense == 1;
    final merchant = notification['merchant'] as String? ?? '';
    final source = notification['source'] as String? ?? '';
    final rawText = notification['raw_text'] as String? ?? '';
    final time = notification['notification_time'] as int?;

    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：来源 + 时间
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _sourceColor(source).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _sourceIcon(source),
                  size: 18,
                  color: _sourceColor(source),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _sourceName(source),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkOnBackground
                            : AppColors.lightOnBackground,
                      ),
                    ),
                    if (merchant.isNotEmpty)
                      Text(
                        merchant,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkOnSurfaceVariant
                              : AppColors.lightTextTertiary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Text(
                _timeAgo(time),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 金额
          Text(
            '${isExpense ? '-' : '+'}¥${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: isExpense
                  ? AppColors.expense
                  : AppColors.income,
            ),
          ),
          // 原始通知文本
          if (rawText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                rawText,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.lightTextTertiary,
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

  Future<void> _confirmOne(Map<String, dynamic> notification) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentConfirmSheet(data: notification),
    );
    if (result == 'confirmed' || result == 'ignore') {
      _loadNotifications();
    }
  }

  Future<void> _ignore(int id) async {
    final service = PaymentNotificationService();
    await service.markPaymentProcessed(id);
    _loadNotifications();
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空所有'),
        content: const Text('确定要清空所有待确认的记账吗？'),
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
      final merchant = notification['merchant'] as String?;

      final accountId = await db.getDefaultAccountBySource(source);
      if (accountId == null) continue;

      final categories = isExpense
          ? await db.getCategories(isExpense: true)
          : await db.getCategories(isExpense: false);
      final otherCat = categories.firstWhere(
        (c) => c['name'] == '其他',
        orElse: () => categories.isNotEmpty ? categories.last : {'id': 1},
      );
      final categoryId = otherCat['id'] as int;

      await db.insertTransaction({
        'amount': amount,
        'is_expense': isExpense ? 1 : 0,
        'note': merchant,
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
