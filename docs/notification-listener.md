# 支付通知监听 — 自动记账 技术文档

> 版本：v1.9.0（重构） | 更新日期：2026-05-14

---

## 一、功能概述

通过 Android 系统的 `NotificationListenerService` 监听微信、支付宝、各银行 APP 推送到状态栏的通知，自动识别付款/收款信息，静默写入待确认表，经用户确认后创建交易记录。

**核心特点：**
- 无需任何敏感权限，仅需用户在系统设置中授权"通知访问权限"
- 服务由 Android 系统管理，APP 被杀死后仍可运行
- 检测到支付后静默入库，用户在待确认列表中统一处理

---

## 二、整体架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Android 系统通知栏                        │
│  （微信/支付宝/银行 APP 推送的通知消息）                      │
└──────────────────────────┬──────────────────────────────────┘
                           │ onNotificationPosted()
                           ▼
┌─────────────────────────────────────────────────────────────┐
│        PaymentNotificationListenerService（Kotlin）          │
│        继承 NotificationListenerService                      │
│                                                             │
│  1. 包名白名单过滤                                           │
│  2. 提取通知文本（title + bigText + text）                   │
│  3. 调用 PaymentNotificationParser 解析                     │
│  4. 写入 SQLite（去重：120秒内相同来源+金额+商户不重复）      │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              pending_payments.db（Android 原生 SQLite）       │
│              status = 'pending' 的待确认记录                  │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                Flutter UI 层                                 │
│                                                             │
│  PendingNotificationsScreen（待确认列表页）                  │
│  ├─ 单条确认：自动匹配"其他"分类 + 默认账户 → 创建交易       │
│  ├─ 忽略：标记为已处理                                       │
│  ├─ 全部确认：批量创建交易                                   │
│  └─ 清空：删除所有记录                                       │
│                                                             │
│  确认后：                                                   │
│  ├─ db.insertTransaction() 写入交易记录                     │
│  ├─ markPaymentProcessed() 标记原生记录为已处理              │
│  └─ 更新账户余额                                            │
└─────────────────────────────────────────────────────────────┘
```

---

## 三、文件清单与职责

### Android 原生层（Kotlin）

| 文件 | 路径 | 职责 |
|------|------|------|
| **PaymentNotificationListenerService.kt** | `android/.../kotlin/.../` | 核心服务：监听系统通知、解析、存储 |
| **PaymentNotificationParser.kt** | 同上 | 通知文本解析器：正则提取金额/商户/收支方向 |
| **MainActivity.kt** | 同上 | MethodChannel 桥接 |

### Flutter 层（Dart）

| 文件 | 路径 | 职责 |
|------|------|------|
| **payment_notification_service.dart** | `lib/core/services/` | Flutter 端通信服务（单例） |
| **pending_notifications_screen.dart** | `lib/features/notification/presentation/` | 待确认列表页（单条确认/忽略/全部确认） |
| **notification_settings_screen.dart** | 同上 | 权限设置页（检查权限/引导授权/APP 开关） |

### 配置文件

| 文件 | 职责 |
|------|------|
| `AndroidManifest.xml` | 声明 `BIND_NOTIFICATION_LISTENER_SERVICE` 权限 + 服务注册 |

---

## 四、详细调用链

### 4.1 通知到达（完整链路）

```
Android 系统
  └─ 通知栏有新通知
      └─ PaymentNotificationListenerService.onNotificationPosted(sbn)
          │
          ├─ 1. sbn.packageName → 包名白名单过滤
          │     └─ getWatchedPackages() 从 SharedPreferences 读取
          │     └─ 不在白名单 → return（忽略）
          │
          ├─ 2. 提取通知文本
          │     ├─ extras["android.title"]   → title
          │     ├─ extras["android.text"]    → text
          │     ├─ extras["android.bigText"] → bigText（微信完整文本）
          │     └─ 拼接: fullText = title + bigText/text
          │
          ├─ 3. PaymentNotificationParser.parse(fullText, packageName)
          │     ├─ packageSourceMap[packageName] → 确定来源（wechat/alipay/...）
          │     ├─ extractAmount(fullText) → 按优先级正则提取金额
          │     │     ├─ 优先级1: 人民币XXX
          │     │     ├─ 优先级2: ¥/￥XXX
          │     │     ├─ 优先级3: XXX元
          │     │     └─ 优先级4: X.XX（跳过账户号/日期/时间）
          │     ├─ 收支关键词判断 isExpense
          │     └─ extractMerchant(fullText, source) → 提取商户名
          │     └─ 返回 ParsedPayment（或 null → 不是支付通知）
          │
          └─ 4. saveToDatabase(parsed)
                ├─ 去重检查: 120秒内 source+amount+merchant 相同 → 跳过
                └─ insert into pending_payments (status='pending')
