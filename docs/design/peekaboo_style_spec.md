# 记账本 UI 设计规范 — Peekaboo 风格移植

> 基于 Peekaboo 儿童应用的柔和梦幻设计风格，移植到记账本项目。

---

## 一、设计风格定位

**风格名称**: 柔和梦幻 (Soft Dreamy)
**关键词**: 温柔、治愈、柔和、可爱、轻盈
**适用场景**: 浅色模式（主要）、深色模式（适配）

整体视觉感受：像清晨阳光透过薄纱窗帘，柔和、温暖、没有攻击性。

---

## 二、色彩系统

### 2.1 浅色模式（核心风格）

#### 主色调
| 用途 | 颜色名称 | 色值 | 说明 |
|------|----------|------|------|
| 主色 | 梦幻紫 | `#B8A9E8` | 按钮、图标、强调色 |
| 主色浅 | 淡薰衣草 | `#D8CEE8` | 浅色背景、hover 状态 |
| 主色深 | 深紫藤 | `#9B8AC4` | 按钮按下态 |
| 次色 | 柔粉 | `#F5C6D0` | 辅助装饰、标签 |
| 次色浅 | 浅粉白 | `#FDE8EF` | 背景渐变底部 |

#### 背景与表面
| 用途 | 色值 | 说明 |
|------|------|------|
| 页面背景顶部 | `#EDE4F5` | 渐变起始（淡薰衣草紫） |
| 页面背景底部 | `#FDE8EF` | 渐变结束（淡粉） |
| 卡片背景 | `#FFFFFF` | 纯白卡片 |
| 输入框填充 | `#F5F0FA` | 极淡紫色填充 |
| 分割线 | `#F0ECF5` | 淡紫色分割线 |

#### 文字颜色
| 层级 | 色值 | 用途 |
|------|------|------|
| 主文字 | `#2D2D3F` | 标题、金额 |
| 副文字 | `#6B6B80` | 描述、说明 |
| 辅助文字 | `#9B9BB0` | 占位符、时间 |
| 白色文字 | `#FFFFFF` | 渐变卡片上的文字 |

#### 功能色（保持柔和）
| 用途 | 色值 | 说明 |
|------|------|------|
| 收入/成功 | `#7EC8A0` | 柔和绿 |
| 支出/错误 | `#E88B8B` | 柔和红 |
| 警告 | `#F0C87A` | 柔和橙黄 |
| 信息 | `#8BB8E8` | 柔和蓝 |

#### 按钮色
| 用途 | 色值 | 说明 |
|------|------|------|
| 主要按钮（黄色） | `#FFD93D` | 醒目但不刺眼 |
| 主要按钮文字 | `#5A4E2A` | 深棕黄色 |
| 次要按钮 | `#FFFFFF` | 白底 |
| 次要按钮边框 | `#E8E0F0` | 淡紫色边框 |

---

### 2.2 深色模式（适配梦幻风格）

> 深色模式保留梦幻感，但降低亮度，使用深紫作为基底。

#### 主色调
| 用途 | 色值 | 说明 |
|------|------|------|
| 主色 | 梦幻紫 | `#B8A9E8` | 与浅色保持一致 |
| 主色浅 | 暗薰衣草 | `#9B8AC4` | 浅色变体 |
| 主色深 | 深紫藤 | `#7B6BA4` | 深色变体 |

#### 背景与表面
| 用途 | 色值 | 说明 |
|------|------|------|
| 页面背景 | `#1A1525` | 深紫黑 |
| 卡片背景 | `#252035` | 深紫灰 |
| 卡片边框 | `#353045` | 微妙边框 |
| 输入框填充 | `#2A2535` | 深紫填充 |

#### 文字颜色
| 层级 | 色值 | 用途 |
|------|------|------|
| 主文字 | `#F0ECF5` | 标题、金额 |
| 剮文字 | `#B0A8C0` | 描述、说明 |
| 辅助文字 | `#7A7090` | 占位符、时间 |

#### 渐变（余额卡片）
| 起始 | 结束 | 说明 |
|------|------|------|
| `#B8A9E8` | `#7B6BA4` | 紫色渐变（替代原来的绿色渐变） |

