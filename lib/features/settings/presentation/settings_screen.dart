import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../app/di/providers.dart';
import '../../../core/services/export_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../account/presentation/account_list_screen.dart';
import '../../category/presentation/category_list_screen.dart';
import '../../tag/presentation/tag_list_screen.dart';
import '../../budget/presentation/budget_screen.dart';
import '../../recurring/presentation/recurring_screen.dart';
import '../../import/presentation/import_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 外观设置
          _buildSectionHeader(context, '外观'),
          AppCard(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: _buildThemeTile(context, ref, themeMode),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 16),

          // 数据管理
          _buildSectionHeader(context, '数据管理'),
          AppCard(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildNavigationTile(
                  context,
                  icon: Icons.account_balance_wallet,
                  iconColor: 0xFFF59E0B,
                  title: '账户管理',
                  subtitle: '管理你的支付账户',
                  onTap: () => _navigateTo(context, const AccountListScreen()),
                ),
                const Divider(height: 1, indent: 56),
                _buildNavigationTile(
                  context,
                  icon: Icons.category,
                  iconColor: 0xFF3B82F6,
                  title: '分类管理',
                  subtitle: '自定义收支分类',
                  onTap: () => _navigateTo(context, const CategoryListScreen()),
                ),
                const Divider(height: 1, indent: 56),
                _buildNavigationTile(
                  context,
                  icon: Icons.label,
                  iconColor: 0xFF5EB8FF,
                  title: '标签管理',
                  subtitle: '管理交易标签',
                  onTap: () => _navigateTo(context, const TagListScreen()),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
          const SizedBox(height: 16),

          // 导入导出
          _buildSectionHeader(context, '导入导出'),
          AppCard(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildNavigationTile(
                  context,
                  icon: Icons.file_download,
                  iconColor: 0xFF10B981,
                  title: '账单导入',
                  subtitle: '从微信/支付宝导入账单',
                  onTap: () => _navigateTo(context, const ImportScreen()),
                ),
                const Divider(height: 1, indent: 56),
                _buildNavigationTile(
                  context,
                  icon: Icons.file_upload,
                  iconColor: 0xFF06B6D4,
                  title: '数据导出',
                  subtitle: '导出为 CSV 或 Excel',
                  onTap: () => _showExportDialog(context, ref),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
          const SizedBox(height: 16),

          // 高级功能
          _buildSectionHeader(context, '高级功能'),
          AppCard(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildNavigationTile(
                  context,
                  icon: Icons.account_balance,
                  iconColor: 0xFFEC4899,
                  title: '预算管理',
                  subtitle: '设置和跟踪预算',
                  onTap: () => _navigateTo(context, const BudgetScreen()),
                ),
                const Divider(height: 1, indent: 56),
                _buildNavigationTile(
                  context,
                  icon: Icons.repeat,
                  iconColor: 0xFFF97316,
                  title: '周期记账',
                  subtitle: '自动记录固定收支',
                  onTap: () => _navigateTo(context, const RecurringScreen()),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
          const SizedBox(height: 16),

          // 关于
          _buildSectionHeader(context, '关于'),
          AppCard(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text('版本'),
                  trailing: const Text('1.0.0'),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.description,
                      color: AppColors.secondary,
                    ),
                  ),
                  title: const Text('用户协议'),
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.privacy_tip,
                      color: AppColors.info,
                    ),
                  ),
                  title: const Text('隐私政策'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('主题模式'),
                  Text(
                    _getThemeModeText(themeMode),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.phone_android, size: 18),
                label: Text('跟随系统'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode, size: 18),
                label: Text('浅色'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode, size: 18),
                label: Text('深色'),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (modes) {
              ref.read(themeModeProvider.notifier).setTheme(modes.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.standard,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
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

  Widget _buildNavigationTile(
    BuildContext context, {
    required IconData icon,
    required int iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(iconColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Color(iconColor)),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  /// 显示导出对话框，支持选择时间范围和导出格式
  void _showExportDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _ExportDialogContent(ref: ref),
    );
  }
}

/// 导出对话框的独立 Stateful Widget
class _ExportDialogContent extends StatefulWidget {
  final WidgetRef ref;
  const _ExportDialogContent({required this.ref});

  @override
  State<_ExportDialogContent> createState() => _ExportDialogContentState();
}

class _ExportDialogContentState extends State<_ExportDialogContent> {
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
          Icon(Icons.file_upload, color: AppColors.primary),
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
              iconColor: AppColors.primary,
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
