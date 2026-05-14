import 'dart:async';
import 'package:flutter/services.dart';

/// Flutter 端支付通知通信服务（单例）
///
/// 负责 Flutter ↔ Android 原生层（MethodChannel）的所有通信。
///
/// ## 职责
/// 1. **接收原生推送**：Android 端检测到付款后，通过 MethodChannel 调用
///    `onPaymentDetected`，本服务转发给 [onPaymentDetected] 回调
/// 2. **调用原生方法**：权限查询、读写待确认记录等操作，均通过本服务发起
/// 3. **接收打开页面指令**：Android 端收到系统通知点击后，通过 `openPendingNotifications`
///    调用本服务，转发给 [onOpenPendingNotifications] 回调
///
/// ## 初始化
/// 在 [app.dart] 的 `initState` 中调用 `PaymentNotificationService().initialize()`
///
/// ## 通信方向
/// ```
/// Android 原生层（Service/Activity）
///       │
///       ▼  invokeMethod("onPaymentDetected", data)
///  PaymentNotificationService（本类）
///       │
///       ▼  onPaymentDetected?.call(data)
///  app.dart → 弹出 PaymentConfirmSheet 确认弹窗
///
///  Flutter UI
///       │
///       ▼  getPendingPayments() / markPaymentProcessed() 等
///  PaymentNotificationService（本类）
///       │
///       ▼  invokeMethod(...)
///  Android 原生层（MethodChannel handler in MainActivity）
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

  /// 支付检测回调 — Android 端检测到付款时触发
  ///
  /// 回调参数 data 字段：
  /// - `id` (int)：数据库记录 ID
  /// - `amount` (double)：交易金额
  /// - `isExpense` (bool)：true=支出
  /// - `merchant` (String)：商户名
  /// - `source` (String)：来源（wechat/alipay/cmb 等）
  /// - `rawText` (String)：原始通知全文
  /// - `packageName` (String)：通知来源包名
  /// - `timestamp` (int)：通知时间戳（毫秒）
  Function(Map<String, dynamic>)? onPaymentDetected;

  /// 打开待确认列表页回调 — 用户点击系统通知后触发
  VoidCallback? onOpenPendingNotifications;

  /// 初始化 MethodChannel 消息处理器
  ///
  /// 调用时机：APP 启动时（app.dart initState）
  /// 调用后：Android 端可通过 MethodChannel 调用本服务的方法
  void initialize() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// 处理来自 Android 原生层的方法调用
  ///
  /// - `onPaymentDetected`：转发支付检测数据到 [onPaymentDetected] 回调
  /// - `openPendingNotifications`：转发到 [onOpenPendingNotifications] 回调
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPaymentDetected':
        // Android 端推送到 Flutter 的支付检测数据，转为 Map 后通知回调
        final data = Map<String, dynamic>.from(call.arguments);
        onPaymentDetected?.call(data);
        break;
      case 'openPendingNotifications':
        // 用户点击系统通知后，Android 端通知 Flutter 打开待确认列表
        onOpenPendingNotifications?.call();
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 调用 Android 原生方法（由 Flutter UI 层调用）
  // ═══════════════════════════════════════════════════════════

  /// 检查通知监听权限是否已开启
  ///
  /// 调用 Android 端 [MainActivity.isNotificationListenerEnabled]，
  /// 读取系统 Settings.Secure 判断。
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
  ///
  /// 用户在此页面手动开启/关闭通知监听权限。
  /// 开启后 Android 系统自动启动 PaymentNotificationListenerService。
  Future<void> openPermissionSettings() async {
    try {
      await _channel.invokeMethod('openNotificationListenerSettings');
    } catch (_) {}
  }

  /// 获取当前配置的监听 APP 包名列表
  ///
  /// 返回 SharedPreferences 中存储的包名集合。
  /// 用户可通过设置页增删监听的 APP。
  Future<List<String>> getWatchedPackages() async {
    try {
      final result = await _channel.invokeMethod('getWatchedPackages');
      return List<String>.from(result ?? []);
    } catch (_) {
      return [];
    }
  }

  /// 保存用户选择的监听 APP 包名列表
  ///
  /// 由设置页的 Switch 开关触发，立即持久化到 SharedPreferences。
  /// 下次 Service 处理通知时会读取最新配置。
  Future<void> setWatchedPackages(List<String> packages) async {
    try {
      await _channel.invokeMethod('setWatchedPackages', packages);
    } catch (_) {}
  }

  /// 获取所有待确认的支付记录
  ///
  /// 读取 Android 原生 SQLite 的 pending_payments 表（status = 'pending'）。
  /// Flutter 端待确认列表页每次打开和下拉刷新时调用。
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

  /// 将指定记录标记为已处理（确认或忽略后调用）
  ///
  /// 更新 Android 端 pending_payments 表的 status 字段为 'confirmed'。
  /// 标记后该记录不再出现在待确认列表中。
  Future<void> markPaymentProcessed(int id) async {
    try {
      await _channel.invokeMethod('markPaymentProcessed', id);
    } catch (_) {}
  }

  /// 清空所有待处理记录（不可恢复）
  ///
  /// 删除 Android 端 pending_payments 表中所有 status = 'pending' 的记录。
  Future<void> clearPendingPayments() async {
    try {
      await _channel.invokeMethod('clearPendingPayments');
    } catch (_) {}
  }
}
