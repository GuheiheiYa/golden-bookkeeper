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
 * 支付通知监听服务（Android 系统级服务）
 *
 * 继承 [NotificationListenerService]，由 Android 系统管理生命周期。
 * 系统会在任何 APP 发送通知到状态栏时回调 [onNotificationPosted]。
 *
 * ## 整体数据流
 * ```
 * Android 通知栏 → onNotificationPosted()
 *   → 包名白名单过滤（getWatchedPackages）
 *   → 提取通知文本（title + bigText + text）
 *   → PaymentNotificationParser.parse() 解析金额/商户/收支方向
 *   → saveToDatabase() 写入本地 SQLite（去重：120秒内相同通知不重复入库）
 *   → 判断 APP 是否在前台：
 *       ├─ 在前台 → pushToFlutter() 通过 MethodChannel 推送 → Flutter 弹出确认弹窗
 *       └─ 不在前台 → showSystemNotification() 发送系统通知 → 用户点击打开待确认列表
 * ```
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
 * - [MainActivity.methodChannel] — 与 Flutter 端通信的 MethodChannel
 * - [PaymentNotificationListenerService.isAppInForeground] — 由 [MainActivity] 维护的前台状态标志
 */
class PaymentNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "PaymentNotifListener"

        /** SharedPreferences 配置文件名，存储监听应用白名单 */
        private const val PREFS_NAME = "payment_notifications"

        /** SharedPreferences key：监听的 APP 包名集合 */
        private const val KEY_WATCHED_PACKAGES = "watched_packages"

        /** 系统通知渠道 ID，用于发送"检测到支付"的系统通知 */
        private const val CHANNEL_ID = "payment_detected"

        /** 系统通知基础 ID（实际通知 ID = NOTIFICATION_ID + dbId，确保每条通知独立） */
        private const val NOTIFICATION_ID = 1001

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

        /**
         * APP 前台状态标志（内存变量，非持久化）
         *
         * 由 [MainActivity.onResume] 设为 true，[MainActivity.onPause] 设为 false。
         * 用于决定检测到付款后走哪条通道：
         * - true  → MethodChannel 实时推送到 Flutter（弹出确认弹窗）
         * - false → 发送系统通知（用户点击后打开 APP 查看待确认列表）
         */
        @Volatile
        var isAppInForeground = false
    }

    /** SQLite 数据库辅助类，管理 pending_payments 表 */
    private lateinit var dbHelper: PendingPaymentDbHelper

    // ═══════════════════════════════════════════════════════════
    // 服务生命周期
    // ═══════════════════════════════════════════════════════════

    override fun onCreate() {
        super.onCreate()
        dbHelper = PendingPaymentDbHelper(this)
        createNotificationChannel()
        Log.d(TAG, "支付通知监听服务已创建")
    }

    /** 创建系统通知渠道（Android 8.0+ 必须） */
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
     * 5. 根据 APP 前台状态选择推送通道
     */
    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn ?: return

        val packageName = sbn.packageName

        // ── 步骤 1：包名白名单过滤 ──
        val watchedPackages = getWatchedPackages()
        if (packageName !in watchedPackages) {
            Log.d(TAG, "忽略未监听的应用通知: $packageName")
            return
        }

        // ── 步骤 2：提取通知文本 ──
        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return

        val title = extractTextFromBundle(extras, "android.title")
        val text = extractTextFromBundle(extras, "android.text")
        val bigText = extractTextFromBundle(extras, "android.bigText")

        Log.d(TAG, "通知标题 [$packageName]: $title")
        Log.d(TAG, "通知正文 [$packageName]: $text")
        Log.d(TAG, "通知完整 [$packageName]: $bigText")

        // 拼接完整文本：优先用 bigText（更完整），其次用 text
        val fullText = buildString {
            if (title.isNotBlank()) append(title).append(" ")
            if (bigText.isNotBlank()) append(bigText)
            else if (text.isNotBlank()) append(text)
        }.trim()

        Log.d(TAG, "拼接后文本 [$packageName]: $fullText")

        // 写入文件，方便电脑上查看正确的中文内容
        writeToFile("[$packageName] title=$title | text=$text | bigText=$bigText | full=$fullText")

        if (fullText.isBlank()) return

        // ── 步骤 3：解析支付信息 ──
        val parsed = PaymentNotificationParser.parse(fullText, packageName)
        if (parsed == null) {
            Log.d(TAG, "非支付通知，已忽略 [$packageName]")
            return
        }


        Log.d(TAG, "解析成功: ¥${parsed.amount} ${if (parsed.isExpense) "支出" else "收入"} 来源=${parsed.source} 商户=${parsed.merchant ?: "无"}")

        // ── 步骤 4：写入 SQLite 待确认表 ──
        val id = saveToDatabase(parsed)
        Log.d(TAG, "已保存到数据库, id=$id")

        // ── 步骤 5：根据 APP 前台状态选择推送通道 ──
        if (isAppInForeground && id > 0) {
            Log.d(TAG, "APP 在前台，通过 MethodChannel 推送到 Flutter")
            pushToFlutter(parsed, id)
        } else if (id > 0) {
            Log.d(TAG, "APP 不在前台，发送系统通知")
            showSystemNotification(parsed, id)
        }
    }

    /**
     * 从通知 extras Bundle 中安全提取文本
     *
     * 通过 getCharSequence 读取通知文本。
     * 部分银行 APP 的通知文本可能存在编码问题，但金额数字（ASCII）不受影响。
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

    /**
     * 将通知内容写入手机存储文件，用于调试查看
     * 文件路径：/sdcard/Download/notification_log.txt
     * 电脑上用记事本打开即可看到正确的中文
     */
    private fun writeToFile(content: String) {
        try {
            val file = java.io.File("/sdcard/Download/notification_log.txt")
            file.appendText(content + "\n---\n")
        } catch (_: Exception) {
            // 写入失败不影响主流程
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // 通知从状态栏移除时无需处理
    }

    // ═══════════════════════════════════════════════════════════
    // 辅助方法
    // ═══════════════════════════════════════════════════════════

    /**
     * 从 SharedPreferences 读取用户配置的监听 APP 包名集合
     *
     * 如果用户从未修改过，返回 [DEFAULT_WATCHED_PACKAGES]。
     * 用户可在 Flutter 设置页（NotificationSettingsScreen）中增删 APP。
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
     * Android 系统可能对同一通知进行多次回调（如通知更新），
     * 或者某些通知内容（如 APP 版本号、日期数字）被误识别为金额后反复触发。
     *
     * @return 成功插入返回新记录的 id（> 0），去重跳过返回 -1
     */
    private fun saveToDatabase(parsed: ParsedPayment): Long {
        val db = dbHelper.writableDatabase

        // 去重查询：检查 120 秒内是否已有相同来源+金额+商户的通知
        val cursor = db.rawQuery(
            """SELECT id FROM pending_payments
               WHERE source = ? AND amount = ? AND merchant = ?
               AND notification_time > ?
               LIMIT 1""",
            arrayOf(
                parsed.source,
                parsed.amount.toString(),
                parsed.merchant ?: "",
                (parsed.timestamp - 120000).toString()  // 120秒前的时间戳
            )
        )
        val exists = cursor.moveToFirst()
        cursor.close()
        if (exists) {
            Log.d(TAG, "重复通知已忽略（120秒内相同来源+金额+商户）")
            return -1
        }

        // 插入新记录，status 默认为 "pending"（待确认）
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

    /**
     * 通过 MethodChannel 将支付信息实时推送到 Flutter 端
     *
     * 仅在 APP 处于前台时调用。Flutter 端的 [PaymentNotificationService] 收到后
     * 会触发 [PaymentConfirmSheet] 确认弹窗。
     *
     * 推送数据字段：
     * - id, amount, isExpense, merchant, source, rawText, packageName, timestamp
     */
    private fun pushToFlutter(parsed: ParsedPayment, dbId: Long) {
        // MainActivity.methodChannel 在 configureFlutterEngine 中初始化，可能为 null
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
            Log.e(TAG, "推送到 Flutter 失败: ${e.message}")
        }
    }

    /**
     * 发送 Android 系统通知，引导用户打开 APP 确认记账
     *
     * 仅在 APP 不在前台时调用。用户点击通知后：
     * - MainActivity 收到 Intent（extra: open_pending_notifications = true）
     * - MainActivity 通过 MethodChannel 通知 Flutter 打开待确认列表页
     *
     * 通知 ID 使用 NOTIFICATION_ID + dbId，确保每条支付通知独立显示，不会互相覆盖。
     */
    private fun showSystemNotification(parsed: ParsedPayment, dbId: Long) {
        val direction = if (parsed.isExpense) "支出" else "收入"
        val title = "检测到$direction ¥${parsed.amount}"
        val body = parsed.merchant ?: parsed.source

        // 点击通知后打开 MainActivity，并携带 open_pending_notifications 标记
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
        Log.d(TAG, "系统通知已发送, 支付id=$dbId")
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
 *
 * ## 表结构：pending_payments
 *
 * | 字段 | 类型 | 说明 |
 * |------|------|------|
 * | id | INTEGER PK | 自增主键 |
 * | amount | REAL | 交易金额 |
 * | is_expense | INTEGER | 1=支出 0=收入 |
 * | merchant | TEXT | 商户名（可空） |
 * | source | TEXT | 来源标识（wechat/alipay/cmb 等） |
 * | raw_text | TEXT | 原始通知全文 |
 * | package_name | TEXT | 通知来源的 Android 包名 |
 * | notification_time | INTEGER | 通知到达时间戳（毫秒） |
 * | status | TEXT | 状态：pending/confirmed/ignored |
 * | category_id | INTEGER | 确认时选择的分类 ID（可空） |
 * | account_id | INTEGER | 确认时选择的账户 ID（可空） |
 * | created_at | TEXT | 记录创建时间（默认当前时间） |
 *
 * ## 数据生命周期
 * 1. **创建**：[PaymentNotificationListenerService.saveToDatabase] 写入 status=pending
 * 2. **消费**：Flutter 端确认/忽略后调用 [markAsProcessed] 更新 status
 * 3. **清理**：调用 [clearAll] 清空所有记录（用户在 Flutter 端触发）
 */
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
        // 当前为版本 1，暂无升级逻辑
    }

    /**
     * 查询所有待处理（status = 'pending'）的支付记录
     *
     * 按通知时间升序排列（最早的在前），供 Flutter 端待确认列表页展示。
     *
     * @return 记录列表，每条记录为 Map，key 为字段名，value 为对应类型
     */
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
                "isExpense" to (cursor.getInt(2) == 1),  // 转为 bool，兼容 Flutter 端
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

    /**
     * 将指定记录标记为已处理（status 改为 'confirmed'）
     *
     * 由 Flutter 端在用户确认记账或忽略后调用。
     *
     * @param id 待确认记录的 ID
     */
    fun markAsProcessed(id: Long) {
        writableDatabase.execSQL(
            "UPDATE pending_payments SET status = 'confirmed' WHERE id = ?",
            arrayOf(id.toString())
        )
    }

    /**
     * 清空所有待处理记录（DELETE，不可恢复）
     *
     * 由 Flutter 端的"清空所有"按钮触发。
     */
    fun clearAll() {
        writableDatabase.execSQL("DELETE FROM pending_payments")
    }
}
