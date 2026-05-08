import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 消息类型
enum NotificationType {
  info, // 普通信息
  success, // 成功
  warning, // 警告
  error, // 错误
}

/// 消息通知模型
class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final VoidCallback? onTap;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    this.type = NotificationType.info,
    DateTime? createdAt,
    this.onTap,
    this.data,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 获取类型对应的颜色
  Color get color {
    switch (type) {
      case NotificationType.success:
        return AppColors.income;
      case NotificationType.warning:
        return AppColors.warning;
      case NotificationType.error:
        return AppColors.error;
      case NotificationType.info:
      default:
        return AppColors.primary;
    }
  }

  /// 获取类型对应的图标
  IconData get icon {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.warning:
        return Icons.warning_amber_outlined;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.info:
      default:
        return Icons.info_outline;
    }
  }
}

/// 消息通知服务（单例）
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// 消息列表
  final List<AppNotification> _notifications = [];

  /// 消息变化回调
  final List<VoidCallback> _listeners = [];

  /// 获取所有消息
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  /// 获取未读消息数量
  int get unreadCount => _notifications.length;

  /// 添加消息
  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    // 保留最近 50 条消息
    if (_notifications.length > 50) {
      _notifications.removeRange(50, _notifications.length);
    }
    _notifyListeners();
  }

  /// 发送信息消息
  void info({
    required String title,
    required String message,
    VoidCallback? onTap,
    Map<String, dynamic>? data,
  }) {
    addNotification(AppNotification(
      id: _generateId(),
      title: title,
      message: message,
      type: NotificationType.info,
      onTap: onTap,
      data: data,
    ));
  }

  /// 发送成功消息
  void success({
    required String title,
    required String message,
    VoidCallback? onTap,
    Map<String, dynamic>? data,
  }) {
    addNotification(AppNotification(
      id: _generateId(),
      title: title,
      message: message,
      type: NotificationType.success,
      onTap: onTap,
      data: data,
    ));
  }

  /// 发送警告消息
  void warning({
    required String title,
    required String message,
    VoidCallback? onTap,
    Map<String, dynamic>? data,
  }) {
    addNotification(AppNotification(
      id: _generateId(),
      title: title,
      message: message,
      type: NotificationType.warning,
      onTap: onTap,
      data: data,
    ));
  }

  /// 发送错误消息
  void error({
    required String title,
    required String message,
    VoidCallback? onTap,
    Map<String, dynamic>? data,
  }) {
    addNotification(AppNotification(
      id: _generateId(),
      title: title,
      message: message,
      type: NotificationType.error,
      onTap: onTap,
      data: data,
    ));
  }

  /// 删除消息
  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _notifyListeners();
  }

  /// 清空所有消息
  void clearAll() {
    _notifications.clear();
    _notifyListeners();
  }

  /// 添加监听器
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// 移除监听器
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// 通知所有监听器
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// 生成唯一 ID
  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_notifications.length}';
  }
}
