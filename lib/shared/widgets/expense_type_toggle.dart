import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// 收支类型切换组件（自定义 pill 风格，替代 Material SegmentedButton）
class ExpenseTypeToggle extends StatelessWidget {
  final bool isExpense;
  final ValueChanged<bool> onChanged;

  const ExpenseTypeToggle({super.key, required this.isExpense, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildItem(true, '支出', isDark),
        const SizedBox(width: 8),
        _buildItem(false, '收入', isDark),
      ],
    );
  }

  Widget _buildItem(bool value, String label, bool isDark) {
    final isSelected = isExpense == value;
    final accentColor = value ? AppColors.expense : AppColors.income;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? accentColor : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
