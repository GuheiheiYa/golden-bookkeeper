package com.bookkeeper.bookkeeper

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

/**
 * 支付通知监听服务（Android 系统级服务）
 *
 * 继承 [NotificationListenerService]，由 Android 系统管理生命周期。
 * 系统会在任何 APP 发送通知到状态栏时回调 [onNotificationPosted]。
 *
 * ## 数据流
 * ```
 * Android 通知栏 → onNotificationPosted()
 *   → 包名白名单过滤（SharedPreferences 配置）
 *   → 提取通知文本（title + bigText + text）
 *   → PaymentNotificationParser.parse() 解析金额/商户/收支方向
 *   → saveToDatabase() 写入本地 SQLite（去重：120秒内相同通知不重复入库）
 *   → 完成
 * ```
 *
 * 用户通过 Flutter 待确认列表页（PendingNotificationsScreen）查看和处理这些记录。
 *
 * ## 生命周期
 * - 用户在系统设置中授权"通知访问权限"后，Android 系统自动启动此服务
 * - 用户撤销授权后，系统自动销毁此服务
 * - 服务与 APP 进程无关，即使 APP 被杀死，只要授权在，服务仍会运行
 *
 * ## 权限要求
 * 需在 AndroidManifest.xml 中声明：
 * ```xml
 * <uses-permission android:name="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"/>
 * <service android:name=".PaymentNotificationListenerService"
 *          android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE">
 *     <intent-filter>
 *         <action android:name="android.service.notification.NotificationListenerService"/>
 *     </intent-filter>
 * </service>
 * ```
 *
 * ## 关键依赖
 * - [PaymentNotificationParser] — 通知文本解析（提取金额、商户、收支方向）
 * - [PendingPaymentDbHelper] — SQLite 待确认记录数据库
 */
class PaymentNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "PaymentNotifListener"

        /** SharedPreferences 配置文件名，存储监听应用白名单 */
        private const val PREFS_NAME = "payment_notifications"

        /** SharedPreferences key：监听的 APP 包名集合 */
        private const val KEY_WATCHED_PACKAGES = "watched_packages"

        /**
         * 默认监听的 APP 包名白名单
         *
         * 用户可在 Flutter 设置页修改此列表（通过 SharedPreferences 持久化）。
         * 此默认值仅在用户从未修改过时使用。
         *
         * 包名与 [PaymentNotificationParser.packageSourceMap] 保持一一对应。
         */
        val DEFAULT_WATCHED_PACKAGES = setOf(
            "com.tencent.mm",                  // 微信
            "com.eg.android.AlipayGphone",     // 支付宝
            "cmb.pb",                          // 招商银行
            "com.icbc",                        // 工商银行
            "com.chinamworld.bocmbci",         // 中国银行
            "com.abchina.abc",                 // 农业银行
            "com.ccb.start",                   // 建设银行
            "com.yitong.mbank.psbc",           // 邮储银行
            "com.pingan.pacemaker",            // 平安银行
            "com.citiccard.mobilebank"         // 中信银行
        )
    }

    /** SQLite 数据库辅助类，管理 pending_payments 表 */
    private lateinit var dbHelper: PendingPaymentDbHelper

    // ═══════════════════════════════════════════════════════════
    // 服务生命周期
    // ═══════════════════════════════════════════════════════════

    override fun onCreate() {
        super.onCreate()
        dbHelper = PendingPaymentDbHelper(this)
        Log.d(TAG, "支付通知监听服务已创建")
    }

    override fun onDestroy() {
        super.onDestroy()
        dbHelper.close()
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "通知监听器已连接")
    }

    // ═══════════════════════════════════════════════════════════
    // 核心：通知到达处理
    // ═══════════════════════════════════════════════════════════

    /**
     * 系统通知到达回调 — 整个功能的入口
     *
     * 处理流程：
     * 1. 包名白名单过滤 → 不在监听列表中直接返回
     * 2. 提取通知文本（title + bigText + text）
     * 3. 调用 [PaymentNotificationParser.parse] 解析支付信息
     * 4. 写入 SQLite 待确认表（去重）
     */
    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn ?: return

        val packageName = sbn.packageName

        // ── 步骤 1：包名白名单过滤 ──
        val watchedPackages = getWatchedPackages()
        if (packageName !in watchedPackages) {
            return
        }

        // ── 步骤 2：提取通知文本 ──
        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return

        val title = extractTextFromBundle(extras, "android.title")
        val text = extractTextFromBundle(extras, "android.text")
        val bigText = extractTextFromBundle(extras, "android.bigText")

        // 拼接完整文本：优先用 bigText（更完整），其次用 text
        val fullText = buildString {
            if (title.isNotBlank()) append(title).append(" ")
            if (bigText.isNotBlank()) append(bigText)
            else if (text.isNotBlank()) append(text)
        }.trim()

        if (fullText.isBlank()) return

        // ── 步骤 3：解析支付信息 ──
        val parsed = PaymentNotificationParser.parse(fullText, packageName, sbn.id)
        if (parsed == null) {
            Log.d(TAG, "非支付通知，已忽略 [$packageName]")
            return
        }

        // 补充通知元数据
        val enriched = parsed.copy(
            title = title,
            text = text,
            bigText = bigText,
            category = notification.category ?: "",
            channelId = notification.channelId ?: "",
            priority = notification.priority,
            postTime = sbn.postTime,
            tickerText = notification.tickerText?.toString() ?: ""
        )

        Log.d(TAG, "解析成功: ¥${enriched.amount} ${if (enriched.isExpense) "支出" else "收入"} 来源=${enriched.source}")

        // ── 步骤 4：写入 SQLite 待确认表 ──
        val id = saveToDatabase(enriched)
        if (id > 0) {
            Log.d(TAG, "已保存到待确认表, id=$id")
        }
    }

    /**
     * 从通知 extras Bundle 中安全提取文本
     */
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
        // 通知从状态栏移除时无需处理
    }

    // ═══════════════════════════════════════════════════════════
    // 数据库操作
    // ═══════════════════════════════════════════════════════════

    /**
     * 从 SharedPreferences 读取用户配置的监听 APP 包名集合
     *
     * 如果用户从未修改过，返回 [DEFAULT_WATCHED_PACKAGES]。
     */
    private fun getWatchedPackages(): Set<String> {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getStringSet(KEY_WATCHED_PACKAGES, DEFAULT_WATCHED_PACKAGES)
            ?: DEFAULT_WATCHED_PACKAGES
    }

    /**
     * 将解析后的支付信息写入 SQLite 待确认表
     *
     * **去重逻辑**：120 秒内相同来源 + 相同金额 + 相同商户的通知不重复入库。
     *
     * 不能用 notification_id 去重：微信等 APP 的 sbn.id 对所有通知都是同一个值（通常为 0），
     * 导致第一条之后的所有微信通知都被误判为重复。
     *
     * @return 成功插入返回新记录的 id（> 0），去重跳过返回 -1
     */
    private fun saveToDatabase(parsed: ParsedPayment): Long {
        val db = dbHelper.writableDatabase

        // 去重查询：120秒内相同 来源+金额+商户 → 跳过（同一条支付通知的重复回调）
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
            Log.d(TAG, "重复通知已忽略（120秒内相同 来源+金额+商户）")
            return -1
        }

        // 插入新记录，status 默认为 "pending"（待确认）
        val values = ContentValues().apply {
            put("notification_id", parsed.notificationId)
            put("amount", parsed.amount)
            put("is_expense", if (parsed.isExpense) 1 else 0)
            put("merchant", parsed.merchant)
            put("source", parsed.source)
            put("raw_text", parsed.rawText)
            put("package_name", parsed.packageName)
            put("notification_time", parsed.timestamp)
            put("status", "pending")
            put("title", parsed.title)
            put("text", parsed.text)
            put("big_text", parsed.bigText)
            put("category", parsed.category)
            put("channel_id", parsed.channelId)
            put("priority", parsed.priority)
            put("post_time", parsed.postTime)
            put("ticker_text", parsed.tickerText)
        }
        return db.insert("pending_payments", null, values)
    }
}

