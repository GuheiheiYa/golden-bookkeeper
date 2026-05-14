import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/payment_notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';

/// 支付通知监听设置页
///
/// 功能：
/// - 显示通知监听权限状态（已开启 / 未开启）
/// - 引导用户前往系统设置授权
/// - 提供 10 个支持的支付 APP 开关，控制哪些 APP 的通知需要监听
/// - 展示使用说明
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final _service = PaymentNotificationService();
  bool _isPermissionEnabled = false;
  List<String> _watchedPackages = [];

  /// 支持的支付 APP 包名与显示名称映射
  static const _allPackages = <String, String>{
    'com.tencent.mm': '微信',
    'com.eg.android.AlipayGphone': '支付宝',
    'cmb.pb': '招商银行',
    'com.icbc': '工商银行',
    'com.chinamworld.bocmbci': '中国银行',
    'com.abchina.abc': '农业银行',
    'com.ccb.start': '建设银行',
    'com.yitong.mbank.psbc': '邮储银行',
    'com.pingan.pacemaker': '平安银行',
    'com.ecitic.bank.mobile': '中信银行',
    'com.citiccard.mobilebank': '中信信用卡',
    'cn.com.cmbc.newmbank': '民生银行',
    'com.csii.xm': '厦门银行',
  };

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  /// 加载权限状态和监听 APP 列表
  Future<void> _loadStatus() async {
    final enabled = await _service.isPermissionEnabled();
    final packages = await _service.getWatchedPackages();
    if (mounted) {
      setState(() {
        _isPermissionEnabled = enabled;
        _watchedPackages = packages;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('支付通知监听', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 权限状态卡片
          AppCard(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (_isPermissionEnabled
                                ? AppColors.success
                                : AppColors.warning)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _isPermissionEnabled
                            ? Icons.check_circle
                            : Icons.warning_amber_rounded,
                        color: _isPermissionEnabled
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isPermissionEnabled ? '监听已开启' : '监听未开启',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isPermissionEnabled
                                ? '正在监听支付通知'
                                : '需要在系统设置中授权通知访问',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!_isPermissionEnabled) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await _service.openPermissionSettings();
                      },
                      icon: const Icon(Icons.settings, size: 18),
                      label: const Text('前往系统设置授权'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.lightPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          // 使用说明
          AppCard(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '使用说明',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '开启后，应用将自动监听来自以下支付应用的推送通知，识别付款信息并存入待确认列表。\n\n'
                  '• 仅在检测到付款/收款通知时触发\n'
                  '• 需要你确认后才会记入账本\n'
                  '• 所有数据仅存储在本地',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

          // 监听应用列表
          Text(
            '监听应用',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.primaryOf(brightness),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          AppCard(
            margin: const EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.zero,
            child: Column(
              children: _allPackages.entries.map((entry) {
                final isEnabled = _watchedPackages.contains(entry.key);
                return Column(
                  children: [
                    if (entry != _allPackages.entries.first)
                      const Divider(height: 1, indent: 56),
                    SwitchListTile(
                      secondary: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 15),
                      ),
                      title: null,
                      value: isEnabled,
                      onChanged: (value) => _togglePackage(entry.key, value),
                      activeThumbColor: AppColors.lightPrimary,
                    ),
                  ],
                );
              }).toList(),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
        ],
      ),
    );
  }

  /// 切换指定 APP 的监听状态
  Future<void> _togglePackage(String packageName, bool enable) async {
    final packages = List<String>.from(_watchedPackages);
    if (enable) {
      if (!packages.contains(packageName)) packages.add(packageName);
    } else {
      packages.remove(packageName);
    }
    await _service.setWatchedPackages(packages);
    setState(() => _watchedPackages = packages);
  }
}
