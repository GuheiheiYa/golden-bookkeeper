import 'dart:async';
import 'package:flutter/services.dart';

class PaymentNotificationService {
  static const _channel = MethodChannel('com.bookkeeper.bookkeeper/payment_notification');
  static final PaymentNotificationService _instance = PaymentNotificationService._();
  factory PaymentNotificationService() => _instance;
  PaymentNotificationService._();

  Function(Map<String, dynamic>)? onPaymentDetected;
  VoidCallback? onOpenPendingNotifications;

  void initialize() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPaymentDetected':
        final data = Map<String, dynamic>.from(call.arguments);
        onPaymentDetected?.call(data);
        break;
      case 'openPendingNotifications':
        onOpenPendingNotifications?.call();
        break;
    }
  }

  Future<bool> isPermissionEnabled() async {
    try {
      final result = await _channel.invokeMethod('isNotificationListenerEnabled');
      return result == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> openPermissionSettings() async {
    try {
      await _channel.invokeMethod('openNotificationListenerSettings');
    } catch (_) {}
  }

  Future<List<String>> getWatchedPackages() async {
    try {
      final result = await _channel.invokeMethod('getWatchedPackages');
      return List<String>.from(result ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<void> setWatchedPackages(List<String> packages) async {
    try {
      await _channel.invokeMethod('setWatchedPackages', packages);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getPendingPayments() async {
    try {
      final result = await _channel.invokeMethod('getPendingPayments');
      if (result == null) return [];
      return (result as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> markPaymentProcessed(int id) async {
    try {
      await _channel.invokeMethod('markPaymentProcessed', id);
    } catch (_) {}
  }

  Future<void> clearPendingPayments() async {
    try {
      await _channel.invokeMethod('clearPendingPayments');
    } catch (_) {}
  }
}
