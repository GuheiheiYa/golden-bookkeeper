import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/utils/icon_utils.dart';
import '../../../app/di/providers.dart';

// ========== 分类管理页面 ==========

class CategoryListScreen extends ConsumerStatefulWidget {
  const CategoryListScreen({super.key});

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 刷新分类数据
  void _refreshData() {
    ref.read(categoryRefreshProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('分类管理', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategoryDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          dividerColor: Colors.transparent,
          dividerHeight: 0,
          tabs: const [
            Tab(text: '支出'),
            Tab(text: '收入'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryTab(isExpense: true),
          _buildCategoryTab(isExpense: false),
        ],
      ),
    );
  }

  /// 构建分类标签页
  Widget _buildCategoryTab({required bool isExpense}) {
    final categoriesAsync = isExpense
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('加载失败: $error')),
      data: (categories) {
        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  '暂无分类',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '点击右上角 + 添加分类',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        }

        return ReorderableListView.builder(
          key: ValueKey('category_list_${isExpense ? "expense" : "income"}'),
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          onReorder: (oldIndex, newIndex) {
            // 更新排序顺序
            if (newIndex > oldIndex) newIndex -= 1;
            _updateSortOrder(categories, oldIndex, newIndex);
          },
          itemBuilder: (context, index) {
            final category = categories[index];
            final name = category['name'] as String;
            final iconName = category['icon'] as String? ?? 'category';
            final colorValue = category['color'] as int? ?? AppColors.primary.value;
            final isSystem = (category['is_system'] as int?) == 1;

            return Container(
              key: ValueKey('cat_${category['id']}_$index'),
              child: AppCard(
                margin: const EdgeInsets.only(bottom: 8),
                onTap: () => _showEditCategoryDialog(context, category),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(colorValue).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        IconUtils.fromName(iconName),
                        color: Color(colorValue),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (isSystem)
                            Text(
                              '系统默认',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.drag_handle,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(
                delay: Duration(milliseconds: 50 * index),
                duration: 200.ms,
              ).slideX(begin: 0.05, end: 0),
            );
          },
        );
      },
    );
  }

  /// 更新分类排序
  Future<void> _updateSortOrder(
      List<Map<String, dynamic>> categories, int oldIndex, int newIndex) async {
    final db = AppDatabase();
    // 拷贝列表，避免直接修改 provider 的数据
    final reordered = List<Map<String, dynamic>>.from(categories);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    // 使用事务批量更新排序顺序
    await db.database.then((db) async {
      await db.transaction((txn) async {
        for (int i = 0; i < reordered.length; i++) {
          await txn.update('categories', {'sort_order': i},
              where: 'id = ?', whereArgs: [reordered[i]['id'] as int]);
        }
      });
    });
    _refreshData();
  }

  // ========== 图标选择器组件 ==========

