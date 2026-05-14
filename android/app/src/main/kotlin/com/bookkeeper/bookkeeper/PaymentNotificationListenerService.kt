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

/**
 * Payment notification listener service (Android system-level service)
 *
 * Extends [NotificationListenerService], lifecycle managed by Android system.
 * The system calls [onNotificationPosted] whenever any app posts a notification.
 *
 * ## Data flow
 * ```
 * Android notification bar → onNotificationPosted()
 *   → package whitelist filter (getWatchedPackages)
 *   → extract notification text (title + bigText + text)
 *   → PaymentNotificationParser.parse() parses amount/merchant/direction
 *   → saveToDatabase() writes to local SQLite (dedup: 120s same source+amount+merchant)
 *   → check app foreground state:
 *       ├─ foreground → pushToFlutter() via MethodChannel → Flutter shows confirm sheet
 *       └─ background → showSystemNotification() → user taps to open pending list
 * ```
 */
class PaymentNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "PaymentNotifListener"
        private const val PREFS_NAME = "payment_notifications"
        private const val KEY_WATCHED_PACKAGES = "watched_packages"
        private const val CHANNEL_ID = "payment_detected"
        private const val NOTIFICATION_ID = 1001

        val DEFAULT_WATCHED_PACKAGES = setOf(
            "com.tencent.mm",                  // WeChat
            "com.eg.android.AlipayGphone",     // Alipay
            "cmb.pb",                          // CMB
            "com.icbc",                        // ICBC
            "com.chinamworld.bocmbci",         // BOC
            "com.abchina.abc",                 // ABC
            "com.ccb.start",                   // CCB
            "com.yitong.mbank.psbc",           // PSBC
            "com.pingan.pacemaker",            // Ping An
            "com.citiccard.mobilebank"         // CITIC
        )

        @Volatile
        var isAppInForeground = false
    }

    private lateinit var dbHelper: PendingPaymentDbHelper

    override fun onCreate() {
        super.onCreate()
        dbHelper = PendingPaymentDbHelper(this)
        createNotificationChannel()
        Log.d(TAG, "Service created")
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Payment Notification",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Alert when payment detected"
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    override fun onDestroy() {
        super.onDestroy()
        dbHelper.close()
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "Listener connected")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn ?: return

        val packageName = sbn.packageName

        // Step 1: whitelist filter
        val watchedPackages = getWatchedPackages()
        if (packageName !in watchedPackages) {
            Log.d(TAG, "Ignored notification from: $packageName")
            return
        }

        // Step 2: extract notification text
        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return

        val title = extractTextFromBundle(extras, "android.title")
        val text = extractTextFromBundle(extras, "android.text")
        val bigText = extractTextFromBundle(extras, "android.bigText")

        Log.d(TAG, "Title [$packageName]: $title")
        Log.d(TAG, "Text [$packageName]: $text")
        Log.d(TAG, "BigText [$packageName]: $bigText")

        val fullText = buildString {
            if (title.isNotBlank()) append(title).append(" ")
            if (bigText.isNotBlank()) append(bigText)
            else if (text.isNotBlank()) append(text)
        }.trim()

        Log.d(TAG, "FullText [$packageName]: $fullText")

        if (fullText.isBlank()) return

        // Step 3: parse payment info
        val parsed = PaymentNotificationParser.parse(fullText, packageName)
        if (parsed == null) {
            Log.d(TAG, "Not a payment notification, skipped [$packageName]")
            return
        }

        Log.d(TAG, "Parsed: ¥${parsed.amount} ${if (parsed.isExpense) "expense" else "income"} source=${parsed.source} merchant=${parsed.merchant ?: "none"}")

        // Step 4: save to SQLite
        val id = saveToDatabase(parsed)
        Log.d(TAG, "Saved to DB, id=$id")

        // Step 5: push based on foreground state
        if (isAppInForeground && id > 0) {
            Log.d(TAG, "App in foreground, pushing via MethodChannel")
            pushToFlutter(parsed, id)
        } else if (id > 0) {
            Log.d(TAG, "App in background, showing system notification")
            showSystemNotification(parsed, id)
        }
    }

    private fun extractTextFromBundle(extras: android.os.Bundle, key: String): String {
        val charSeq = extras.getCharSequence(key)
        if (charSeq != null) {
            val text = charSeq.toString()
            if (text.isNotBlank()) {
                return text
            }
        }
        return ""
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // No action needed when notification is removed
    }

    private fun getWatchedPackages(): Set<String> {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getStringSet(KEY_WATCHED_PACKAGES, DEFAULT_WATCHED_PACKAGES)
            ?: DEFAULT_WATCHED_PACKAGES
    }

    private fun saveToDatabase(parsed: ParsedPayment): Long {
        val db = dbHelper.writableDatabase

        val cursor = db.rawQuery(
            """SELECT id FROM pending_payments
               WHERE source = ? AND amount = ? AND merchant = ?
               AND notification_time > ?
               LIMIT 1""",
            arrayOf(
                parsed.source,
                parsed.amount.toString(),
                parsed.merchant ?: "",
                (parsed.timestamp - 120000).toString()
            )
        )
        val exists = cursor.moveToFirst()
        cursor.close()
        if (exists) {
            Log.d(TAG, "Duplicate notification skipped (120s dedup)")
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
            Log.e(TAG, "Push to Flutter failed: ${e.message}")
        }
    }

    private fun showSystemNotification(parsed: ParsedPayment, dbId: Long) {
        val direction = if (parsed.isExpense) "expense" else "income"
        val title = "Payment detected: $direction ¥${parsed.amount}"
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
        Log.d(TAG, "System notification sent, paymentId=$dbId")
    }
}

// ═══════════════════════════════════════════════════════════════
// SQLite Database Helper
// ═══════════════════════════════════════════════════════════════

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
        // Current version 1, no upgrade logic needed
    }

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

    fun markAsProcessed(id: Long) {
        writableDatabase.execSQL(
            "UPDATE pending_payments SET status = 'confirmed' WHERE id = ?",
            arrayOf(id.toString())
        )
    }

    fun clearAll() {
        writableDatabase.execSQL("DELETE FROM pending_payments")
    }
}
