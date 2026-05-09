# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**项目名称**: 记账本 (Bookkeeper)
**版本**: 1.0.0
**平台**: Android (Flutter 跨平台)
**描述**: 一个功能完整、界面美观的记账 APP，采用 Claude 风格设计（紫色/靛蓝主色调）

## 技术栈

| 组件 | 选择 | 理由 |
|------|------|------|
| 框架 | Flutter | 跨平台，一套代码 |
| 状态管理 | Riverpod | 编译时安全，与 drift Stream 无缝配合 |
| 数据库 | drift (SQLite ORM) | 类型安全查询，Stream 响应式 |
| 路由 | go_router | 声明式路由，支持嵌套导航 |
| 图表 | fl_chart | 饼图/折线图/柱状图全支持 |
| 动画 | flutter_animate | 声明式链式动画 |

## 开发命令

### 环境准备
```bash
# 检查 Flutter 环境
flutter doctor

# 获取依赖
flutter pub get

# 生成代码 (drift 和 riverpod)
dart run build_runner build --delete-conflicting-outputs

# 监听代码变化并自动生成
dart run build_runner watch
```

### 运行和调试
```bash
# 运行应用
flutter run

# 运行测试
flutter test

# 运行单个测试
flutter test test/path/to/test.dart

# 构建 APK
flutter build apk --release
```

### 代码质量
```bash
# 代码分析
flutter analyze

# 格式化代码
dart format lib/
```

## 项目结构

```
lib/
├── main.dart                          # 应用入口
├── app/
│   ├── app.dart                       # MaterialApp 配置
│   ├── router/app_router.dart         # go_router 路由定义
│   └── di/providers.dart              # Riverpod Provider 注册
├── core/
│   ├── database/                      # drift 数据库
│   │   ├── app_database.dart          # 数据库定义
│   │   ├── tables/                    # 表定义
│   │   └── daos/                      # 数据访问对象
│   ├── theme/                         # 主题系统
│   ├── constants/                     # 常量定义
│   ├── utils/                         # 工具类
│   └── services/                      # 服务层
├── features/                          # 功能模块
│   ├── home/                          # 首页
│   ├── transaction/                   # 记账核心
│   ├── category/                      # 分类管理
│   ├── statistics/                    # 统计报表
│   ├── budget/                        # 预算管理
│   ├── recurring/                     # 周期记账
│   ├── account/                       # 账户管理
│   ├── tag/                           # 标签管理
│   ├── import/                        # 账单导入
│   └── settings/                      # 设置
└── shared/                            # 共享组件
    ├── widgets/                       # 通用组件
    └── mixins/                        # 混入
```

## 数据库表结构

| 表名 | 描述 |
|------|------|
| accounts | 账户表（现金、银行卡、支付宝、微信） |
| categories | 分类表（支持二级分类） |
| transactions | 交易记录表（核心表） |
| tags | 标签表 |
| transaction_tags | 交易-标签关联表 |
| budgets | 预算表 |
| recurring_rules | 周期记账规则表 |
| exchange_rates | 汇率缓存表 |
| import_records | 导入记录表 |
| import_duplicates | 重复记录检测表 |

## 双主题 UI 设计

### 深色模式（霓虹金融科技）
- **主色**: `#C6FF00` (霓虹柠绿)，按钮/图标文字用黑色
- **背景**: `#000000` 纯黑，卡片 `#121212`
- **卡片**: `BorderRadius.circular(28)`，绿色发光替代黑阴影
- **发光**: `AppColors.primaryDark.withOpacity(0.15~0.30)`
- **渐变**: Hero 卡 `#D4FF00` → `#1B5E20`

### 浅色模式（自然与生活）
- **主色**: `#2D4F35` (森绿)，次色 `#C5A059` (哑光金)
- **背景**: `#FFFFFF` 纯白，卡片白色靠阴影分层
- **卡片**: `BorderRadius.circular(16)`，极柔阴影
- **文字**: 三级色阶 `#1A1A1A` → `#666666` → `#999999`

