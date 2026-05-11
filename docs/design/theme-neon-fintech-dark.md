# 「霓虹金融科技 · 深色」视觉规范（Neon Fintech Dark）

本文档基于参考界面抽象 **Neon Fintech Dark（霓虹金融科技深色）** 的整体气质与各组件样式：纯黑底、荧光绿强调、玻璃拟态与高圆角、发光替代硬阴影。不涉及页面结构与排版坐标。

文末提供 **JSON 设计令牌**：① 深色主主题（与画面一致）；② 浅色衍生主题（保留霓虹品牌基因的清爽映射）。

---

## 1. 整体视觉气质

### 1.1 关键词

- **赛博金融 / Crypto-Fintech**：深色界面 + 高饱和霓虹绿，传递「行情、增长、能量」，区别于银行 app's 铜蓝稳重。
- **纯黑画布**：背景接近 **`#000000`**，让霓虹色产生「自发光」观感；若完全纯黑刺眼，可退阶到 **`#0B0B0B`**，但仍要足够暗。
- **发光重于投影**：少用黑色扩散阴影；多用 **带色相的绿色光晕（glow / bloom）**，元素像灯源而非纸片。
- **玻璃拟态（Glassmorphism）**：半透明层 + 模糊 + 细亮描边，用于卡片遮罩、次级按钮、悬浮导航。
- **超大圆角**：卡片与主按钮圆角常在 **24～32px**，界面柔软、偏「消费级炫酷」而非直角表格工具。
- **线性图标为主**：细描边图标；局部可用少量 **高光立体图标**（如宝箱）作奖励感点缀，不宜铺满。

### 1.2 与现有「银行铜蓝深色」的差异

| 维度 | 银行金融深色（本项目曾对齐） | Neon Fintech Dark（本文） |
|------|-------------------------------|---------------------------|
| 背景 | `#0D0D0D`～`#121212` | **更偏纯黑 `#000000`** |
| 主强调 | 柔和蓝 + 铜氛围 | **荧光黄绿 / 柠绿 → 森绿渐变** |
| 阴影 | 黑色柔阴影 | **绿色发光（colored glow）** |
| 质感 | 轻微描边层次 | **玻璃模糊 + 霓虹描边** |

若记账本同时支持多套主题，可将本文作为 **「霓虹」主题档位**，与「经典银行」档位并列。

---

## 2. 色彩系统（深色模式 · 主参考）

### 2.1 画布与表面

| 令牌 | 建议色值 | 视觉描述 |
|------|-----------|----------|
| `scaffoldBackground` | `#000000` | 纯黑底；霓虹唯一可靠衬托。 |
| `surface` / 次级卡片底 | `#121212`～`#1A1A1A` | 比黑屏略亮一级；用于列表卡片、栅格块，形成微弱层级。 |
| `surfaceContainerHighest` | `#1A1A1A` | 再抬一级时使用（嵌套区块）。 |

### 2.2 霓虹主色与渐变轴

| 令牌 | 建议色值 | 视觉描述 |
|------|-----------|----------|
| `neonLime`（高光端） | `#C6FF00`～`#D4FF00` | 柠黄绿、荧光感强；渐变起点、发光核心色。 |
| `neonMid` | `#89C400`～`#9CCC65` | 中段过渡；仍偏黄绿。 |
| `neonForest`（暗端） | `#2E7D32`～`#4CAF50` | Material 绿区间；渐变终点、图表主线可选用。 |
| `primary`（语义主键） | 取渐变中 **`#C6FF00`** 或 **`#B2FF00`** | 用于 Tab 选中、关键 CTA 填充（若按钮为实心霓虹底）。 |

### 2.3 文本

| 令牌 | 建议色值 | 视觉描述 |
|------|-----------|----------|
| `onBackground` / 主标题 | `#FFFFFF` | _balance、大标题。 |
| `onSurfaceVariant` | `#8E8E93` | iOS 风格浅灰标签；辅助说明。 |
| `mutedGreenGray`（可选标签） | `#4A5D4A` | 偏绿的灰，与霓虹体系同一色相家族，弱化但不脏。 |
| `onPrimary`（霓虹按钮上） | `#000000` | **黑字压在亮霓虹底上**，对比极强，符合参考描述。 |

### 2.4 语义色（涨跌 / 状态）

| 语义 | 建议 | 说明 |
|------|------|------|
| 正向 / 涨 | `#00C853`～霓虹绿系 | 可与图表线同色阶。 |
| 负向 / 跌 | `#FF3B30` | 珊瑚红，在深色上醒目。 |

### 2.5 渐变规范（概念）

- **主摘要 / Hero 卡片**：**线性渐变** — 左上 **`#C6FF00`（或更亮的 `#D4FF00`）** → 右下 **`#1B5E20`～`#2E7D32` 深绿**；整块面积大时在边缘做 **外发光**，颜色取 **`neonLime` 约 25%～40% 透明度**。
- **氛围光斑**：**径向渐变** — 中心 **低不透明霓虹绿** → 向外 **透明**，打在纯黑背景上制造景深。

