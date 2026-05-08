import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/constants/currency_list.dart';
import '../../../app/di/providers.dart';

/// 从标签管理页面导入 tagsProvider，避免重复定义
import '../../tag/presentation/tag_list_screen.dart' show tagsProvider;

class AddTransactionScreen extends ConsumerStatefulWidget {
  /// 可选的交易 ID，传入时为编辑模式
  final int? transactionId;

  const AddTransactionScreen({super.key, this.transactionId});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _amount = '0';
  String _note = '';
  DateTime _selectedDate = DateTime.now();
  int? _selectedCategoryId;
  int? _selectedAccountId;
  String _selectedCurrency = 'CNY';

  // 计算器状态
  double? _firstOperand;
  String? _pendingOperator;
  bool _waitingForSecondOperand = false;
  Set<int> _selectedTagIds = {};

  /// 是否为编辑模式
  bool get _isEditing => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // 切换支出/收入时重置选中分类
      setState(() {
        _selectedCategoryId = null;
      });
    });

    // 编辑模式：加载已有交易数据
    if (_isEditing) {
      _loadTransactionData();
    }
  }

  /// 编辑模式：从数据库加载交易数据填充表单
  Future<void> _loadTransactionData() async {
    final db = ref.read(appDatabaseProvider);
    final tx = await db.getTransactionById(widget.transactionId!);
    if (tx == null || !mounted) return;

    final isExpense = (tx['is_expense'] as int) == 1;
    final amount = (tx['amount'] as num).toDouble();
    final tags = await db.getTagsForTransaction(widget.transactionId!);

    setState(() {
      // 如果是收入，切换到收入 Tab
      if (!isExpense) {
        _tabController.index = 1;
      }
      // 格式化金额，去除尾部多余的 0
      _amount = amount == amount.roundToDouble()
          ? amount.toStringAsFixed(0)
          : amount.toString();
      _note = tx['note'] as String? ?? '';
      _selectedDate = DateTime.parse(tx['date'] as String);
      _selectedCategoryId = tx['category_id'] as int;
      _selectedAccountId = tx['account_id'] as int;
      _selectedCurrency = tx['currency'] as String? ?? 'CNY';
      _selectedTagIds = tags.map((t) => t['id'] as int).toSet();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 从数据库读取分类列表
    final categoriesAsync = _tabController.index == 0
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);
    // 从数据库读取账户列表
    final accountsAsync = ref.watch(accountsProvider);
    // 从数据库读取标签列表
    final tagsAsync = ref.watch(tagsProvider);

    // 默认选中第一个账户（仅新建模式）
    if (!_isEditing) {
      accountsAsync.whenData((accounts) {
        if (_selectedAccountId == null && accounts.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedAccountId = accounts.first['id'] as int;
              });
            }
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEditing ? '编辑交易' : '记一笔'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => _saveTransaction(context),
            child: Text(
              '保存',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(text: '支出'),
            Tab(text: '收入'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 金额显示
          _buildAmountDisplay(),
          // 分类选择（从数据库读取）
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildCategoryGrid(categoriesAsync),
                  _buildAdditionalOptions(accountsAsync),
                  _buildTagSelection(tagsAsync),
                ],
              ),
            ),
          ),
          // 数字键盘
          _buildNumericKeyboard(),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay() {
    final currencySymbol = getCurrencySymbol(_selectedCurrency);
    // 构建显示表达式
    String displayText = _amount;
    if (_pendingOperator != null && _firstOperand != null) {
      final firstStr = _firstOperand!.toStringAsFixed(
        _firstOperand!.truncateToDouble() == _firstOperand! ? 0 : 2,
      );
      if (_waitingForSecondOperand) {
        displayText = '$firstStr${_pendingOperator!}';
      } else {
        displayText = '$firstStr${_pendingOperator!}$_amount';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Column(
        children: [
          // 计算表达式提示
          if (_pendingOperator != null && _firstOperand != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${_firstOperand!.toStringAsFixed(_firstOperand!.truncateToDouble() == _firstOperand! ? 0 : 2)} ${_pendingOperator == '+' ? '+' : '-'}',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.primary.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              GestureDetector(
                onTap: _showCurrencyPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currencySymbol,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _waitingForSecondOperand ? '' : _amount,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  /// 分类网格 - 从数据库读取
  Widget _buildCategoryGrid(AsyncValue<List<Map<String, dynamic>>> categoriesAsync) {
    return categoriesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: Text('加载分类失败: $e')),
      ),
      data: (categories) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '选择分类',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final catId = category['id'] as int;
                  final catName = category['name'] as String;
                  final catIcon = category['icon'] as String?;
                  final catColor = category['color'] as int? ?? 0xFF6B7280;
                  final isSelected = _selectedCategoryId == catId;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategoryId = catId;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(catColor).withOpacity(0.1)
                            : Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: Color(catColor), width: 2)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            mapIconName(catIcon),
                            color: isSelected
                                ? Color(catColor)
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            catName,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? Color(catColor)
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
      },
    );
  }

  /// 附加选项 - 账户从数据库读取
  Widget _buildAdditionalOptions(AsyncValue<List<Map<String, dynamic>>> accountsAsync) {
    final accountName = accountsAsync.when(
      loading: () => '加载中...',
      error: (_, __) => '加载失败',
      data: (accounts) {
        if (_selectedAccountId == null) return '请选择';
        final match = accounts.where((a) => a['id'] == _selectedAccountId);
        return match.isNotEmpty ? (match.first['name'] as String) : '请选择';
      },
    );

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildOptionTile(
            icon: Icons.account_balance_wallet,
            label: '账户',
            value: accountName,
            onTap: () => _showAccountPicker(accountsAsync),
          ),
          _buildOptionTile(
            icon: Icons.calendar_today,
            label: '日期',
            value: '${_selectedDate.month}月${_selectedDate.day}日',
            onTap: _selectDate,
          ),
          _buildOptionTile(
            icon: Icons.note,
            label: '备注',
            value: _note.isEmpty ? '点击添加' : _note,
            onTap: _showNoteDialog,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  /// 标签选择区域 - 从数据库读取标签，支持多选
  Widget _buildTagSelection(AsyncValue<List<Map<String, dynamic>>> tagsAsync) {
    return tagsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (tags) {
        if (tags.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '标签',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((tag) {
                  final tagId = tag['id'] as int;
                  final tagName = tag['name'] as String;
                  final tagColor = tag['color'] as int? ?? 0xFF7C3AED;
                  final isSelected = _selectedTagIds.contains(tagId);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedTagIds.remove(tagId);
                        } else {
                          _selectedTagIds.add(tagId);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(tagColor).withOpacity(0.15)
                            : Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Color(tagColor)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.check,
                                size: 16,
                                color: Color(tagColor),
                              ),
                            ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Color(tagColor),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tagName,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? Color(tagColor)
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 250.ms, duration: 300.ms);
      },
    );
  }

  Widget _buildNumericKeyboard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildKey('1'),
              _buildKey('2'),
              _buildKey('3'),
              _buildKey('⌫', isAction: true),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildKey('4'),
              _buildKey('5'),
              _buildKey('6'),
              _buildKey('+', isAction: true),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildKey('7'),
              _buildKey('8'),
              _buildKey('9'),
              _buildKey('-', isAction: true),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildKey('.'),
              _buildKey('0'),
              _buildKey('📅', isAction: true, isDate: true),
              _buildKey('完成', isAction: true, isConfirm: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String text, {bool isAction = false, bool isConfirm = false, bool isDate = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: isConfirm
              ? AppColors.primary
              : isAction
                  ? Theme.of(context).colorScheme.surfaceVariant
                  : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _onKeyPressed(text, isDate: isDate),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              child: isDate
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_selectedDate.month}/${_selectedDate.day}',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      text,
                      style: TextStyle(
                        fontSize: isConfirm ? 16 : 20,
                        fontWeight: isConfirm ? FontWeight.w600 : FontWeight.w500,
                        color: isConfirm
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _onKeyPressed(String key, {bool isDate = false}) {
    if (isDate) {
      _selectDate();
      return;
    }
    setState(() {
      if (key == '⌫') {
        if (_waitingForSecondOperand) {
          // 如果在等待第二个操作数，取消操作
          _pendingOperator = null;
          _firstOperand = null;
          _waitingForSecondOperand = false;
        } else if (_amount.length > 1) {
          _amount = _amount.substring(0, _amount.length - 1);
        } else {
          _amount = '0';
        }
      } else if (key == '完成') {
        // 如果有待执行的操作，先计算结果
        if (_pendingOperator != null && _firstOperand != null) {
          _calculateResult();
        }
        _saveTransaction(context);
      } else if (key == '+' || key == '-') {
        final currentValue = double.tryParse(_amount) ?? 0;
        if (_firstOperand != null && _pendingOperator != null && !_waitingForSecondOperand) {
          // 连续计算：先执行上一个操作
          _calculateResult();
          _firstOperand = double.tryParse(_amount);
        } else {
          _firstOperand = currentValue;
        }
        _pendingOperator = key;
        _waitingForSecondOperand = true;
      } else if (key == '.') {
        if (_waitingForSecondOperand) {
          _amount = '0';
          _waitingForSecondOperand = false;
        }
        if (!_amount.contains('.')) {
          _amount += '.';
        }
      } else {
        if (_waitingForSecondOperand) {
          _amount = key;
          _waitingForSecondOperand = false;
        } else {
          if (_amount == '0') {
            _amount = key;
          } else {
            // 限制小数点后2位
            if (_amount.contains('.')) {
              final parts = _amount.split('.');
              if (parts.length > 1 && parts[1].length >= 2) {
                return;
              }
            }
            _amount += key;
          }
        }
      }
    });
  }

  /// 执行计算器运算
  void _calculateResult() {
    if (_firstOperand == null || _pendingOperator == null) return;
    final secondOperand = double.tryParse(_amount) ?? 0;
    double result;
    if (_pendingOperator == '+') {
      result = _firstOperand! + secondOperand;
    } else {
      result = _firstOperand! - secondOperand;
    }
    // 格式化结果，保留最多2位小数
    _amount = result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 2);
    _firstOperand = null;
    _pendingOperator = null;
  }

  /// 账户选择弹窗 - 从数据库读取
  void _showAccountPicker(AsyncValue<List<Map<String, dynamic>>> accountsAsync) {
    accountsAsync.whenData((accounts) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '选择账户',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ...accounts.map((account) {
                  final accId = account['id'] as int;
                  final accName = account['name'] as String;
                  final accIcon = account['icon'] as String?;
                  final accColor = account['color'] as int? ?? 0xFF6B7280;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(accColor).withOpacity(0.1),
                      child: Icon(
                        mapIconName(accIcon),
                        color: Color(accColor),
                      ),
                    ),
                    title: Text(accName),
                    trailing: _selectedAccountId == accId
                        ? Icon(Icons.check_circle, color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedAccountId = accId;
                      });
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          );
        },
      );
    });
  }

  /// 币种选择弹窗 - Claude 风格
  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '选择币种',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '选择记账使用的币种',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: supportedCurrencies.length,
                itemBuilder: (context, index) {
                  final currency = supportedCurrencies[index];
                  final isSelected = _selectedCurrency == currency.code;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCurrency = currency.code;
                      });
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currency.symbol,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currency.code,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currency.name,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.7)
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('zh', 'CN'),
      helpText: '选择日期',
      cancelText: '取消',
      confirmText: '确定',
      fieldLabelText: '日期',
      fieldHintText: '年/月/日',
    );
    if (date != null) {
      // 保留当前时分秒
      final now = DateTime.now();
      setState(() {
        _selectedDate = DateTime(date.year, date.month, date.day, now.hour, now.minute, now.second);
      });
    }
  }

  void _showNoteDialog() {
    final controller = TextEditingController(text: _note);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '添加备注',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '输入备注信息',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: 3,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _note = controller.text;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('确定'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// 保存交易到数据库（新建或更新）
  Future<void> _saveTransaction(BuildContext context) async {
    final amount = double.tryParse(_amount);
    if (amount == null || amount <= 0) {
      if (mounted) {
        _showCenterToast('请输入有效金额', isError: true);
      }
      return;
    }

    if (_selectedCategoryId == null) {
      if (mounted) {
        _showCenterToast('请选择分类', isError: true);
      }
      return;
    }

    if (_selectedAccountId == null) {
      if (mounted) {
        _showCenterToast('请选择账户', isError: true);
      }
      return;
    }

    final isExpense = _tabController.index == 0;
    final db = ref.read(appDatabaseProvider);

    // 获取汇率（非 CNY 时）
    double exchangeRate = 1.0;
    if (_selectedCurrency != 'CNY') {
      exchangeRate = await db.getExchangeRate(_selectedCurrency, 'CNY');
    }

    final transactionData = {
      'amount': amount,
      'is_expense': isExpense ? 1 : 0,
      'note': _note.isNotEmpty ? _note : null,
      'date': _selectedDate.toIso8601String(),
      'category_id': _selectedCategoryId!,
      'account_id': _selectedAccountId!,
      'currency': _selectedCurrency,
      'exchange_rate': exchangeRate,
    };

    try {
      int transactionId;

      if (_isEditing) {
        // 编辑模式：更新已有交易
        transactionId = widget.transactionId!;
        await db.updateTransaction(transactionId, transactionData);
        // 先删除旧的标签关联，再重新插入
        await db.deleteTransactionTags(transactionId);
      } else {
        // 新建模式：插入交易
        transactionId = await db.insertTransaction(transactionData);
      }

      // 保存标签关联
      for (final tagId in _selectedTagIds) {
        await db.insertTransactionTag(transactionId, tagId);
      }

      // 通知刷新
      ref.read(transactionRefreshProvider.notifier).state++;

      if (mounted) {
        // 先显示成功提示，然后关闭页面
        _showCenterToast(_isEditing ? '更新成功' : '保存成功');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        _showCenterToast('${_isEditing ? '更新' : '保存'}失败: $e', isError: true);
      }
    }
  }

  /// 显示居中提示（替代 SnackBar，不遮挡底部按钮）
  void _showCenterToast(String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return _ToastWidget(
          message: message,
          isError: isError,
          onDismiss: () {
            if (entry.mounted) {
              entry.remove();
            }
          },
        );
      },
    );
    overlay.insert(entry);

    // 自动关闭
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }
}

/// 居中提示组件
class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black26,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.isError
                        ? Colors.red.withOpacity(0.1)
                        : const Color(0xFF7C3AED).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isError
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    color: widget.isError
                        ? Colors.red
                        : const Color(0xFF7C3AED),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.isError
                        ? Colors.red
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