### 主题感知
- 使用 `AppColors.primaryOf(brightness)` 获取当前主题主色
- 使用 `AppColors.secondaryOf(brightness)` 获取当前主题次色
- 字体: Noto Sans SC (中文)
- 动画: flutter_animate 链式调用

## 文档管理

### 文档位置
- 需求文档: `docs/requirements.md`
- 功能文档: `docs/features.md`
- 版本日志: `docs/changelog.md`

### 更新文档
使用 `/update-docs` skill 自动更新文档：
```
/update-docs features 新增了标签筛选功能
/update-docs changelog v1.1.0 新增标签筛选
/update-docs all 完成了预算管理模块
```

## 开发规范

### 文件路径规范（硬性要求）
- **安装应用、导出文件、生成文件等操作必须优先使用 D 盘**
- 默认路径：`D:/` 或 `D:/project/`
- 禁止将文件输出到 C 盘（除非用户明确指定）
- 示例：
  - APK 输出：`D:/project/bookkeeper/build/`
  - 导出文件：`D:/exports/`
  - 临时文件：`D:/temp/`

### Git 提交规范（硬性要求）
- **每次完成一个功能或修复后，必须立即提交 git**
- 提交流程：
  1. `git add` 添加相关文件
  2. `git commit` 提交（使用规范的 commit message）
  3. `git push` 推送到远程仓库
- 触发时机：
  - 新功能开发完成后
  - Bug 修复完成后
  - 文档更新完成后
  - 代码重构完成后
- 禁止积压多个功能后一次性提交