---

## 3. 组件级样式（细节）

### 3.1 Hero 余额卡（霓虹渐变主卡片）

- **外形**：圆角 **28～32px**。
- **填充**：上文 **柠绿 → 深绿** 线性渐变。
- **玻璃层（可选）**：在文字区域叠一层 **`rgba(255,255,255,0.06～0.12)`** + **背景模糊（等价 BackdropFilter）**，柔化渐变上的文字底。
- **外发光**：`BoxShadow` 多取 **绿色** `color: Color(0x40C6FF00)` 一类，`blurRadius` **大（24～40）**，**spread** 略为正或 0；避免纯黑阴影。
- **文字**：大金额 **白色 Bold**；副标签 **`#8E8E93` 或半透白**。

### 3.2 次级卡片（列表 / 功能块）

- **背景**：实心 **`#1A1A1A`**。
- **边框**：**1px** **`#2A2A2A`** 或 **极暗绿灰** `#1F2E1F`，存在感弱。
- **圆角**：**24～28px**。
- **阴影**：仍以 **绿色漫反射** 为辅，或几乎不用黑阴影。

### 3.3 按钮

- **主按钮**：背景 **实心霓虹（如 `#C6FF00`）**，文字 **`#000000` Bold**；圆角 **pill（≥20px）**。
- **次级 / 玻璃按钮**：背景 **`rgba(255,255,255,0.05～0.08)`** + **blur 10～15px**；文字 **白色**；可加 **1px `rgba(255,255,255,0.1)` 描边**。
- **图标按钮**：圆形；默认暗底；激活态 **细霓虹描边** 或 **外圈绿色 glow**。

### 3.4 图表（折线 / 面积）

- **折线**：亮绿 **`#4CAF50`～`#76FF03`**，可加 **发光 stroke**（宽线 + 模糊底层 duplicate）。
- **面积填充**：自上而下 **霓虹绿 约 20% 透明度** → **底部透明**。
- **网格线**：**几乎不可见**的深灰 **`#1C1C1C`** 或 **`#252525`**。

### 3.5 导航栏（底部）

- **形态**：**悬浮感** — 与屏幕边缘留白或通过阴影抬升。
- **背景**：**深色半透明** **`rgba(26,26,26,0.72)`** + **强模糊（15～24）**。
- **选中**：图标 **霓虹绿**；可叠加 **小圆点指示** 或 **微弱绿色背景 pill**。
- **未选中**：**`#8E8E93`**。

### 3.6 通用图标

- **默认**：细线、白色或浅灰。
- **激活**：霓虹绿填充或描边 + 可选 glow。

---

## 4. 特效参数（实现侧对照）

### 4.1 玻璃三层（典型）

| 属性 | 参考值 |
|------|--------|
| 背景透明度 | `rgba(255,255,255,0.05)` |
| 模糊 | `sigma` **12～18**（Flutter `BackdropFilter`） |
| 边框 | **1px** `rgba(255,255,255,0.08～0.12)` |

### 4.2 霓虹外发光（示例）

```text
BoxShadow(
  color: Color(0x4DC6FF00),  // ~30% 不透明霓虹黄绿
  blurRadius: 28,
  spreadRadius: 0,
  offset: Offset(0, 8),
)
```

可叠 **2～3 层** 不同半径营造「晕」而非「圈」。

---

## 5. 字体与层级

- **数字 / 余额**：**Bold / Black**，字号 **28～36sp** 量级；白色。
- **卡片标题**：**Semibold**，白色。
- **标签 / 说明**：**Regular / Medium**，**`#8E8E93`** 或 **`#4A5D4A`**。
- **按钮（霓虹底）**：**Bold 黑字**，保证 WCAG 对比。

---

## 6. JSON · 深色主主题（Neon Fintech Dark）

与界面一致的令牌集合，供配置或映射 `ThemeData`。