```

### 4.2 用户确认记账

```
PendingNotificationsScreen._confirmOne(notification)
  │
  ├─ 1. db.getDefaultAccountBySource(source) → 匹配账户
  ├─ 2. db.getCategories() → 找"其他"分类
  │
  ├─ 3. db.insertTransaction({...})
  │     └─ 写入 Flutter sqflite 数据库的 transactions 表
  │
  ├─ 4. PaymentNotificationService().markPaymentProcessed(id)
  │     └─ MethodChannel → MainActivity → PendingPaymentDbHelper.markAsProcessed(id)
  │         └─ UPDATE pending_payments SET status='confirmed' WHERE id=?
  │
  └─ 5. db.updateAccount(accountId, {'balance': newBalance})
        └─ 支出: balance - amount | 收入: balance + amount
```

### 4.3 全部确认（批量）

```
PendingNotificationsScreen._confirmAll()
  │
  └─ 遍历 _notifications 列表
      │
      ├─ db.getDefaultAccountBySource(source) → 匹配账户
      ├─ db.getCategories(isExpense: isExpense) → 找"其他"分类
      ├─ db.insertTransaction({...}) → 创建交易
      ├─ service.markPaymentProcessed(id) → 标记已处理
      └─ db.updateAccount(accountId, {'balance': newBalance})
```

### 4.4 权限设置流程

```
NotificationSettingsScreen
  │
  ├─ _loadStatus()
  │     ├─ PaymentNotificationService().isPermissionEnabled()
  │     │     └─ MethodChannel → MainActivity.isNotificationListenerEnabled()
  │     │         └─ Settings.Secure.getString("enabled_notification_listeners")
  │     │             └─ 检查是否包含本应用包名
  │     └─ PaymentNotificationService().getWatchedPackages()
  │           └─ MethodChannel → SharedPreferences 读取
  │
  ├─ 用户点击"前往系统设置授权"
  │     └─ PaymentNotificationService().openPermissionSettings()
  │         └─ MethodChannel → MainActivity.openNotificationListenerSettings()
  │             └─ Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
  │
  └─ 用户切换 APP 开关
        └─ _togglePackage(packageName, enable)
            └─ PaymentNotificationService().setWatchedPackages(packages)
                └─ MethodChannel → SharedPreferences 写入
