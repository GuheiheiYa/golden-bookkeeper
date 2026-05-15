package com.bookkeeper.bookkeeper

/**
 * 支付宝支付通知解析器
 *
 * ## 支持的格式
 *
 * 1. **支出（通用）**：`交易提醒 你有一笔{金额}元的支出，点此查看详情。`
 * 2. **收款（收入）**：`你已成功收款{金额}元（{来源}） 已转入余额`
 * 3. **转账到账（收入）**：`xxx向你转账{金额}元`
 * 4. **付款（支出）**：`向xxx付款{金额}元`
 *
 * ## 与默认解析器的差异
 * - **收支判断优先检查开头关键词**：以"收款"/"到账"开头 → 收入，避免"消费"等次级关键词干扰
 * - **商户提取**：支持收款括号格式 `（来源描述）` 和转账格式
 * - **所有字段均不依赖 packageSourceMap**：因为工厂已路由到该解析器
 *
 * @see DefaultPaymentParser 默认解析器
 * @see BasePaymentParser 解析器接口
 */
class AlipayPaymentParser : BasePaymentParser {

    companion object {
        /** 支付宝包名 */
        const val ALIPAY_PACKAGE = "com.eg.android.AlipayGphone"

        /** 人民币金额正则 */
        private val amountPattern = Regex("""(\d[\d,]*\.?\d{0,2})\s*元""")
    }

    // ═══════════════════════════════════════════════════════════
    // 收支方向判断（支付宝专用）
    // ═══════════════════════════════════════════════════════════

    /**
     * 收入前缀关键词 — 通知以这些词开头时，判定为收入
     *
     * 例如："你已成功收款0.01元"、"收到转账0.01元"
     */
    private val incomePrefixKeywords = listOf(
        "你已成功收款", "你已收款", "收到转账", "到账", "收入",
    )

    /** 收入包含关键词 */
    private val incomeKeywords = listOf(
        "向你转账", "转入余额", "已转入", "红包",
    )

    /** 支出包含关键词 */
    private val expenseKeywords = listOf(
        "支出", "付款", "消费", "扣款", "支付",
    )

    /**
     * 判断收支方向
     *
     * 优先级：
     * 1. 文本以"收款"/"到账"前缀开头 → 收入（权重最高）
     * 2. 包含"向你转账"等收入关键词 → 收入
     * 3. 包含"支出"/"付款"等支出关键词 → 支出
     * 4. 无法判断时默认支出
     */
    private fun determineIsExpense(text: String): Boolean {
        // 优先级 1：收入前缀（最明确）
        for (prefix in incomePrefixKeywords) {
            if (text.startsWith(prefix)) return false
        }
        // 优先级 2：收入关键词
        if (incomeKeywords.any { text.contains(it) }) return false
        // 优先级 3：支出关键词
        if (expenseKeywords.any { text.contains(it) }) return true
        // 默认：支出
        return true
    }

    // ═══════════════════════════════════════════════════════════
    // 金额提取
    // ═══════════════════════════════════════════════════════════

    /**
     * 从文本中提取金额
     *
     * 支付宝格式："0.01元" → 0.01
     */
    private fun extractAmount(text: String): Double? {
        for (match in amountPattern.findAll(text)) {
            val amount = match.groupValues[1]
                .replace(",", "")
                .toDoubleOrNull()
            if (amount != null && amount > 0 && amount <= 999999) {
                return amount
            }
        }
        return null
    }

    // ═══════════════════════════════════════════════════════════
    // 商户名提取
    // ═══════════════════════════════════════════════════════════

    /**
     * 提取商户名
     *
     * 支持的格式：
     * - 收款：`你已成功收款0.01元（新顾客消费）` → "新顾客消费"
     * - 转账：`xxx向你转账0.01元` → "xxx"
     * - 付款：`向xxx付款0.01元` → "xxx"
     * - 通用支出：无详细商户信息，返回 null
     */
    private fun extractMerchant(text: String): String? {
        // 格式 1：收款括号 "你已成功收款0.01元（新顾客消费）"
        val incomeBracket = Regex("""收款[\d.,]+元[（(]\s*(.+?)\s*[）)]""").find(text)
        if (incomeBracket != null) {
            return incomeBracket.groupValues[1].trim()
        }

        // 格式 2：转账 "xxx向你转账0.01元"
        val transferPattern = Regex("""(.+?)向你转账""").find(text)
        if (transferPattern != null) {
            return transferPattern.groupValues[1].trim()
        }

        // 格式 3：付款 "向xxx付款0.01元"
        val payPattern = Regex("""向\s*(.+?)\s*付款""").find(text)
        if (payPattern != null) {
            return payPattern.groupValues[1].trim()
        }

        // 格式 4：贷款/金融 "你借的xxx已到账"
        val loanPattern = Regex("""你借的(.+?)已到账""").find(text)
        if (loanPattern != null) {
            return loanPattern.groupValues[1].trim()
        }

        return null
    }

