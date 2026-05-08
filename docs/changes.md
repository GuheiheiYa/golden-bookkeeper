# 变更记录

本文档记录每次修改的详细内容，包括修改原因、修改文件和具体变更。

---

## 2026-05-06

### 1. 项目初始化
- 创建 Flutter 项目
- 配置 pubspec.yaml 依赖
- 配置 Android 构建环境（Gradle 镜像、SDK 路径）

### 2. 核心功能实现
- 实现数据库层（8 张表，完整 CRUD）
- 实现主题系统（Claude 风格配色）
- 实现路由系统（4 Tab 导航）
- 实现首页、记账、统计、设置页面

### 3. 高级功能实现
- 标签系统
- 多币种支持
- 统计报表（饼图、折线图、柱状图）
- 预算管理
- 周期记账
- 数据导出（CSV/Excel）
- 账单导入接口

### 4. UI/UX 优化
- 深色/浅色模式切换
- 滑动删除/编辑
- 空状态提示
- 加载动画

### 5. Bug 修复
- 修复 add_transaction_screen.dart 括号不匹配
- 修复 file_picker v1 embedding 错误
- 修复非 ASCII 路径问题
- 修复主题模式样式错位

---

## 2026-05-07 (中午)

### 1. 修复分类管理 bug
**原因**: 分类管理页面报错 "Every item of ReorderableListView must have a key"
**文件**: `lib/features/category/presentation/category_list_screen.dart`
**变更**:
- 将 `key: ValueKey(category['id'])` 从 `AppCard` 移到外层 `Container`
- 因为 `.animate()` 包装后会丢失 key，ReorderableListView 要求最外层组件必须有 key

### 2. 修复分类排序无法保存
**原因**: 分类拖拽排序后刷新列表会恢复原样
**文件**:
- `lib/app/di/providers.dart`
- `lib/features/category/presentation/category_list_screen.dart`
**变更**:
- 添加 `categoryRefreshProvider` 刷新触发器
- `expenseCategoriesProvider` 和 `incomeCategoriesProvider` 监听该触发器
- `_refreshData()` 改为递增触发器状态而非直接 invalidate

### 3. 升级图标库
**原因**: 原有图标数量少，没有分类，不够美观
**文件**: `lib/shared/utils/icon_utils.dart`
**变更**:
- 新增 `IconCategory` 枚举（餐饮、交通、购物、娱乐、居住、医疗、教育、工作、金融、旅行、宠物、其他）
- 新增 `IconInfo` 类（包含 name、icon、label、category）
- 图标数量从 20+ 扩展到 90+，按分类分组
- 新增 `iconsByCategory` getter 返回按分类分组的图标
- 新增 `getCategoryName()` 方法返回分类中文名

### 4. 优化分类图标选择器
**原因**: 原有图标选择器是平铺显示，不好找
**文件**: `lib/features/category/presentation/category_list_screen.dart`
**变更**:
- 提取 `_buildIconPicker()` 组件方法，图标按分类分组显示
- 提取 `_buildColorPicker()` 组件方法
- 添加和编辑分类对话框复用这两个组件
- 图标添加 Tooltip 显示中文名称

### 5. 修复备注弹窗键盘溢出
**原因**: 编辑备注时键盘弹出会导致弹窗溢出屏幕
**文件**: `lib/features/transaction/presentation/add_transaction_screen.dart`
**变更**:
- 将 `showDialog` 改为 `showModalBottomSheet`
- 使用 `isScrollControlled: true` + `MediaQuery.of(context).viewInsets.bottom`

### 6. 日期选择器中文化
**原因**: 日期选择器显示英文
**文件**:
- `lib/app/app.dart`
- `lib/pubspec.yaml`
- `lib/features/transaction/presentation/add_transaction_screen.dart`
**变更**:
- 添加 `flutter_localizations` 依赖
- 配置 `localizationsDelegates`、`supportedLocales`、`locale`
- 日期选择器添加中文参数（helpText、cancelText、confirmText 等）

### 7. 修复提示框不自动消失
**原因**: 使用 showDialog 显示的提示框无法自动关闭
**文件**:
- `lib/features/transaction/presentation/add_transaction_screen.dart`
- `lib/features/transaction/presentation/transaction_list_screen.dart`
**变更**:
- 改用 `OverlayEntry` 实现提示框
- 新增 `_ToastWidget` 和 `_ListToastWidget` 组件
- 使用 `AnimationController` 实现缩放和淡入动画
- 1.5 秒后自动移除 OverlayEntry

### 8. 优化数字键盘布局
**原因**: `00` 按钮不常用，日期选择需要更快捷
**文件**: `lib/features/transaction/presentation/add_transaction_screen.dart`
**变更**:
- 去掉 `00` 按钮
- 添加日期选择按钮（显示 📅 和当前日期）
- 点击直接打开日期选择器

