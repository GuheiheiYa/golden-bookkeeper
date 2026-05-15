import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../app/di/providers.dart';
import '../../../shared/widgets/theme_mode_toggle.dart';
import '../../../core/services/export_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../account/presentation/account_list_screen.dart';
import '../../category/presentation/category_list_screen.dart';
import '../../tag/presentation/tag_list_screen.dart';
import '../../budget/presentation/budget_screen.dart';
import '../../recurring/presentation/recurring_screen.dart';
import '../../import/presentation/import_screen.dart';
import '../../notification/presentation/notification_settings_screen.dart';
import '../../ai/presentation/ai_assistant_screen.dart';
import '../../ai/presentation/ai_config_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('设置', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 外观设置
          _buildSectionHeader(context, '外观'),
          AppCard(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: _buildThemeTile(context, ref, themeMode),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 16),

          // 数据管理
          _buildSectionHeader(context, '数据管理'),
          _buildNavCard(
            context, icon: Icons.account_balance_wallet_rounded, iconColor: 0xFFF59E0B,
            title: '账户管理', subtitle: '管理你的支付账户',
            onTap: () => _navigateTo(context, const AccountListScreen()),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
          _buildNavCard(
            context, icon: Icons.category_rounded, iconColor: 0xFF3B82F6,
            title: '分类管理', subtitle: '自定义收支分类',
            onTap: () => _navigateTo(context, const CategoryListScreen()),
          ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
          _buildNavCard(
            context, icon: Icons.label_rounded, iconColor: 0xFF8BB8E8,
            title: '标签管理', subtitle: '管理交易标签',
            onTap: () => _navigateTo(context, const TagListScreen()),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
          const SizedBox(height: 16),

          // 导入导出
          _buildSectionHeader(context, '导入导出'),
          _buildNavCard(
            context, icon: Icons.file_download_rounded, iconColor: 0xFF10B981,
            title: '账单导入', subtitle: '从微信/支付宝导入账单',
            onTap: () => _navigateTo(context, const ImportScreen()),
          ).animate().fadeIn(delay: 250.ms, duration: 300.ms),
          _buildNavCard(
            context, icon: Icons.file_upload_rounded, iconColor: 0xFF06B6D4,
            title: '数据导出', subtitle: '导出为 CSV 或 Excel',
            onTap: () => _showExportDialog(context, ref),
          ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
          const SizedBox(height: 16),

          // 智能记账
          _buildSectionHeader(context, '智能记账'),
          _buildNavCard(
            context, icon: Icons.notifications_active_rounded, iconColor: 0xFF8B5CF6,
            title: '支付通知监听', subtitle: '自动识别微信/支付宝支付通知',
            onTap: () => _navigateTo(context, const NotificationSettingsScreen()),
          ).animate().fadeIn(delay: 350.ms, duration: 300.ms),
          _buildNavCard(
            context, icon: Icons.auto_awesome_rounded, iconColor: 0xFFF59E0B,
            title: '智能助手', subtitle: 'AI 分析账单给出理财建议',
            onTap: () => _navigateTo(context, const AiAssistantScreen()),
          ).animate().fadeIn(delay: 370.ms, duration: 300.ms),
          _buildNavCard(
            context, icon: Icons.tune_rounded, iconColor: 0xFF10B981,
            title: 'AI 配置', subtitle: '设置 API Key 和模型参数',
            onTap: () => _navigateTo(context, const AiConfigScreen()),
          ).animate().fadeIn(delay: 390.ms, duration: 300.ms),
          const SizedBox(height: 16),

          // 高级功能
          _buildSectionHeader(context, '高级功能'),
          _buildNavCard(
            context, icon: Icons.pie_chart_rounded, iconColor: 0xFFEC4899,
            title: '预算管理', subtitle: '设置和跟踪预算',
            onTap: () => _navigateTo(context, const BudgetScreen()),
          ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
          _buildNavCard(
            context, icon: Icons.repeat_rounded, iconColor: 0xFFF97316,
            title: '周期记账', subtitle: '自动记录固定收支',
            onTap: () => _navigateTo(context, const RecurringScreen()),
          ).animate().fadeIn(delay: 450.ms, duration: 300.ms),
          const SizedBox(height: 16),

          // 关于
          _buildSectionHeader(context, '关于'),
          _buildInfoCard(context, icon: Icons.info_outline_rounded, iconColor: AppColors.lightPrimary, title: '版本', trailing: const Text('1.10.0', style: TextStyle(fontSize: 14))).animate().fadeIn(delay: 500.ms, duration: 300.ms),
          _buildInfoCard(context, icon: Icons.description_rounded, iconColor: AppColors.secondary, title: '用户协议', onTap: () {}).animate().fadeIn(delay: 520.ms, duration: 300.ms),
          _buildInfoCard(context, icon: Icons.privacy_tip_rounded, iconColor: AppColors.info, title: '隐私政策', onTap: () {}).animate().fadeIn(delay: 540.ms, duration: 300.ms),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNavCard(
    BuildContext context, {
    required IconData icon,
    required int iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightCard,
              borderRadius: BorderRadius.circular(28),
              border: isDark ? null : Border.all(color: AppColors.lightOutline, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.15) : AppColors.lightPrimary.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(iconColor).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Color(iconColor), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightCard,
              borderRadius: BorderRadius.circular(28),
              border: isDark ? null : Border.all(color: AppColors.lightOutline, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.15) : AppColors.lightPrimary.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeTile(
      BuildContext context, WidgetRef ref, ThemeMode themeMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: AppColors.warning,
                size: 21,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('主题模式', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  Text(
                    _getThemeModeText(themeMode),
                    style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ThemeModeToggle(
          selected: themeMode,
          onChanged: (mode) => ref.read(themeModeProvider.notifier).setTheme(mode),
        ),
      ],
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
    }
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.bgGradientTop,
              AppColors.bgGradientMid,
              AppColors.bgGradientBottom,
            ],
          ),
        ),
        child: screen,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ));
  }

  /// 显示导出对话框，支持选择时间范围和导出格式
  void _showExportDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ExportDialogContent(ref: ref),
    );
  }
}

