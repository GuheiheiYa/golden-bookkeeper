package com.bookkeeper.bookkeeper

import android.content.ComponentName
import android.content.Intent
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.bookkeeper.bookkeeper/payment_notification"
        var methodChannel: MethodChannel? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isNotificationListenerEnabled" -> {
                    result.success(isNotificationListenerEnabled())
                }
                "openNotificationListenerSettings" -> {
                    openNotificationListenerSettings()
                    result.success(true)
                }
                "getWatchedPackages" -> {
                    val prefs = getSharedPreferences("payment_notifications", MODE_PRIVATE)
                    val packages = prefs.getStringSet(
                        "watched_packages",
                        PaymentNotificationListenerService.DEFAULT_WATCHED_PACKAGES
                    ) ?: PaymentNotificationListenerService.DEFAULT_WATCHED_PACKAGES
                    result.success(packages.toList())
                }
                "setWatchedPackages" -> {
                    @Suppress("UNCHECKED_CAST")
                    val packages = call.arguments as? List<String> ?: emptyList()
                    getSharedPreferences("payment_notifications", MODE_PRIVATE)
                        .edit()
                        .putStringSet("watched_packages", packages.toSet())
                        .apply()
                    result.success(true)
                }
                "getPendingPayments" -> {
                    val helper = PendingPaymentDbHelper(this)
                    val payments = helper.getPendingPayments()
                    helper.close()
                    result.success(payments)
                }
                "markPaymentProcessed" -> {
                    val id = (call.arguments as? Number)?.toLong()
                    if (id != null) {
                        val helper = PendingPaymentDbHelper(this)
                        helper.markAsProcessed(id)
                        helper.close()
                    }
                    result.success(true)
                }
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

    override fun onResume() {
        super.onResume()
        PaymentNotificationListenerService.isAppInForeground = true
        // 处理从系统通知打开的情况
        handlePendingNotificationIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handlePendingNotificationIntent(intent)
    }

    private fun handlePendingNotificationIntent(intent: Intent?) {
        if (intent?.getBooleanExtra("open_pending_notifications", false) == true) {
            intent.removeExtra("open_pending_notifications")
            val channel = methodChannel ?: return
            // 延迟发送，等 Flutter 初始化完成
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                try {
                    channel.invokeMethod("openPendingNotifications", null)
                } catch (e: Exception) {
                    Log.e("MainActivity", "Failed to notify Flutter: ${e.message}")
                }
            }, 1000)
        }
    }

    override fun onPause() {
        super.onPause()
        PaymentNotificationListenerService.isAppInForeground = false
    }

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

    private fun openNotificationListenerSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }
}
