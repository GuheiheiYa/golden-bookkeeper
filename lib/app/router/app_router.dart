import 'dart:ui' show ImageFilter;

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
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: isDark
            ? Stack(
                children: [
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Container(
                        color: AppColors.darkSurface.withOpacity(0.52),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.06)),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withOpacity(0.15),
                          blurRadius: 24,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: BottomAppBar(
                      height: 65,
                      padding: EdgeInsets.zero,
                      notchMargin: 8,
                      shape: const CircularNotchedRectangle(),
                      color: Colors.transparent,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      child: _bottomNavRow(context),
                    ),
                  ),
                ],
              )
            : Container(
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
                  color: theme.colorScheme.surface,
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.12),
                  child: _bottomNavRow(context),
                ),
              ),
      ),
      floatingActionButton: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  colors: [
                    AppColors.primaryDark,
                    AppColors.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    AppColors.lightPrimary,
                    AppColors.lightPrimaryLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? AppColors.primaryDark.withOpacity(0.30)
                  : AppColors.primaryOf(brightness).withOpacity(0.35),
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
          child: Icon(
            Icons.add,
            size: 32,
            color: isDark ? Colors.white : Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _bottomNavRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildNavItem(
          context,
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: '首页',
          index: 0,
          isSelected: navigationShell.currentIndex == 0,
        ),
        _buildNavItem(
          context,
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          label: '明细',
          index: 1,
          isSelected: navigationShell.currentIndex == 1,
        ),
        const SizedBox(width: 60),
        _buildNavItem(
          context,
          icon: Icons.bar_chart_outlined,
          selectedIcon: Icons.bar_chart,
          label: '统计',
          index: 2,
          isSelected: navigationShell.currentIndex == 2,
        ),
        _buildNavItem(
          context,
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          label: '设置',
          index: 3,
          isSelected: navigationShell.currentIndex == 3,
        ),
      ],
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
      iconColor =
          isSelected ? AppColors.primary : AppColors.darkOnSurfaceVariant;
      labelColor =
          isSelected ? AppColors.primary : AppColors.darkOnSurfaceVariant;
    } else {
      final color =
          isSelected ? AppColors.lightPrimary : theme.colorScheme.onSurfaceVariant;
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
            Icon(
              isSelected ? selectedIcon : icon,
              color: iconColor,
              size: 24,
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
