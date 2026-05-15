package com.bookkeeper.bookkeeper

/**
 * 支付通知解析器工厂
 *
 * 根据通知来源的 Android 包名，返回对应的 [BasePaymentParser] 实现。
 *
 * ## 注册新解析器
 * 在 [parsers] 映射表中添加新条目即可：
 * ```
 * "com.some.bank" to SomeBankPaymentParser()
 * ```
 *
 * 未注册的包名自动使用 [DefaultPaymentParser]（默认通用逻辑）。
 * 如果专用解析器无法处理（返回 null），会自动降级到默认解析器。
 *
 * ## 使用示例
 * ```kotlin
 * val parser = PaymentParserFactory.getParser(packageName)
 * val result = parser.parse(text, packageName, notificationId)
 * ```
 *
 * @see BasePaymentParser 解析器接口
 * @see DefaultPaymentParser 默认解析器
 * @see CmbPaymentParser 招商银行解析器
 */
object PaymentParserFactory {

    /** 专用解析器注册表 — 按 Android 包名索引 */
    private val parsers: Map<String, BasePaymentParser> = mapOf(
        WechatPaymentParser.WECHAT_PACKAGE to WechatPaymentParser(),
        AlipayPaymentParser.ALIPAY_PACKAGE to AlipayPaymentParser(),
        CmbPaymentParser.CMB_PACKAGE to CmbPaymentParser(),
        CiticPaymentParser.CITIC_BANK_PACKAGE to CiticPaymentParser(),
        CiticPaymentParser.CITIC_CREDIT_PACKAGE to CiticPaymentParser(),
    )

    /** 默认解析器（单例） */
    private val defaultParser: BasePaymentParser = DefaultPaymentParser

    /**
     * 获取包名对应的解析器
     *
     * 如果未注册专用解析器，返回 [DefaultPaymentParser]。
     *
     * @param packageName Android 包名，如 "cmb.pb"
     * @return [BasePaymentParser] 实现实例
     */
    fun getParser(packageName: String): BasePaymentParser {
        return parsers[packageName] ?: defaultParser
    }

    /**
     * 获取所有已注册的解析器
     *
     * 用于调试和日志输出。
     */
    fun getRegisteredParsers(): Map<String, String> {
        return parsers.mapValues { it.value::class.java.simpleName }
    }
}