### 9. 实现计算器功能
**原因**: +/- 按钮点击后不显示计算过程
**文件**: `lib/features/transaction/presentation/add_transaction_screen.dart`
**变更**:
- 添加 `_firstOperand`、`_pendingOperator`、`_waitingForSecondOperand` 状态
- 按 +/- 后在金额上方显示表达式（如 `10 +`）
- 输入第二个数字时更新显示
- 按完成时自动计算结果
- 支持连续计算

### 10. 修复首页 FAB 遮挡问题
**原因**: "记一笔"浮动按钮挡住最后一条交易的金额
**文件**: `lib/features/home/presentation/home_screen.dart`
**变更**:
- 在最近交易列表底部添加 80px 留白

### 11. 修复分类对话框保存按钮位置
**原因**: 保存按钮在最底部，需要滚动才能看到
**文件**: `lib/features/category/presentation/category_list_screen.dart`
**变更**:
- 添加/编辑分类对话框改为上下布局
- 内容区域可滚动，最大高度限制为屏幕 75%
- 保存按钮固定在底部，始终可见

### 12. 创建 update-docs skill
**原因**: 需要规范文档更新流程
**文件**: `.claude/skills/update-docs/SKILL.md`
**变更**:
- 创建文档更新技能，支持 `/update-docs` 命令
- 支持 features、changelog、requirements、all 四种类型

---

## 2026-05-07 (下午)

### 1. 实现首页预算功能
**时间**: 2026-05-07 15:30:00
**原因**: 首页预算进度卡片只有展示作用，没有实际功能
**文件**:
- `lib/features/home/presentation/home_screen.dart`
**变更**:
- 导入 budget_screen.dart 中的 budgetUsageProvider
- 替换硬编码的预算数据为真实数据库数据
- 显示总预算、已用金额、剩余金额和进度百分比
- 超支时显示红色警告，正常使用时显示绿色/紫色
- 暂无预算时显示空状态提示和"去设置"按钮
- "查看详情"按钮跳转到预算管理页面
- 快捷操作中"预算"和"周期"按钮也能正确跳转

### 2. 修复日期筛选 bug
**时间**: 2026-05-07 15:45:00
**原因**: 选择日期范围时，选当天日期无法筛选出当天的交易记录
**文件**:
- `lib/app/di/providers.dart`
**变更**:
- 在 groupedTransactionsProvider 中修正结束日期为当天 23:59:59
- 确保当天交易能被正确筛选到

### 3. 优化筛选面板布局
**时间**: 2026-05-07 15:50:00
**原因**: "应用筛选"按钮需要滚动到底部才能看到
**文件**:
- `lib/features/transaction/presentation/transaction_list_screen.dart`
**变更**:
- 筛选面板改为 Column 布局，内容区域可滚动
- "应用筛选"按钮固定在底部，始终可见
- 添加最大高度限制（屏幕 75%）

### 4. 优化筛选标签样式
**时间**: 2026-05-07 15:55:00
**原因**: 清空和筛选条件的边框太突兀，不够美观
**文件**:
- `lib/features/transaction/presentation/transaction_list_screen.dart`
**变更**:
- 移除 Chip 和 ActionChip 组件
- 使用自定义 Container 实现筛选标签
- 圆角胶囊样式，淡紫色背景
- 图标和文字使用主题色，更加协调

### 5. 新增长按快捷操作
**时间**: 2026-05-07 16:10:00
**原因**: 需要更便捷的方式编辑和删除交易记录
**文件**:
- `lib/features/transaction/presentation/transaction_list_screen.dart`
**变更**:
- 为交易列表项添加 GestureDetector 包装
- 长按 1-2 秒弹出快捷操作底部弹窗
- 显示交易信息摘要（收支类型、备注、金额）
- 提供编辑和删除两个操作按钮
- 使用 ListTile 样式，带图标和说明文字

### 6. 更新 update-docs skill
**时间**: 2026-05-07 16:15:00
**原因**: 原有 skill 描述不够清晰，不易自动触发
**文件**:
- `.claude/skills/update-docs/SKILL.md`
**变更**:
- 重写 skill 描述，明确自动触发规则
- 简化文档结构，突出核心规则
- 添加触发时机说明
- 添加版本号规则

### 7. 交易明细页添加记账按钮
**时间**: 2026-05-07 16:30:00
**原因**: 交易明细页面没有快速添加入口
**文件**:
- `lib/features/transaction/presentation/transaction_list_screen.dart`
**变更**:
- 在 AppBar 添加添加按钮
- 点击跳转到记账页面
- 返回后自动刷新列表

---

## 2026-05-08

