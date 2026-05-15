package com.bookkeeper.bookkeeper

/**
 * 解析后的支付信息数据模型
 *
 * 由各 [BasePaymentParser] 实现类从原始通知文本中解析得出。
 * 包含金额、收支方向、商户名、来源 APP 等信息，供后续记账使用。
 *
 * ## 字段说明
 * - [merchant]：展示用商户名，在待确认列表头部显示
 * - [goods]：商品名，在确认弹窗中默认填入商品输入框
 * - [note]：备注，在确认弹窗中默认填入备注输入框
 *
 * @param amount      交易金额（正数，不含符号），如 50.00
 * @param isExpense   true = 支出，false = 收入
 * @param merchant    商户/对方名称（用于列表展示），可能为 null
 * @param source      来源标识，如 "wechat"、"alipay"、"cmb" 等
 * @param rawText     原始通知全文
 * @param packageName 通知来源的 Android 包名
 * @param timestamp   解析时间戳（毫秒）
 * @param goods       商品名称（特定解析器可提取精确商品名）
 * @param note        备注（特定解析器可提取精确备注）
 */
data class ParsedPayment(
    val amount: Double,
    val isExpense: Boolean,
    val merchant: String?,
    val source: String,
    val rawText: String,
    val packageName: String,
    val timestamp: Long,
    val goods: String? = null,
    val note: String? = null,
    val notificationId: Int = 0,
    val title: String = "",
    val text: String = "",
    val bigText: String = "",
    val category: String = "",
    val channelId: String = "",
    val groupKey: String = "",
    val priority: Int = 0,
    val postTime: Long = 0,
    val tickerText: String = ""
)

/**
 * 支付通知文本解析器（无状态单例）
 *
 * 职责：从微信、支付宝、各银行 APP 的通知文本中提取交易金额、收支方向、商户名。
 *
 * ## 解析流程
 * 1. 通过 [packageSourceMap] 确定通知来源（不在白名单内 → 返回 null，直接忽略）
 * 2. 按优先级用正则提取金额（人民币 > ¥符号 > 元后缀 > 通用小数）
 * 3. 根据关键词判断收支方向（支出关键词优先于收入关键词）
 * 4. 按来源格式提取商户名（微信括号格式 / 支付宝"向xxx付款"格式 / 银行"商户:"格式）
 *
 * ## 调用方
 * - [PaymentNotificationListenerService.onNotificationPosted] 在收到系统通知时调用
 *
 * ## 线程安全
 * 所有状态均为不可变常量，对象可安全地在任意线程调用。
 */
/**
 * 默认支付通知解析器 — 通用逻辑（策略模式的默认实现）
 *
 * 作为 [BasePaymentParser] 的默认实现，处理所有未被专用解析器覆盖的支付通知格式。
 * 职责：从微信、支付宝、各银行 APP 的通知文本中提取交易金额、收支方向、商户名。
 *
 * ## 解析流程
 * 1. 通过 [packageSourceMap] 确定通知来源（不在白名单内 → 返回 null）
 * 2. 按优先级用正则提取金额（人民币 > ¥符号 > 元后缀 > 通用小数）
 * 3. 根据关键词判断收支方向（支出关键词优先于收入关键词）
 * 4. 按来源格式提取商户名（微信括号格式 / 支付宝"向xxx付款"格式 / 银行"商户:"格式）
 *
 * ## 线程安全
 * 所有状态均为不可变常量，对象可安全地在任意线程调用。
 */
object DefaultPaymentParser : BasePaymentParser {

    // ═══════════════════════════════════════════════════════════
    // 金额提取正则（按优先级从高到低）
    // ═══════════════════════════════════════════════════════════

    /** 优先级 1：人民币 50.00 / 人民币1,234.56 */
    private val renminbiPattern = Regex("""人民币\s*(\d[\d,]*\.?\d{0,2})""")

    /** 优先级 2：¥50.00 / ￥1,234.56（支持全角和半角符号） */
    private val currencySymbolPattern = Regex("""[¥￥]\s*(\d[\d,]*\.?\d{0,2})""")

    /** 优先级 3：50.00元 / 1,234.56 元 */
    private val yuanSuffixPattern = Regex("""(\d[\d,]*\.?\d{0,2})\s*元""")

    /** 优先级 4：50.00 / 1,234.56（仅当以上三种模式均无匹配时才使用，需两位小数） */
    private val genericAmountPattern = Regex("""(\d[\d,]*\.\d{1,2})""")

    // ═══════════════════════════════════════════════════════════
    // 干扰数字过滤（跳过这些上下文中的数字）
    // ═══════════════════════════════════════════════════════════

