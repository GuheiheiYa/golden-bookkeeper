import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/theme_mode_toggle.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../core/services/notification_service.dart';
import '../../account/presentation/account_list_screen.dart';
import '../../category/presentation/category_list_screen.dart';
import '../../tag/presentation/tag_list_screen.dart';
import '../../budget/presentation/budget_screen.dart';
import '../../recurring/presentation/recurring_screen.dart';
import '../../import/presentation/import_screen.dart';
import '../../loan/presentation/loan_list_screen.dart';
import '../../settings/presentation/settings_screen.dart' show ExportDialogContent;
import '../../notification/presentation/pending_notifications_screen.dart';
import '../../notification/presentation/notification_settings_screen.dart';
import '../../ai/presentation/ai_assistant_screen.dart';
import '../../ai/presentation/ai_config_screen.dart';
import 'profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final assetAsync = ref.watch(assetSummaryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 120),
        children: [
          // 顶部栏
          _buildHeaderRow(context, ref),
          const SizedBox(height: 24),

          // 头像区
          _buildAvatarSection(context, ref, profile),
          const SizedBox(height: 20),

          // 等级进度条
          _buildLevelProgress(context, profile),
          const SizedBox(height: 24),

          // 资产卡片
          _buildAssetCards(context, assetAsync),
          const SizedBox(height: 24),

          // 荣誉室
          _buildAchievementSection(context),
          const SizedBox(height: 24),

          // ========== 设置区块 ==========
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
          _buildNavCard(
            context, icon: Icons.real_estate_agent_rounded, iconColor: 0xFFEF4444,
            title: '贷款管理', subtitle: '管理贷款和负债',
            onTap: () => _navigateTo(context, const LoanListScreen()),
          ).animate().fadeIn(delay: 250.ms, duration: 300.ms),
          const SizedBox(height: 16),

          // 导入导出
          _buildSectionHeader(context, '导入导出'),
          _buildNavCard(
            context, icon: Icons.file_download_rounded, iconColor: 0xFF10B981,
            title: '账单导入', subtitle: '从微信/支付宝导入账单',
            onTap: () => _navigateTo(context, const ImportScreen()),
          ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
          _buildNavCard(
            context, icon: Icons.file_upload_rounded, iconColor: 0xFF06B6D4,
            title: '数据导出', subtitle: '导出为 CSV 或 Excel',
            onTap: () => _showExportDialog(context, ref),
          ).animate().fadeIn(delay: 350.ms, duration: 300.ms),
          const SizedBox(height: 16),

          // 智能记账
          _buildSectionHeader(context, '智能记账'),
          _buildNavCard(
            context, icon: Icons.notifications_active_rounded, iconColor: 0xFF8B5CF6,
            title: '支付通知监听', subtitle: '自动识别微信/支付宝支付通知',
            onTap: () => _navigateTo(context, const NotificationSettingsScreen()),
          ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
          _buildNavCard(
            context, icon: Icons.auto_awesome_rounded, iconColor: 0xFFF59E0B,
            title: '智能助手', subtitle: 'AI 分析账单给出理财建议',
            onTap: () => _navigateTo(context, const AiAssistantScreen(), rootNavigator: true),
          ).animate().fadeIn(delay: 420.ms, duration: 300.ms),
          _buildNavCard(
            context, icon: Icons.tune_rounded, iconColor: 0xFF10B981,
            title: 'AI 配置', subtitle: '设置 API Key 和模型参数',
            onTap: () => _navigateTo(context, const AiConfigScreen(), rootNavigator: true),
          ).animate().fadeIn(delay: 440.ms, duration: 300.ms),
          const SizedBox(height: 16),

          // 高级功能
          _buildSectionHeader(context, '高级功能'),
          _buildNavCard(
            context, icon: Icons.pie_chart_rounded, iconColor: 0xFFEC4899,
            title: '预算管理', subtitle: '设置和跟踪预算',
            onTap: () => _navigateTo(context, const BudgetScreen()),
          ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
          _buildNavCard(
            context, icon: Icons.repeat_rounded, iconColor: 0xFFF97316,
            title: '周期记账', subtitle: '自动记录固定收支',
            onTap: () => _navigateTo(context, const RecurringScreen()),
          ).animate().fadeIn(delay: 550.ms, duration: 300.ms),
          const SizedBox(height: 16),

          // 关于
          _buildSectionHeader(context, '关于'),
          _buildInfoCard(context, icon: Icons.info_outline_rounded, iconColor: AppColors.lightPrimary, title: '版本', trailing: const Text('1.10.0', style: TextStyle(fontSize: 14))).animate().fadeIn(delay: 600.ms, duration: 300.ms),
          _buildInfoCard(context, icon: Icons.description_rounded, iconColor: AppColors.secondary, title: '用户协议', onTap: () {}).animate().fadeIn(delay: 620.ms, duration: 300.ms),
          _buildInfoCard(context, icon: Icons.privacy_tip_rounded, iconColor: AppColors.info, title: '隐私政策', onTap: () {}).animate().fadeIn(delay: 640.ms, duration: 300.ms),
        ],
      ),
    );
  }

  // ========== 顶部栏 ==========

  Widget _buildHeaderRow(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingNotificationCountProvider);
    final pendingCount = pendingAsync.valueOrNull ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 待确认记账（替代档案中心）
        GestureDetector(
          onTap: () => _navigateTo(context, const PendingNotificationsScreen()),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      '待确认记账',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (pendingCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$pendingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // 通知图标
        GestureDetector(
          onTap: () => NotificationService.showNotificationList(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  // ========== 头像区 ==========

  Widget _buildAvatarSection(BuildContext context, WidgetRef ref, UserProfile profile) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickAvatar(ref),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4A574), width: 3),
                ),
                child: CircleAvatar(
                  radius: 37,
                  backgroundColor: AppColors.lightPrimary.withValues(alpha: 0.15),
                  backgroundImage: profile.avatarPath != null
                      ? FileImage(File(profile.avatarPath!))
                      : null,
                  child: profile.avatarPath == null
                      ? Icon(
                          Icons.person_rounded,
                          size: 40,
                          color: AppColors.lightPrimary,
                        )
                      : null,
                ),
              ),
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 14,
                    color: AppColors.lightPrimary,
                  ),
                ),
              ),
              Positioned(
                right: -4,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Lv.${profile.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => _showEditNameDialog(context, ref, profile),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                profile.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.edit_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          profile.subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  // ========== 等级进度条 ==========

  Widget _buildLevelProgress(BuildContext context, UserProfile profile) {
    final progress = profile.xp / profile.xpTarget;
    final remaining = profile.xpTarget - profile.xp;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 18),
              const SizedBox(width: 6),
              Text(
                'Lv.${profile.level}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${profile.xp}/${profile.xpTarget} XP',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF22C55E),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '距升职 Lv.${profile.level + 1} 还需要 $remaining 笔健康记账',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 300.ms);
  }

  // ========== 资产卡片（3 个并排小卡片） ==========

  Widget _buildAssetCards(BuildContext context, AsyncValue<AssetSummary> assetAsync) {
    return assetAsync.when(
      loading: () => const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SizedBox(
        height: 90,
        child: Center(child: Text('加载失败: $e')),
      ),
      data: (asset) => Row(
        children: [
          Expanded(
            child: _buildSmallAssetCard(
              context,
              title: '总资产',
              amount: asset.totalAssets,
              color: const Color(0xFF22C55E),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSmallAssetCard(
              context,
              title: '净资产',
              amount: asset.netAssets,
              color: AppColors.lightPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSmallAssetCard(
              context,
              title: '负债',
              amount: asset.liabilities,
              color: const Color(0xFFEF4444),
            ),
          ),
        ],
      ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildSmallAssetCard(
    BuildContext context, {
    required String title,
    required double amount,
    required Color color,
  }) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.formatCompact(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ========== 荣誉室 ==========

  Widget _buildAchievementSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '镇长荣誉室',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                '查看全部 >',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.lightPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '已解锁 1 项',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _achievements.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final achievement = _achievements[index];
              return _buildAchievementCard(context, achievement);
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 250.ms, duration: 300.ms);
  }

  Widget _buildAchievementCard(BuildContext context, _Achievement achievement) {
    final isUnlocked = achievement.unlocked;

    return Container(
      width: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnlocked
            ? achievement.color.withValues(alpha: 0.08)
            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? achievement.color.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? achievement.color.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              achievement.icon,
              size: 24,
              color: isUnlocked ? achievement.color : Colors.grey.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            achievement.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? null : Colors.grey.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            isUnlocked ? achievement.desc : '未解锁',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ========== 设置区块方法 ==========

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

  Widget _buildThemeTile(BuildContext context, WidgetRef ref, ThemeMode themeMode) {
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
                themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
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

  void _navigateTo(BuildContext context, Widget screen, {bool rootNavigator = false}) {
    Navigator.of(context, rootNavigator: rootNavigator).push(PageRouteBuilder(
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

  Future<void> _pickAvatar(WidgetRef ref) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image != null) {
      ref.read(userProfileProvider.notifier).updateAvatar(image.path);
    }
  }

  void _showEditNameDialog(BuildContext context, WidgetRef ref, UserProfile profile) {
    final controller = TextEditingController(text: profile.name);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 12,
          decoration: const InputDecoration(
            hintText: '输入新昵称',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('昵称不能为空')),
                );
                return;
              }
              ref.read(userProfileProvider.notifier).updateName(newName);
              Navigator.pop(dialogContext);
              messenger.showSnackBar(
                const SnackBar(content: Text('昵称已更新')),
              );
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ExportDialogContent(ref: ref),
    );
  }
}

// ========== 成就数据 ==========

class _Achievement {
  final String name;
  final String desc;
  final IconData icon;
  final Color color;
  final bool unlocked;

  const _Achievement({
    required this.name,
    required this.desc,
    required this.icon,
    required this.color,
    this.unlocked = false,
  });
}

const _achievements = [
  _Achievement(
    name: '魅力之星',
    desc: '记录超过100笔',
    icon: Icons.favorite_rounded,
    color: Color(0xFFFF6B9D),
    unlocked: true,
  ),
  _Achievement(
    name: '预算卫士',
    desc: '连续3月不超支',
    icon: Icons.shield_rounded,
    color: Color(0xFF3B82F6),
  ),
  _Achievement(
    name: '储蓄新星',
    desc: '月结余超过5000',
    icon: Icons.savings_rounded,
    color: Color(0xFFFBBF24),
  ),
  _Achievement(
    name: '记账达人',
    desc: '连续记账30天',
    icon: Icons.local_fire_department_rounded,
    color: Color(0xFFF97316),
  ),
  _Achievement(
    name: '分类大师',
    desc: '使用所有分类记账',
    icon: Icons.category_rounded,
    color: Color(0xFF8B5CF6),
  ),
];
