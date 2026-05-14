# 记账本 (Bookkeeper) 文档中心

> **项目**: 功能完整、界面美观的 Flutter 记账 APP  
> **当前风格**: Peekaboo 柔和梦幻（梦幻紫 `#B8A9E8` + 暖黄强调 `#FFD93D`）  
> **最新版本**: v1.9.0

---

## 文档索引

### 核心文档

| 文档 | 说明 | 状态 |
|------|------|------|
| [requirements.md](requirements.md) | 项目需求（功能需求、非功能需求、里程碑） | ✅ |
| [features.md](features.md) | 功能模块详情（含数据模型、UI 说明） | ✅ |
| [changelog.md](changelog.md) | 版本更新日志（语义化版本） | ✅ |
| [database.md](database.md) | 数据库表结构、版本迁移、备份恢复 | ✅ |
| [bugs.md](bugs.md) | Bug 追踪记录 | ✅ |

### 设计规范

| 文档 | 说明 | 状态 |
|------|------|------|
| [design/peekaboo_style_spec.md](design/peekaboo_style_spec.md) | Peekaboo 风格完整视觉规范（**当前风格**） | ✅ |
| [design/ui-style-reference.md](design/ui-style-reference.md) | UI 风格参考与设计稿对照说明 | ✅ |
| [design/theme-neon-fintech-dark.md](design/theme-neon-fintech-dark.md) | 霓虹金融科技深色主题（历史归档） | 📚 |
| [design/theme-nature-lifestyle-light.md](design/theme-nature-lifestyle-light.md) | 自然与生活浅色主题（历史归档） | 📚 |

### 测试报告

| 文档 | 说明 |
|------|------|
| [testing/2026-05-08_bug修复验证.md](testing/2026-05-08_bug修复验证.md) | v1.3.2 按钮遮挡/深色字体/周期执行修复验证 |
| [testing/2026-05-08_周期记账频率扩展_账单导入xlsx.md](testing/2026-05-08_周期记账频率扩展_账单导入xlsx.md) | v1.3.1 周期频率扩展/账单导入 xlsx 测试 |

---

## 关键文件速查

| 用途 | 文件路径 |
|------|----------|
| 项目总入口（含完整 UI 规范） | `CLAUDE.md` |
| AppColors 色彩常量 | `lib/core/theme/app_colors.dart` |
| ThemeData 主题配置 | `lib/core/theme/app_theme.dart` |
| 通用卡片组件 | `lib/shared/widgets/app_card.dart` |
| 路由（含底部导航/FAB） | `lib/app/router/app_router.dart` |
| 首页（余额卡片/快捷操作） | `lib/features/home/presentation/home_screen.dart` |
| 通知监听服务 | `lib/core/services/notification_service.dart` |
| 数据库定义 | `lib/core/database/app_database.dart` |

---

## 开发速查

```bash
flutter pub get                          # 获取依赖
dart run build_runner build --delete-conflicting-outputs  # 生成代码
flutter run                              # 运行应用
flutter analyze                          # 代码分析
flutter test                             # 运行测试
flutter build apk --release              # 构建 APK
```

### 提交规范

| 前缀 | 用途 |
|------|------|
| `feat:` | 新功能 |
| `fix:` | Bug 修复 |
| `docs:` | 文档更新 |
| `style:` | 代码格式 |
| `refactor:` | 重构 |
| `test:` | 测试 |
| `chore:` | 构建/工具 |

### 文档更新流程

每次代码变更后，必须同步更新文档（先文档，后提交，一次 commit）：
1. 更新 `docs/changelog.md`：在 `[未发布]` 之前插入新版本条目
2. 更新 `docs/features.md`：对应功能列表
3. 如有数据库变更 → 更新 `docs/database.md`
4. 代码 + 文档一起 `git add` + `git commit`

---

*最后更新: 2026-05-13 · 文档整理后生成*
