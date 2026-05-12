import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/app_card.dart';
import '../../account/presentation/account_list_screen.dart';
import '../../category/presentation/category_list_screen.dart';
import '../../tag/presentation/tag_list_screen.dart';
import '../../budget/presentation/budget_screen.dart';
import '../../recurring/presentation/recurring_screen.dart';
import '../../import/presentation/import_screen.dart';
import '../../loan/presentation/loan_list_screen.dart';
import '../../settings/presentation/settings_screen.dart' show ExportDialogContent;
import 'profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final brightness = Theme.of(context).brightness;
    final assetAsync = ref.watch(assetSummaryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 120),
        children: [
          // 顶部栏
          _buildHeaderRow(context),
          const SizedBox(height: 24),

          // 头像区
          _buildAvatarSection(context, profile),
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
                const Divider(height: 1, indent: 56),
                _buildNavigationTile(
                  context,
                  icon: Icons.account_balance,
                  iconColor: 0xFFEF4444,
                  title: '贷款管理',
                  subtitle: '管理贷款和负债',
                  onTap: () => _navigateTo(context, const LoanListScreen()),
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
                      color: AppColors.primaryOf(brightness).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: AppColors.primaryOf(brightness),
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
                      color: AppColors.secondaryOf(brightness).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.description,
                      color: AppColors.secondaryOf(brightness),
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
        ],
      ),
    );
  }

  // ========== 顶部栏 ==========

  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_open, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text(
                '档案中心',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6B6B),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  // ========== 头像区 ==========

  Widget _buildAvatarSection(BuildContext context, UserProfile profile) {
    return Column(
      children: [
        Stack(
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
                backgroundColor: AppColors.lightPrimary.withOpacity(0.15),
                child: Icon(
                  Icons.person_rounded,
                  size: 40,
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
                      color: const Color(0xFF22C55E).withOpacity(0.3),
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
        const SizedBox(height: 14),
        Text(
          profile.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          profile.subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
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
              backgroundColor: Colors.grey.withOpacity(0.15),
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
            ? achievement.color.withOpacity(0.08)
            : Theme.of(context).colorScheme.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? achievement.color.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
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
                  ? achievement.color.withOpacity(0.15)
                  : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              achievement.icon,
              size: 24,
              color: isUnlocked ? achievement.color : Colors.grey.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            achievement.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? null : Colors.grey.withOpacity(0.6),
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

  // ========== 设置区块方法（复用自 settings_screen） ==========

  Widget _buildSectionHeader(BuildContext context, String title) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.primaryOf(brightness),
              fontWeight: FontWeight.w600,
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
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
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.lightPrimary.withOpacity(0.15);
                }
                return null;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.lightPrimaryDark;
                }
                return null;
              }),
              side: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return BorderSide(color: AppColors.lightPrimary.withOpacity(0.4));
                }
                return BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.3));
              }),
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