### 1. 底部导航栏改版
**时间**: 2026-05-08 10:00:00
**原因**: 用户希望将记一笔功能放到底部导航栏，采用中间凸起的圆形图标设计
**文件**:
- `lib/app/router/app_router.dart`
- `lib/features/home/presentation/home_screen.dart`
**变更**:
- 底部导航栏改为 5 个菜单：首页、明细、记一笔（中间凸起）、统计、设置
- 使用 BottomAppBar + CircularNotchedRectangle 实现凹陷效果
- 中间记一笔按钮使用渐变色圆形 FAB
- 移除首页的 FAB 按钮

### 2. 修复 TabBar 底部白线
**时间**: 2026-05-08 10:15:00
**原因**: 记账页面、统计页面、分类管理页面的 TabBar 底部有白线，影响美观
**文件**:
- `lib/features/transaction/presentation/add_transaction_screen.dart`
- `lib/features/statistics/presentation/statistics_screen.dart`
- `lib/features/category/presentation/category_list_screen.dart`
**变更**:
- 为所有 TabBar 添加 dividerColor: Colors.transparent 和 dividerHeight: 0
- 移除 TabBar 底部的白线

### 3. 修复预算不自动更新
**时间**: 2026-05-08 10:30:00
**原因**: 记一笔后首页预算进度不会自动更新，需要手动去预算页面保存才会更新
**文件**:
- `lib/features/budget/presentation/budget_screen.dart`
- `lib/features/home/presentation/home_screen.dart`
**变更**:
- budgetUsageProvider 和 budgetsProvider 添加对 transactionRefreshProvider 的监听
- 首页添加对 budgetUsageProvider 的监听
- 交易数据更新后预算数据会自动刷新

### 4. 添加每分钟、每小时的周期记账频率
**时间**: 2026-05-08 11:00:00
**原因**: 用户需要更细粒度的周期记账频率
**文件**:
- `lib/features/recurring/presentation/recurring_screen.dart`
- `lib/core/database/app_database.dart`
**变更**:
- 在频率选择器中添加"每分钟"和"每小时"选项
- 更新 _getFrequencyText 方法支持新频率
- 修改 executeDueRecurringRules 方法支持新频率的执行逻辑

### 5. 修复周期记账保存按钮重叠
**时间**: 2026-05-08 11:15:00
**原因**: 编辑周期记账时，保存按钮和底部导航栏的记账按钮重叠
**文件**:
- `lib/features/recurring/presentation/recurring_screen.dart`
**变更**:
- 为添加和编辑对话框的保存按钮添加底部边距 (padding: EdgeInsets.only(bottom: 20))

### 6. 修复账单导入文件选择
**时间**: 2026-05-08 11:30:00
**原因**: 账单导入无法选择 xlsx 文件，只能选择 csv 和 txt 文件
**文件**:
- `lib/features/import/presentation/import_screen.dart`
- `lib/features/import/domain/wechat_parser.dart`
- `lib/features/import/domain/alipay_parser.dart`
**变更**:
- 文件选择器添加 xlsx 扩展名支持
- 微信解析器添加 xlsx 格式解析功能
- 支付宝解析器添加 xlsx 格式解析功能
- 使用 excel 包解析 xlsx 文件

### 7. 修复交易明细按钮被导航栏遮挡
**时间**: 2026-05-08 12:00:00
**原因**: 交易明细页面的编辑和删除按钮被底部导航栏遮挡
**文件**:
- `lib/features/transaction/presentation/transaction_list_screen.dart`
**变更**:
- 为 _showQuickActions 底部弹窗添加额外的底部边距 (padding: EdgeInsets.only(bottom: 20))

### 8. 修复深色主题字体不明显
**时间**: 2026-05-08 12:15:00
**原因**: 深色主题下，交易明细页面的分类、时间、账户字体不明显
**文件**:
- `lib/features/transaction/presentation/transaction_list_screen.dart`
**变更**:
- 为 subtitle 文本添加 color: Theme.of(context).colorScheme.onSurfaceVariant

### 9. 修复每分钟周期记账不执行
**时间**: 2026-05-08 12:30:00
**原因**: 设置每分钟的周期记账规则后，并没有每分钟进行记账
**文件**:
- `lib/features/home/presentation/home_screen.dart`
**变更**:
- 添加 Timer.periodic 定时器，每分钟检查一次周期记账规则
- 在 initState 中启动定时器，在 dispose 中取消定时器
- 添加 dart:async 导入

### 10. 优化滑动操作样式
**时间**: 2026-05-08 14:00:00
**原因**: 交易明细左右滑动编辑/删除时，背景色占据了整行，视觉效果不佳
**文件**:
- `lib/features/transaction/presentation/transaction_list_screen.dart`
**变更**:
- Dismissible 背景添加 margin (horizontal: 16, vertical: 4)
- 背景添加圆角 (borderRadius: BorderRadius.circular(12))
- 编辑背景显示在左侧，删除背景显示在右侧