```

---

## 五、两个数据库的关系

| 特性 | Flutter 端（sqflite） | Android 原生端（SQLiteOpenHelper） |
|------|----------------------|----------------------------------|
| 文件 | `bookkeeper.db` | `pending_payments.db` |
| 管理者 | AppDatabase（Dart） | PendingPaymentDbHelper（Kotlin） |
| 核心表 | transactions, accounts, categories... | pending_payments |
| 访问方式 | Dart 代码直接调用 | Kotlin 代码 + MethodChannel 桥接 |
| 数据流向 | 交易确认后写入 | 通知检测后写入，确认后标记 |

**为什么是两个独立数据库？**

`PaymentNotificationListenerService` 是 Android 系统服务，运行在原生层，无法直接访问 Flutter 的 sqflite 数据库。因此使用独立的 `PendingPaymentDbHelper` 管理待确认记录，通过 MethodChannel 与 Flutter 通信。

---

## 六、MethodChannel 接口文档

**通道名称：** `com.bookkeeper.bookkeeper/payment_notification`

### Flutter → Android（请求）

| 方法名 | 参数 | 返回值 | 说明 |
|--------|------|--------|------|
| `isNotificationListenerEnabled` | 无 | `bool` | 检查通知监听权限 |
| `openNotificationListenerSettings` | 无 | `true` | 跳转系统设置 |
| `getWatchedPackages` | 无 | `List<String>` | 获取监听 APP 列表 |
| `setWatchedPackages` | `List<String>` | `true` | 保存监听 APP 列表 |
| `getPendingPayments` | 无 | `List<Map>` | 获取所有待确认记录 |
| `markPaymentProcessed` | `int` (id) | `true` | 标记记录已处理 |
| `clearPendingPayments` | 无 | `true` | 清空所有待处理记录 |

---

## 七、金额解析规则

### 优先级（从高到低）

| 优先级 | 正则模式 | 示例 | 说明 |
|--------|----------|------|------|
| 1 | `人民币\s*(\d[\d,]*\.?\d{0,2})` | `人民币50.00` | 最可信，明确标记 |
| 2 | `[¥￥]\s*(\d[\d,]*\.?\d{0,2})` | `¥50.00` / `￥50.00` | 常见货币符号 |
| 3 | `(\d[\d,]*\.?\d{0,2})\s*元` | `50.00元` | 中文"元"后缀 |
| 4 | `(\d[\d,]*\.\d{1,2})` | `50.00` | 仅当前三种无匹配时使用，需两位小数 |

### 干扰数字过滤（优先级 4 专用）

以下上下文中的数字会被跳过：
- `账户 3832` — 银行卡号
- `2024年` — 年份
- `05月13日` — 日期
- `11:26` — 时间
- `尾号3832` — 卡号后四位

### 安全校验

- 金额必须 > 0
- 金额必须 ≤ 999,999（防止天文数字误识别）

---

## 八、去重机制

```
时间线：
  T=0s    通知A到达 → 写入 DB
  T=5s    通知A再次到达（系统回调） → 检查: source+amount+merchant 在 120秒内已存在 → 跳过
  T=60s   通知A第三次到达 → 跳过
  T=130s  通知A第四次到达 → 距上次 > 120秒 → 重新写入
```

**去重三要素：** `source` + `amount` + `merchant`
**时间窗口：** 120 秒

---

## 九、支持的 APP

| APP | 包名 | 来源标识 | 通知特点 |
|-----|------|---------|---------|
| 微信 | `com.tencent.mm` | wechat | `¥XX.XX` 或 `消费XX元`，商户在括号内 |
| 支付宝 | `com.eg.android.AlipayGphone` | alipay | `向 XX 付款XX元` |
| 招商银行 | `cmb.pb` | cmb | `支出/收入XXXX元 (商户: XX)` |
| 工商银行 | `com.icbc` | icbc | 同上 |
| 中国银行 | `com.chinamworld.bocmbci` | boc | 同上 |
| 农业银行 | `com.abchina.abc` | abc | 同上 |
| 建设银行 | `com.ccb.start` | ccb | 同上 |
| 邮储银行 | `com.yitong.mbank.psbc` | psbc | 同上 |
| 平安银行 | `com.pingan.pacemaker` | pingan | 同上 |
| 中信银行 | `com.citiccard.mobilebank` | citic | 同上 |

可通过设置页动态增删。

---

## 十、已知限制

1. **误识别**：非付款通知中恰好包含类似金额的数字（如 APP 版本号 7.11）+ 支出关键词时，可能被误识别为付款通知
2. **通知格式变化**：各 APP 更新后通知格式可能变化，需更新正则规则
3. **微信聊天消息**：微信聊天通知也可能包含支付关键词（如"我付了50元"），导致误识别
4. **多设备**：通知监听仅在本机生效，不支持跨设备
5. **币种**：目前仅支持人民币（CNY），不支持外币通知
