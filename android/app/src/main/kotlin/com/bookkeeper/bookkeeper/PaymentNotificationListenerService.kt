package com.bookkeeper.bookkeeper

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.os.Build
import android.os.IBinder
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.core.app.NotificationCompat

class PaymentNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "PaymentNotifListener"
        private const val PREFS_NAME = "payment_notifications"
        private const val KEY_WATCHED_PACKAGES = "watched_packages"
        private const val CHANNEL_ID = "payment_detected"
        private const val NOTIFICATION_ID = 1001

        val DEFAULT_WATCHED_PACKAGES = setOf(
            "com.tencent.mm",
            "com.eg.android.AlipayGphone",
            "cmb.pb",
            "com.icbc",
            "com.chinamworld.bocmbci",
            "com.abchina.abc",
            "com.ccb.start",
            "com.yitong.mbank.psbc",
            "com.pingan.pacemaker",
            "com.citiccard.mobilebank"
        )

        // 内存标志：APP 是否在前台
        @Volatile
        var isAppInForeground = false
    }

    private lateinit var dbHelper: PendingPaymentDbHelper

    override fun onCreate() {
        super.onCreate()
        dbHelper = PendingPaymentDbHelper(this)
        createNotificationChannel()
        Log.d(TAG, "PaymentNotificationListenerService created")
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "支付通知",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "检测到支付时提醒"
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    override fun onDestroy() {
        super.onDestroy()
        dbHelper.close()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn ?: return

        val packageName = sbn.packageName
        val watchedPackages = getWatchedPackages()
        if (packageName !in watchedPackages) {
            Log.d(TAG, "Ignoring notification from unwatched package: $packageName")
            return
        }

        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return

        // 提取通知文本
        val title = extras.getCharSequence("android.title")?.toString() ?: ""
        val text = extras.getCharSequence("android.text")?.toString() ?: ""

        // 微信等消息类通知可能在 messages bundle 中
        val bigText = extras.getCharSequence("android.bigText")?.toString() ?: ""

        val fullText = buildString {
            if (title.isNotBlank()) append(title).append(" ")
            if (bigText.isNotBlank()) append(bigText)
            else if (text.isNotBlank()) append(text)
        }.trim()

        Log.d(TAG, "Notification from $packageName: $fullText")

        if (fullText.isBlank()) return

        // 解析付款信息
        val parsed = PaymentNotificationParser.parse(fullText, packageName)
        if (parsed == null) {
            Log.d(TAG, "Not a payment notification, ignored")
            return
        }

        Log.d(TAG, "Parsed payment: ¥${parsed.amount} ${if (parsed.isExpense) "expense" else "income"} from ${parsed.source}")

        // 存入数据库
        val id = saveToDatabase(parsed)
        Log.d(TAG, "Saved to database, id=$id")

        if (isAppInForeground && id > 0) {
            // APP 在前台 → MethodChannel 实时推送
            pushToFlutter(parsed, id)
        } else if (id > 0) {
            // APP 不在前台 → 发送系统通知
            showSystemNotification(parsed, id)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // 不需要处理
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "NotificationListener connected")
    }

    private fun getWatchedPackages(): Set<String> {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getStringSet(KEY_WATCHED_PACKAGES, DEFAULT_WATCHED_PACKAGES)
            ?: DEFAULT_WATCHED_PACKAGES
    }

    private fun saveToDatabase(parsed: ParsedPayment): Long {
        // 去重：10秒内完全相同的通知不重复入库（防同一通知多次推送）
        val db = dbHelper.writableDatabase
        val cursor = db.rawQuery(
            """SELECT id FROM pending_payments
               WHERE raw_text = ? AND source = ? AND notification_time > ?
               LIMIT 1""",
            arrayOf(
                parsed.rawText,
                parsed.source,
                (parsed.timestamp - 10000).toString()
            )
        )
        val exists = cursor.moveToFirst()
        cursor.close()
        if (exists) {
            Log.d(TAG, "Duplicate notification ignored (same text within 10s)")
            return -1
        }

        val values = ContentValues().apply {
            put("amount", parsed.amount)
            put("is_expense", if (parsed.isExpense) 1 else 0)
            put("merchant", parsed.merchant)
            put("source", parsed.source)
            put("raw_text", parsed.rawText)
            put("package_name", parsed.packageName)
            put("notification_time", parsed.timestamp)
            put("status", "pending")
        }
        return db.insert("pending_payments", null, values)
    }

    private fun pushToFlutter(parsed: ParsedPayment, dbId: Long) {
        val channel = MainActivity.methodChannel ?: return
        val data = mapOf(
            "id" to dbId,
            "amount" to parsed.amount,
            "isExpense" to parsed.isExpense,
            "merchant" to (parsed.merchant ?: ""),
            "source" to parsed.source,
            "rawText" to parsed.rawText,
            "packageName" to parsed.packageName,
            "timestamp" to parsed.timestamp
        )
        try {
            channel.invokeMethod("onPaymentDetected", data)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to push to Flutter: ${e.message}")
        }
    }

    private fun showSystemNotification(parsed: ParsedPayment, dbId: Long) {
        val direction = if (parsed.isExpense) "支出" else "收入"
        val title = "检测到$direction ¥${parsed.amount}"
        val body = parsed.merchant ?: parsed.source

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("open_pending_notifications", true)
        }
        val pendingIntent = PendingIntent.getActivity(
            this, dbId.toInt(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID + dbId.toInt(), notification)
        Log.d(TAG, "System notification sent for payment id=$dbId")
    }
}

class PendingPaymentDbHelper(context: Context) : SQLiteOpenHelper(context, DB_NAME, null, DB_VERSION) {

    companion object {
        private const val DB_NAME = "pending_payments.db"
        private const val DB_VERSION = 1
    }

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            """CREATE TABLE pending_payments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                amount REAL NOT NULL,
                is_expense INTEGER NOT NULL,
                merchant TEXT,
                source TEXT NOT NULL,
                raw_text TEXT,
                package_name TEXT,
                notification_time INTEGER,
                status TEXT DEFAULT 'pending',
                category_id INTEGER,
                account_id INTEGER,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )"""
        )
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        // 暂无升级需求
    }

    /** 读取所有待处理记录 */
    fun getPendingPayments(): List<Map<String, Any?>> {
        val db = readableDatabase
        val cursor = db.rawQuery(
            """SELECT id, amount, is_expense, merchant, source, raw_text, package_name, notification_time
               FROM pending_payments WHERE status = 'pending'
               ORDER BY notification_time ASC""",
            null
        )
        val list = mutableListOf<Map<String, Any?>>()
        while (cursor.moveToNext()) {
            list.add(mapOf(
                "id" to cursor.getLong(0),
                "amount" to cursor.getDouble(1),
                "isExpense" to (cursor.getInt(2) == 1),
                "merchant" to (cursor.getString(3) ?: ""),
                "source" to cursor.getString(4),
                "rawText" to (cursor.getString(5) ?: ""),
                "packageName" to (cursor.getString(6) ?: ""),
                "timestamp" to cursor.getLong(7)
            ))
        }
        cursor.close()
        return list
    }

    /** 标记记录为已处理 */
    fun markAsProcessed(id: Long) {
        writableDatabase.execSQL(
            "UPDATE pending_payments SET status = 'confirmed' WHERE id = ?",
            arrayOf(id.toString())
        )
    }

    /** 清空所有待处理记录 */
    fun clearAll() {
        writableDatabase.execSQL("DELETE FROM pending_payments")
    }
}
