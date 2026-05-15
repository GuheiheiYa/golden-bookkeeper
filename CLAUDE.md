# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**项目名称**: 记账本 (Bookkeeper)
**版本**: 1.9.0
**平台**: Android (Flutter 跨平台)
**描述**: 一个功能完整、界面美观的记账 APP，采用 Peekaboo 柔和梦幻设计风格（梦幻紫 #B8A9E8 + 暖黄强调 #FFD93D）

## 技术栈

| 组件 | 选择 | 理由 |
|------|------|------|
| 框架 | Flutter | 跨平台，一套代码 |
| 状态管理 | Riverpod | 编译时安全，与 Stream 无缝配合 |
| 数据库 | sqflite (SQLite) | 原生查询，无 ORM 开销 |
| 路由 | go_router | 声明式路由，支持嵌套导航 |
| 图表 | fl_chart | 饼图/折线图/柱状图全支持 |
| 动画 | flutter_animate | 声明式链式动画 |
| 通知监听 | Android NotificationListenerService | 原生系统服务 |

## 开发命令

### 环境准备
```bash
flutter doctor
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch  # 监听模式
```

### 运行和调试
```bash
flutter run
flutter test
flutter test test/path/to/test.dart
flutter build apk --release
```

### 代码质量
```bash
flutter analyze
dart format lib/
```

## 项目结构

```
lib/
├── main.dart
├── app/
│   ├── app.dart                       # MaterialApp 配置
│   ├── router/app_router.dart         # go_router 路由 + 底部导航栏
│   └── di/providers.dart              # Riverpod Provider 注册
├── core/
│   ├── database/
│   │   ├── app_database.dart          # 数据库定义 + 迁移
│   │   ├── tables/                    # 表定义
│   │   └── daos/                      # 数据访问
│   ├── theme/
│   │   ├── app_colors.dart            # 色彩系统（AppColors）
│   │   └── app_theme.dart             # ThemeData 配置
│   ├── constants/
│   ├── utils/
│   └── services/
│       ├── notification_service.dart  # 消息通知服务（v1.4.0）
│       └── payment_notification_service.dart  # 支付通知服务（v1.9.0）
├── features/
│   ├── home/                          # 首页
│   ├── transaction/                   # 记账核心
│   ├── category/                      # 分类管理
│   ├── statistics/                    # 统计报表
│   ├── budget/                        # 预算管理
│   ├── recurring/                     # 周期记账
│   ├── account/                       # 账户管理
│   ├── tag/                           # 标签管理
│   ├── import/                        # 账单导入
│   ├── profile/                       # 个人中心（v1.8.0）
│   ├── loan/                          # 贷款管理（v1.8.0）
│   ├── notification/                  # 智能记账通知（v1.9.0）
│   └── settings/                      # 设置
└── shared/
    ├── widgets/
    │   └── app_card.dart              # 通用卡片组件
    └── mixins/
```

## 数据库表结构

| 表名 | 描述 | 引入版本 |
|------|------|----------|
| accounts | 账户表（现金/银行卡/支付宝/微信/贷款） | v1.0.0 |
| categories | 分类表（含 loan_id 关联贷款） | v1.0.0 (v3) |
| transactions | 交易记录表（核心表，含 goods 字段） | v1.0.0 (v2) |
| tags | 标签表 | v1.0.0 |
| transaction_tags | 交易-标签关联表 | v1.0.0 |
| budgets | 预算表 | v1.0.0 |
| recurring_rules | 周期记账规则表 | v1.0.0 |
| exchange_rates | 汇率缓存表 | v1.0.0 |
| pending_payments | 待确认支付表（支付通知监听） | v1.9.0 |

详见 `docs/database.md`

## 双主题 UI 设计（Peekaboo 柔和梦幻风格）

### 浅色模式
- **背景**: 紫粉渐变 `#1E1B4B` → `#F5D5C8` → `#F0E6F6`（三色 bgGradient）
- **卡片**: 暖米白 `#E8FBF5EF`（91%透明），毛玻璃效果，0.5px 淡紫描边
- **强调色**: 暖琥珀金 `#D4A574`（FAB、按钮）
- **文字**: `#2D2D3F` / `#6B6B80` / `#9B9BB0`
- **导航**: 浮动胶囊底部栏，圆角 24px

### 深色模式
- **背景**: 深紫渐变 `#1C1618` → `#201A1C` → `#251E20`
- **卡片**: 半透明深色，毛玻璃描边
- **强调色**: 暖琥珀金 `#D4A574`
- **文字**: `#F5EDE8` / `#BEB0A8` / `#8A7E78`

### 主题感知
- 使用 `AppColors.primaryOf(brightness)` 获取当前主题主色
- 使用 `AppColors.secondaryOf(brightness)` 获取当前主题次色
- 字体: Noto Sans SC（中文）
- 动画: flutter_animate 链式调用
- 设计规范: `docs/design/peekaboo_style_spec.md`

---

## UI 设计强制规范

> **本节为项目硬性规范，所有新增页面、组件、修改必须遵守。**
> 违反本规范的代码不予合入。

### 一、色彩系统

所有颜色必须通过 `AppColors` 类引用，禁止硬编码色值。

#### 1.1 主色

