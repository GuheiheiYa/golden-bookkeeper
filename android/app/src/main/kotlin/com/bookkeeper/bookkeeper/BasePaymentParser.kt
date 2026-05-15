package com.bookkeeper.bookkeeper

/**
 * 支付通知解析器基类接口
 *
 * 每个银行/平台可以实现此接口来定制自己的通知文本解析逻辑。
 * 不重写则使用 [DefaultPaymentParser] 的通用逻辑。
 *
 * ## 如何添加新解析器
 * 1. 创建一个实现 [BasePaymentParser] 的 class
 * 2. 覆盖 [parse] 方法，解析成功后返回 [ParsedPayment]
 * 3. 在 [PaymentParserFactory] 中注册包名到解析器的映射
 *
 * ## 解析流程
 * ```
 * 工厂收到包名 → 查找对应解析器 → 未找到则使用 DefaultPaymentParser
 *                    → 调用 parse(text, packageName, notificationId)
 *                    → 返回 ParsedPayment（含 amount/isExpense/merchant/goods/note）
 * ```
 *
 * @see DefaultPaymentParser 默认解析器（通用逻辑）
 * @see CmbPaymentParser 招商银行专用解析器（示例）
 * @see PaymentParserFactory 解析器工厂
 */
interface BasePaymentParser {

    /**
     * 解析通知文本，提取支付信息
     *
     * @param text       通知完整文本（title + bigText/text 拼接）
     * @param packageName 通知来源的 Android 包名
     * @param notificationId Android 系统通知唯一 ID
     * @return 解析成功返回 [ParsedPayment]，非支付通知或解析失败返回 null
     */
    fun parse(text: String, packageName: String, notificationId: Int = 0): ParsedPayment?
}
