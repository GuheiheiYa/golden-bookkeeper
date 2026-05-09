# 「自然与生活」浅色视觉规范（Nature & Lifestyle）

本文档从参考界面中抽象**整体视觉气质与各组件样式**，不涉及页面结构与排版顺序；文末附带 **浅色模式设计令牌 JSON**，可供主题配置或设计交付对照。

---

## 1. 整体视觉气质（宏观）

### 1.1 关键词

- **清透、留白、呼吸感**：界面像杂志或精品旅行 App，信息密度适中，块与块之间用留白分隔，而不是挤满控件。
- **自然意象**：主品牌色为**森绿**，辅以**哑光金/亚麻金**点缀，传递户外、质感、温和高级感，而非科技感霓虹。
- **光影胜过扁平**：元素少有「一刀切开」的纯色平面感；依靠**极轻阴影**、**微妙底色分层**和（若有图的区域）**大图叙事**，形成柔和的纵深。
- **圆角友好**：从搜索胶囊到卡片，圆角普遍偏大，视觉上柔软、易亲近，偏生活方式类产品而非工具型表格界面。
- **线性图标为主**：导航与工具区多用**细线轮廓图标**，填色图标多用于卡片内的小符号或分类徽标，整体笔触干净。

### 1.2 与白底医疗/政务风格的区别

本风格**不是**冷灰极简商务：它有明确的**品牌绿**与**金点缀**，页面基底可以是纯白或极浅冷灰，但整体氛围偏**暖、有机**，插图与摄影若出现则占视觉权重较大。

---

## 2. 色彩系统（浅色模式）

以下均为 **sRGB 十六进制**，便于设计与代码对齐。

### 2.1 画布与表面层级

| 令牌语义 | 色值 | 视觉描述 |
|----------|------|----------|
| **页面主背景 `background`** | `#FFFFFF` | 纯白画布；主要内容区、底层滚动背景；显得干净、印刷品级白。 |
| **次级页面背景 `surface` / `scaffoldVariant`** | `#F7F8FA` | 极浅冷灰，介于白与浅灰之间；用于整页浅灰底、或与纯白卡片形成一层淡淡分层；远看仍是「浅色」，不发脏。 |
| **输入区 / 搜索槽底色 `inputBackground`** | `#F2F2F2` | 比 `surface` 略深一丁点的浅灰药丸底；专用于搜索框、筛选槽等「凹进去的槽」，与白卡片区分开。 |

三层关系：**白（页）→ 浅灰（可选整页底）→ 更浅灰槽（搜索）**，对比都很克制。

### 2.2 品牌与强调色

| 令牌语义 | 色值 | 视觉描述 |
|----------|------|----------|
| **主色 `primary`（森绿）** | `#2D4F35` | 深森林绿，饱和适中、明度偏低；稳重不荧光；用于主按钮实心填充、底部导航选中态、关键标签实心底等。 |
| **主色之上文字 `onPrimary`** | `#FFFFFF` | 纯白；压在森绿按钮与 FAB 上保证对比度。 |
| **次要强调 / 金属点缀 `accentGold`** | `#C5A059` | 哑光金、亚麻铜金感；用于评分星、勋章角标、「精选」类标签描边或填充、次要高亮，面积宜小。 |

### 2.3 文本色阶

| 令牌语义 | 色值 | 视觉描述 |
|----------|------|----------|
| **主标题 / 正文强调 `textPrimary`** | `#1A1A1A` | 近黑但非 `#000`；柔化刺眼感，用于标题、列表主行、金额主数字。 |
| **次要说明 `textSecondary`** | `#666666` | 中灰；副标题、卡片简介、列表次要一行。 |
| **弱化 / 占位 / 元数据 `textTertiary`** | `#999999` | 浅灰；搜索占位符、时间戳、辅助标签、「查看更多」弱化文案。 |

层次：**1A → 66 → 99** 形成清晰三段，避免只用两种灰导致层级糊。

### 2.4 分割与线框

| 令牌语义 | 色值 | 视觉描述 |
|----------|------|----------|
| **分割线 / 细边框 `divider`** | `#EEEEEE` | 极浅线；列表行间、卡片可选内部分割、底栏顶细线，存在感极低。 |

### 2.5 阴影（概念化 — 由实现侧映射为 `box-shadow` 或 Flutter `BoxShadow`）

