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
 * 2. **静态持有 MethodChannel 实例**：[PaymentNotificationListenerService]
 *    作为系统服务运行在独立进程，需要通过 [methodChannel] 静态引用
 *    将检测到的支付信息推送到 Flutter 端
 *
 * 3. **前台状态管理**：[onResume] / [onPause] 更新
 *    [PaymentNotificationListenerService.isAppInForeground] 标志
 *
 * 4. **系统通知点击处理**：用户点击支付检测系统通知后，通过 Intent extra
 *    通知 Flutter 打开待确认列表页
 */
class MainActivity : FlutterActivity() {

    companion object {
        /** MethodChannel 通道名称，与 Flutter 端 PaymentNotificationService 保持一致 */
        private const val CHANNEL = "com.bookkeeper.bookkeeper/payment_notification"

        /**
         * 静态持有 MethodChannel 实例，供 PaymentNotificationListenerService 调用
         *
         * 在 configureFlutterEngine 中赋值，在 Service 中通过此引用推送数据到 Flutter。
         * 使用 @Volatile 保证线程可见性（Service 可能在子线程调用）。
         */
        var methodChannel: MethodChannel? = null
    }

    // ═══════════════════════════════════════════════════════════
    // MethodChannel 初始化与方法分发
    // ═══════════════════════════════════════════════════════════

    /**
     * Flutter 引擎初始化回调 — 注册 MethodChannel 并设置方法处理器
     *
     * Flutter 端的 [PaymentNotificationService] 通过此通道调用以下方法：
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
                // 优先读 SharedPreferences（用户可能修改过），否则返回默认列表
                "getWatchedPackages" -> {
                    val prefs = getSharedPreferences("payment_notifications", MODE_PRIVATE)
                    val packages = prefs.getStringSet(
                        "watched_packages",
                        PaymentNotificationListenerService.DEFAULT_WATCHED_PACKAGES
                    ) ?: PaymentNotificationListenerService.DEFAULT_WATCHED_PACKAGES
                    result.success(packages.toList())
                }

                // ── 保存用户选择的监听 APP 列表 ──
                // Flutter 设置页的开关状态变更时调用
                "setWatchedPackages" -> {
                    @Suppress("UNCHECKED_CAST")
                    val packages = call.arguments as? List<String> ?: emptyList()
                    getSharedPreferences("payment_notifications", MODE_PRIVATE)
                        .edit()
                        .putStringSet("watched_packages", packages.toSet())
                        .apply()
                    result.success(true)
                }

                // ── 读取所有待确认的支付记录 ──
                // Flutter 待确认列表页调用，每次打开或下拉刷新时调用
                "getPendingPayments" -> {
                    val helper = PendingPaymentDbHelper(this)
                    val payments = helper.getPendingPayments()
                    helper.close()
                    result.success(payments)
                }

                // ── 标记单条记录为已处理（确认或忽略） ──
                // 参数：记录 id（int/long）
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
    // 前台状态管理
    // ═══════════════════════════════════════════════════════════

    override fun onResume() {
        super.onResume()
        // APP 进入前台 → Service 走 MethodChannel 实时推送通道
        PaymentNotificationListenerService.isAppInForeground = true
        // 检查是否通过系统通知点击进入（携带 open_pending_notifications 标记）
        handlePendingNotificationIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // APP 已在前台时收到新的 Intent（用户点击通知后再次打开）
        handlePendingNotificationIntent(intent)
    }

    /**
     * 处理"从系统通知打开"的 Intent
     *
     * 当用户点击支付检测系统通知时，通知的 PendingIntent 携带
     * extra "open_pending_notifications" = true。
     * 收到后通过 MethodChannel 通知 Flutter 打开待确认列表页。
     *
     * 延迟 1 秒发送是为了等待 Flutter 引擎和路由初始化完成，
     * 避免 Flutter 尚未就绪时调用失败。
     */
    private fun handlePendingNotificationIntent(intent: Intent?) {
        if (intent?.getBooleanExtra("open_pending_notifications", false) == true) {
            intent.removeExtra("open_pending_notifications")
            val channel = methodChannel ?: return
            // 延迟 1 秒，等 Flutter 初始化完成后通知 Flutter 跳转页面
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                try {
                    channel.invokeMethod("openPendingNotifications", null)
                } catch (e: Exception) {
                    Log.e("MainActivity", "通知 Flutter 失败: ${e.message}")
                }
            }, 1000)
        }
    }

    override fun onPause() {
        super.onPause()
        // APP 进入后台 → Service 走系统通知通道
        PaymentNotificationListenerService.isAppInForeground = false
    }

    // ═══════════════════════════════════════════════════════════
    // 通知监听权限检查与跳转
    // ═══════════════════════════════════════════════════════════

    /**
     * 检查本应用是否已获得"通知访问权限"
     *
     * 原理：读取系统 Settings.Secure 中的 "enabled_notification_listeners" 字段，
     * 该字段存储所有已授权访问通知的组件名（ComponentName），格式为：
     * `com.bookkeeper.bookkeeper/.PaymentNotificationListenerService:...`
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
     *
     * 用户在此页面中手动开启/关闭本应用的通知监听权限。
     * 权限开启后 Android 系统自动启动 PaymentNotificationListenerService。
     */
    private fun openNotificationListenerSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }
}
