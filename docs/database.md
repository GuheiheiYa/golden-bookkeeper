# 数据库存储说明

## 数据库技术栈

- **数据库引擎**: SQLite
- **Flutter 插件**: sqflite
- **ORM**: 无（原生 SQL 查询）

## 数据库存放位置

### Android 设备

```
/data/data/com.bookkeeper.bookkeeper/databases/bookkeeper.db
```

完整路径说明：
- 包名: `com.bookkeeper.bookkeeper`
- 数据库文件名: `bookkeeper.db`
- 通过 `getApplicationDocumentsDirectory()` 获取应用文档目录

### 开机调试路径

使用 adb 访问数据库：
```bash
# 进入应用数据目录
adb shell run-as com.bookkeeper.bookkeeper ls databases/

# 导出数据库到电脑
adb shell run-as com.bookkeeper.bookkeeper cat databases/bookkeeper.db > bookkeeper.db

# 使用 sqlite3 查看数据
adb shell run-as com.bookkeeper.bookkeeper sqlite3 databases/bookkeeper.db
```

### Web 平台

Web 平台使用内存数据库（`inMemoryDatabasePath`），数据不持久化。

## 数据库版本

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| 1 | 2026-05-06 | 初始版本，创建所有表 |
| 2 | 2026-05-08 | transactions 表新增 goods 字段 |

## 数据库表结构

### accounts - 账户表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| name | TEXT | 账户名称 |
| type | TEXT | 账户类型（cash/bank/alipay/wechat） |
| currency | TEXT | 币种，默认 CNY |
| balance | REAL | 余额 |
| icon | TEXT | 图标名称 |
| color | INTEGER | 颜色值 |
| include_in_total | INTEGER | 是否计入总资产（1/0） |
| sort_order | INTEGER | 排序顺序 |
| created_at | TEXT | 创建时间 |

### categories - 分类表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| name | TEXT | 分类名称 |
| is_expense | INTEGER | 是否支出（1=支出，0=收入） |
| icon | TEXT | 图标名称 |
| color | INTEGER | 颜色值 |
| sort_order | INTEGER | 排序顺序 |
| is_system | INTEGER | 是否系统内置（1=内置，0=自定义） |
| created_at | TEXT | 创建时间 |

### transactions - 交易记录表

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
| recurring_rule_id | INTEGER FK | 周期规则 ID |
| image_path | TEXT | 图片路径 |
| created_at | TEXT | 创建时间 |
| updated_at | TEXT | 更新时间 |

### tags - 标签表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| name | TEXT | 标签名称 |
| color | INTEGER | 颜色值 |
| created_at | TEXT | 创建时间 |

### transaction_tags - 交易标签关联表

| 字段 | 类型 | 说明 |
|------|------|------|
| transaction_id | INTEGER FK | 交易 ID |
| tag_id | INTEGER FK | 标签 ID |

### budgets - 预算表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| category_id | INTEGER FK | 分类 ID（NULL 表示总预算） |
| amount | REAL | 预算金额 |
| period_type | TEXT | 周期类型（monthly/yearly） |
| year | INTEGER | 年份 |
| month | INTEGER | 月份 |
| currency | TEXT | 币种 |

### recurring_rules - 周期记账规则表

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

### exchange_rates - 汇率缓存表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER PK | 主键 |
| from_currency | TEXT | 源币种 |
| to_currency | TEXT | 目标币种 |
| rate | REAL | 汇率 |
| updated_at | TEXT | 更新时间 |

## 数据备份与恢复

### 备份方法

使用 adb 导出数据库：
```bash
adb shell run-as com.bookkeeper.bookkeeper cp databases/bookkeeper.db /sdcard/bookkeeper_backup.db
adb pull /sdcard/bookkeeper_backup.db
```

### 恢复方法

```bash
adb push bookkeeper_backup.db /sdcard/
adb shell run-as com.bookkeeper.bookkeeper cp /sdcard/bookkeeper_backup.db databases/bookkeeper.db
```

## 数据库迁移

数据库版本升级时，`onUpgrade` 方法会自动执行迁移脚本：

```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // v2: transactions 表新增 goods 字段
    await db.execute('ALTER TABLE transactions ADD COLUMN goods TEXT');
  }
}
```

## 默认数据

### 默认支出分类
餐饮、交通、购物、娱乐、居住、医疗、教育、通讯、转账、其他

### 默认收入分类
工资、奖金、投资、其他

### 默认账户
现金、银行卡、支付宝、微信