| 用途 | 常量名 | 色值 | 说明 |
|------|--------|------|------|
| 主色 | `AppColors.lightPrimary` / `AppColors.primary` | `#B8A9E8` | 按钮、图标、强调色 |
| 主色浅 | `AppColors.lightPrimaryLight` | `#D8CEE8` | 浅色背景、hover |
| 主色深 | `AppColors.lightPrimaryDark` | `#9B8AC4` | 按钮按下态 |
| 次色 | `AppColors.lightSecondary` / `AppColors.secondary` | `#F5C6D0` | 辅助装饰、标签 |
| 次色浅 | `AppColors.lightSecondaryLight` | `#FDE8EF` | 背景渐变底部 |

动态获取：`AppColors.primaryOf(brightness)` / `AppColors.secondaryOf(brightness)`

#### 1.2 功能色（柔和版）

| 用途 | 常量名 | 色值 | 使用场景 |
|------|--------|------|----------|
| 成功/收入 | `AppColors.success` / `AppColors.income` | `#7EC8A0` | 收入金额、成功提示、进度完成 |
| 警告 | `AppColors.warning` | `#F0C87A` | 警告提示、预算接近上限 |
| 错误/支出 | `AppColors.error` / `AppColors.expense` | `#E88B8B` | 支出金额、错误提示、删除操作 |
| 信息 | `AppColors.info` | `#8BB8E8` | 信息提示、链接 |

#### 1.3 按钮色

| 用途 | 常量名 | 色值 |
|------|--------|------|
| 主按钮琥珀 | `AppColors.warmYellow` | `#D4A574` |
| 主按钮琥珀深 | `AppColors.warmYellowDark` | `#C4956A` |
| 主按钮字色 | `AppColors.warmYellowText` | `#4A3528` |

#### 1.4 浅色模式表面色

| 用途 | 常量名 | 色值 |
|------|--------|------|
| 页面背景 | `AppColors.lightBackground` | `#EDE4F5` |
| 卡片背景 | `AppColors.lightCard` | `#E8FBF5EF`（91%暖米白） |
| Scaffold 背景 | `AppColors.lightScaffold` | `#FBF5EF`（push路由页面） |
| 输入框填充 | `AppColors.lightInputFill` | `#F5F0FA` |
| 描边 | `AppColors.lightOutline` | `#E8E0F0` |
| 主文字 | `AppColors.lightOnBackground` | `#2D2D3F` |
| 副文字 | `AppColors.lightOnSurfaceVariant` | `#6B6B80` |
| 辅助文字 | `AppColors.lightTextTertiary` | `#9B9BB0` |
| 阴影色 | `AppColors.lightShadow` | `#10B8A9E8`（8%主色） |

#### 1.5 深色模式表面色

| 用途 | 常量名 | 色值 |
|------|--------|------|
| 页面背景 | `AppColors.darkBackground` | `#1C1618` |
| 卡片/表面 | `AppColors.darkSurface` | `#2A2225` |
| 表面变体 | `AppColors.darkSurfaceVariant` | `#332A2D` |
| 描边 | `AppColors.darkOutline` | `#3D3235` |
| 主文字 | `AppColors.darkOnBackground` | `#F5EDE8` |
| 副文字 | `AppColors.darkOnSurfaceVariant` | `#BEB0A8` |
| 辅助文字 | `AppColors.darkTextTertiary` | `#8A7E78` |
| 卡片边框 | `AppColors.darkCardBorder` | `#3D3235` |
| 阴影色 | `AppColors.darkShadow` | `#66000000`（40%黑） |

#### 1.6 页面背景渐变

```dart
// 浅色模式 - 三色渐变（全局统一）
[AppColors.bgGradientTop, AppColors.bgGradientMid, AppColors.bgGradientBottom]
// 即: #1E1B4B → #F5D5C8 → #F0E6F6

// 深色模式 - 三色渐变
[AppColors.bgGradientTopDark, AppColors.bgGradientMidDark, AppColors.bgGradientBottomDark]
// 即: #1C1618 → #201A1C → #251E20
```

渐变方向：`Alignment.topCenter` → `Alignment.bottomCenter`

#### 1.7 余额卡片渐变

```dart
// 浅色模式
LinearGradient(colors: [AppColors.balanceGradientStart, AppColors.balanceGradientEnd])
// 即: #B8A9E8 → #9B8AC4

// 深色模式
LinearGradient(colors: [AppColors.balanceGradientStartDark, AppColors.balanceGradientEndDark])
// 即: #2A2225 → #1C1618
```

#### 1.8 分类颜色

使用 `AppColors.categoryColors` 列表，按索引循环分配：
```dart
[#B8A9E8, #8BB8E8, #7EC8A0, #F0C87A, #E88B8B, #F5C6D0,
 #81D4C8, #C4B5E0, #A8D8EA, #FFD93D, #B5EAD7, #E2B6CF]
```

---

### 二、字体规范

#### 2.1 字体家族
- 中文：Noto Sans SC（思源黑体）
- 英文/数字：系统默认（DIN Alternate 或 Roboto）

#### 2.2 字号层级

