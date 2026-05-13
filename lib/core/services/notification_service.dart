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

  /// 显示通知列表弹窗（首页和我的页面共用）
  static void showNotificationList(BuildContext context) {
    final service = NotificationService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '消息通知',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground,
                          ),
                        ),
                        if (service.notifications.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              service.clearAll();
                              setModalState(() {});
                            },
                            child: Text(
                              '清空',
                              style: TextStyle(fontSize: 14, color: AppColors.lightPrimary),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: service.notifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_off_outlined,
                                  size: 56,
                                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '暂无消息',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: service.notifications.length,
                            itemBuilder: (context, index) {
                              final notification = service.notifications[index];
                              return ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: notification.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(notification.icon, color: notification.color, size: 20),
                                ),
                                title: Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground,
                                  ),
                                ),
                                subtitle: Text(
                                  notification.message,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightTextTertiary,
                                  ),
                                ),
                                trailing: Text(
                                  _formatTime(notification.createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  notification.onTap?.call();
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }
}
