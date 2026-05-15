# 数据库存储说明

## 技术栈

- **数据库引擎**: SQLite
- **Flutter 插件**: sqflite
- **ORM**: 无（原生 SQL 查询）
- **原生数据库**: `pending_payments` 表使用原生 `sqflite` API（独立于 ORM 层）

## 数据库位置

### Android 设备
```
/data/data/com.bookkeeper.bookkeeper/databases/bookkeeper.db
```

### ADB 调试
```bash
# 进入应用数据目录
adb shell run-as com.bookkeeper.bookkeeper ls databases/

# 导出数据库
adb shell run-as com.bookkeeper.bookkeeper cat databases/bookkeeper.db > bookkeeper.db

# 直接查询
adb shell run-as com.bookkeeper.bookkeeper sqlite3 databases/bookkeeper.db
```

### Web 平台
使用内存数据库（`inMemoryDatabasePath`），数据不持久化。

---

## 数据库版本

| 版本 | 日期 | 变更 |
|------|------|------|
| 3 | 2026-05-12 | categories 表新增 `loan_id` 字段（关联贷款账户） |
| 2 | 2026-05-08 | transactions 表新增 `goods` 字段 |
| 1 | 2026-05-06 | 初始版本，创建所有基础表 |

### Native SQLite 版本（pending_payments.db）

| 版本 | 日期 | 变更 |
|------|------|------|
| 3 | 2026-05-15 | 新增 `goods` 和 `note` 字段（策略解析器提取的精确信息） |
| 2 | 2026-05-12 | 新增 `notification_id` 及通知元数据字段（title/text/bigText 等） |
| 1 | 2026-05-12 | 初始版本，创建 `pending_payments` 表 |

### 迁移脚本

```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute('ALTER TABLE transactions ADD COLUMN goods TEXT');
  }
  if (oldVersion < 3) {
    await db.execute('ALTER TABLE categories ADD COLUMN loan_id INTEGER REFERENCES accounts(id)');
  }
}
```

---

## 数据库表结构

### accounts — 账户表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| name | TEXT | 账户名称 |
| type | TEXT | 账户类型（cash/bank/alipay/wechat/loan） |
| currency | TEXT | 币种，默认 CNY |
| balance | REAL | 余额 |
| icon | TEXT | 图标名称 |
| color | INTEGER | 颜色值 |
| include_in_total | INTEGER | 是否计入总资产（1=是，0=否） |
| sort_order | INTEGER | 排序 |
| created_at | TEXT | 创建时间 |

**type 值说明**:
- `cash` — 现金
- `bank` — 银行卡
- `alipay` — 支付宝
- `wechat` — 微信
- `loan` — 贷款账户（房贷/车贷/信用贷/网贷/其他）

贷款账户通过 `type = 'loan'` 标识，账户管理页面过滤掉贷款，贷款管理页面只显示贷款。

---

### categories — 分类表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| name | TEXT | 分类名称 |
| is_expense | INTEGER | 是否支出（1=支出，0=收入） |
| icon | TEXT | 图标名称 |
| color | INTEGER | 颜色值 |
| sort_order | INTEGER | 排序 |
| is_system | INTEGER | 是否系统内置（1=内置不可删，0=自定义） |
| loan_id | INTEGER FK | 关联贷款账户 ID（v3 新增，仅支出分类可用） |
| created_at | TEXT | 创建时间 |

**loan_id 逻辑**:
- 仅支出分类（`is_expense = 1`）可设置
- 关联后，记账时自动从对应的贷款账户扣减余额
- 编辑/删除交易时自动调整或恢复贷款余额

---

### transactions — 交易记录表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| amount | REAL | 金额 |
| currency | TEXT | 币种，默认 CNY |
| exchange_rate | REAL | 汇率，默认 1.0 |
| is_expense | INTEGER | 是否支出（1=支出，0=收入） |
| note | TEXT | 备注 |
| goods | TEXT | 商品名称（v2 新增） |
| date | TEXT | 交易日期 |
| category_id | INTEGER FK | 分类 ID |
| account_id | INTEGER FK | 账户 ID |
| recurring_rule_id | INTEGER FK | 周期规则 ID（可为 NULL） |
| image_path | TEXT | 图片路径 |
| created_at | TEXT | 创建时间 |
| updated_at | TEXT | 更新时间 |