| 层级 | 字号 | 字重 | 用途 | 颜色绑定 |
|------|------|------|------|----------|
| H1 | 32px | w700 Bold | 余额大数字 | `lightOnBackground` / `darkOnBackground` |
| H2 | 24px | w600 SemiBold | 问候语、页面大标题 | `lightOnBackground` / `darkOnBackground` |
| H3 | 20px | w600 SemiBold | 区块标题 | `lightOnBackground` / `darkOnBackground` |
| H4 | 18px | w600 SemiBold | AppBar 标题 | `lightOnBackground` / `darkOnBackground` |
| Body L | 16px | w500 Medium | 列表标题、按钮文字 | `lightOnBackground` / `darkOnBackground` |
| Body | 15px | w400 Normal | 正文内容 | `lightOnBackground` / `darkOnBackground` |
| Body S | 14px | w400 Normal | 次要内容 | `lightOnSurfaceVariant` / `darkOnSurfaceVariant` |
| Caption | 13px | w400 Normal | 说明文字 | `lightOnSurfaceVariant` / `darkOnSurfaceVariant` |
| Tiny | 12px | w500 Medium | 标签、时间戳 | `lightTextTertiary` / `darkTextTertiary` |
| Micro | 11px | w400 Normal | 最小文字 | `lightTextTertiary` / `darkTextTertiary` |
| Nano | 10px | w500 Medium | 底部导航文字 | `lightTextTertiary` / `darkTextTertiary` |

#### 2.3 金额文字特殊规则

| 场景 | 字号 | 字重 | 浅色颜色 | 深色颜色 |
|------|------|------|----------|----------|
| 余额卡片金额 | 32px | w700 | `#FFFFFF` | `#FFFFFF` |
| 收入金额 | 15px | w600 | `AppColors.income` | `AppColors.income` |
| 支出金额 | 15px~32px | w700~w800 | `AppColors.expense` | `AppColors.expense` |

---

### 三、间距系统

基础单位：**4px**

| Token | 值 | 用途 |
|-------|-----|------|
| `xxs` | 2px | 图标与角标最小间距 |
| `xs` | 4px | 图标与文字间距、行内极小间距 |
| `sm` | 8px | 列表项内部小间距、卡片间小间距 |
| `md` | 12px | 卡片内元素间距、区块内小分组间距 |
| `lg` | 16px | 卡片外边距（水平）、区块间距 |
| `xl` | 20px | 卡片内边距（padding） |
| `xxl` | 24px | 大区块间距（section spacing）、Hero卡片内边距 |
| `xxxl` | 32px | 页面顶部留白、大区块分隔 |

**具体使用场景：**

| 场景 | 值 |
|------|-----|
| 页面水平内边距 | `EdgeInsets.symmetric(horizontal: 12)` 或 `16` |
| 卡片外部 margin | `EdgeInsets.symmetric(horizontal: 12, vertical: 6)` |
| 卡片内部 padding | `EdgeInsets.all(20)` |
| 区块之间间距 | `SizedBox(height: 24)` |
| 列表项之间间距 | `SizedBox(height: 8)` 或 无（用分割线） |
| 底部导航栏距屏幕底 | `EdgeInsets.fromLTRB(20, 0, 20, 16)` |
| 底部内容留白 | `paddingBottom: 100`（浮动导航栏安全区） |
| AppBar 内边距 | `EdgeInsets.fromLTRB(20, 12, 20, 0)` |

---

### 四、圆角系统

| Token | 值 | 用途 |
|-------|-----|------|
| `xs` | 4px | 极小组件（角标圆点等） |
| `sm` | 8px | 小图标容器、设置导航 leading icon 容器 |
| `md` | 12px | 标签（Tag）、月份徽章、小卡片 |
| `lg` | 14px | 交易列表图标容器 |
| `xl` | 16px | 输入框、成就卡片、快捷操作图标容器（实际用18px） |
| `xxl` | 18px | 快捷操作图标容器 |
| `card` | 20px | 浅色模式卡片 |
| `cardDark` | 24px | 深色模式卡片、Hero 余额卡片、底部 Sheet |
| `pill` | 28px | 按钮（胶囊形）、底部导航栏、交易列表项（毛玻璃卡片） |

**具体使用场景：**

| 组件 | 圆角值 |
|------|--------|
| AppCard（浅色） | `BorderRadius.circular(20)` |
| AppCard（深色） | `BorderRadius.circular(24)` |
| Hero 余额卡片 | `BorderRadius.circular(24)` |
| 底部导航栏 | `BorderRadius.circular(24)` |
| 底部弹窗（Sheet） | `BorderRadius.vertical(top: Radius.circular(24))` |
| 主要按钮（黄色） | `BorderRadius.circular(28)` |
| 次要按钮（白色） | `BorderRadius.circular(24)` |
| 快捷操作图标 | `BorderRadius.circular(18)` |
| 交易列表图标 | `BorderRadius.circular(14)` |
| 输入框 | `BorderRadius.circular(16)` |
| 标签（Tag） | `BorderRadius.circular(16)` |
| 设置导航 leading icon | `BorderRadius.circular(8)` |
| 进度条 | `BorderRadius.circular(6)` |
| 成就卡片 | `BorderRadius.circular(16)` |
| 筛选标签 | `BorderRadius.circular(20)` |
| 底部 Sheet 拖拽手柄 | `BorderRadius.circular(2)` |