[//]: # (### 测试规范（硬性要求）)

[//]: # (- **每次功能开发或修改完成后，必须启动子 agent 作为资深测试工程师进行测试**)

[//]: # (- 测试流程：)

[//]: # (  1. 功能开发完成)

[//]: # (  2. 启动子 agent 进行测试)

[//]: # (  3. 测试通过后提交代码)

[//]: # (  4. 测试失败则修复后重新测试)

[//]: # (- 测试内容：)

[//]: # (  - 功能正常性测试（核心流程）)

[//]: # (  - 边界条件测试)

[//]: # (  - UI/UX 测试（布局、样式、交互）)

[//]: # (  - 兼容性测试（深色/浅色模式）)

[//]: # (- 子 agent 职责：)

[//]: # (  - 阅读相关代码，理解功能逻辑)

[//]: # (  - 检查潜在的 bug 和问题)

[//]: # (  - 验证 UI 布局和样式)

[//]: # (  - 提出改进建议)

[//]: # (  - 生成测试文档（见下方格式）)

[//]: # ()
[//]: # (### 测试文档规范)

[//]: # (- **每次测试必须生成测试文档，保存到 `docs/testing/` 目录**)

[//]: # (- 文件命名：`YYYY-MM-DD_功能名称.md`)

[//]: # (- 文档格式：)

[//]: # (```markdown)

[//]: # (# 测试报告：功能名称)

[//]: # ()
[//]: # (## 测试信息)

[//]: # (- **测试时间**: YYYY-MM-DD HH:mm:ss)

[//]: # (- **测试版本**: v1.x.x)

[//]: # (- **测试人员**: Claude &#40;AI 测试工程师&#41;)

[//]: # (- **测试结果**: ✅ 通过 / ❌ 失败)

[//]: # ()
[//]: # (## 测试范围)

[//]: # (- 修改的文件列表)

[//]: # (- 影响的功能模块)

[//]: # ()
[//]: # (## 测试用例)

[//]: # ()
[//]: # (### 功能测试)

[//]: # (| 编号 | 测试项 | 测试步骤 | 预期结果 | 实际结果 | 状态 |)

[//]: # (|------|--------|----------|----------|----------|------|)

[//]: # (| TC001 | xxx | 1. xxx | xxx | xxx | ✅/❌ |)

[//]: # ()
[//]: # (### 边界测试)

[//]: # (| 编号 | 测试项 | 测试步骤 | 预期结果 | 实际结果 | 状态 |)

[//]: # (|------|--------|----------|----------|----------|------|)

[//]: # ()
[//]: # (### UI/UX 测试)

[//]: # (| 编号 | 测试项 | 测试步骤 | 预期结果 | 实际结果 | 状态 |)

[//]: # (|------|--------|----------|----------|----------|------|)

[//]: # ()
[//]: # (## 发现的问题)

[//]: # (| 编号 | 问题描述 | 严重程度 | 状态 |)

[//]: # (|------|----------|----------|------|)

[//]: # (| BUG001 | xxx | 高/中/低 | 已修复/待修复 |)

[//]: # ()
[//]: # (## 测试结论)

[//]: # (- 测试总结)

[//]: # (- 遗留问题)

[//]: # (- 改进建议)

[//]: # (```)

### 并行开发规范（可选）
- **当功能可以拆分为多个独立子任务时，可以使用子 agent 并行执行**
- 适用场景：
  - 多个独立的 UI 组件开发
  - 多个独立的 API 接口实现
  - 多个独立的 bug 修复
  - 文档更新与代码开发并行
- 使用方式：
  - 使用 Agent 工具启动多个子 agent
  - 每个子 agent 负责一个独立任务
  - 主 agent 负责协调和合并结果
- 注意事项：
  - 确保子任务之间没有依赖关系
  - 子任务完成后由主 agent 统一提交
  - 避免多个子 agent 修改同一文件

### 上下文管理（可选）
- **当对话上下文过长时，可以执行 `/compact` 压缩上下文**
- 触发时机：
  - 进行了大量代码修改后
  - 上下文包含过多工具调用结果时
  - 感觉响应变慢或质量下降时
- 使用方式：直接输入 `/compact` 命令
- 注意事项：
  - 压缩后会保留关键信息和摘要
  - 不会影响代码修改和文件状态
  - 可以在任何时候执行

### 代码规范
- 使用 Dart 官方代码风格
- 使用 Riverpod 进行状态管理
- 使用 drift 进行数据库操作
- 使用 go_router 进行路由管理

### 命名规范
- 文件名: snake_case.dart
- 类名: PascalCase
- 变量/函数: camelCase
- 常量: camelCase (Dart 推荐)

### 提交规范
- feat: 新功能
- fix: 修复问题
- docs: 文档更新
- style: 代码格式调整
- refactor: 代码重构
- test: 测试相关
- chore: 构建/工具相关

## 重要说明

### 代码生成
- drift 和 riverpod 需要代码生成
- 修改表定义后必须运行 `dart run build_runner build`
- `.g.dart` 文件是自动生成的，不要手动修改

### 数据库迁移
- 修改表结构需要更新 schemaVersion
- 在 migration 中添加迁移逻辑
- 测试迁移脚本的正确性

### 主题切换
- 使用 Riverpod 管理主题状态
- 支持深色/浅色/跟随系统三种模式
- 主题持久化到 SharedPreferences

## 常见问题

### Q: 如何添加新的数据库表？
A: 在 `core/database/tables/` 中创建表定义，然后在 `app_database.dart` 中注册，最后运行代码生成。

### Q: 如何添加新的功能模块？
A: 在 `features/` 中创建新的模块目录，包含 `presentation/`、`domain/`、`providers/` 子目录。

### Q: 如何更新文档？
A: 使用 `/update-docs` skill，指定文档类型和更新内容。

## 相关资源

- [Flutter 官方文档](https://flutter.dev)
- [drift 文档](https://drift.simonbinder.eu)
- [Riverpod 文档](https://riverpod.dev)
- [go_router 文档](https://pub.dev/packages/go_router)
- [fl_chart 文档](https://pub.dev/packages/fl_chart)