// ═══════════════════════════════════════════════════════════════
// SQLite 数据库辅助类
// ═══════════════════════════════════════════════════════════════

/**
 * 待确认支付记录 SQLite 数据库辅助类
 *
 * 管理 `pending_payments` 表的创建和 CRUD 操作。
 * 此数据库独立于 Flutter 的 sqflite 数据库（因为 NotificationListenerService
 * 运行在 Android 原生层，无法直接访问 Flutter 的数据库）。
 */
class PendingPaymentDbHelper(context: Context) : SQLiteOpenHelper(context, DB_NAME, null, DB_VERSION) {

    companion object {
        private const val DB_NAME = "pending_payments.db"
        private const val DB_VERSION = 2
    }

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            """CREATE TABLE pending_payments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                notification_id INTEGER,
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
                title TEXT,
                text TEXT,
                big_text TEXT,
                category TEXT,
                channel_id TEXT,
                priority INTEGER,
                post_time INTEGER,
                ticker_text TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )"""
        )
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        if (oldVersion < 2) {
            db.execSQL("ALTER TABLE pending_payments ADD COLUMN notification_id INTEGER")
            db.execSQL("ALTER TABLE pending_payments ADD COLUMN title TEXT")
            db.execSQL("ALTER TABLE pending_payments ADD COLUMN text TEXT")
            db.execSQL("ALTER TABLE pending_payments ADD COLUMN big_text TEXT")
            db.execSQL("ALTER TABLE pending_payments ADD COLUMN category TEXT")
            db.execSQL("ALTER TABLE pending_payments ADD COLUMN channel_id TEXT")
            db.execSQL("ALTER TABLE pending_payments ADD COLUMN priority INTEGER")
            db.execSQL("ALTER TABLE pending_payments ADD COLUMN post_time INTEGER")
            db.execSQL("ALTER TABLE pending_payments ADD COLUMN ticker_text TEXT")
        }
    }

    /**
     * 查询所有待处理（status = 'pending'）的支付记录
     */
    fun getPendingPayments(): List<Map<String, Any?>> {
        val db = readableDatabase
        val cursor = db.rawQuery(
            """SELECT id, notification_id, amount, is_expense, merchant, source, raw_text,
                      package_name, notification_time, title, text, big_text,
                      category, channel_id, priority, post_time, ticker_text
               FROM pending_payments WHERE status = 'pending'
               ORDER BY notification_time ASC""",
            null
        )
        val list = mutableListOf<Map<String, Any?>>()
        while (cursor.moveToNext()) {
            list.add(mapOf(
                "id" to cursor.getLong(0),
                "notificationId" to cursor.getInt(1),
                "amount" to cursor.getDouble(2),
                "isExpense" to (cursor.getInt(3) == 1),
                "merchant" to (cursor.getString(4) ?: ""),
                "source" to cursor.getString(5),
                "rawText" to (cursor.getString(6) ?: ""),
                "packageName" to (cursor.getString(7) ?: ""),
                "timestamp" to cursor.getLong(8),
                "title" to (cursor.getString(9) ?: ""),
                "text" to (cursor.getString(10) ?: ""),
                "bigText" to (cursor.getString(11) ?: ""),
                "category" to (cursor.getString(12) ?: ""),
                "channelId" to (cursor.getString(13) ?: ""),
                "priority" to cursor.getInt(14),
                "postTime" to cursor.getLong(15),
                "tickerText" to (cursor.getString(16) ?: "")
            ))
        }
        cursor.close()
        return list
    }

    /**
     * 将指定记录标记为已处理（status 改为 'confirmed'）
     *
     * 由 Flutter 端在用户确认记账或忽略后调用。
     */
    fun markAsProcessed(id: Long) {
        writableDatabase.execSQL(
            "UPDATE pending_payments SET status = 'confirmed' WHERE id = ?",
            arrayOf(id.toString())
        )
    }

    /**
     * 清空所有待处理记录（DELETE，不可恢复）
     */
    fun clearAll() {
        writableDatabase.execSQL("DELETE FROM pending_payments")
    }
}