/// 导出对话框的独立 Stateful Widget
class ExportDialogContent extends StatefulWidget {
  final WidgetRef ref;
  const ExportDialogContent({super.key, required this.ref});

  @override
  State<ExportDialogContent> createState() => ExportDialogContentState();
}

class ExportDialogContentState extends State<ExportDialogContent> {
  // 时间范围选项: 0=全部, 1=本月, 2=本年, 3=自定义
  int _timeRangeIndex = 0;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _isExporting = false;

  final ExportService _exportService = ExportService();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.file_upload, color: AppColors.primaryOf(Theme.of(context).brightness)),
          const SizedBox(width: 8),
          const Text('数据导出'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 时间范围选择
            Text(
              '选择时间范围',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildChip(0, '全部'),
                _buildChip(1, '本月'),
                _buildChip(2, '本年'),
                _buildChip(3, '自定义'),
              ],
            ),

            // 自定义日期范围
            if (_timeRangeIndex == 3) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      label: '开始日期',
                      date: _customStartDate,
                      onTap: () => _selectDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDatePicker(
                      label: '结束日期',
                      date: _customEndDate,
                      onTap: () => _selectDate(isStart: false),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // 导出格式选择
            Text(
              '选择导出格式',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),

            // CSV 导出按钮
            _buildExportOption(
              context,
              icon: Icons.table_chart,
              iconColor: AppColors.success,
              title: '导出为 CSV',
              subtitle: '通用格式，可用 Excel 打开',
              onTap: _isExporting ? null : () => _doExport(isExcel: false),
            ),

            const SizedBox(height: 8),

            // Excel 导出按钮
            _buildExportOption(
              context,
              icon: Icons.description,
              iconColor: AppColors.primaryOf(Theme.of(context).brightness),
              title: '导出为 Excel',
              subtitle: '带格式化的表格文件',
              onTap: _isExporting ? null : () => _doExport(isExcel: true),
            ),

            // 导出进度
            if (_isExporting) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '正在导出...',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }

  Widget _buildChip(int index, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _timeRangeIndex == index,
      onSelected: (_) => setState(() => _timeRangeIndex = index),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              date != null ? _dateFormat.format(date) : '点击选择',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.file_download,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_customStartDate ?? DateTime(now.year, now.month, 1))
        : (_customEndDate ?? now);
    final firstDate = DateTime(2020);
    final lastDate = DateTime(now.year + 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _customStartDate = picked;
        } else {
          _customEndDate = picked;
        }
      });
    }
  }

  /// 计算时间范围
  ({DateTime? start, DateTime? end}) _getDateRange() {
    final now = DateTime.now();
    switch (_timeRangeIndex) {
      case 1: // 本月
        return (
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case 2: // 本年
        return (
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        );
      case 3: // 自定义
        return (
          start: _customStartDate,
          end: _customEndDate != null
              ? DateTime(_customEndDate!.year, _customEndDate!.month,
                  _customEndDate!.day, 23, 59, 59)
              : null,
        );
      default: // 全部
        return (start: null, end: null);
    }
  }

  Future<void> _doExport({required bool isExcel}) async {
    // 自定义范围校验
    if (_timeRangeIndex == 3) {
      if (_customStartDate == null || _customEndDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请选择完整的日期范围')),
        );
        return;
      }
      if (_customStartDate!.isAfter(_customEndDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('开始日期不能晚于结束日期')),
        );
        return;
      }
    }

    setState(() => _isExporting = true);

    try {
      final db = widget.ref.read(appDatabaseProvider);
      final range = _getDateRange();

      // 获取交易数据
      final transactions = await db.getTransactions(
        startDate: range.start,
        endDate: range.end,
      );

      if (transactions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('该时间范围内没有交易记录')),
          );
          setState(() => _isExporting = false);
        }
        return;
      }

      // 生成文件名
      final fileName = _exportService.getDefaultFileName(
        startDate: range.start != null
            ? _exportService.formatDate(range.start!)
            : null,
        endDate:
            range.end != null ? _exportService.formatDate(range.end!) : null,
      );

      // 导出文件
      final file = isExcel
          ? await _exportService.exportToExcel(
              transactions: transactions, fileName: fileName)
          : await _exportService.exportToCsv(
              transactions: transactions, fileName: fileName);

      if (mounted) {
        // 关闭对话框
        Navigator.pop(context);

        // 显示成功提示并提供分享选项
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出成功，共 ${transactions.length} 条记录'),
            action: SnackBarAction(
              label: '分享',
              onPressed: () => _exportService.shareFile(file),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
        setState(() => _isExporting = false);
      }
    }
  }
}