---

### 五、阴影系统

#### 5.1 浅色模式阴影

```dart
// 卡片阴影（淡紫色调 - AppCard）
BoxShadow(
  color: AppColors.lightPrimary.withValues(alpha: 0.08),
  blurRadius: 16,
  offset: Offset(0, 3),
)

// Hero 余额卡片阴影
BoxShadow(
  color: AppColors.lightPrimary.withValues(alpha: 0.3),
  blurRadius: 20,
  offset: Offset(0, 8),
)

// 快捷操作图标阴影
BoxShadow(
  color: accentColor.withValues(alpha: 0.3),
  blurRadius: 12,
  offset: Offset(0, 4),
)

// 底部导航栏阴影（向上）
BoxShadow(
  color: AppColors.lightPrimary.withValues(alpha: 0.1),
  blurRadius: 20,
  offset: Offset(0, 4),
)
```

#### 5.2 深色模式阴影

```dart
// 卡片阴影
BoxShadow(
  color: Colors.black.withValues(alpha: 0.2),
  blurRadius: 20,
  offset: Offset(0, 4),
)

// Hero 余额卡片阴影
BoxShadow(
  color: Colors.black.withValues(alpha: 0.4),
  blurRadius: 20,
  offset: Offset(0, 8),
)

// 底部导航栏阴影
BoxShadow(
  color: Colors.black.withValues(alpha: 0.3),
  blurRadius: 20,
  offset: Offset(0, 4),
)
```

**注意：** 所有阴影颜色禁止使用 `withOpacity()`，统一使用 `withValues(alpha: ...)`。

---

### 六、组件规范

#### 6.1 AppCard（通用卡片组件）

```dart
AppCard(
  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),  // 默认
  padding: EdgeInsets.all(20),  // 默认
  borderRadius: 20,  // 浅色默认，深色默认 24
  color: AppColors.lightCard,  // 浅色暖米白 91% 透明
  // 深色: theme.colorScheme.surface
  child: ...
)
```

| 属性 | 浅色模式 | 深色模式 |
|------|---------|---------|
| 背景色 | `AppColors.lightCard` (`#E8FBF5EF`) | `theme.colorScheme.surface` |
| 圆角 | 20px | 24px |
| 阴影 | 主色8% / blur 16 / offset(0,3) | 黑色20% / blur 20 / offset(0,4) |
| 描边 | `AppColors.lightOutline` 0.5px | 无 |
| 内边距 | 20px all | 20px all |
| 外边距 | h:12 v:6 | h:12 v:6 |

**强制要求：** 新页面中的卡片必须使用 `AppCard` 组件，禁止自行创建 Container 卡片（特殊情况如 Hero 卡片、毛玻璃卡片除外）。

#### 6.2 主要按钮（梦幻紫胶囊）

```dart
Container(
  height: 56,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [AppColors.warmYellow, AppColors.warmYellowDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(28),
    boxShadow: [
      BoxShadow(
        color: AppColors.warmYellow.withValues(alpha: 0.3),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: Center(
    child: Text(
      '按钮文字',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.warmYellowText,  // #FFFFFF 白色
      ),
    ),
  ),
)
```

| 属性 | 值 |
|------|-----|
| 高度 | 56px |
| 圆角 | 28px（完全胶囊） |
| 背景 | `AppColors.warmYellow` (`#B8A9E8`) → `AppColors.warmYellowDark` (`#9B8AC4`) 梦幻紫渐变 |
| 文字色 | `AppColors.warmYellowText` (`#FFFFFF`) |
| 文字字号 | 16px, w600 |
| 阴影 | `warmYellow` 30% / blur 12 / offset(0,4) |

#### 6.3 次要按钮（白色胶囊）

```dart
Container(
  height: 48,
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: AppColors.lightOutline, width: 1),
  ),
  child: Center(
    child: Text(
      '按钮文字',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.lightOnSurfaceVariant,
      ),
    ),
  ),
)
```

| 属性 | 浅色模式 | 深色模式 |
|------|---------|---------|
| 高度 | 48px | 48px |
| 圆角 | 24px | 24px |
| 背景 | `Colors.white` | `AppColors.darkSurface` |
| 边框 | `AppColors.lightOutline` 1px | `AppColors.darkOutline` 1px |
| 文字色 | `AppColors.lightOnSurfaceVariant` | `AppColors.darkOnSurfaceVariant` |
| 文字字号 | 14px, w500 | 14px, w500 |

#### 6.4 文字按钮

```dart
TextButton(
  onPressed: () {},
  child: Text(
    '按钮文字',
    style: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.primaryOf(brightness),
    ),
  ),
)
```

#### 6.5 OutlineButton（操作按钮）

```dart
OutlinedButton(
  onPressed: () {},
  style: OutlinedButton.styleFrom(
    minimumSize: Size(0, 40),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  child: Text('操作'),
)
```

#### 6.6 FilledButton（主要操作按钮）

```dart
FilledButton(
  onPressed: () {},
  style: FilledButton.styleFrom(
    backgroundColor: AppColors.lightPrimary,
    minimumSize: Size(0, 40),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  child: Text('操作'),
)
```

