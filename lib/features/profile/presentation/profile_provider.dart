import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/di/providers.dart';
import '../../../core/database/app_database.dart';

// ========== 贷款数据刷新触发器 ==========

final loanRefreshProvider = StateProvider<int>((ref) => 0);

// ========== 账户数据刷新触发器 ==========

final accountRefreshProvider = StateProvider<int>((ref) => 0);

// ========== 用户档案数据 ==========

class UserProfile {
  final String name;
  final String subtitle;
  final int level;
  final int xp;
  final int xpTarget;

  const UserProfile({
    this.name = '咯噔',
    this.subtitle = '精打细算的见习镇长',
    this.level = 4,
    this.xp = 88,
    this.xpTarget = 100,
  });

  UserProfile copyWith({
    String? name,
    String? subtitle,
    int? level,
    int? xp,
    int? xpTarget,
  }) {
    return UserProfile(
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      xpTarget: xpTarget ?? this.xpTarget,
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier() : super(const UserProfile()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    state = UserProfile(
      name: prefs.getString('profile_name') ?? '咯噔',
      subtitle: prefs.getString('profile_subtitle') ?? '精打细算的见习镇长',
      level: prefs.getInt('profile_level') ?? 4,
      xp: prefs.getInt('profile_xp') ?? 88,
      xpTarget: prefs.getInt('profile_xpTarget') ?? 100,
    );
  }

  Future<void> updateName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', name);
    state = state.copyWith(name: name);
  }

  Future<void> updateSubtitle(String subtitle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_subtitle', subtitle);
    state = state.copyWith(subtitle: subtitle);
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier();
});

// ========== 资产汇总 ==========

class AssetSummary {
  final double totalAssets;
  final double liabilities;
  final double netAssets;

  const AssetSummary({
    required this.totalAssets,
    required this.liabilities,
    required this.netAssets,
  });
}

final assetSummaryProvider = FutureProvider<AssetSummary>((ref) async {
  ref.watch(transactionRefreshProvider);
  // 监听贷款账户变化（loan_list_screen 刷新时同步更新资产卡片）
  ref.watch(loanRefreshProvider);
  // 监听普通账户变化（account_list_screen 新增/编辑时同步更新资产卡片）
  ref.watch(accountRefreshProvider);
  final db = ref.watch(appDatabaseProvider);
  final accounts = await db.getAccounts();

  double totalAssets = 0;
  double liabilities = 0;

  for (final account in accounts) {
    final balance = (account['balance'] as num?)?.toDouble() ?? 0;
    final type = account['type'] as String?;
    if (type != null && type.startsWith('loan')) {
      liabilities += balance;
    } else if (balance > 0) {
      totalAssets += balance;
    }
  }

  return AssetSummary(
    totalAssets: totalAssets,
    liabilities: liabilities,
    netAssets: totalAssets - liabilities,
  );
});
