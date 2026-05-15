package com.bookkeeper.bookkeeper

/**
 * 微信支付通知解析器
 *
 * ## 支持的格式
 *
 * | 格式 | 收支 | 示例 |
 * |------|------|------|
 * | 已支付 | 支出 | `微信支付 已支付¥0.01` |
 * | 已收款 | 收入 | `微信支付 已收款¥10.00` |
 * | 已退款 | 收入 | `微信支付 已退款¥20.00` |
 * | 已转入（零钱通等） | 收入 | `微信支付 零钱通转入¥50.00` |
 * | 向xxx转账 | 支出 | `你已成功向张三转账¥100.00` |
 * | xxx向你转账 | 收入 | `李四向你转账¥200.00` |
 *
 * ## 商户提取
 * 微信通知可能包含（商户：xxx）括号格式，解析器会提取作为商户名。
 *
 * @see DefaultPaymentParser 默认解析器
 * @see BasePaymentParser 解析器接口
 */
class WechatPaymentParser : BasePaymentParser {

    companion object {
        /** 微信包名 */
        const val WECHAT_PACKAGE = "com.tencent.mm"

        /** 金额正则：¥符号前缀或"元"后缀 */
        private val amountPattern = Regex("""[¥￥]\s*(\d[\d,]*\.?\d{0,2})""")
        private val yuanPattern = Regex("""(\d[\d,]*\.?\d{0,2})\s*元""")
    }

    // ═══════════════════════════════════════════════════════════
    // 收支方向判断
    // ═══════════════════════════════════════════════════════════

    private fun determineIsExpense(text: String): Boolean {
        // 明确收入
        if (text.contains("已收款") || text.contains("向你转账") || text.contains("零钱通转入")) return false
        // 明确支出
        if (text.contains("已支付") || text.contains("向") && text.contains("转账")) return true
        // 退款：退款到账是收入（钱回来了）
        if (text.contains("退款") || text.contains("已退款")) return false
        // 兜底：包含"支付"关键词 → 支出
        if (text.contains("支付")) return true
        return true
    }

    // ═══════════════════════════════════════════════════════════
    // 金额提取
    // ═══════════════════════════════════════════════════════════

    private fun extractAmount(text: String): Double? {
        // 优先 ¥ 符号
        for (match in amountPattern.findAll(text)) {
            val amount = match.groupValues[1].replace(",", "").toDoubleOrNull()
            if (amount != null && amount > 0 && amount <= 999999) return amount
        }
        // 后备 "元" 后缀
        for (match in yuanPattern.findAll(text)) {
            val amount = match.groupValues[1].replace(",", "").toDoubleOrNull()
            if (amount != null && amount > 0 && amount <= 999999) return amount
        }
        return null
    }

    // ═══════════════════════════════════════════════════════════
    // 商户/商品提取
    // ═══════════════════════════════════════════════════════════

    private fun extractMerchant(text: String): String? {
        // （商户：xxx）格式
        val bracket = Regex("""[（(]商户[：:]?\s*(.+?)[）)]""").find(text)
        if (bracket != null) return bracket.groupValues[1].trim()
        return null
    }

    private fun extractGoods(text: String): String? {
        // 转账格式："你已成功向张三转账" → "张三"
        val transferOut = Regex("""向\s*(.+?)\s*转账""").find(text)
        if (transferOut != null) return "转账给${transferOut.groupValues[1].trim()}"
        // 收款格式："张三向你转账" → "张三"
        val transferIn = Regex("""(.+?)向你转账""").find(text)
        if (transferIn != null) return "${transferIn.groupValues[1].trim()}转账"
        return null
    }

    // ═══════════════════════════════════════════════════════════
    // 主入口
    // ═══════════════════════════════════════════════════════════

    override fun parse(text: String, packageName: String, notificationId: Int): ParsedPayment? {
        if (packageName != WECHAT_PACKAGE) return null
        if (text.isBlank()) return null

        val amount = extractAmount(text) ?: return null
        val isExpense = determineIsExpense(text)
        val merchant = extractMerchant(text)
        val goods = extractGoods(text)

        return ParsedPayment(
            amount = amount,
            isExpense = isExpense,
            merchant = merchant,
            source = "wechat",
            rawText = text,
            packageName = packageName,
            timestamp = System.currentTimeMillis(),
            notificationId = notificationId,
            goods = goods,
            note = merchant
        )
    }
}
