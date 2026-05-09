import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/transaction/presentation/transaction_list_screen.dart';
import '../../features/transaction/presentation/add_transaction_screen.dart';
import '../../features/statistics/presentation/statistics_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (context, state) => const TransactionListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/statistics',
                builder: (context, state) => const StatisticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/add-transaction',
        builder: (context, state) => const AddTransactionScreen(),
      ),
      GoRoute(
        path: '/transaction/edit/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AddTransactionScreen(transactionId: id);
        },
      ),
    ],
  );
});

class MainScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomAppBar(
          height: 65,
          padding: EdgeInsets.zero,
          notchMargin: 8,
          shape: const CircularNotchedRectangle(),
          color: isDark ? AppColors.darkSurfaceVariant : theme.colorScheme.surface,
          elevation: isDark ? 8 : 2,
          shadowColor: Colors.black.withOpacity(isDark ? 0.45 : 0.12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 首页
              _buildNavItem(
                context,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: '首页',
                index: 0,
                isSelected: navigationShell.currentIndex == 0,
              ),
              // 明细
              _buildNavItem(
                context,
                icon: Icons.receipt_long_outlined,
                selectedIcon: Icons.receipt_long,
                label: '明细',
                index: 1,
                isSelected: navigationShell.currentIndex == 1,
              ),
              // 占位（中间留给记一笔按钮）
              const SizedBox(width: 60),
              // 统计
              _buildNavItem(
                context,
                icon: Icons.bar_chart_outlined,
                selectedIcon: Icons.bar_chart,
                label: '统计',
                index: 2,
                isSelected: navigationShell.currentIndex == 2,
              ),
              // 设置
              _buildNavItem(
                context,
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings,
                label: '设置',
                index: 3,
                isSelected: navigationShell.currentIndex == 3,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryLight,
              AppColors.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(isDark ? 0.55 : 0.35),
              blurRadius: isDark ? 16 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            context.push('/add-transaction');
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add,
            size: 32,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    late final Color iconColor;
    late final Color labelColor;
    if (isDark) {
      if (isSelected) {
        iconColor = AppColors.darkBackground;
        labelColor = AppColors.darkBackground;
      } else {
        iconColor = AppColors.darkOnSurfaceVariant;
        labelColor = AppColors.darkOnSurfaceVariant;
      }
    } else {
      final color =
          isSelected ? AppColors.primary : theme.colorScheme.onSurfaceVariant;
      iconColor = color;
      labelColor = color;
    }

    return InkWell(
      onTap: () {
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 34,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isDark && isSelected)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Icon(
                    isSelected ? selectedIcon : icon,
                    color: iconColor,
                    size: 24,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