| 名称 | 建议 | 视觉描述 |
|------|------|----------|
| **soft** | `0 4px 20px rgba(0,0,0,0.05)` | **柔雾**：扩散半径较大、透明度极低；白卡片浮在浅灰或白底上，边缘几乎看不清边界，仅有一丝.lift。 |
| **medium** | `0 6px 25px rgba(0,0,0,0.10)` | 稍明显但仍克制；用于悬浮按钮、弹窗或强调卡片第二层级，不使用深色大块投影。 |

原则：**黑色透明度极低**，宁可「飘不起来」也不要「很重的水泥阴影」。

---

## 3. 尺寸与形状令牌（无布局坐标）

| 令牌 | 数值（逻辑像素） | 视觉描述 |
|------|------------------|----------|
| **卡片圆角 `cardBorderRadius`** | 16 | 标准内容卡片；四角圆弧明显但不过分圆润。 |
| **按钮圆角 `buttonBorderRadius`** | 24 | 主按钮接近胶囊；两侧几乎半圆，与森绿实心按钮搭配显精致。 |
| **输入 / 搜索槽圆角 `inputBorderRadius`** | 20～25 | 搜索条为**横向长胶囊**；圆角接近高度的一半时最「pill」。 |
| **页面水平内边距 `pagePadding`** | 16～20 | 内容与屏幕边的留白，维持通透感。 |
| **块间距 `elementSpacing`** | 12～16 | 卡片之间、标题与列表之间的垂直节奏。 |
| **FAB 直径参考 `fabSize`** | 56 | 底部导航中间凸起按钮的常见尺度；绿色实心圆 + 白加号。 |

---

## 4. 字体与字重（层级感）

| 用途 | 建议字重 | 建议字号区间（sp） | 颜色绑定 |
|------|----------|---------------------|----------|
| 栏目标题 / 卡片主标题 | Bold **700** / Semibold **600** | 16～18 | `textPrimary` |
| 正文 / 列表主行 | Regular **400** | 14～15 | `textPrimary` 或 `textSecondary` |
| 辅助说明 / 次要一行 | Regular **400** | 12～14 | `textSecondary` |
| 标签 / 时间 / Tab 小字 | Medium **500** 或 Regular | 10～12 | `textTertiary` 或 `textSecondary` |

数字金额可选用 **Semibold** 提升可读性；全页避免过多 Bold，防止「到处是标题」。

---

## 5. 按组件拆解的视觉样式（细节）

### 5.1 顶区与搜索条（合并气质描述）

- **顶栏背景**：与页面一致为 **纯白或极浅灰**，**不要用大块深色或强渐变顶栏**；与下方内容无缝衔接，顶多有一条 `#EEEEEE` 细分隔或干脆不用。
- **搜索框外形**：**横向胶囊**，高度约 **40px** 量级；背景 **`#F2F2F2`**，无边框或仅有极淡描边（可与分割线同色但更浅）。
- **搜索图标**：左侧内置 **细线放大镜**，颜色 **`#999999`** 或与 `textTertiary` 一致。
- **占位文案**：**`#999999`**，字数精简（如「搜索目的地 / 关键词」类）。
- **右侧工具图标**（通知、设置等）：**线框样式**，默认 **`#666666`**，按下时可短暂变为 **`#2D4F35`**。
- **地理位置文案**（若存在）：小字号 **`textSecondary`**，右侧 **小下垂箭头**，无粗描边按钮包裹，保持文字主导。

### 5.2 标准卡片（无图 / 白底信息卡）

- **填充色**：**`#FFFFFF`**，若在 `#F7F8FA` 页面上则对比清晰。
- **圆角**：**16px**。
- **阴影**：**soft**（见上文）；四边均匀晕开，不要单侧很重。
- **内边距**：正文与卡片边缘保持舒适留白（常 **16** 左右）；标题与正文之间再缩一档间距。
- **内部分割**：若一条卡片内有多行信息，用 **`#EEEEEE` 细线**或 **12px 间距**分隔，避免粗分割线。

### 5.3 图片卡片（大图 + 文案）

- **图片**：占卡片宽度 **满宽**，**圆角与卡片外轮廓一致**（顶部圆角裁切图片）；图片质量要求高，饱和度自然。
- **文案在图下方**：白底延续或卡片白底上；标题 **16～18 Semibold `textPrimary`**，副文 **`textSecondary` 12～14**。
- **文案叠在图底部**（可选）：底部叠加 **自上而下** 的线性渐变：`transparent → rgba(0,0,0,0.55～0.65)`，上层文字用 **白色**，保证可读；标题略大，副信息略小。