#### 6.7 输入框

> **统一标准**（适用于所有弹窗、设置页、子页面中的输入框）

```dart
TextField(
  style: TextStyle(fontSize: 15, height: 1.5, color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground),
  decoration: InputDecoration(
    hintText: '提示文字',
    hintStyle: TextStyle(color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary, fontSize: 15),
    filled: true,
    fillColor: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF3F4F6),  // 中性浅灰，非紫色
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  ),
)
```

| 属性 | 浅色模式 | 深色模式 |
|------|---------|---------|
| 字号 | 15px | 15px |
| 圆角 | 12px | 12px |
| 填充色 | `Color(0xFFF3F4F6)` 中性灰 | `AppColors.darkSurfaceVariant` |
| 聚焦边框 | `AppColors.lightPrimary` 1.5px | `AppColors.lightPrimary` 1.5px |
| 文字色 | `AppColors.lightOnBackground` | `AppColors.darkOnBackground` |
| 占位符色 | `AppColors.lightTextTertiary` | `AppColors.darkTextTertiary` |
| 内边距 | `horizontal: 12, vertical: 10` | `horizontal: 12, vertical: 10` |

**关键：填充色必须是 `Color(0xFFF3F4F6)` 中性灰，不能用 `AppColors.lightInputFill`（淡紫色），避免弹窗内一片紫色造成视觉疲劳。**

#### 6.8 AppBar（顶部导航栏）

```dart
AppBar(
  backgroundColor: Colors.transparent,  // 透明显示页面渐变
  elevation: 0,
  centerTitle: true,
  title: Text(
    '页面标题',
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.lightOnBackground,  // 浅色
      // 深色: AppColors.darkOnBackground
    ),
  ),
  iconTheme: IconThemeData(
    color: AppColors.lightOnSurfaceVariant,  // 浅色
    // 深色: AppColors.darkOnSurfaceVariant
  ),
)
```

| 属性 | 浅色模式 | 深色模式 |
|------|---------|---------|
| 背景 | 透明 | 透明 |
| 标题色 | `lightOnBackground` (#2D2D3F) | `darkOnBackground` (#F5EDE8) |
| 图标色 | `lightOnSurfaceVariant` (#6B6B80) | `darkOnSurfaceVariant` (#BEB0A8) |
| elevation | 0 | 0 |
| 标题对齐 | 居中 | 居中 |

**强制要求：** 所有 push 进入的页面（非 Tab 页面），AppBar 背景必须为透明，让页面渐变背景透出。

#### 6.9 底部导航栏（浮动胶囊 + 中间凸起按钮）

```dart
Padding(
  padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
  child: SizedBox(
    height: 68,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        // 导航栏背景
        Container(
          height: 68,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : AppColors.lightPrimary.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(...),  // 首页
              _buildNavItem(...),  // 明细
              const SizedBox(width: 56),  // 中间占位
              _buildNavItem(...),  // 统计
              _buildNavItem(...),  // 我的
            ],
          ),
        ),
        // 中间凸起记账按钮
        Positioned(
          top: -18,  // 浮起18px
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () => context.push('/add-transaction'),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.warmYellow, AppColors.warmYellowDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warmYellow.withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: AppColors.warmYellowText, size: 30),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
)
```

| 属性 | 值 |
|------|-----|
| 容器高度 | 68px |
| 圆角 | 24px |
| 外边距 | `fromLTRB(20, 0, 20, 16)` |
| 背景（浅色） | `Colors.white` |
| 背景（深色） | `AppColors.darkSurface` |
| 中间 FAB 尺寸 | 56×56 圆形 |
| 中间 FAB 浮起 | -18px（约 1/4 露出） |
| FAB 渐变 | `AppColors.warmYellow` → `AppColors.warmYellowDark` |
| FAB 阴影 | `warmYellow` 45% / blur 18 / offset(0,6) |
| FAB 图标 | `Icons.add_rounded`, 30px, `warmYellowText` 白色 |
| 导航项图标大小 | 24px |
| 导航项文字大小 | 11px |
| 选中色 | `AppColors.lightPrimary` |
| 未选中色（浅色） | `AppColors.lightTextTertiary` |
| 未选中色（深色） | `AppColors.darkOnSurfaceVariant` |

#### 6.10 空状态

```dart
EmptyState(
  icon: Icons.receipt_long_rounded,
  title: '暂无数据',
  subtitle: '描述文字',
)
```

| 属性 | 值 |
|------|-----|
| 图标尺寸 | 80px |
| 图标颜色 | `Theme.of(context).colorScheme.primary` 50% 透明 |
| 图标与标题间距 | 24px |
| 标题与副标题间距 | 8px |
| 外层 padding | 32px all |

#### 6.11 快捷操作按钮（首页）

```dart
// 图标容器
Container(
  width: 56,
  height: 56,
  decoration: BoxDecoration(
    color: actionColor.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: actionColor.withValues(alpha: 0.3),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: Icon(icon, color: Colors.white, size: 24),
)
// 标签
Text(
  '标签',
  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
)
```

| 属性 | 值 |
|------|-----|
| 容器尺寸 | 56×56 |
| 圆角 | 18px |
| 背景色 | 功能色 12% 透明度 |
| 图标尺寸 | 24px |
| 图标颜色 | 白色 |
| 标签字号 | 12px, w500 |
| 布局 | `Row` + `MainAxisAlignment.spaceEvenly` |

#### 6.12 交易列表图标

```dart
Container(
  width: 44,
  height: 44,
  decoration: BoxDecoration(
    color: categoryColor.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(14),
  ),
  child: Icon(icon, color: categoryColor, size: 22),
)
```

| 属性 | 值 |
|------|-----|
| 尺寸 | 44×44 |
| 圆角 | 14px |
| 背景色 | 分类色 12% 透明度 |
| 图标尺寸 | 22px |

#### 6.13 进度条

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(6),
  child: LinearProgressIndicator(
    minHeight: 8,
    backgroundColor: Colors.grey.withValues(alpha: 0.15),
    valueColor: AlwaysStoppedAnimation(AppColors.success),
  ),
)
```

#### 6.14 标签（Tag）

```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: tagColor.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(16),
  ),
  child: Text(
    '标签名',
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: tagColor,
    ),
  ),
)
```

| 属性 | 值 |
|------|-----|
| 高度 | 32px（自适应） |
| 圆角 | 16px（完全胶囊） |
| 背景色 | 标签色 15% 透明度 |
| 文字色 | 标签色 |
| 内边距 | h:12, v:6 |

#### 6.15 对话框（AlertDialog）

```dart
AlertDialog(
  title: Text('标题'),
  content: Text('内容'),
  actions: [
    TextButton(onPressed: () {}, child: Text('取消')),
    TextButton(
      onPressed: () {},
      child: Text('确定', style: TextStyle(color: Colors.red)),
    ),
  ],
)
```

| 属性 | 值 |
|------|-----|
| 圆角 | 28px（系统默认） |
| 背景色 | 浅色: 白色 / 深色: `AppColors.darkSurface` |
| 确定按钮色 | 根据语义：危险操作用红色，普通操作用 `AppColors.lightPrimary` |

#### 6.16 SnackBar

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('提示内容')),
);
```

