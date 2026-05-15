import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// 主题模式切换组件（自定义 pill 风格，替代 Material SegmentedButton）
class ThemeModeToggle extends StatelessWidget {
  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;

  const ThemeModeToggle({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        _buildItem(ThemeMode.system, Icons.phone_android_rounded, '跟随系统', isDark),
        const SizedBox(width: 8),
        _buildItem(ThemeMode.light, Icons.light_mode_rounded, '浅色', isDark),
        const SizedBox(width: 8),
        _buildItem(ThemeMode.dark, Icons.dark_mode_rounded, '深色', isDark),
      ],
    );
  }

  Widget _buildItem(ThemeMode mode, IconData icon, String label, bool isDark) {
    final isSelected = selected == mode;
    return GestureDetector(
      onTap: () => onChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightPrimary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.lightPrimary : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.lightPrimary : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