### 5.4 主按钮（实心）

- **背景**：**`#2D4F35`**。
- **文字**：**`#FFFFFF`**，字重 **Semibold**。
- **圆角**：**≥20px**，整体呈 **胶囊条**。
- **按压态**：可略 **加深绿色**（降低明度 5%～8%）或 **非常轻的向内阴影**，不做夸张缩放。

### 5.5 次级按钮（幽灵 / 弱填充）

- **幽灵**：透明底 + **`#2D4F35` 1px 描边** + 字色森绿；或浅灰底 **`#F2F2F2`** + 深灰字。
- **禁用**：背景与文字统一降为 **`textTertiary`** 系灰度。

### 5.6 底部导航栏

- **栏背景**：**`#FFFFFF`** 实心。
- **顶部分隔**：**`#EEEEEE` 1px** 或 **soft 阴影向上**，二者择一即可，避免又线又影过重。
- **图标**：**线稿轮廓**；未选中 **`#999999`**，选中 **`#2D4F35`**。
- **文字标签**（若有）：与图标同色逻辑；选中可加 **Semibold**。
- **中间 FAB**：直径约 **56**；填充 **`#2D4F35`**，中心 **白色「+」** 粗细则中等；外圈可带 **soft** 级阴影使其略浮起。

### 5.7 「票券 / Pass」风格卡片（特种组件）

- **整体**：竖向信息编排；可有 **角落印章风小图标**（复古票据感），颜色可用 **`accentGold`** 或森绿线稿。
- **边缘**：中间可有 **波浪形虚线分割**（穿孔线），颜色 **`#EEEEEE` 或浅灰**，模拟撕票；不影响可读前提下强化「手持实物」的心理暗示。
- **阴影**：仍偏 **soft**，避免厚重。

---

## 6. 动效与交互气质（简要）

- **过渡**：页面与卡片进入可用 **短淡出 + 轻微上移 2～4px**，时长 **200～300ms**，曲线 ease-out。
- **卡片按压**：轻微 **scale 0.98** 或 **阴影略减弱**，不需弹跳。
- **列表**：滚动时顶栏可轻微显现分隔线或轻微模糊（可选），保持轻盈。

---

## 7. 浅色模式设计令牌 JSON

以下为 **可直接用于配置 / 设计交付 / 映射到 `ThemeData`** 的 JSON；颜色均为十六进制字符串，尺寸为数字（逻辑像素）。

