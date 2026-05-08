# 记账本 (Bookkeeper)

一个功能完整、界面美观的记账 Android APP，采用 Claude 风格设计（紫色/靛蓝主色调）。

## 功能特性

### 核心功能
- **收支记录** - 快速记账，支持自定义数字键盘和计算器
- **分类管理** - 系统内置 + 自定义分类，支持图标和颜色自定义
- **账户管理** - 现金、银行卡、支付宝、微信等多种账户
- **标签系统** - 支持多标签关联，标签筛选

### 高级功能
- **多币种支持** - 支持 8 种常用货币，汇率缓存
- **统计报表** - 饼图、折线图、柱状图，多维度分析
- **预算管理** - 总预算和分类预算，进度跟踪
- **周期记账** - 自动记账规则，进入首页自动执行
- **数据导出** - CSV/Excel 导出，分享功能
- **账单导入** - 微信/支付宝账单导入接口

### UI/UX
- **Claude 风格设计** - 紫色/靛蓝主色调，简洁极简
- **深色/浅色模式** - 支持跟随系统自动切换
- **流畅动画** - flutter_animate 链式动画效果
- **卡片式设计** - 圆角卡片，微弱阴影
- **滑动操作** - 左滑编辑，右滑删除

## 技术栈

| 组件 | 选择 | 理由 |
|------|------|------|
| 框架 | Flutter | 跨平台，一套代码 |
| 状态管理 | Riverpod | 编译时安全，响应式 |
| 数据库 | sqflite | 本地 SQLite 存储 |
| 路由 | go_router | 声明式路由，嵌套导航 |
| 图表 | fl_chart | 饼图/折线图/柱状图 |
| 动画 | flutter_animate | 声明式链式动画 |

## 项目结构

```
lib/
├── main.dart                          # 应用入口
├── app/
│   ├── app.dart                       # MaterialApp 配置（主题、路由、国际化）
│   ├── router/app_router.dart         # go_router 路由定义
│   └── di/providers.dart              # Riverpod Provider 注册
├── core/
│   ├── database/
│   │   └── app_database.dart          # SQLite 数据库定义和 CRUD 操作
│   ├── theme/
│   │   ├── app_theme.dart             # 亮色/暗色主题配置
│   │   └── app_colors.dart            # 颜色常量（Claude 风格配色）
│   ├── constants/
│   │   └── currency_list.dart         # 币种列表和符号映射
│   └── utils/
│       └── currency_formatter.dart    # 货币格式化工具
├── features/
│   ├── home/
│   │   └── presentation/
│   │       └── home_screen.dart       # 首页（余额卡片、快捷操作、最近交易）
│   ├── transaction/
│   │   └── presentation/
│   │       ├── add_transaction_screen.dart  # 记账页面（数字键盘、分类选择）
│   │       └── transaction_list_screen.dart # 交易明细（搜索、筛选、分组列表）
│   ├── category/
│   │   └── presentation/
│   │       └── category_list_screen.dart    # 分类管理（拖拽排序、图标选择）
│   ├── account/
│   │   └── presentation/
│   │       └── account_list_screen.dart     # 账户管理
│   ├── tag/
│   │   └── presentation/
│   │       └── tag_list_screen.dart         # 标签管理
│   ├── statistics/
│   │   └── presentation/
│   │       └── statistics_screen.dart       # 统计报表
│   ├── budget/
│   │   └── presentation/
│   │       └── budget_screen.dart           # 预算管理
│   ├── recurring/
│   │   └── presentation/
│   │       └── recurring_screen.dart        # 周期记账
│   ├── import/
│   │   ├── presentation/
│   │   │   └── import_screen.dart           # 账单导入
│   │   └── domain/
│   │       ├── bill_parser.dart             # 账单解析接口
│   │       ├── wechat_parser.dart           # 微信账单解析
│   │       └── alipay_parser.dart           # 支付宝账单解析
│   └── settings/
│       └── presentation/
│           └── settings_screen.dart         # 设置页面
└── shared/
    ├── widgets/
    │   ├── app_card.dart              # 通用卡片组件
    │   ├── empty_state.dart           # 空状态提示组件
    │   └── loading_indicator.dart     # 加载指示器
    └── utils/
        └── icon_utils.dart            # 图标工具类（分类图标库）
```

## 数据库表结构

| 表名 | 描述 | 主要字段 |
|------|------|----------|
| accounts | 账户表 | name, type, currency, balance, icon, color |
| categories | 分类表 | name, is_expense, icon, color, parent_id, sort_order |
| transactions | 交易记录表 | amount, currency, is_expense, note, date, category_id, account_id |
| tags | 标签表 | name, color |
| transaction_tags | 交易-标签关联表 | transaction_id, tag_id |
| budgets | 预算表 | category_id, amount, period_type, year, month |
| recurring_rules | 周期记账规则表 | title, amount, frequency, day_of_month, start_date |
| exchange_rates | 汇率缓存表 | base_currency, target_currency, rate |

## 快速开始

### 环境要求
- Flutter SDK >= 3.2.0
- Android SDK
- Android Studio 或 VS Code

### 安装运行

```bash
# 克隆项目
git clone <repository-url>
cd bookkeeper

# 获取依赖
flutter pub get

# 运行应用
flutter run

# 构建 APK
flutter build apk --debug
```

### 安装到手机

```bash
# 连接手机后执行
flutter install
```

## 开发命令

```bash
# 代码分析
flutter analyze

# 格式化代码
dart format lib/

# 运行测试
flutter test
```

## 页面导航

| Tab | 页面 | 功能 |
|-----|------|------|
| 首页 | HomeScreen | 余额概览、预算进度、最近交易、快速记账 |
| 明细 | TransactionListScreen | 按日分组交易列表、搜索筛选 |
| 统计 | StatisticsScreen | 饼图/折线图/柱状图、周/月/年维度 |
| 设置 | SettingsScreen | 主题切换、账户/分类/标签管理、数据导入导出 |

## 主题配色

- **主色调**: `#7C3AED` (紫色) + `#6366F1` (靛蓝)
- **收入色**: `#10B981` (绿色)
- **支出色**: `#EF4444` (红色)
- **警告色**: `#F59E0B` (橙色)
- **深色背景**: `#0F0F23`

## 文档

- [功能文档](docs/features.md) - 详细功能说明
- [更新日志](docs/changelog.md) - 版本更新记录
- [需求文档](docs/requirements.md) - 产品需求设计
- [变更记录](docs/changes.md) - 每次修改记录

## License

MIT License
