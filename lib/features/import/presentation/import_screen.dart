import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../../app/di/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/bill_parser.dart';
import '../domain/wechat_parser.dart';
import '../domain/alipay_parser.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final List<BillParser> _parsers = [WechatParser(), AlipayParser()];
  BillParser? _selectedParser;
  BillParser? _activeParser; // 实际选中的解析器（用于标题显示）
  List<ParsedTransaction> _parsedTransactions = [];
  bool _isLoading = false;
  bool _isImporting = false;
  String? _errorMessage;
  String? _fileName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_activeParser != null
            ? '${_activeParser!.sourceName}账单导入'
            : '账单导入'),
      ),
      body: _isLoading
          ? _buildLoading()
          : _parsedTransactions.isEmpty
              ? _buildSourceSelection()
              : _buildPreview(),
    );
  }

  /// 加载中界面
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '正在解析账单文件...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// 来源选择界面
  Widget _buildSourceSelection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题区域
          Text(
            '选择账单来源',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '请选择你要导入的账单类型，然后选择对应的文件',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),

          // 解析器列表
          ..._parsers.map((parser) => _buildParserCard(parser)),

          // 错误提示
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const Spacer(),

          // 提示信息
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '微信: 进入"我 > 服务 > 钱包 > 账单 > 常见问题 > 下载账单"\n'
                    '支付宝: 进入"我的 > 账单 > 右上角... > 开具交易流水证明"',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.info,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 解析器选择卡片
  Widget _buildParserCard(BillParser parser) {
    final isSelected = _selectedParser == parser;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _selectParser(parser),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                parser.sourceName == '微信'
                    ? Icons.chat
                    : Icons.account_balance_wallet,
                size: 40,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${parser.sourceName}账单',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                : null,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '从${parser.sourceName}导入账单记录',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withOpacity(0.7)
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 预览界面
  Widget _buildPreview() {
    final totalExpense = _parsedTransactions
        .where((t) => t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalIncome = _parsedTransactions
        .where((t) => !t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    return Column(
      children: [
        // 顶部文件信息
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '共解析到 ${_parsedTransactions.length} 条记录',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_fileName != null)
                          Text(
                            _fileName!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _clearParsed,
                    child: const Text('重新选择'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 收支汇总
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryChip(
                      label: '总支出',
                      amount: totalExpense,
                      color: AppColors.error,
                      icon: Icons.arrow_downward,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryChip(
                      label: '总收入',
                      amount: totalIncome,
                      color: AppColors.income,
                      icon: Icons.arrow_upward,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 记录列表
        Expanded(
          child: ListView.separated(
            itemCount: _parsedTransactions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final transaction = _parsedTransactions[index];
              return _buildTransactionTile(transaction);
            },
          ),
        ),

        // 底部按钮
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isImporting ? null : _clearParsed,
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isImporting ? null : _importTransactions,
                    icon: _isImporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: Text(_isImporting ? '导入中...' : '导入 ${_parsedTransactions.length} 条记录'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 汇总卡片
  Widget _buildSummaryChip({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                    ),
              ),
              Text(
                '¥${amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 交易记录条目
  Widget _buildTransactionTile(ParsedTransaction transaction) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: transaction.isExpense
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          transaction.isExpense ? Icons.arrow_downward : Icons.arrow_upward,
          color: transaction.isExpense
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        transaction.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${DateFormat('MM/dd').format(transaction.date)}  ${transaction.category ?? ''}',
      ),
      trailing: Text(
        '${transaction.isExpense ? '-' : '+'}¥${transaction.amount.toStringAsFixed(2)}',
        style: TextStyle(
          color: transaction.isExpense
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 选择解析器并打开文件选择器
  void _selectParser(BillParser parser) {
    setState(() {
      _selectedParser = parser;
      _activeParser = parser;
      _errorMessage = null;
    });
    _pickFile();
  }

  /// 使用 file_picker 选择文件
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt', 'xlsx'],
        dialogTitle: '选择${_selectedParser!.sourceName}账单文件',
      );

      if (result == null || result.files.isEmpty) {
        // 用户取消了选择
        setState(() {
          _selectedParser = null;
          _activeParser = null;
        });
        return;
      }

      final platformFile = result.files.first;
      final filePath = platformFile.path;
      if (filePath == null) {
        setState(() {
          _errorMessage = '无法读取文件路径';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _fileName = platformFile.name;
      });

      final file = File(filePath);

      // 验证文件格式
      if (!_selectedParser!.canParse(file)) {
        setState(() {
          _isLoading = false;
          _errorMessage = '文件格式不正确，请选择${_selectedParser!.sourceName}账单文件';
        });
        return;
      }

      // 解析账单
      final transactions = await _selectedParser!.parse(file);

      setState(() {
        _isLoading = false;
        if (transactions.isEmpty) {
          _errorMessage = '未解析到任何交易记录，请检查文件格式';
        } else {
          _parsedTransactions = transactions;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '文件解析失败: $e';
      });
    }
  }

  /// 清除已解析的数据
  void _clearParsed() {
    setState(() {
      _parsedTransactions = [];
      _selectedParser = null;
      _activeParser = null;
      _errorMessage = null;
      _fileName = null;
    });
  }

  /// 将解析后的记录导入数据库
  Future<void> _importTransactions() async {
    setState(() => _isImporting = true);

    try {
      final db = ref.read(appDatabaseProvider);

      // 获取分类列表用于自动匹配
      final categories = await db.getCategories();
      final expenseCategories =
          categories.where((c) => c['is_expense'] == 1).toList();
      final incomeCategories =
          categories.where((c) => c['is_expense'] == 0).toList();

      // 获取账户列表，默认使用与来源匹配的账户
      final accounts = await db.getAccounts();
      int defaultAccountId = 1; // 默认现金账户

      // 根据来源匹配账户
      for (final account in accounts) {
        if (_activeParser?.sourceName == '微信' &&
            account['type'] == 'wechat') {
          defaultAccountId = account['id'] as int;
          break;
        } else if (_activeParser?.sourceName == '支付宝' &&
            account['type'] == 'alipay') {
          defaultAccountId = account['id'] as int;
          break;
        }
      }

      int importedCount = 0;
      int skippedCount = 0;

      for (final tx in _parsedTransactions) {
        // 检查是否已存在相同记录（通过订单号或日期+金额+描述去重）
        final existingTransactions = await db.getTransactions(
          startDate: DateTime(tx.date.year, tx.date.month, tx.date.day),
          endDate:
              DateTime(tx.date.year, tx.date.month, tx.date.day, 23, 59, 59),
        );

        bool isDuplicate = false;
        for (final existing in existingTransactions) {
          final existingAmount = (existing['amount'] as num?)?.toDouble() ?? 0;
          final existingIsExpense = existing['is_expense'] == 1;
          if (existingAmount == tx.amount &&
              existingIsExpense == tx.isExpense) {
            isDuplicate = true;
            break;
          }
        }

        if (isDuplicate) {
          skippedCount++;
          continue;
        }

        // 自动匹配分类 - 固定使用"其他"作为默认分类
        final defaultCategories = tx.isExpense ? expenseCategories : incomeCategories;
        int categoryId = _findOtherCategoryId(defaultCategories, tx.isExpense);

        // 1. 先根据来源分类字段匹配
        if (tx.category != null && tx.category!.isNotEmpty) {
          final matchedCategory = _matchCategory(
            tx.category!,
            defaultCategories,
          );
          if (matchedCategory != null) {
            categoryId = matchedCategory;
          }
        }

        // 2. 如果分类字段没匹配到，再根据描述匹配
        if (categoryId == _findOtherCategoryId(defaultCategories, tx.isExpense) &&
            tx.description.isNotEmpty) {
          final matchedByDesc = _matchCategoryByDescription(
            tx.description,
            defaultCategories,
          );
          if (matchedByDesc != null) {
            categoryId = matchedByDesc;
          }
        }

        // 插入交易记录
        await db.insertTransaction({
          'amount': tx.amount,
          'is_expense': tx.isExpense ? 1 : 0,
          'note': tx.description,
          'date': tx.date.toIso8601String(),
          'category_id': categoryId,
          'account_id': defaultAccountId,
        });

        importedCount++;
      }

      if (mounted) {
        // 关闭页面并返回
        Navigator.of(context).pop();

        // 显示结果
        String message = '成功导入 $importedCount 条记录';
        if (skippedCount > 0) {
          message += '，跳过 $skippedCount 条重复记录';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  /// 根据关键词匹配分类
  int? _matchCategory(String sourceCategory, List<Map<String, dynamic>> categories) {
    // 关键词到分类名的映射（覆盖微信/支付宝真实分类和商户关键词）
    final keywordMap = <String, List<String>>{
      '餐饮': [
        '餐饮', '美食', '食品', '外卖', '餐饮美食', '美团', '饿了么',
        '商户消费', '餐饮', '小吃', '快餐', '火锅', '烧烤', '面馆',
        '奶茶', '咖啡', '饮品', '甜品', '蛋糕', '面包', '超市',
        '便利店', '水果', '生鲜', '菜市场', '食堂', '麦当劳', '肯德基',
        '星巴克', '瑞幸', '海底捞', '必胜客', '汉堡', '披萨',
        '早餐', '午餐', '晚餐', '夜宵', '零食', '饮料',
      ],
      '交通': [
        '交通', '出行', '打车', '地铁', '公交', '滴滴', '加油',
        '出租', '网约车', '高铁', '火车', '飞机', '机票', '火车票',
        'ETC', '停车', '过路费', '汽车', '保养', '维修', '洗车',
        '共享单车', '哈啰', '青桔', '美团单车', 'T3出行', '曹操出行',
        '航空', '铁路', '客运', '船票', '摆渡',
      ],
      '购物': [
        '购物', '商城', '淘宝', '京东', '拼多多', '天猫', '苏宁',
        '唯品会', '闲鱼', '转转', '得物', '1688', '抖音商城',
        '服装', '鞋', '包', '配饰', '化妆品', '护肤品', '日用',
        '百货', '家居', '数码', '电器', '手机', '电脑',
      ],
      '娱乐': [
        '娱乐', '游戏', '电影', 'KTV', '旅游', '景区', '门票',
        '酒店', '民宿', '旅行', '签证', '演出', '演唱会', '话剧',
        '酒吧', '网咖', '电竞', '剧本杀', '密室', '桌游',
        '视频会员', '音乐会员', '爱奇艺', '优酷', '腾讯视频', '网易云',
        'Spotify', 'Apple', 'Steam', 'PlayStation', 'Nintendo',
      ],
      '居住': [
        '居住', '房租', '水电', '物业', '家居', '装修', '家具',
        '家电', '燃气', '电费', '水费', '暖气', '宽带', '网费',
        '房贷', '房租', '中介', '保洁', '搬家', '维修',
      ],
      '医疗': [
        '医疗', '医院', '药房', '药店', '诊所', '体检', '挂号',
        '牙科', '眼科', '皮肤', '中医', '保健', '维生素', '口罩',
        '保险', '社保', '医保',
      ],
      '教育': [
        '教育', '培训', '课程', '书店', '图书', '文具', '考试',
        '学费', '网课', '辅导', '考研', '留学', '英语', '驾校',
      ],
      '通讯': [
        '话费', '流量', '充值', '中国移动', '中国联通', '中国电信',
        '移动', '联通', '电信', '手机充值',
      ],
      '工资': ['工资', '薪资', '薪酬', '薪水', '收入'],
      '奖金': ['奖金', '年终奖', '绩效', '提成', '补贴'],
      '投资': ['投资', '理财', '基金', '股票', '债券', '利息', '分红', '收益'],
      '红包': ['红包', '转账'],
    };

    for (final entry in keywordMap.entries) {
      for (final keyword in entry.value) {
        if (sourceCategory.contains(keyword)) {
          for (final cat in categories) {
            if (cat['name'] == entry.key) {
              return cat['id'] as int;
            }
          }
        }
      }
    }

    return null;
  }

  /// 根据描述匹配分类（用于微信等没有分类字段的来源）
  int? _matchCategoryByDescription(String description, List<Map<String, dynamic>> categories) {
    final descLower = description.toLowerCase();

    final descKeywordMap = <String, List<String>>{
      '餐饮': ['餐', '饭', '食', '吃', '喝', '茶', '咖啡', '奶茶', '火锅', '烧烤',
              '面', '粉', '饺', '包', '饼', '鸡', '鱼', '肉', '菜', '果',
              '美团', '饿了么', '麦当劳', '肯德基', '星巴克', '瑞幸', '海底捞'],
      '交通': ['打车', '滴滴', '地铁', '公交', '出租', '加油', '停车', '高速',
              '火车', '高铁', '飞机', '机票', '车', '行', '旅'],
      '购物': ['淘宝', '京东', '拼多多', '天猫', '苏宁', '超市', '商场',
              '服装', '鞋', '包', '化妆品', '日用', '百货'],
      '娱乐': ['电影', '游戏', 'KTV', '旅游', '景区', '酒店', '民宿',
              '演出', '酒吧', '会员', '充值'],
      '居住': ['房租', '水电', '物业', '燃气', '宽带', '家具', '装修', '保洁'],
      '医疗': ['医院', '药', '诊所', '体检', '牙', '眼', '保健'],
      '教育': ['书', '课', '培训', '学', '考试', '文具'],
      '通讯': ['话费', '流量', '充值', '移动', '联通', '电信'],
    };

    for (final entry in descKeywordMap.entries) {
      for (final keyword in entry.value) {
        if (descLower.contains(keyword)) {
          for (final cat in categories) {
            if (cat['name'] == entry.key) {
              return cat['id'] as int;
            }
          }
        }
      }
    }

    return null;
  }

  /// 查找"其他"分类的 ID，固定使用该分类作为兜底
  int _findOtherCategoryId(List<Map<String, dynamic>> categories, bool isExpense) {
    // 优先找名为"其他"的分类
    for (final cat in categories) {
      if (cat['name'] == '其他') {
        return cat['id'] as int;
      }
    }
    // 兜底：硬编码 ID
    return isExpense ? 8 : 12;
  }
}
