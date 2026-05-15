package com.bookkeeper.bookkeeper

/**
 * 招商银行支付通知解析器
 *
 * 招商银行通知格式：
 * ```
 * 招商银行您账户3832于05月15日09:20在【财付通-微信支付-厦门市集美区餐点点餐…】发生快捷支付扣款，人民币16.58
 * ```
 *
 * ## 解析策略
 * 1. **金额**：使用 "人民币" + 数字 格式提取（与默认解析器相同）
 * 2. **收支方向**：含"扣款"/"支付"关键词 → 支出
 * 3. **商户/备注**：提取 【...】 括号内的完整内容
 *    - [merchant]：括号内完整文本（如"财付通-微信支付-厦门市集美区餐点点餐"）
 *    - [note]：括号内完整文本（传递给备注字段）
 *    - [goods]：括号内最后一个 `-` 后的部分（如"厦门市集美区餐点点餐"）
 *
 * 括号末尾常有「…」省略号（通知被截断），解析时会自动去掉。
 *
 * @see DefaultPaymentParser 默认解析器
 * @see BasePaymentParser 解析器接口
 */
class CmbPaymentParser : BasePaymentParser {

    companion object {
        /** CMB 包名（对应 PaymentNotificationParser.packageSourceMap 中的 "cmb.pb"） */
        const val CMB_PACKAGE = "cmb.pb"

        /** 人民币金额正则 */
        private val renminbiPattern = Regex("""人民币\s*(\d[\d,]*\.?\d{0,2})""")

        /** 【】括号内容提取正则（带末尾省略号过滤） */
        private val bracketContentPattern = Regex("""【([^】]+)""")

        /** 末尾省略号（全角/半角） */
        private val trailingEllipsis = Regex("""[…...]+$""")
    }

    // ═══════════════════════════════════════════════════════════
    // 金额提取 — 复用与默认解析器相同的策略
    // ═══════════════════════════════════════════════════════════

    /**
     * 从文本中提取金额
     *
     * 招商银行使用"人民币"标记，优先级最高：
     * - "人民币16.58" → 16.58
     * - "人民币 1,234.56" → 1234.56
     *
     * @return 提取到的金额（正数），无匹配返回 null
     */
    private fun extractAmount(text: String): Double? {
        for (match in renminbiPattern.findAll(text)) {
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
    // 【】括号内容提取
    // ═══════════════════════════════════════════════════════════

    /**
     * 提取 【...】 括号内的内容
     *
     * 从 "在【财付通-微信支付-厦门市集美区餐点点餐…】" 中提取
     * → "财付通-微信支付-厦门市集美区餐点点餐"（去掉末尾省略号）
     *
     * @return 括号内文本（已去掉末尾省略号），无匹配返回 null
     */
    private fun extractBracketContent(text: String): String? {
        val match = bracketContentPattern.find(text) ?: return null
        var content = match.groupValues[1].trim()
        // 去掉末尾的省略号（全角…或半角...）
        content = trailingEllipsis.replaceFirst(content, "")
        return content.ifBlank { null }
    }

    // ═══════════════════════════════════════════════════════════
    // 商户名/商品名拆分
    // ═══════════════════════════════════════════════════════════

    /**
     * 从括号内容中拆分为商户和商品
     *
     * 规则：
     * - merchant：括号内的完整内容（如 "财付通-微信支付-厦门市集美区餐点点餐"）
     * - goods：最后一个 `-` 之后的部分（如 "厦门市集美区餐点点餐"）
     * - 如果没有 `-`，goods 取完整内容、merchant 取完整内容
     *
     * @return Pair(merchant, goods)，商品名可为 null
     */
    private fun splitMerchantAndGoods(bracketContent: String): Pair<String, String?> {
        val segments = bracketContent.split("-")
        return if (segments.size >= 2) {
            // merchant 取完整内容，goods 取最后一个段
            bracketContent to segments.last().trim().ifBlank { null }
        } else {
            // 没有分隔符，整个作为商户名，goods 取整个内容
            bracketContent to bracketContent.trim().ifBlank { null }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // 收支方向判断
    // ═══════════════════════════════════════════════════════════

    /** 支出关键词 — 通知文本包含任一即判定为支出 */
    private val expenseKeywords = listOf("扣款", "支付", "消费", "付款", "支出", "转出")

    /**
     * 判断收支方向
     *
     * 招商银行通知一般都是支出（扣款/支付），
     * 如果匹配到退款/转入等关键词则为收入。
     *
     * @return true = 支出，false = 收入
     */
    private fun determineIsExpense(text: String): Boolean {
        if (text.contains("退款") || text.contains("到账") || text.contains("收入") || text.contains("转入")) {
            return false
        }
        return expenseKeywords.any { text.contains(it) }
    }

    // ═══════════════════════════════════════════════════════════
    // 主入口：parse()
    // ═══════════════════════════════════════════════════════════

    override fun parse(text: String, packageName: String, notificationId: Int): ParsedPayment? {
        // 仅处理招商银行通知
        if (packageName != CMB_PACKAGE) return null

        // 空文本直接跳过
        if (text.isBlank()) return null

        // 提取金额
        val amount = extractAmount(text) ?: return null

        // 判断收支方向
        val isExpense = determineIsExpense(text)

        // 提取括号内容，拆分为商户名/商品名
        val bracketContent = extractBracketContent(text)
        val (merchant, goods) = if (bracketContent != null) {
            splitMerchantAndGoods(bracketContent)
        } else {
            // 没有括号内容时尝试通用商户提取
            val genericMerchant = extractFallbackMerchant(text)
            genericMerchant to null
        }

        // 备注 = 括号内完整内容（如果有），否则为 null
        val note = bracketContent

        return ParsedPayment(
            amount = amount,
            isExpense = isExpense,
            merchant = merchant,
            source = "cmb",  // 与 packageSourceMap 保持一致
            rawText = text,
            packageName = packageName,
            timestamp = System.currentTimeMillis(),
            notificationId = notificationId,
            goods = goods,
            note = note
        )
    }

    /**
     * 备用商户提取 — 当没有 【】 括号格式时使用
     *
     * 银行通用格式："尾号xxxx的卡支出/收入xxxx元 (商户: xxx)"
     */
    private fun extractFallbackMerchant(text: String): String? {
        val bankMerchant = Regex("""商户[：:]\s*(.+?)(?:\s|$)""").find(text)
        return bankMerchant?.groupValues?.get(1)?.trim()
    }
}
