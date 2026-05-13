package com.bookkeeper.bookkeeper

data class ParsedPayment(
    val amount: Double,
    val isExpense: Boolean,
    val merchant: String?,
    val source: String,
    val rawText: String,
    val packageName: String,
    val timestamp: Long
)

object PaymentNotificationParser {

    // 金额提取优先级：人民币 > ¥/￥符号 > 元后缀 > 通用数字
    private val renminbiPattern = Regex("""人民币\s*(\d[\d,]*\.?\d{0,2})""")
    private val currencySymbolPattern = Regex("""[¥￥]\s*(\d[\d,]*\.?\d{0,2})""")
    private val yuanSuffixPattern = Regex("""(\d[\d,]*\.?\d{0,2})\s*元""")
    private val genericAmountPattern = Regex("""(\d[\d,]*\.\d{1,2})""")

    // 需要跳过的数字模式（账户号、日期、时间等）
    private val skipPatterns = listOf(
        Regex("""账户\s*\d+"""),           // 账户3832
        Regex("""\d{4}年"""),              // 2024年
        Regex("""\d{1,2}月\d{1,2}日"""),   // 05月13日
        Regex("""\d{1,2}:\d{2}"""),        // 11:26
        Regex("""尾号\d+"""),               // 尾号3832
    )

    private val expenseKeywords = listOf("消费", "付款", "支出", "扣款", "转出", "支付成功", "已扣")
    private val incomeKeywords = listOf("收款", "收入", "到账", "转入", "收到", "红包", "已入账", "退款")

    // 包名 → 来源标识
    private val packageSourceMap = mapOf(
        "com.tencent.mm" to "wechat",
        "com.eg.android.AlipayGphone" to "alipay",
        "cmb.pb" to "cmb",
        "com.icbc" to "icbc",
        "com.chinamworld.bocmbci" to "boc",
        "com.abchina.abc" to "abc",
        "com.ccb.start" to "ccb",
        "com.yitong.mbank.psbc" to "psbc",
        "com.pingan.pacemaker" to "pingan",
        "com.citiccard.mobilebank" to "citic"
    )

    fun parse(text: String, packageName: String): ParsedPayment? {
        if (text.isBlank()) return null

        val source = packageSourceMap[packageName] ?: return null

        // 按优先级提取金额
        val amount = extractAmount(text) ?: return null
        if (amount <= 0 || amount > 999999) return null

        // 判断收支方向（expense 优先，避免"退款"在渠道名中被误匹配）
        val isExpense = when {
            expenseKeywords.any { text.contains(it) } -> true
            incomeKeywords.any { text.contains(it) } -> false
            else -> true // 默认支出
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
            timestamp = System.currentTimeMillis()
        )
    }

    /**
     * 按优先级提取金额，跳过账户号/日期/时间等干扰数字
     * 优先级：人民币XXX > ¥XXX > XXX元 > X.XX（两位小数）
     */
    private fun extractAmount(text: String): Double? {
        // 收集所有候选金额
        val candidates = mutableListOf<Pair<Double, Int>>() // (金额, 优先级)

        // 优先级1: 人民币XXX
        for (match in renminbiPattern.findAll(text)) {
            val amount = parseAmountGroup(match.groupValues[1])
            if (amount != null) candidates.add(amount to 1)
        }

        // 优先级2: ¥/￥XXX
        for (match in currencySymbolPattern.findAll(text)) {
            val amount = parseAmountGroup(match.groupValues[1])
            if (amount != null) candidates.add(amount to 2)
        }

        // 优先级3: XXX元
        for (match in yuanSuffixPattern.findAll(text)) {
            val amount = parseAmountGroup(match.groupValues[1])
            if (amount != null) candidates.add(amount to 3)
        }

        // 优先级4: X.XX（两位小数，通常为金额）
        if (candidates.isEmpty()) {
            for (match in genericAmountPattern.findAll(text)) {
                if (isInSkippedContext(text, match.range)) continue
                val amount = parseAmountGroup(match.groupValues[1])
                if (amount != null) candidates.add(amount to 4)
            }
        }

        if (candidates.isEmpty()) return null

        // 按优先级排序，同优先级取第一个
        candidates.sortBy { it.second }
        return candidates.firstOrNull()?.first
    }

    private fun parseAmountGroup(group: String): Double? {
        return group.replace(",", "").toDoubleOrNull()
    }

    /** 检查匹配位置是否在需要跳过的上下文中（账户号、日期等） */
    private fun isInSkippedContext(text: String, range: IntRange): Boolean {
        // 扩大检查范围：取匹配前后各10个字符
        val start = (range.first - 10).coerceAtLeast(0)
        val end = (range.last + 10).coerceAtMost(text.length - 1)
        val context = text.substring(start, end + 1)
        return skipPatterns.any { it.containsMatchIn(context) }
    }

    private fun extractMerchant(text: String, source: String): String? {
        // 微信格式：微信支付消费 ¥50.00 （商户：xxx）
        val merchantInParentheses = Regex("""[（(]商户[：:]?\s*(.+?)[）)]""").find(text)
        if (merchantInParentheses != null) {
            return merchantInParentheses.groupValues[1].trim()
        }

        // 支付宝格式：xxx成功付款50.00元
        val alipayPattern = Regex("""向\s*(.+?)\s*付款""")
        if (source == "alipay") {
            val match = alipayPattern.find(text)
            if (match != null) return match.groupValues[1].trim()
        }

        // 银行格式：尾号xxxx的卡支出/收入xxxx元 (商户: xxx)
        val bankMerchant = Regex("""商户[：:]\s*(.+?)(?:\s|$)""").find(text)
        if (bankMerchant != null) {
            return bankMerchant.groupValues[1].trim()
        }

        return null
    }
}