---

## 三、渐变系统

### 3.1 页面背景渐变
```dart
// 浅色模式 - 全屏背景
LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFFEDE4F5),  // 淡薰衣草紫（顶部）
    Color(0xFFF5EFF8),  // 过渡色
    Color(0xFFFDE8EF),  // 淡粉（底部）
  ],
)

// 深色模式 - 全屏背景
LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF1A1525),  // 深紫黑（顶部）
    Color(0xFF1F1A2D),  // 过渡色
    Color(0xFF251F30),  // 稍暖深紫（底部）
  ],
)
```

### 3.2 余额卡片渐变
```dart
// 浅色模式
LinearGradient(
  colors: [Color(0xFFB8A9E8), Color(0xFF9B8AC4)],
)

// 深色模式
LinearGradient(
  colors: [Color(0xFFB8A9E8), Color(0xFF7B6BA4)],
)
```

### 3.3 主要按钮渐变（黄色）
```dart
LinearGradient(
  colors: [Color(0xFFFFD93D), Color(0xFFF0C87A)],
)
```

---

## 四、组件规范

### 4.1 卡片 (Card)

#### 浅色模式
```
背景色:     #FFFFFF (纯白)
圆角:       20px
阴影:       0 2px 12px rgba(184, 169, 232, 0.08)  // 淡紫色阴影
内边距:     20px
外边距:     水平 20px, 垂直 8px
边框:       无
```

#### 深色模式
```
背景色:     #252035
圆角:       24px
阴影:       0 2px 16px rgba(0, 0, 0, 0.3)
内边距:     20px
外边距:     水平 20px, 垂直 8px
边框:       1px solid #353045
```

#### 代码示例
```dart
Container(
  decoration: BoxDecoration(
    color: isDark ? Color(0xFF252035) : Colors.white,
    borderRadius: BorderRadius.circular(isDark ? 24 : 20),
    boxShadow: [
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.3)
            : Color(0xFFB8A9E8).withOpacity(0.08),
        blurRadius: isDark ? 16 : 12,
        offset: Offset(0, 2),
      ),
    ],
    border: isDark
        ? Border.all(color: Color(0xFF353045), width: 1)
        : null,
  ),
  padding: EdgeInsets.all(20),
  child: ...
)
```

---

### 4.2 按钮

#### 主要按钮（黄色 - 如"记一笔"）
```
高度:       56px
圆角:       28px (完全胶囊形)
背景渐变:   #FFD93D → #F0C87A
文字颜色:   #5A4E2A
字号:       16px, SemiBold
阴影:       0 4px 12px rgba(255, 217, 61, 0.3)
内边距:     水平 24px
```

#### 次要按钮（白色）
```
高度:       48px
圆角:       24px (完全胶囊形)
背景色:     #FFFFFF
边框:       1px solid #E8E0F0
文字颜色:   #6B6B80
字号:       14px, Medium
内边距:     水平 20px
```

#### 文字按钮
```
高度:       40px
圆角:       20px
背景色:     透明
文字颜色:   #B8A9E8 (主色)
字号:       14px, Medium
```

#### 代码示例
```dart
// 主要按钮（黄色）
Container(
  height: 56,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFFFFD93D), Color(0xFFF0C87A)],
    ),
    borderRadius: BorderRadius.circular(28),
    boxShadow: [
      BoxShadow(
        color: Color(0xFFFFD93D).withOpacity(0.3),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: Center(
    child: Text(
      '记一笔',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF5A4E2A),
      ),
    ),
  ),
)

// 次要按钮（白色胶囊）
Container(
  height: 48,
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Color(0xFFE8E0F0), width: 1),
  ),
  child: Center(
    child: Text(
      '查看详情',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF6B6B80),
      ),
    ),
  ),
)
```

---

### 4.3 底部导航栏