    // ═══════════════════════════════════════════════════════════
    // 商品/备注提取
    // ═══════════════════════════════════════════════════════════

    /**
     * 提取商品名
     *
     * 对于收款通知，括号内的来源描述作为商品名：
     * "你已成功收款0.01元（新顾客消费）" → goods = "新顾客消费"
     */
    private fun extractGoods(text: String): String? {
        // 收款括号内容
        val bracket = Regex("""[（(]\s*(.+?)\s*[）)]""").find(text)
        if (bracket != null) {
            return bracket.groupValues[1].trim().ifBlank { null }
        }
        return null
    }

    // ═══════════════════════════════════════════════════════════
    // 主入口
    // ═══════════════════════════════════════════════════════════

    // ═══════════════════════════════════════════════════════════
    // 非交易通知排除
    // ═══════════════════════════════════════════════════════════

    /**
     * 交易相关关键词 — 通知文本必须包含至少一个才被认为是支付通知
     *
     * 用于过滤营销/卡包/信用分等非交易通知（如"淘宝闪购18元红包今晚失效"）。
     */
    private val transactionKeywords = listOf(
        "支出", "消费", "扣款", "支付", "付款",
        "收款", "到账", "转账", "转入", "退款",
        "红包", "收益", "利息",
    )

    /**
     * 排除关键词 — 通知包含这些词且无交易关键词时，直接跳过
     *
     * 用于识别"红包失效"、"账单提醒"等非交易场景。
     */
    private val exclusionKeywords = listOf(
        "过期", "失效", "提醒", "通知", "额度",
    )

    /**
     * 判断是否为有效的交易通知
     *
     * 支付宝有大量非交易通知（营销、卡券、信用提醒等），
     * 只有在文本中包含交易关键词时，才进行后续解析。
     */
    private fun isTransactionNotification(text: String): Boolean {
        // 必须包含至少一个交易关键词
        val hasTransactionKeyword = transactionKeywords.any { text.contains(it) }
        if (!hasTransactionKeyword) return false

        // 如果包含排除关键词，检查是否也有明确的交易语义
        // "红包失效" → 不是交易；"收到红包" → 是交易
        val hasExclusion = exclusionKeywords.any { text.contains(it) }
        if (hasExclusion) {
            // 排除关键词场景下，必须有"收到"/"到账"/"收款"等明确交易前缀才放行
            val strongIncome = incomePrefixKeywords.any { text.contains(it) }
            val strongExpense = listOf("支出", "扣款", "付款").any { text.contains(it) }
            if (!strongIncome && !strongExpense) return false
        }

        return true
    }

    override fun parse(text: String, packageName: String, notificationId: Int): ParsedPayment? {
        // 仅处理支付宝通知
        if (packageName != ALIPAY_PACKAGE) return null

        // 空文本直接跳过
        if (text.isBlank()) return null

        // 非交易通知过滤（营销/卡券等）
        if (!isTransactionNotification(text)) return null

        // 提取金额
        val amount = extractAmount(text) ?: return null

        // 判断收支方向
        val isExpense = determineIsExpense(text)

        // 提取商户
        val merchant = extractMerchant(text)

        // 提取商品名（括号内来源描述）
        val goods = extractGoods(text)

        return ParsedPayment(
            amount = amount,
            isExpense = isExpense,
            merchant = merchant,
            source = "alipay",
            rawText = text,
            packageName = packageName,
            timestamp = System.currentTimeMillis(),
            notificationId = notificationId,
            goods = goods,
            note = merchant  // 商户描述也放进备注
        )
    }
}