  Widget _buildIconPicker({
    required String selectedIcon,
    required ValueChanged<String> onIconSelected,
  }) {
    final brightness = Theme.of(context).brightness;
    final categories = IconUtils.iconsByCategory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择图标',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ...categories.entries.map((entry) {
          final category = entry.key;
          final icons = entry.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  IconUtils.getCategoryName(category),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: icons.map((info) {
                  final isSelected = selectedIcon == info.name;
                  return GestureDetector(
                    onTap: () => onIconSelected(info.name),
                    child: Tooltip(
                      message: info.label,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryOf(brightness).withValues(alpha: 0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          info.icon,
                          size: 22,
                          color: AppColors.primaryOf(brightness),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 4),
            ],
          );
        }),
      ],
    );
  }

  // ========== 颜色选择器组件 ==========

  Widget _buildColorPicker({
    required int selectedColor,
    required ValueChanged<int> onColorSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择颜色',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AppColors.categoryColors.map((color) {
            final isSelected = selectedColor == color.value;
            return GestureDetector(
              onTap: () => onColorSelected(color.value),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : AppColors.darkOutline,
                          width: 3,
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ========== 添加分类对话框 ==========

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final isExpense = _tabController.index == 0;
    String selectedIcon = 'restaurant';
    int selectedColor = AppColors.categoryColors[0].value;
    int? selectedLoanId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final screenHeight = MediaQuery.of(context).size.height;
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screenHeight * 0.72),
              child: Container(
                padding: EdgeInsets.fromLTRB(0, 0, 0, bottomInset + bottomPadding),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('添加${isExpense ? "支出" : "收入"}分类', style: Theme.of(context).textTheme.titleLarge),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('分类名称', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.lightOnSurfaceVariant, letterSpacing: 0.5)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: nameController,
                              style: const TextStyle(fontSize: 15),
                              decoration: InputDecoration(
                                hintText: '请输入分类名称',
                                filled: true,
                                fillColor: const Color(0xFFF3F4F6),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.5)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildIconPicker(selectedIcon: selectedIcon, onIconSelected: (name) { setModalState(() => selectedIcon = name); }),
                            const SizedBox(height: 16),
                            _buildColorPicker(selectedColor: selectedColor, onColorSelected: (value) { setModalState(() => selectedColor = value); }),
                            if (isExpense) ...[
                              const SizedBox(height: 16),
                              _buildLoanPicker(selectedLoanId: selectedLoanId, onLoanSelected: (id) { setModalState(() => selectedLoanId = id); }),
                            ],
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        border: Border(top: BorderSide(color: isDark ? AppColors.darkOutline : const Color(0xFFF0EBF5), width: 0.5)),
                      ),
                      child: SizedBox(
                        width: double.infinity, height: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(colors: [AppColors.warmYellow, AppColors.warmYellowDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              final name = nameController.text.trim();
                              if (name.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入分类名称'))); return; }
                              final db = AppDatabase();
                              final categoryData = <String, dynamic>{'name': name, 'is_expense': isExpense ? 1 : 0, 'icon': selectedIcon, 'color': selectedColor, 'sort_order': 999, 'is_system': 0};
                              if (selectedLoanId != null) { categoryData['loan_id'] = selectedLoanId; }
                              final messenger = ScaffoldMessenger.of(context);
                              await db.insertCategory(categoryData);
                              Navigator.pop(context);
                              _refreshData();
                              messenger.showSnackBar(const SnackBar(content: Text('分类添加成功')));
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                            child: const Text('保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.warmYellowText)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ========== 编辑分类对话框 ==========

  void _showEditCategoryDialog(BuildContext context, Map<String, dynamic> category) {
    final isSystem = (category['is_system'] as int?) == 1;
    if (isSystem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('系统默认分类不可编辑')),
      );
      return;
    }

    final nameController = TextEditingController(text: category['name'] as String);
    String selectedIcon = category['icon'] as String? ?? 'category';
    int selectedColor = category['color'] as int? ?? AppColors.primary.value;
    int? selectedLoanId = category['loan_id'] as int?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final screenHeight = MediaQuery.of(context).size.height;
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screenHeight * 0.72),
              child: Container(
                padding: EdgeInsets.fromLTRB(0, 0, 0, bottomInset + bottomPadding),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('编辑分类', style: Theme.of(context).textTheme.titleLarge),
                          GestureDetector(
                            onTap: () => _showDeleteConfirmation(context, category),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('分类名称', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.lightOnSurfaceVariant, letterSpacing: 0.5)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: nameController,
                              style: const TextStyle(fontSize: 15),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF3F4F6),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.5)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildIconPicker(selectedIcon: selectedIcon, onIconSelected: (name) { setModalState(() => selectedIcon = name); }),
                            const SizedBox(height: 16),
                            _buildColorPicker(selectedColor: selectedColor, onColorSelected: (value) { setModalState(() => selectedColor = value); }),
                            const SizedBox(height: 16),
                            _buildLoanPicker(selectedLoanId: selectedLoanId, onLoanSelected: (id) { setModalState(() => selectedLoanId = id); }),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        border: Border(top: BorderSide(color: isDark ? AppColors.darkOutline : const Color(0xFFF0EBF5), width: 0.5)),
                      ),
                      child: SizedBox(
                        width: double.infinity, height: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(colors: [AppColors.warmYellow, AppColors.warmYellowDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              final name = nameController.text.trim();
                              if (name.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入分类名称'))); return; }
                              final db = AppDatabase();
                              final updateData = <String, dynamic>{'name': name, 'icon': selectedIcon, 'color': selectedColor, 'loan_id': selectedLoanId};
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await db.updateCategory(category['id'] as int, updateData);
                                Navigator.pop(context);
                                _refreshData();
                                messenger.showSnackBar(const SnackBar(content: Text('分类更新成功')));
                              } catch (e) {
                                messenger.showSnackBar(SnackBar(content: Text('保存失败: $e')));
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                            child: const Text('保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.warmYellowText)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ========== 关联贷款选择器组件 ==========

  Widget _buildLoanPicker({
    required int? selectedLoanId,
    required ValueChanged<int?> onLoanSelected,
  }) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AppDatabase().getLoans(),
      builder: (context, snapshot) {
        final loans = snapshot.data ?? [];
        if (loans.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '关联贷款（可选）',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                GestureDetector(
                  onTap: () => onLoanSelected(null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selectedLoanId == null ? AppColors.primaryOf(Theme.of(context).brightness).withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('不关联', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selectedLoanId == null ? AppColors.primaryOf(Theme.of(context).brightness) : AppColors.lightOnSurfaceVariant)),
                  ),
                ),
                ...loans.map((loan) {
                  final isSelected = selectedLoanId == loan['id'];
                  const loanColor = Color(0xFFEF4444);
                  return GestureDetector(
                    onTap: () => onLoanSelected(loan['id'] as int),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? loanColor.withValues(alpha: 0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(loan['name'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? loanColor : AppColors.lightOnSurfaceVariant)),
                    ),
                  );
                }),
              ],
            ),
          ],
        );
      },
    );
  }

  // ========== 删除确认对话框 ==========

  void _showDeleteConfirmation(BuildContext dialogContext, Map<String, dynamic> category) {
    showDialog(
      context: dialogContext,
      builder: (confirmContext) {
        return FutureBuilder<int>(
          future: AppDatabase().getTransactionCountForCategory(category['id'] as int),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return AlertDialog(
              title: const Text('删除分类'),
              content: Text(
                count > 0
                    ? '该分类下有 $count 条交易记录，确定删除吗？\n删除后相关交易记录不会被删除。'
                    : '确定要删除分类"${category['name']}"吗？',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(confirmContext),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final db = AppDatabase();
                    await db.deleteCategory(category['id'] as int);
                    // 关闭确认对话框
                    Navigator.pop(confirmContext);
                    // 关闭编辑对话框
                    Navigator.pop(dialogContext);
                    _refreshData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('分类已删除')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  child: const Text('删除'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