```json
{
  "themeName": "NeonBookkeeperDark",
  "mode": "dark",
  "meta": {
    "visualStyle": "NeonFintechGlass",
    "version": "1.0.0"
  },
  "colors": {
    "scaffoldBackground": "#000000",
    "surface": "#121212",
    "surfaceContainer": "#1A1A1A",
    "neonLime": "#C6FF00",
    "neonLimeBright": "#D4FF00",
    "neonMid": "#89C400",
    "neonForest": "#2E7D32",
    "primary": "#C6FF00",
    "onPrimary": "#000000",
    "primaryContainer": "#1B3D1F",
    "onPrimaryContainer": "#B8FFB0",
    "onBackground": "#FFFFFF",
    "onSurface": "#FFFFFF",
    "onSurfaceVariant": "#8E8E93",
    "mutedGreenGray": "#4A5D4A",
    "outline": "#2A2A2A",
    "outlineMutedGreen": "#1F2E1F",
    "success": "#00C853",
    "error": "#FF3B30",
    "chartLine": "#4CAF50",
    "chartFillTop": "#334CAF50",
    "glowColor": "#C6FF00",
    "glowOpacity": 0.35
  },
  "gradients": {
    "heroBalanceCard": {
      "type": "linear",
      "begin": "topLeft",
      "end": "bottomRight",
      "colors": ["#D4FF00", "#1B5E20"]
    },
    "ambientOrb": {
      "type": "radial",
      "colors": ["#33C6FF00", "#00C6FF00"]
    },
    "chartAreaFill": {
      "type": "linear",
      "begin": "topCenter",
      "end": "bottomCenter",
      "colors": ["#334CAF50", "#004CAF50"]
    }
  },
  "dimensions": {
    "radiusCardMin": 24,
    "radiusCardMax": 32,
    "radiusButton": 20,
    "radiusFab": 28,
    "blurGlass": 15,
    "blurNavBar": 22,
    "glowBlurRadius": 28
  },
  "components": {
    "heroCard": {
      "borderRadiusToken": "radiusCardMax",
      "glassOverlayOpacity": 0.08,
      "outerGlow": true
    },
    "secondaryCard": {
      "backgroundToken": "surfaceContainer",
      "borderWidth": 1,
      "borderColorToken": "outline"
    },
    "primaryButton": {
      "backgroundToken": "neonLime",
      "foregroundToken": "onPrimary",
      "borderRadiusToken": "radiusButton"
    },
    "glassButton": {
      "fillOpacity": 0.06,
      "blurToken": "blurGlass",
      "borderOpacity": 0.1
    },
    "bottomNavigation": {
      "style": "floatingGlass",
      "backgroundOpacity": 0.72,
      "blurToken": "blurNavBar",
      "activeColorToken": "neonLime",
      "inactiveColorToken": "onSurfaceVariant"
    },
    "chart": {
      "lineColorToken": "chartLine",
      "gridOpacity": 0.06,
      "areaFillGradientToken": "chartAreaFill"
    }
  }
}
```

---

## 7. JSON · 浅色衍生（NeonBookkeeperLight）

在保持 **霓虹黄绿品牌色** 的前提下，将画布改为浅灰绿清爽底，避免浅色也用纯黑字压在荧光上造成刺眼；适合「同一品牌 Dual Theme」。

```json
{
  "themeName": "NeonBookkeeperLight",
  "mode": "light",
  "meta": {
    "visualStyle": "Glassmorphism-Light-NeonAccent",
    "derivedFrom": "NeonBookkeeperDark",
    "version": "1.0.0"
  },
  "colors": {
    "background": "#F5F7F5",
    "surface": "#FFFFFF",
    "surfaceVariant": "#EEF5EE",
    "primary": "#B2FF00",
    "primaryDark": "#2D4B00",
    "onPrimary": "#000000",
    "onBackground": "#1A1C1A",
    "onSurface": "#1A1C1A",
    "onSurfaceVariant": "#6A706A",
    "outline": "#E0E8E0",
    "success": "#00C853",
    "error": "#FF3B30",
    "glowTint": "#B2FF00"
  },
  "gradients": {
    "heroCard": {
      "type": "linear",
      "begin": "topLeft",
      "end": "bottomRight",
      "colors": ["#B2FF00", "#89C400"]
    }
  },
  "dimensions": {
    "radiusCard": 28,
    "radiusButton": 20,
    "elevationSoft": 4
  },
  "components": {
    "card": {
      "shadow": "0px 4px 20px rgba(0,0,0,0.05)",
      "borderRadius": 28
    },
    "navigation": {
      "type": "floating",
      "backgroundColor": "rgba(255,255,255,0.82)",
      "blur": 20,
      "activeColor": "#2D4B00",
      "inactiveColor": "#9CA399"
    },
    "glassOverlay": {
      "opacity": 0.08,
      "blur": 15,
      "borderWidth": 1,
      "borderColor": "rgba(255,255,255,0.55)"
    }
  },
  "effects": {
    "chart": {
      "lineColor": "#4CAF50",
      "fillGradient": ["rgba(76,175,80,0.2)", "transparent"]
    }
  }
}
```

---

## 8. 落地实现备忘（Flutter）

1. **Scaffold**：深色主题 `scaffoldBackgroundColor: Color(0xFF000000)`。
2. **Hero 卡**：`Container` + `BoxDecoration` `gradient: LinearGradient(...)`；可选 `Stack` + `BackdropFilter` 做玻璃层。
3. **Glow**：`BoxShadow(color: primary.withOpacity(0.25～0.4), blurRadius: 24～40)`。
4. **形状**：卡片 `BorderRadius.circular(24)` 起跳，重要容器可到 **32**。
5. **图表**：`fl_chart` 等的 `border` / `gridData` 用极浅灰；曲线 `belowBarData` / `gradient` 套绿色透明渐变。

---

## 9. 文档维护

- 若与设计稿色差校准，同步更新本文 JSON 中的十六进制与 `docs/changes.md`。

---

*文档版本：1.0 · Neon Fintech Dark 视觉抽象*
