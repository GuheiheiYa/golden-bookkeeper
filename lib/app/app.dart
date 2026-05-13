import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/payment_notification_service.dart';
import '../core/theme/app_theme.dart';
import '../features/notification/presentation/pending_notifications_screen.dart';
import '../features/notification/presentation/payment_confirm_sheet.dart';
import 'router/app_router.dart';
import 'di/providers.dart';
import 'dart:async';

final navigatorKey = GlobalKey<NavigatorState>();

class BookkeeperApp extends ConsumerStatefulWidget {
  const BookkeeperApp({super.key});

  @override
  ConsumerState<BookkeeperApp> createState() => _BookkeeperAppState();
}

class _BookkeeperAppState extends ConsumerState<BookkeeperApp> {
  @override
  void initState() {
    super.initState();
    _initPaymentNotificationListener();
  }

  void _initPaymentNotificationListener() {
    final service = PaymentNotificationService();
    service.initialize();
    service.onPaymentDetected = (data) {
      if (!mounted) return;
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      showModalBottomSheet<String>(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PaymentConfirmSheet(data: data),
      );
    };
    service.onOpenPendingNotifications = () {
      if (!mounted) return;
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      Navigator.of(ctx).push(
        MaterialPageRoute(builder: (_) => const PendingNotificationsScreen()),
      );
    };
    // APP 启动时检查待处理的支付通知
    _checkPendingPayments();
  }

  void _checkPendingPayments() {
    // 延迟检查，等 Flutter 完全初始化
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final service = PaymentNotificationService();
      final pending = await service.getPendingPayments();
      if (!mounted || pending.isEmpty) return;
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      showModalBottomSheet<String>(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PaymentConfirmSheet(data: pending.first),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      key: navigatorKey,
      title: '记账本',
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