#### 样式
```
容器样式:
  背景色:     #FFFFFF (浅色) / #252035 (深色)
  圆角:       28px (顶部)
  阴影:       0 -2px 12px rgba(184, 169, 232, 0.08)
  内边距:     顶部 8px, 底部 8px (安全区域)
  外边距:     底部 12px, 左右 16px

导航项:
  图标大小:   24px
  文字大小:   10px
  选中色:     #B8A9E8 (梦幻紫)
  未选中色:   #9B9BB0 (辅助文字色)
  间距:       图标与文字 4px
```

#### 代码示例
```dart
Container(
  margin: EdgeInsets.fromLTRB(16, 0, 16, 12),
  decoration: BoxDecoration(
    color: isDark ? Color(0xFF252035) : Colors.white,
    borderRadius: BorderRadius.circular(28),
    boxShadow: [
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.3)
            : Color(0xFFB8A9E8).withOpacity(0.08),
        blurRadius: 12,
        offset: Offset(0, -2),
      ),
    ],
  ),
  child: ...
)
```

---

### 4.4 顶部导航栏 (AppBar)

```
背景:       透明（显示页面渐变背景）
标题颜色:   #2D2D3F (浅色) / #F0ECF5 (深色)
标题字号:   18px, SemiBold
标题位置:   居中
图标颜色:   #6B6B80 (浅色) / #B0A8C0 (深色)
elevation:  0
```

---

### 4.5 输入框

#### 样式
```
高度:       52px
圆角:       16px
背景填充:   #F5F0FA (浅色) / #2A2535 (深色)
边框:       无（正常）/ 2px #B8A9E8（聚焦）
内边距:     水平 16px
文字颜色:   #2D2D3F (浅色) / #F0ECF5 (深色)
占位符色:   #9B9BB0
字号:       15px
```

#### 代码示例
```dart
TextField(
  decoration: InputDecoration(
    filled: true,
    fillColor: isDark ? Color(0xFF2A2535) : Color(0xFFF5F0FA),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Color(0xFFB8A9E8), width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
)
```

---

### 4.6 分类标签 / Tag

```
高度:       32px
圆角:       16px (完全胶囊)
背景色:     对应分类颜色的 15% 透明度
文字颜色:   对应分类颜色
字号:       12px, Medium
内边距:     水平 12px, 垂直 6px
```

---

### 4.7 交易列表项

```
高度:       自适应 (最小 64px)
内边距:     水平 20px, 垂直 14px
左侧图标:
  尺寸:     44px
  圆角:     14px
  背景:     对应分类颜色的 12% 透明度
  内边距:   10px

中间文字:
  标题:     15px, Medium, #2D2D3F
  副标题:   12px, Normal, #9B9BB0

右侧金额:
  收入:     15px, SemiBold, #7EC8A0
  支出:     15px, SemiBold, #E88B8B
  日期:     11px, Normal, #9B9BB0 (金额下方)

分割线:
  左侧偏移: 76px (对齐文字)
  颜色:     #F0ECF5
  高度:     1px
```

---

### 4.8 余额展示卡片（Hero Card）

```
高度:       180px
圆角:       24px
背景渐变:   #B8A9E8 → #9B8AC4
阴影:       0 8px 24px rgba(184, 169, 232, 0.25)
内边距:     24px

内部布局:
  顶部标签:
    背景:     rgba(255,255,255,0.2)
    圆角:     12px
    文字:     12px, Medium, 白色
    内边距:   8px x 12px

  金额:
    字号:     36px, Bold
    颜色:     白色

  收入/支出:
    字号:     14px, Medium
    颜色:     rgba(255,255,255,0.8)
    间距:     24px (水平)
```

---

### 4.9 快捷操作按钮

```
容器:
  尺寸:     56px x 56px
  圆角:     18px
  背景:     对应颜色的 12% 透明度
  阴影:     无

图标:
  尺寸:     24px
  颜色:     对应颜色

文字:
  字号:     11px, Medium
  颜色:     #6B6B80
  间距:     图标与文字 6px

布局:
  水平均匀分布
  间距:     16px
```

---

### 4.10 环形进度条（预算）