使用系统默认 SnackBar 样式，不自定义。

#### 6.17 底部弹窗（Bottom Sheet）

> **此规范为强制标准，所有新增底部弹窗必须遵守。** 参考实现：`lib/features/notification/presentation/pending_confirm_sheet.dart`

**调用方式：**

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useRootNavigator: true,  // 覆盖底部导航栏
  backgroundColor: Colors.transparent,
  builder: (_) => const SomeSheet(),
);
```

**弹窗主体结构：**

```dart
ConstrainedBox(
  constraints: BoxConstraints(maxHeight: screenHeight * 0.72),  // 最大高度
  child: Container(
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkSurface : Colors.white,  // 浅色纯白
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. 拖拽手柄
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 4),
          child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.lightOutline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // 2. 可滚动内容区
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 弹窗内容...
                const SizedBox(height: 12),  // 底部留白
              ],
            ),
          ),
        ),
        // 3. 固定底部按钮栏（不随滚动）
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkOutline : const Color(0xFFF0EBF5),
                width: 0.5,
              ),
            ),
          ),
          child: Row(children: [
            // 次要按钮 + 主要按钮
          ]),
        ),
      ],
    ),
  ),
)
```

| 属性 | 值 | 说明 |
|------|-----|------|
| 最大高度 | `screenHeight * 0.72` | 留出顶部内容可见 |
| 顶部圆角 | 28px | |
| 背景色（浅色） | `Colors.white` 纯白 | 禁用非白色，除非特殊场景 |
| 背景色（深色） | `AppColors.darkSurface` | |
| 拖拽手柄 | 40×4, borderRadius 2, `AppColors.lightOutline` | 距顶部 14px |
| 可滚动区域 padding | `fromLTRB(20, 12, 20, 0)` | |
| 固定按钮栏 | 分隔线 0.5px + padding `fromLTRB(20, 12, 20, 8)` | |
| `useRootNavigator` | 必须为 `true` | 覆盖底部导航栏 |
| `backgroundColor` | 必须为 `Colors.transparent` | |

**弹窗内组件规范：**

| 组件 | 规范 |
|------|------|
| 区块标签 | 13px w600, `AppColors.lightOnSurfaceVariant`, letterSpacing 0.5, 与内容间距 8px |
| 输入框填充色 | 浅色 `Color(0xFFF3F4F6)`（中性浅灰），深色 `AppColors.darkSurfaceVariant` |
| 输入框字体 | 15px, height 1.5, padding `horizontal: 12, vertical: 10` |
| 输入框圆角 | 12px, 聚焦边框 `AppColors.lightPrimary` 1.5px |
| 忽略按钮 | OutlinedButton, 48px 高, 24px 圆角, `AppColors.lightOutline` 描边 |
| 确认按钮 | 琥珀渐变胶囊, 48px 高, 24px 圆角, 文字 `AppColors.warmYellowText` |
| 分类网格 | 4 列, LayoutBuilder 动态计算宽度, 间距 8px |
| 分类未选中 | 透明背景, 图标保留颜色, 12px 文字 |
| 分类选中 | 分类色 12% 背景, 12px 圆角, 无边框 |
| 账户标签 | 圆角 14px, 选中: 账户色 20% 背景, 未选中: 账户色 8% 背景 |

---

### 七、页面布局规范

#### 7.1 标准页面结构（Tab 页面）

```dart
Scaffold(
  backgroundColor: Colors.transparent,  // 强制：必须透明
  appBar: AppBar(
    backgroundColor: Colors.transparent,
    ...
  ),
  body: ...,
)
```

**所有页面 Scaffold 背景必须为透明**，由 `MainScreen` 的渐变 Container 统一提供背景。

#### 7.2 可滚动页面布局

```dart
SingleChildScrollView(
  physics: BouncingScrollPhysics(),
  padding: EdgeInsets.fromLTRB(16, 0, 16, 100),  // 底部留白适配导航栏
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 各区块之间用 SizedBox(height: 24) 分隔
    ],
  ),
)
```

#### 7.3 ListView 页面布局

```dart
ListView.builder(
  padding: EdgeInsets.symmetric(vertical: 8),
  itemCount: items.length,
  itemBuilder: (context, index) => AppCard(
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ...
  ),
)
```

#### 7.4 设置页导航项模式

```dart
_buildNavigationTile({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String? subtitle,
  required VoidCallback onTap,
}) {
  return ListTile(
    leading: Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: iconColor, size: 20),
    ),
    title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
    subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12)) : null,
    trailing: Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.lightTextTertiary),
    onTap: onTap,
  );
}
```

分割线：`Divider(height: 1, indent: 56)`（对齐 leading icon 右侧）

---

### 八、导航规范

#### 8.1 Tab 页面切换

使用 `StatefulShellRoute.indexedStack`，页面切换无动画（instant），由 `RepaintBoundary` 防止背景重绘闪烁。

#### 8.2 非 Tab 页面导航

**强制使用 `PageRouteBuilder` + `FadeTransition`**，禁止使用 `MaterialPageRoute`。

```dart
Navigator.of(context).push(
  PageRouteBuilder(
    pageBuilder: (_, __, ___) => TargetScreen(),
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  ),
);
```

**原因：** `MaterialPageRoute` 在渐变背景页面间切换时会产生视觉闪烁。

#### 8.3 go_router push 导航

```dart
context.push('/route-path');
```

用于需要传参的路由（如 `/add-transaction`、`/transaction/edit/:id`）。

---

### 九、动画规范

所有动画使用 `flutter_animate` 库，禁止手写 AnimationController。

#### 9.1 页面入场动画

```dart
// 基础淡入
widget.fadeIn(duration: 300.ms)