---

### tags — 标签表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| name | TEXT | 标签名称 |
| color | INTEGER | 颜色值 |
| created_at | TEXT | 创建时间 |

---

### transaction_tags — 交易标签关联表

| 字段 | 类型 | 说明 |
|------|------|------|
| transaction_id | INTEGER FK | 交易 ID |
| tag_id | INTEGER FK | 标签 ID |

联合主键: (transaction_id, tag_id)

---

### budgets — 预算表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| category_id | INTEGER FK | 分类 ID（NULL 表示总预算） |
| amount | REAL | 预算金额 |
| period_type | TEXT | 周期类型（monthly/yearly） |
| year | INTEGER | 年份 |
| month | INTEGER | 月份 |
| currency | TEXT | 币种 |

---

### recurring_rules — 周期记账规则表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| title | TEXT | 规则名称 |
| amount | REAL | 金额 |
| currency | TEXT | 币种 |
| is_expense | INTEGER | 是否支出 |
| category_id | INTEGER FK | 分类 ID |
| account_id | INTEGER FK | 账户 ID |
| frequency | TEXT | 频率（minutely/hourly/daily/weekly/monthly/yearly） |
| day_of_month | INTEGER | 每月几号 |
| start_date | TEXT | 开始日期 |
| is_active | INTEGER | 是否启用 |
| last_executed | TEXT | 上次执行时间 |
| created_at | TEXT | 创建时间 |

---

### exchange_rates — 汇率缓存表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| from_currency | TEXT | 源币种 |
| to_currency | TEXT | 目标币种 |
| rate | REAL | 汇率 |
| updated_at | TEXT | 更新时间 |

---

### pending_payments — 待确认支付表（v1.9.0）

> 注意：此表使用原生 sqflite API 管理，独立于主数据库 ORM 层。

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| notification_id | INTEGER | Android 系统通知 ID |
| amount | REAL | 金额 |
| is_expense | INTEGER | 是否支出 |
| merchant | TEXT | 商户名称（列表展示用） |
| goods | TEXT | 商品名称（由策略解析器提取，如 CMB 解析器从【】中拆出） |
| note | TEXT | 备注（由策略解析器提取，默认为 raw_text） |
| source | TEXT | 来源 APP（wechat/alipay/cmb/icbc/boc 等） |
| raw_text | TEXT | 原始通知全文 |
| package_name | TEXT | 来源包名 |
| notification_time | INTEGER | 通知时间戳 |
| status | TEXT | 状态（pending/confirmed/ignored） |
| category_id | INTEGER | 自动匹配的分类 ID |
| account_id | INTEGER | 自动匹配的账户 ID |
| ... | ... | 其他通知元数据字段 |

**goods 和 note 字段**：
- 默认解析器（DefaultPaymentParser）不设置此字段，Flutter 端 fallback 到 merchant/raw_text
- 专用解析器（如 CmbPaymentParser）可以从通知文本中提取更精确的信息
- 例如 CMB 通知 `【财付通-微信支付-厦门市集美区餐点点餐…】` → goods=`厦门市集美区餐点点餐`, note=`财付通-微信支付-厦门市集美区餐点点餐`

**数据流**:
- v1.9.0：NotificationListenerService 检测到支付 → 写入此表（status='pending'）→ 用户打开待确认列表处理
- goods/note 字段在 v1.9.0 的后续优化中加入（PendingPaymentDbHelper 版本 2→3）

---

## 默认数据

### 默认支出分类（10 个）
餐饮、交通、购物、娱乐、居住、医疗、教育、通讯、转账、其他

### 默认收入分类（4 个）
工资、奖金、投资、其他

### 默认账户（4 个）
现金、银行卡、支付宝、微信

---

## 数据备份与恢复

### 备份
```bash
adb shell run-as com.bookkeeper.bookkeeper cp databases/bookkeeper.db /sdcard/bookkeeper_backup.db
adb pull /sdcard/bookkeeper_backup.db
```

### 恢复
```bash
adb push bookkeeper_backup.db /sdcard/
adb shell run-as com.bookkeeper.bookkeeper cp /sdcard/bookkeeper_backup.db databases/bookkeeper.db
```

---

*最后更新: 2026-05-13 · 文档整理*