    /**
     * 需要跳过的数字上下文模式（前后各 10 字符范围内检查）
     *
     * 当通用金额正则（优先级4）匹配到数字时，会检查其上下文。
     * 命中任一模式 → 认为不是金额，跳过。
     */
    private val skipPatterns = listOf(
        Regex("""账户\s*\d+"""),           // 如 "账户3832" 中的 3832
        Regex("""\d{4}年"""),              // 如 "2024年" 中的 2024
        Regex("""\d{1,2}月\d{1,2}日"""),   // 如 "05月13日" 中的数字
        Regex("""\d{1,2}:\d{2}"""),        // 如 "11:26" 中的时间
        Regex("""尾号\d+"""),               // 如 "尾号3832" 中的卡号后四位
        Regex("""[A-Za-z一-鿿]\d[\d.]*"""),  // 字母/汉字后紧跟数字，如 "v7.11"、"XX7.11"、"微信7.11"
    )

    /**
     * 优先级 4 的额外严格校验：
     * 上下文中必须出现支付相关关键词，否则认为是普通数字而非金额。
     * （优先级 1~3 已有明确的货币标记，不需要此检查）
     */
    private val paymentContextKeywords = listOf(
        "消费", "付款", "支出", "扣款", "转出", "支付", "已扣",
        "收款", "收入", "到账", "转入", "收到", "红包", "已入账", "退款",
        "余额", "可用", "账户", "扣费", "充值", "缴费"
    )

    // ═══════════════════════════════════════════════════════════
    // 收支方向关键词
    // ═══════════════════════════════════════════════════════════

    /** 支出关键词 — 通知文本包含任一即判定为支出 */
    private val expenseKeywords = listOf("消费", "付款", "支出", "扣款", "转出", "支付成功", "已扣")

    /** 收入关键词 — 通知文本包含任一即判定为收入 */
    private val incomeKeywords = listOf("收款", "收入", "到账", "转入", "收到", "红包", "已入账", "退款", "存入")

    // ═══════════════════════════════════════════════════════════
    // 包名 → 来源标识映射（白名单）
    // ═══════════════════════════════════════════════════════════

    /**
     * Android 包名 → 内部来源标识的映射表
     *
     * 只有在此白名单中的 APP 通知才会被处理，其余直接忽略。
     * 此映射与 [PaymentNotificationListenerService.DEFAULT_WATCHED_PACKAGES] 保持一致。
     *
     * Flutter 侧用 source 标识来匹配对应账户（如 wechat → 微信账户，alipay → 支付宝账户）。
     */
    private val packageSourceMap = mapOf(
        "com.tencent.mm" to "wechat",                  // 微信
        "com.eg.android.AlipayGphone" to "alipay",     // 支付宝
        "cmb.pb" to "cmb",                             // 招商银行
        "com.icbc" to "icbc",                           // 工商银行
        "com.chinamworld.bocmbci" to "boc",            // 中国银行
        "com.abchina.abc" to "abc",                     // 农业银行
        "com.ccb.start" to "ccb",                       // 建设银行
        "com.yitong.mbank.psbc" to "psbc",             // 邮储银行
        "com.pingan.pacemaker" to "pingan",             // 平安银行
        "com.ecitic.bank.mobile" to "citic",             // 中信银行
        "com.citiccard.mobilebank" to "citic",         // 中信信用卡
        "cn.com.cmbc.newmbank" to "cmbc",             // 民生银行
        "com.csii.xm" to "xm"                         // 厦门银行
    )

    /**
     * 解析通知文本，提取支付信息
     *
     * @param text       通知完整文本（title + bigText/text 拼接）
     * @param packageName 通知来源的 Android 包名
     * @param notificationId Android 系统通知唯一 ID（sbn.id）
     * @return 解析成功返回 [ParsedPayment]，非支付通知或解析失败返回 null
     */
    override fun parse(text: String, packageName: String, notificationId: Int): ParsedPayment? {
        // 注意：当 notify (notification) 到达时，DefaultPaymentParser 作为 CMB 等专用解析器的降级备用
        // 专用解析器已处理的通知不会再进入此方法
        // 包名白名单检查：只有 packageSourceMap 中注册的包名才会被处理
        // 空文本直接跳过
        if (text.isBlank()) return null

        // 包名不在白名单 → 非目标 APP，忽略
        val source = packageSourceMap[packageName] ?: return null

        // 按优先级提取金额，提取失败 → 非付款通知，忽略
        val amount = extractAmount(text) ?: return null
        // 金额安全校验：必须大于 0 且不超过 99 万
        if (amount <= 0 || amount > 999999) return null

        // 判断收支方向：支出关键词优先于收入关键词
        // （避免通知文本中同时出现"退款"和"支付"时误判为收入）
        val isExpense = when {
            expenseKeywords.any { text.contains(it) } -> true
            incomeKeywords.any { text.contains(it) } -> false
            else -> true // 无法判断时默认支出
        }

        // 尝试提取商户/对方名称
        val merchant = extractMerchant(text, source)

        return ParsedPayment(
            amount = amount,
            isExpense = isExpense,
            merchant = merchant,
            source = source,
            rawText = text,
            packageName = packageName,
            timestamp = System.currentTimeMillis(),
            notificationId = notificationId
        )
    }