### 11. 创建消息通知服务
**时间**: 2026-05-08 14:15:00
**原因**: 需要一个可复用的消息通知系统，用于首页显示各种通知（周期记账执行、预算提醒等）
**文件**:
- `lib/core/services/notification_service.dart` (新建)
**变更**:
- 创建 NotificationService 单例服务
- 支持 info、success、warning、error 四种消息类型
- 支持消息监听器模式
- 最多保留 50 条消息
- 提供 unreadCount 属性

### 12. 首页集成消息通知
**时间**: 2026-05-08 14:30:00
**原因**: 首页需要显示通知消息，特别是周期记账执行通知
**文件**:
- `lib/features/home/presentation/home_screen.dart`
**变更**:
- 导入 NotificationService
- 周期记账执行后通过 NotificationService 发送通知
- AppBar 添加通知铃铛图标，显示未读数量角标
- 点击铃铛显示通知列表底部弹窗
- 通知列表支持点击跳转和滑动删除

### 13. 修复所有页面弹窗按钮被遮挡
**时间**: 2026-05-08 14:45:00
**原因**: 多个页面的底部弹窗保存按钮被中间凸起的记账按钮遮挡
**文件**:
- `lib/features/budget/presentation/budget_screen.dart`
- `lib/features/account/presentation/account_list_screen.dart`
- `lib/features/tag/presentation/tag_list_screen.dart`
**变更**:
- 预算页面添加/编辑对话框保存按钮添加底部边距 (padding: EdgeInsets.only(bottom: 20))
- 账户页面添加/编辑对话框保存按钮添加底部边距
- 标签页面添加/编辑对话框保存按钮添加底部边距

### 14. 优化分类拖拽排序交互
**时间**: 2026-05-08 15:00:00
**原因**: 分类排序需要长按才能拖动，不够直观
**文件**:
- `lib/features/category/presentation/category_list_screen.dart`
**变更**:
- 在分类列表项右侧添加拖拽手柄图标 (Icons.drag_handle)
- 使用 ReorderableDragStartListener 包装拖拽手柄
- 触摸右侧手柄即可拖动，长按整行拖动也保留

### 15. 修复高频周期记账立即执行
**时间**: 2026-05-08 15:15:00
**原因**: 创建每分钟/每小时的周期记账规则后，需要等到下一个检查周期才会执行
**文件**:
- `lib/features/recurring/presentation/recurring_screen.dart`
**变更**:
- 创建高频规则（每分钟/每小时）后立即调用 executeDueRecurringRules
- 确保用户创建规则后马上能看到效果

---

## 2026-05-08 (续)

### 16. 修复分类排序功能
**时间**: 2026-05-08 16:00:00
**原因**: 分类拖拽排序后不生效，_updateSortOrder 直接修改了 Riverpod provider 的列表数据
**文件**:
- `lib/features/category/presentation/category_list_screen.dart`
**变更**:
- 拷贝列表后再操作，避免修改 provider 的缓存数据
- 使用数据库事务批量更新 sort_order，保证原子性

### 17. 新增批量删除交易记录
**时间**: 2026-05-08 16:15:00
**原因**: 用户需要批量删除多条交易记录
**文件**:
- `lib/features/transaction/presentation/transaction_list_screen.dart`
**变更**:
- AppBar 新增多选模式按钮（checklist 图标）
- 多选模式下显示全选、删除、退出按钮
- 多选模式下点击交易项切换选中状态，禁用滑动操作
- 顶部显示已选中数量
- 支持批量删除选中记录

### 18. 交易明细页添加回到顶部按钮
**时间**: 2026-05-08 16:20:00
**原因**: 交易记录多时需要快速回到顶部
**文件**:
- `lib/features/transaction/presentation/transaction_list_screen.dart`
**变更**:
- 添加 ScrollController 监听滚动位置
- 滚动超过 300px 后右下角显示回到顶部浮动按钮
- 点击按钮平滑滚动回顶部

### 19. 优化账单导入分类匹配
**时间**: 2026-05-08 16:30:00
**原因**: 导入的交易记录大部分被分到"咖啡"分类，分类匹配不准确
**文件**:
- `lib/features/import/presentation/import_screen.dart`
- `lib/core/database/app_database.dart`
**变更**:
- 大幅扩展关键词映射，覆盖微信/支付宝真实分类值和常见商户名
- 新增"通讯"分类（话费、流量、充值等）
- 新增 _matchCategoryByDescription 方法，根据交易描述二次匹配
- 修复 fallback 逻辑：固定使用"其他"分类而非列表最后一个
- 导入匹配优先级：分类字段 → 描述字段 → "其他"兜底

---

## 变更模板

### YYYY-MM-DD

#### 变更标题
**原因**: 为什么要修改
**文件**: 修改了哪些文件
**变更**:
- 具体修改内容