```json
{
  "themeName": "NatureLifestyleLight",
  "meta": {
    "description": "自然与生活 · 浅色主题 · 森绿 + 哑光金",
    "mode": "light",
    "version": "1.0.0"
  },
  "colors": {
    "primary": "#2D4F35",
    "onPrimary": "#FFFFFF",
    "primaryContainer": "#E8EFE9",
    "onPrimaryContainer": "#1A3328",
    "secondary": "#C5A059",
    "onSecondary": "#FFFFFF",
    "secondaryContainer": "#F5F0E6",
    "onSecondaryContainer": "#5C4A2A",
    "background": "#FFFFFF",
    "onBackground": "#1A1A1A",
    "surface": "#FFFFFF",
    "surfaceVariant": "#F7F8FA",
    "onSurface": "#1A1A1A",
    "onSurfaceVariant": "#666666",
    "outline": "#EEEEEE",
    "outlineVariant": "#F2F2F2",
    "inputFill": "#F2F2F2",
    "shadow": "#000000",
    "accentGold": "#C5A059",
    "textPrimary": "#1A1A1A",
    "textSecondary": "#666666",
    "textTertiary": "#999999",
    "divider": "#EEEEEE",
    "inverseSurface": "#2D4F35",
    "inverseOnSurface": "#FFFFFF"
  },
  "dimensions": {
    "cardBorderRadius": 16,
    "buttonBorderRadius": 24,
    "inputBorderRadius": 20,
    "searchPillRadius": 25,
    "pagePaddingHorizontal": 16,
    "pagePaddingVertical": 16,
    "sectionSpacing": 16,
    "elementSpacing": 12,
    "searchBarHeight": 40,
    "fabSize": 56,
    "fabIconSize": 28,
    "bottomNavHeight": 56,
    "topBarIconSize": 24
  },
  "elevationShadows": {
    "soft": {
      "offsetX": 0,
      "offsetY": 4,
      "blurRadius": 20,
      "spreadRadius": 0,
      "color": "#000000",
      "opacity": 0.05
    },
    "medium": {
      "offsetX": 0,
      "offsetY": 6,
      "blurRadius": 25,
      "spreadRadius": 0,
      "color": "#000000",
      "opacity": 0.1
    }
  },
  "typography": {
    "fontFamilyFallback": "Noto Sans SC, system-ui, sans-serif",
    "titleLarge": { "fontSize": 18, "fontWeight": 700, "colorToken": "textPrimary" },
    "titleMedium": { "fontSize": 16, "fontWeight": 600, "colorToken": "textPrimary" },
    "bodyLarge": { "fontSize": 15, "fontWeight": 400, "colorToken": "textPrimary" },
    "bodyMedium": { "fontSize": 14, "fontWeight": 400, "colorToken": "textSecondary" },
    "labelLarge": { "fontSize": 12, "fontWeight": 500, "colorToken": "textSecondary" },
    "labelSmall": { "fontSize": 11, "fontWeight": 400, "colorToken": "textTertiary" }
  },
  "components": {
    "appBar": {
      "backgroundColorToken": "background",
      "foregroundColorToken": "textPrimary",
      "iconStyle": "outlined",
      "elevation": 0,
      "bottomBorderColorToken": "divider",
      "bottomBorderWidth": 0
    },
    "searchBar": {
      "backgroundColorToken": "inputFill",
      "borderRadiusToken": "searchPillRadius",
      "heightToken": "searchBarHeight",
      "iconColorToken": "textTertiary",
      "placeholderColorToken": "textTertiary",
      "textColorToken": "textPrimary"
    },
    "card": {
      "backgroundColorToken": "surface",
      "borderRadiusToken": "cardBorderRadius",
      "shadowStyle": "soft",
      "borderColorToken": "outline",
      "borderWidth": 0
    },
    "primaryButton": {
      "backgroundColorToken": "primary",
      "foregroundColorToken": "onPrimary",
      "borderRadiusToken": "buttonBorderRadius",
      "shadowStyle": "none"
    },
    "secondaryButton": {
      "style": "outline",
      "borderColorToken": "primary",
      "foregroundColorToken": "primary",
      "backgroundColorToken": "transparent"
    },
    "bottomNavigationBar": {
      "backgroundColorToken": "background",
      "topBorderColorToken": "divider",
      "topBorderWidth": 1,
      "activeIconColorToken": "primary",
      "inactiveIconColorToken": "textTertiary",
      "activeLabelColorToken": "primary",
      "inactiveLabelColorToken": "textTertiary"
    },
    "fab": {
      "backgroundColorToken": "primary",
      "foregroundColorToken": "onPrimary",
      "sizeToken": "fabSize",
      "shadowStyle": "soft",
      "shape": "circle"
    },
    "ticketPassCard": {
      "backgroundColorToken": "surface",
      "perforationLineColorToken": "divider",
      "stampAccentToken": "accentGold",
      "cornerIconStyle": "lineArt"
    }
  },
  "imagery": {
    "imageCornerMatchesCard": true,
    "textOverlayGradient": {
      "type": "linear",
      "begin": "topCenter",
      "end": "bottomCenter",
      "colors": [
        "rgba(0,0,0,0)",
        "rgba(0,0,0,0.62)"
      ]
    }
  }
}
```

### JSON 使用说明

- **`colors`**：可与 Flutter `ColorScheme.fromSeed` 或自定义 `ThemeData` 映射；`primaryContainer` / `secondaryContainer` 为生成柔和背景用的衍生色（浅绿灰、浅金灰）。
- **`elevationShadows`**：实现时把 `opacity` 作用于 `shadow` 色。
- **`components.*`** 中的 `*Token` 表示引用 `colors` 或 `dimensions` 里的键名，便于主题切换时统一替换。

---

## 8. 与记账本产品结合的备注（非布局）

- **顶栏**：保持 **白/浅底 + 森绿图标强调**，避免深色大块顶栏，与本文浅色规范一致。
- **收支语义**：绿色可保留「正向」心理，但需与品牌森绿 **`#2D4F35`** 区分层次（收入可用略亮绿色或专用 success 色），避免与主按钮完全同色混淆。
- **深色模式**：本文仅定义 **浅色 Nature & Lifestyle**；夜间主题需另立文档重新映射对比度。

---

*文档版本：1.0 · 基于「自然与生活」参考界面视觉抽象*