// 带位移的淡入
widget.fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0)
```

#### 9.2 列表项交错动画

```dart
item.animate().fadeIn(
  duration: 300.ms,
  delay: (index * 50).ms,  // 每项延迟 50ms
)
```

#### 9.3 典型延迟梯度

| 组件 | 延迟 |
|------|------|
| 第一个区块 | 0ms |
| 第二个区块 | 100ms |
| 第三个区块 | 150ms |
| 第四个区块 | 200ms |
| 第五个区块 | 250ms |
| 第六个区块 | 300ms |

#### 9.4 动画参数

| 参数 | 值 |
|------|-----|
| 默认持续时间 | 300ms |
| 曲线 | `Curves.easeOutCubic`（flutter_animate 默认） |
| 列表项间隔 | 50ms |
| 页面切换 | FadeTransition（无额外持续时间设置，跟随系统） |

---

### 十、深色/浅色模式对照表

| 元素 | 浅色模式 | 深色模式 |
|------|---------|---------|
| 页面背景 | 渐变 `#1E1B4B` → `#F5D5C8` → `#F0E6F6` | 渐变 `#1C1618` → `#201A1C` → `#251E20` |
| Scaffold 背景 | `Colors.transparent` | `Colors.transparent` |
| 卡片背景 | `AppColors.lightCard` (`#E8FBF5EF`) | `theme.colorScheme.surface` |
| 卡片圆角 | 20px | 24px |
| 卡片描边 | `AppColors.lightOutline` 0.5px | 无 |
| 主色 | `#B8A9E8` | `#B8A9E8`（保持一致） |
| 主按钮 | 黄色渐变胶囊 | 黄色渐变胶囊（保持一致） |
| 文字主色 | `#2D2D3F` | `#F5EDE8` |
| 文字副色 | `#6B6B80` | `#BEB0A8` |
| 文字辅助色 | `#9B9BB0` | `#8A7E78` |
| 输入框填充 | `#F5F0FA` | `AppColors.darkSurfaceVariant` |
| 描边 | `#E8E0F0` | `#3D3235` |
| 阴影 | 主色 8% / blur 16 | 黑色 20% / blur 20 |
| 底部导航栏 | 白色 / 圆角 24 | `darkSurface` / 圆角 24 |
| 底部导航栏阴影 | 主色 10% / blur 20 | 黑色 30% / blur 20 |
| AppBar 标题 | `#2D2D3F` | `#F5EDE8` |
| AppBar 图标 | `#6B6B80` | `#BEB0A8` |
| 功能色 | 保持一致（柔和版） | 保持一致（柔和版） |

---

### 十一、代码编写强制规则（13 条）

