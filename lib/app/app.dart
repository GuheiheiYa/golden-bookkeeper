import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/payment_notification_service.dart';
import '../core/theme/app_theme.dart';
import 'router/app_router.dart';
import 'di/providers.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class BookkeeperApp extends ConsumerStatefulWidget {
  const BookkeeperApp({super.key});

  @override
  ConsumerState<BookkeeperApp> createState() => _BookkeeperAppState();
}

class _BookkeeperAppState extends ConsumerState<BookkeeperApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 初始化支付通知 MethodChannel，使 Android 端可以推送数据到 Flutter
    PaymentNotificationService().initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// APP 从后台恢复到前台时，刷新待确认通知数量角标
  ///
  /// 原因：Android 通知监听服务在 APP 后台时仍会静默写入新通知到数据库，
  /// 但 Flutter 端无法感知。通过在 resume 时重新查询来保持角标同步。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(pendingRefreshProvider.notifier).state++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      key: navigatorKey,
      title: '咯噔记账',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('zh', 'CN'),
    );
  }
}
