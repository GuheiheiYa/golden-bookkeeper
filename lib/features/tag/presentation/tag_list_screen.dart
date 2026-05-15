import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';

// ========== 标签数据 Provider ==========

/// 标签列表数据 Provider
final tagsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = AppDatabase();
  return await db.getTags();
});

// ========== 标签管理页面 ==========

class TagListScreen extends ConsumerStatefulWidget {
  const TagListScreen({super.key});

  @override
  ConsumerState<TagListScreen> createState() => _TagListScreenState();
}

class _TagListScreenState extends ConsumerState<TagListScreen> {
  /// 刷新标签数据
  void _refreshData() {
    ref.invalidate(tagsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(tagsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text('标签管理', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTagDialog(context),
          ),
        ],
      ),
      body: tagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('加载失败: $error')),
        data: (tags) {
          if (tags.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.label_outline,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '暂无标签',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右上角 + 添加标签',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 说明
                Text(
                  '标签可以帮助你更好地分类和筛选交易记录',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(height: 24),
                // 标签云
                Text(
                  '所有标签',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: tags.asMap().entries.map((entry) {
                    final index = entry.key;
                    final tag = entry.value;
                    final name = tag['name'] as String;
                    final colorValue = tag['color'] as int? ?? AppColors.primary.value;

                    return GestureDetector(
                      onTap: () => _showEditTagDialog(context, tag),
                      onLongPress: () => _showDeleteConfirmation(context, tag),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Color(colorValue).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Color(colorValue),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              name,
                              style: TextStyle(
                                color: Color(colorValue),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: 50 * index),
                          duration: 200.ms,
                        )
                        .scale(begin: const Offset(0.9, 0.9));
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ========== 添加标签对话框 ==========

  void _showAddTagDialog(BuildContext context) {
    final nameController = TextEditingController();
    int selectedColor = AppColors.categoryColors[0].value;

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
                      child: Text('添加标签', style: Theme.of(context).textTheme.titleLarge),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('标签名称', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.lightOnSurfaceVariant, letterSpacing: 0.5)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: nameController,
                              style: const TextStyle(fontSize: 15),
                              decoration: InputDecoration(
                                hintText: '请输入标签名称',
                                filled: true,
                                fillColor: const Color(0xFFF3F4F6),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.5)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('选择颜色', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.lightOnSurfaceVariant, letterSpacing: 0.5)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12, runSpacing: 12,
                              children: AppColors.categoryColors.map((color) {
                                final isSelected = selectedColor == color.value;
                                return GestureDetector(
                                  onTap: () => setModalState(() => selectedColor = color.value),
                                  child: Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: color, shape: BoxShape.circle,
                                      border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                                      boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)] : null,
                                    ),
                                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                                  ),
                                );
                              }).toList(),
                            ),
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
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入标签名称')));
                                return;
                              }
                              final db = AppDatabase();
                              try {
                                await db.insertTag({'name': name, 'color': selectedColor});
                                Navigator.pop(context);
                                _refreshData();
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('标签添加成功')));
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('标签名称已存在')));
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

  // ========== 编辑标签对话框 ==========

  void _showEditTagDialog(BuildContext context, Map<String, dynamic> tag) {
    final nameController = TextEditingController(text: tag['name'] as String);
    int selectedColor = tag['color'] as int? ?? AppColors.primary.value;

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
                          Text('编辑标签', style: Theme.of(context).textTheme.titleLarge),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _showDeleteConfirmation(context, tag);
                            },
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
                            Text('标签名称', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.lightOnSurfaceVariant, letterSpacing: 0.5)),
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
                            Text('选择颜色', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.lightOnSurfaceVariant, letterSpacing: 0.5)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12, runSpacing: 12,
                              children: AppColors.categoryColors.map((color) {
                                final isSelected = selectedColor == color.value;
                                return GestureDetector(
                                  onTap: () => setModalState(() => selectedColor = color.value),
                                  child: Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: color, shape: BoxShape.circle,
                                      border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                                      boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)] : null,
                                    ),
                                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                                  ),
                                );
                              }).toList(),
                            ),
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
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入标签名称')));
                                return;
                              }
                              final db = AppDatabase();
                              try {
                                await db.updateTag(tag['id'] as int, {'name': name, 'color': selectedColor});
                                Navigator.pop(context);
                                _refreshData();
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('标签更新成功')));
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('标签名称已存在')));
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

  // ========== 删除确认对话框 ==========

  void _showDeleteConfirmation(BuildContext context, Map<String, dynamic> tag) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除标签'),
          content: Text('确定要删除标签"${tag['name']}"吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final db = AppDatabase();
                await db.deleteTag(tag['id'] as int);
                Navigator.pop(context);
                _refreshData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('标签已删除')),
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
  }
}