```
尺寸:       160px x 160px
线宽:       12px
背景线颜色: #F0ECF5 (浅色) / #353045 (深色)
进度线颜色: #B8A9E8 (梦幻紫)
圆角:       圆形 (StrokeCap.round)

中心文字:
  金额:     24px, Bold, #2D2D3F
  标签:     12px, Normal, #9B9BB0
```

---

### 4.11 日期选择器 / 月份切换

```
容器:
  高度:     40px
  圆角:     20px
  背景:     #F5F0FA (浅色) / #2A2535 (深色)
  内边距:   水平 16px

箭头按钮:
  尺寸:     32px
  圆角:     16px
  背景:     透明
  图标色:   #B8A9E8

文字:
  字号:     14px, SemiBold
  颜色:     #2D2D3F
```

---

### 4.12 空状态

```
图标/插图:
  尺寸:     120px
  颜色:     #D8CEE8 (淡薰衣草)

标题:
  字号:     16px, SemiBold
  颜色:     #6B6B80

副标题:
  字号:     13px, Normal
  颜色:     #9B9BB0

按钮:
  使用次要按钮样式
```

---

## 五、间距系统

### 基础间距单位: 4px

| Token | 值 | 用途 |
|-------|-----|------|
| xs | 4px | 图标与文字间距 |
| sm | 8px | 列表项内部小间距 |
| md | 12px | 卡片内元素间距 |
| lg | 16px | 卡片外边距、区块间距 |
| xl | 20px | 卡片内边距 |
| xxl | 24px | 大区块间距、Hero 卡片内边距 |
| xxxl | 32px | 页面顶部留白 |

---

## 六、圆角系统

| Token | 值 | 用途 |
|-------|-----|------|
| sm | 8px | 小图标容器 |
| md | 12px | 标签、小卡片 |
| lg | 16px | 输入框、列表项图标 |
| xl | 20px | 卡片（浅色模式） |
| xxl | 24px | 卡片（深色模式）、Hero 卡片 |
| pill | 28px | 按钮、底部导航栏（完全胶囊形） |

---

## 七、阴影系统

### 浅色模式
```dart
// 卡片阴影（淡紫色调）
BoxShadow(
  color: Color(0xFFB8A9E8).withOpacity(0.08),
  blurRadius: 12,
  offset: Offset(0, 2),
)

// 按钮阴影
BoxShadow(
  color: Color(0xFFFFD93D).withOpacity(0.3),
  blurRadius: 12,
  offset: Offset(0, 4),
)

// 底部导航阴影
BoxShadow(
  color: Color(0xFFB8A9E8).withOpacity(0.08),
  blurRadius: 12,
  offset: Offset(0, -2),
)
```

### 深色模式
```dart
// 卡片阴影
BoxShadow(
  color: Colors.black.withOpacity(0.3),
  blurRadius: 16,
  offset: Offset(0, 2),
)
```

---

## 八、字体规范

### 字体
- 中文: Noto Sans SC (思源黑体)
- 数字: DIN Alternate 或系统默认

### 字号层级

| 层级 | 字号 | 字重 | 用途 |
|------|------|------|------|
| H1 | 32px | Bold | 余额数字 |
| H2 | 24px | SemiBold | 页面大标题 |
| H3 | 20px | SemiBold | 区块标题 |
| H4 | 18px | SemiBold | 导航标题 |
| Body Large | 16px | Medium | 列表标题 |
| Body | 15px | Normal | 正文内容 |
| Body Small | 14px | Normal | 次要内容 |
| Caption | 13px | Normal | 说明文字 |
| Tiny | 12px | Medium | 标签、时间 |
| Micro | 11px | Normal | 最小文字 |
| Nano | 10px | Medium | 底部导航文字 |

---

## 九、动画规范

### 过渡动画
```
持续时间:   300ms
曲线:       Curves.easeOutCubic
```

### 页面切换
```
类型:       SlideTransition (从右向左)
持续时间:   350ms
```

### 列表项入场
```
类型:       FadeIn + SlideIn (从下方)
持续时间:   300ms
间隔:       50ms (逐项延迟)
```

### 按钮点击
```
缩放:       0.95 → 1.0
持续时间:   150ms
```

