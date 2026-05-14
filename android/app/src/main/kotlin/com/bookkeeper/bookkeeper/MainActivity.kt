package com.bookkeeper.bookkeeper

import android.content.ComponentName
import android.content.Intent
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter 主 Activity — 负责 MethodChannel 桥接
 *
 * 在支付通知监听功能中，本 Activity 承担以下职责：
 *
 * 1. **MethodChannel 初始化**：在 [configureFlutterEngine] 中注册通道，
 *    供 Flutter 端调用原生方法（查权限、读写待确认记录等）
 *
 * 2. **静态持有 MethodChannel 实例**：供其他组件通过 [methodChannel] 引用
 */
class MainActivity : FlutterActivity() {

    companion object {
        /** MethodChannel 通道名称，与 Flutter 端 PaymentNotificationService 保持一致 */
        private const val CHANNEL = "com.bookkeeper.bookkeeper/payment_notification"

        /**
         * 静态持有 MethodChannel 实例
         *
         * 在 configureFlutterEngine 中赋值，供需要与 Flutter 通信的组件使用。
         */
        var methodChannel: MethodChannel? = null
    }

    // ═══════════════════════════════════════════════════════════
    // MethodChannel 初始化与方法分发
    // ═══════════════════════════════════════════════════════════

    /**
     * Flutter 引擎初始化回调 — 注册 MethodChannel 并设置方法处理器
     *
     * Flutter 端通过此通道调用以下方法：
     *
     * | 方法名 | 说明 | 参数 | 返回值 |
     * |--------|------|------|--------|
     * | isNotificationListenerEnabled | 检查通知监听权限是否已开启 | 无 | bool |
     * | openNotificationListenerSettings | 跳转系统通知监听设置页 | 无 | true |
     * | getWatchedPackages | 获取当前监听的 APP 包名列表 | 无 | List<String> |
     * | setWatchedPackages | 保存用户选择的监听 APP 列表 | List<String> | true |
     * | getPendingPayments | 读取所有待确认记录 | 无 | List<Map> |
     * | markPaymentProcessed | 标记单条记录为已处理 | int (id) | true |
     * | clearPendingPayments | 清空所有待处理记录 | 无 | true |
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                // ── 检查通知监听权限是否已开启 ──
                "isNotificationListenerEnabled" -> {
                    result.success(isNotificationListenerEnabled())
                }

                // ── 跳转到系统"通知访问权限"设置页 ──
                "openNotificationListenerSettings" -> {
                    openNotificationListenerSettings()
                    result.success(true)
                }

                // ── 获取当前监听的 APP 包名列表 ──
                "getWatchedPackages" -> {
                    val prefs = getSharedPreferences("payment_notifications", MODE_PRIVATE)
                    val removed = prefs.getStringSet("removed_packages", null) ?: emptySet()
                    val packages = PaymentNotificationListenerService.DEFAULT_WATCHED_PACKAGES - removed
                    result.success(packages.toList())
                }

                // ── 保存用户选择的监听 APP 列表 ──
                "setWatchedPackages" -> {
                    @Suppress("UNCHECKED_CAST")
                    val packages = call.arguments as? List<String> ?: emptyList()
                    // 计算用户移除了哪些默认包名，存入 removed_packages
                    val removed = PaymentNotificationListenerService.DEFAULT_WATCHED_PACKAGES - packages.toSet()
                    getSharedPreferences("payment_notifications", MODE_PRIVATE)
                        .edit()
                        .putStringSet("removed_packages", removed)
                        .apply()
                    result.success(true)
                }

                // ── 读取所有待确认的支付记录 ──
                "getPendingPayments" -> {
                    val helper = PendingPaymentDbHelper(this)
                    val payments = helper.getPendingPayments()
                    helper.close()
                    result.success(payments)
                }

                // ── 标记单条记录为已处理 ──
                "markPaymentProcessed" -> {
                    val id = (call.arguments as? Number)?.toLong()
                    if (id != null) {
                        val helper = PendingPaymentDbHelper(this)
                        helper.markAsProcessed(id)
                        helper.close()
                    }
                    result.success(true)
                }

                // ── 清空所有待处理记录 ──
                "clearPendingPayments" -> {
                    val helper = PendingPaymentDbHelper(this)
                    helper.clearAll()
                    helper.close()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // 通知监听权限检查与跳转
    // ═══════════════════════════════════════════════════════════

    /**
     * 检查本应用是否已获得"通知访问权限"
     *
     * 读取系统 Settings.Secure 中的 "enabled_notification_listeners" 字段，
     * 检查是否包含本应用的 NotificationListenerService 组件名。
     *
     * @return true 表示已授权，false 表示未授权
     */
    private fun isNotificationListenerEnabled(): Boolean {
        val pkgName = packageName
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        if (!TextUtils.isEmpty(flat)) {
            val names = flat.split(":")
            for (name in names) {
                val cn = ComponentName.unflattenFromString(name)
                if (cn != null && TextUtils.equals(pkgName, cn.packageName)) {
                    return true
                }
            }
        }
        return false
    }

    /**
     * 跳转到系统"通知访问权限"设置页
     */
    private fun openNotificationListenerSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }
}
