package com.bookkeeper.bookkeeper

/**
 * 中信银行支付通知解析器
 *
 * ## 支持的格式
 *
 * 1. **存入（收入）**：`中信银行 您尾号9554的账户存入1.00元，点此查看详情。`
 * 2. **支出（通用）**：`中信银行 您尾号XXXX的账户支出XXX元`
 * 3. **消费**：`中信银行 您尾号XXXX的账户消费XXX元`
 * 4. **转入**：`中信银行 您尾号XXXX的账户转入XXX元`
 * 5. **转出**：`中信银行 您尾号XXXX的账户转出XXX元`
 *
 * ## 与默认解析器的差异
 * - **收入优先**：以"存入"开头的交易动作 → 判定为收入
 * - **金额提取**：使用 "XXX元" 后缀格式
 *
 * @see DefaultPaymentParser 默认解析器
 * @see BasePaymentParser 解析器接口
 */
class CiticPaymentParser : BasePaymentParser {

    companion object {
        /** 中信银行包名 */
        const val CITIC_BANK_PACKAGE = "com.ecitic.bank.mobile"
        /** 中信信用卡包名 */
        const val CITIC_CREDIT_PACKAGE = "com.citiccard.mobilebank"

        /** 金额正则："XXX元" */
        private val amountPattern = Regex("""(\d[\d,]*\.?\d{0,2})\s*元""")
    }

    // ═══════════════════════════════════════════════════════════
    // 收支方向判断
    // ═══════════════════════════════════════════════════════════

    /**
     * 收入关键词
     *
     * 中信银行通知中，"存入"表示存款/收入，"转入"表示转账收入。
     */
    private val incomeKeywords = listOf("存入", "转入", "到账", "退款")

    /** 支出关键词 */
    private val expenseKeywords = listOf("支出", "消费", "扣款", "转出", "付款")

    private fun determineIsExpense(text: String): Boolean {
        // 收入优先（避免"存入"被误判）
        if (incomeKeywords.any { text.contains(it) }) return false
        // 支出判断
        if (expenseKeywords.any { text.contains(it) }) return true
        // 默认支出
        return true
    }

    // ═══════════════════════════════════════════════════════════
    // 金额提取
    // ═══════════════════════════════════════════════════════════

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

    private fun extractMerchant(text: String): String? {
        // 商户格式："(商户: xxx)" 或 "（商户：xxx）"
        val merchantInParentheses = Regex("""[（(]商户[：:]?\s*(.+?)[）)]""").find(text)
        if (merchantInParentheses != null) {
            return merchantInParentheses.groupValues[1].trim()
        }
        return null
    }

    // ═══════════════════════════════════════════════════════════
    // 主入口
    // ═══════════════════════════════════════════════════════════

    override fun parse(text: String, packageName: String, notificationId: Int): ParsedPayment? {
        // 仅处理中信银行和中信信用卡通知
        if (packageName != CITIC_BANK_PACKAGE && packageName != CITIC_CREDIT_PACKAGE) return null

        if (text.isBlank()) return null

        val amount = extractAmount(text) ?: return null
        val isExpense = determineIsExpense(text)
        val merchant = extractMerchant(text)

        return ParsedPayment(
            amount = amount,
            isExpense = isExpense,
            merchant = merchant,
            source = "citic",
            rawText = text,
            packageName = packageName,
            timestamp = System.currentTimeMillis(),
            notificationId = notificationId,
            goods = if (!isExpense && text.contains("存入")) "账户存入" else null,
            note = merchant
        )
    }
}
