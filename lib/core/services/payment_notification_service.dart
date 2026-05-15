import 'dart:async';
import 'package:flutter/services.dart';

/// Flutter 端支付通知通信服务（单例）
///
/// 通过 MethodChannel 与 Android 原生层通信，提供以下能力：
/// - 查询/打开通知监听权限
/// - 读写监听 APP 包名列表
/// - 读取、标记、清空待确认支付记录
///
/// ## 初始化
/// 在 `app.dart` 的 `initState` 中调用 `PaymentNotificationService().initialize()`
///
/// ## 通信方向
/// ```
/// Flutter UI（待确认列表页 / 设置页）
///       │
///       ▼  getPendingPayments() / markPaymentProcessed() 等
///  PaymentNotificationService（本类）
///       │
///       ▼  invokeMethod(...)
///  Android 原生层（MethodChannel handler in MainActivity）
///       │
///       ▼  PendingPaymentDbHelper 操作 pending_payments.db
/// ```
class PaymentNotificationService {
  /// MethodChannel 通道名称，与 MainActivity.kt 中的 CHANNEL 常量保持一致
  static const _channel =
      MethodChannel('com.bookkeeper.bookkeeper/payment_notification');

  /// 单例模式：全局唯一实例
  static final PaymentNotificationService _instance =
      PaymentNotificationService._();
  factory PaymentNotificationService() => _instance;
  PaymentNotificationService._();

  /// 初始化 MethodChannel 消息处理器
  ///
  /// 调用时机：APP 启动时（app.dart initState）
  void initialize() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// 处理来自 Android 原生层的方法调用
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    // 当前无需处理 Android 端主动推送的方法
  }

  // ═══════════════════════════════════════════════════════════
  // 权限管理
  // ═══════════════════════════════════════════════════════════

  /// 检查通知监听权限是否已开启
  ///
  /// @return true = 已授权，false = 未授权或调用失败
  Future<bool> isPermissionEnabled() async {
    try {
      final result = await _channel.invokeMethod('isNotificationListenerEnabled');
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// 跳转到系统"通知访问权限"设置页
  Future<void> openPermissionSettings() async {
    try {
      await _channel.invokeMethod('openNotificationListenerSettings');
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════════
  // 监听 APP 列表管理
  // ═══════════════════════════════════════════════════════════

  /// 获取当前配置的监听 APP 包名列表
  Future<List<String>> getWatchedPackages() async {
    try {
      final result = await _channel.invokeMethod('getWatchedPackages');
      return List<String>.from(result ?? []);
    } catch (_) {
      return [];
    }
  }

  /// 保存用户选择的监听 APP 包名列表
  Future<void> setWatchedPackages(List<String> packages) async {
    try {
      await _channel.invokeMethod('setWatchedPackages', packages);
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════════
  // 待确认记录操作
  // ═══════════════════════════════════════════════════════════

  /// 获取所有待确认的支付记录
  ///
  /// 读取 Android 原生 SQLite 的 pending_payments 表（status = 'pending'）。
  ///
  /// @return 记录列表，每条包含 id/amount/isExpense/merchant/source/rawText/timestamp
  Future<List<Map<String, dynamic>>> getPendingPayments() async {
    try {
      final result = await _channel.invokeMethod('getPendingPayments');
      if (result == null) return [];
      return (result as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 将指定记录标记为已处理
  ///
  /// 更新 pending_payments 表的 status 字段为 'confirmed'。
  Future<void> markPaymentProcessed(int id) async {
    try {
      await _channel.invokeMethod('markPaymentProcessed', id);
    } catch (_) {}
  }

  /// 删除指定记录（从表中移除）
  Future<void> deletePayment(int id) async {
    try {
      await _channel.invokeMethod('deletePayment', id);
    } catch (_) {}
  }

  /// 清空所有待处理记录（不可恢复）
  Future<void> clearPendingPayments() async {
    try {
      await _channel.invokeMethod('clearPendingPayments');
    } catch (_) {}
  }
}