    /**
     * 按优先级从通知文本中提取金额
     *
     * 优先级策略：明确带"人民币"标记的最可信，其次是 ¥ 符号，再是"元"后缀，
     * 最后才尝试匹配通用小数格式（并跳过账户号/日期/时间等干扰数字）。
     *
     * @return 提取到的金额（正数），无匹配返回 null
     */
    private fun extractAmount(text: String): Double? {
        // (金额数值, 优先级编号)，用于后续排序
        val candidates = mutableListOf<Pair<Double, Int>>()

        // 优先级 1: "人民币 50.00" 格式
        for (match in renminbiPattern.findAll(text)) {
            val amount = parseAmountGroup(match.groupValues[1])
            if (amount != null) candidates.add(amount to 1)
        }

        // 优先级 2: "¥50.00" / "￥50.00" 格式
        for (match in currencySymbolPattern.findAll(text)) {
            val amount = parseAmountGroup(match.groupValues[1])
            if (amount != null) candidates.add(amount to 2)
        }

        // 优先级 3: "50.00元" 格式
        for (match in yuanSuffixPattern.findAll(text)) {
            val amount = parseAmountGroup(match.groupValues[1])
            if (amount != null) candidates.add(amount to 3)
        }

        // 优先级 4: "50.00" 通用小数格式（仅当前三种均无匹配时启用）
        if (candidates.isEmpty()) {
            // 必须上下文中有支付相关关键词，否则不认为是金额
            // （防止联系人备注中的生日数字如 "XX7.11" 被误识别）
            val hasPaymentContext = paymentContextKeywords.any { text.contains(it) }
            if (hasPaymentContext) {
                for (match in genericAmountPattern.findAll(text)) {
                    // 跳过账户号、日期、时间、字母/汉字后紧跟数字等干扰
                    if (isInSkippedContext(text, match.range)) continue
                    val amount = parseAmountGroup(match.groupValues[1])
                    if (amount != null) candidates.add(amount to 4)
                }
            }
        }

        if (candidates.isEmpty()) return null

        // 按优先级升序排列，取优先级最高的（编号最小的）
        candidates.sortBy { it.second }
        return candidates.firstOrNull()?.first
    }

    /**
     * 将正则匹配到的金额组字符串解析为 Double
     *
     * 处理千分位逗号：如 "1,234.56" → 1234.56
     * @return 解析成功返回 Double，失败返回 null
     */
    private fun parseAmountGroup(group: String): Double? {
        return group.replace(",", "").toDoubleOrNull()
    }

    /**
     * 检查匹配位置是否处于需要跳过的上下文中
     *
     * 以匹配位置为中心，取前后各 10 个字符作为上下文，
     * 检查是否命中 [skipPatterns] 中的任一模式（账户号、日期、时间等）。
     *
     * 仅在优先级 4（通用小数匹配）时调用，避免将卡号尾号、日期等误认为金额。
     */
    private fun isInSkippedContext(text: String, range: IntRange): Boolean {
        val start = (range.first - 10).coerceAtLeast(0)
        val end = (range.last + 10).coerceAtMost(text.length - 1)
        val context = text.substring(start, end + 1)
        return skipPatterns.any { it.containsMatchIn(context) }
    }

    /**
     * 从通知文本中提取商户/对方名称
     *
     * 不同来源的通知格式不同，按来源分别处理：
     * - **微信**：关注"（商户：xxx）"括号格式
     * - **支付宝**：关注"向 xxx 付款"格式
     * - **银行**：关注"商户: xxx"格式
     *
     * @return 商户名，提取失败返回 null
     */
    private fun extractMerchant(text: String, source: String): String? {
        // 微信格式："微信支付消费 ¥50.00 （商户：xxx）"
        val merchantInParentheses = Regex("""[（(]商户[：:]?\s*(.+?)[）)]""").find(text)
        if (merchantInParentheses != null) {
            return merchantInParentheses.groupValues[1].trim()
        }

        // 支付宝格式："xxx成功向 xxx 付款50.00元"
        val alipayPattern = Regex("""向\s*(.+?)\s*付款""")
        if (source == "alipay") {
            val match = alipayPattern.find(text)
            if (match != null) return match.groupValues[1].trim()
        }

        // 银行通用格式："尾号xxxx的卡支出/收入xxxx元 (商户: xxx)"
        val bankMerchant = Regex("""商户[：:]\s*(.+?)(?:\s|$)""").find(text)
        if (bankMerchant != null) {
            return bankMerchant.groupValues[1].trim()
        }

        return null
    }
}