---

## 十、AppColors 新增字段建议

```dart
class AppColors {
  // ===== 梦幻紫风格（新） =====

  /// 主色：梦幻紫
  static const Color dreamyPurple = Color(0xFFB8A9E8);
  static const Color dreamyPurpleLight = Color(0xFFD8CEE8);
  static const Color dreamyPurpleDark = Color(0xFF9B8AC4);

  /// 次色：柔粉
  static const Color softPink = Color(0xFFF5C6D0);
  static const Color softPinkLight = Color(0xFFFDE8EF);

  /// 主要按钮：暖黄
  static const Color warmYellow = Color(0xFFFFD93D);
  static const Color warmYellowDark = Color(0xFFF0C87A);
  static const Color warmYellowText = Color(0xFF5A4E2A);

  /// 页面背景渐变
  static const Color bgGradientTopLight = Color(0xFFEDE4F5);
  static const Color bgGradientMidLight = Color(0xFFF5EFF8);
  static const Color bgGradientBottomLight = Color(0xFFFDE8EF);

  static const Color bgGradientTopDark = Color(0xFF1A1525);
  static const Color bgGradientMidDark = Color(0xFF1F1A2D);
  static const Color bgGradientBottomDark = Color(0xFF251F30);

  /// 卡片阴影色（淡紫色调）
  static const Color cardShadowLight = Color(0x14B8A9E8); // 8% 透明度

  /// 输入框填充
  static const Color inputFillLight = Color(0xFFF5F0FA);
  static const Color inputFillDark = Color(0xFF2A2535);

  /// 分割线
  static const Color dividerLight = Color(0xFFF0ECF5);
  static const Color dividerDark = Color(0xFF353045);

  /// 柔和功能色
  static const Color softSuccess = Color(0xFF7EC8A0);
  static const Color softError = Color(0xFFE88B8B);
  static const Color softWarning = Color(0xFFF0C87A);
  static const Color softInfo = Color(0xFF8BB8E8);

  // ===== 文字颜色 =====
  static const Color textPrimaryLight = Color(0xFF2D2D3F);
  static const Color textSecondaryLight = Color(0xFF6B6B80);
  static const Color textTertiaryLight = Color(0xFF9B9BB0);

  static const Color textPrimaryDark = Color(0xFFF0ECF5);
  static const Color textSecondaryDark = Color(0xFFB0A8C0);
  static const Color textTertiaryDark = Color(0xFF7A7090);
}
```

---

## 十一、深色模式适配要点

| 元素 | 浅色模式 | 深色模式 |
|------|---------|---------|
| 页面背景 | 渐变 #EDE4F5 → #FDE8EF | 渐变 #1A1525 → #251F30 |
| 卡片 | 白色 + 淡紫阴影 | #252035 + 深色阴影 + 边框 |
| 主色 | #B8A9E8 | #B8A9E8 (保持一致) |
| 按钮 | 黄色渐变 | 黄色渐变 (保持一致) |
| 文字主色 | #2D2D3F | #F0ECF5 |
| 文字副色 | #6B6B80 | #B0A8C0 |
| 分割线 | #F0ECF5 | #353045 |
| 输入框 | #F5F0FA | #2A2535 |

---

## 十二、与当前项目的差异对照

| 元素 | 当前设计 | 新设计 (Peekaboo 风格) |
|------|---------|----------------------|
| 浅色主色 | 森绿 #2D4F35 | 梦幻紫 #B8A9E8 |
| 浅色次色 | 哑光金 #C5A059 | 柔粉 #F5C6D0 |
| 页面背景 | 纯白 #FFFFFF | 渐变 紫→粉 |
| 卡片阴影 | 黑色 5% | 淡紫色 8% |
| 按钮风格 | 实色填充 | 黄色渐变胶囊 |
| 底部导航 | 标准底部栏 | 圆角胶囊浮动栏 |
| 整体感觉 | 自然、清爽 | 温柔、治愈 |

---

*文档版本: 1.0*
*创建日期: 2026-05-11*
*设计参考: Peekaboo 儿童应用*