1. **颜色引用**：所有颜色必须通过 `AppColors.xxx` 引用，禁止硬编码 `Color(0xFF...)`
2. **透明度方法**：禁止使用 `withOpacity()`，统一使用 `withValues(alpha: ...)`
3. **Scaffold 背景**：所有页面 `backgroundColor: Colors.transparent`
4. **AppBar 背景**：所有 push 页面 `backgroundColor: Colors.transparent`
5. **卡片组件**：优先使用 `AppCard`，特殊卡片（Hero、毛玻璃）可自定义但必须遵循圆角/阴影规范
6. **页面导航**：Tab 外页面一律使用 `PageRouteBuilder` + `FadeTransition`
7. **动画**：一律使用 `flutter_animate`，禁止手写 `AnimationController`
8. **主题判断**：使用 `Theme.of(context).brightness == Brightness.dark` 或 `isDark` 变量
9. **间距**：区块间距统一 `24px`，卡片间距 `6-8px`，遵循间距系统
10. **圆角**：遵循圆角系统，不得随意设置非标准圆角值
11. **文件路径**：安装/导出/生成文件优先使用 D 盘（`D:/` 或 `D:/project/`），禁止默认输出到 C 盘
12. **弹窗输入框**：填充色必须用 `Color(0xFFF3F4F6)` 中性灰，禁止用 `AppColors.lightInputFill`（淡紫），避免弹窗内大面积紫色
13. **弹窗列表图标**：ListTile 的 leading icon 颜色使用 `AppColors.lightOnSurfaceVariant`（灰色），禁止使用 `AppColors.primaryOf(brightness)`（紫色），避免紫色疲劳

---

## 文档管理

### 文档索引
| 文档 | 路径 | 说明 |
|------|------|------|
| 文档中心 | `docs/README.md` | 统一入口，含所有文档链接和开发速查 |
| 需求文档 | `docs/requirements.md` | 项目需求、非功能需求、里程碑 |
| 功能文档 | `docs/features.md` | 功能模块详情（含数据模型、UI 说明） |
| 版本日志 | `docs/changelog.md` | 按时间倒序的完整版本记录 |
| 数据库说明 | `docs/database.md` | 表结构、版本迁移、备份恢复 |
| Bug 追踪 | `docs/bugs.md` | Bug 记录和修复状态 |
| 设计规范 | `docs/design/peekaboo_style_spec.md` | Peekaboo 风格完整视觉规范 |
| UI 参考 | `docs/design/ui-style-reference.md` | UI 风格参考与设计对照 |
| 历史主题 | `docs/design/theme-*.md` | 霓虹深色 / 自然浅色（归档） |

### 使用 `/update-docs` skill 更新文档
```
/update-docs features 新增了标签筛选功能
/update-docs changelog v1.2.0 新增标签筛选
/update-docs all 完成了预算管理模块
```

---

## 开发规范

### Git 提交规范（硬性要求）
- **每次完成一个功能或修复后，必须立即提交 git**
- 提交流程：
  1. `git add` 添加相关文件
  2. `git commit` 提交（使用规范的 commit message）
  3. `git push` 推送到远程仓库
- 禁止积压多个功能后一次性提交

### 文档更新规范（硬性要求）
- **每次完成功能或修复后，必须同步更新文档**
- 流程（先文档，后提交，一次 commit）：
  1. 更新 `docs/changelog.md`：在 `[未发布]` 之前插入新版本条目
  2. 更新 `docs/features.md`：更新对应功能列表
  3. 如涉及数据库变更 → 更新 `docs/database.md`
  4. 如涉及 UI 规范变更 → 更新 `CLAUDE.md`
  5. 代码 + 文档一起 `git add` + `git commit`

### 代码规范
- 使用 Dart 官方代码风格
- 使用 Riverpod 进行状态管理
- 使用 sqflite 进行数据库操作
- 使用 go_router 进行路由管理

### 命名规范
- 文件名: snake_case.dart
- 类名: PascalCase
- 变量/函数: camelCase
- 常量: camelCase (Dart 推荐)

### 提交前缀
| 前缀 | 用途 |
|------|------|
| `feat:` | 新功能 |
| `fix:` | 修复问题 |
| `docs:` | 文档更新 |
| `style:` | 代码格式调整 |
| `refactor:` | 代码重构 |
| `test:` | 测试相关 |
| `chore:` | 构建/工具相关 |

---

## 重要说明

### 代码生成
- 修改表定义后必须运行 `dart run build_runner build`
- `.g.dart` 文件是自动生成的，不要手动修改

### 数据库迁移
- 修改表结构需要更新 schemaVersion
- 在 migration 中添加迁移逻辑
- 当前版本：v3（categories 含 loan_id）

### 主题切换
- 使用 Riverpod 管理主题状态
- 支持深色/浅色/跟随系统三种模式
- 主题持久化到 SharedPreferences

### 并行开发规范
- 独立子任务可使用子 agent 并行执行
- 确保子任务之间无依赖，避免修改同一文件

---

## 相关资源

- [Flutter 官方文档](https://flutter.dev)
- [Riverpod 文档](https://riverpod.dev)
- [go_router 文档](https://pub.dev/packages/go_router)
- [fl_chart 文档](https://pub.dev/packages/fl_chart)
