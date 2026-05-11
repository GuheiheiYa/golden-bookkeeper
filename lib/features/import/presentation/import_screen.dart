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
      backgroundColor: Colors.transparent,
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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateFormat('MM/dd').format(transaction.date)}'
            '${transaction.category != null ? '  ${transaction.category}' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (transaction.goods != null &&
              transaction.goods!.isNotEmpty &&
              transaction.goods != transaction.description)
            Text(
              '商品: ${transaction.goods!}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          if (transaction.note != null && transaction.note!.isNotEmpty)
            Text(
              '备注: ${transaction.note!}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
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

        // 自动匹配分类
        final defaultCategories = tx.isExpense ? expenseCategories : incomeCategories;
        int categoryId = _findOtherCategoryId(defaultCategories, tx.isExpense);

        // 1. 优先根据交易类型直接映射（微信的"交易类型"：转账、群收款、滴滴出行等）
        if (tx.category != null && tx.category!.isNotEmpty) {
          final mappedId = _matchByTransactionType(
            tx.category!, tx.isExpense, expenseCategories, incomeCategories,
          );
          if (mappedId != null) {
            categoryId = mappedId;
          }
        }

        // 2. 如果交易类型没有直接映射，根据描述匹配商户名
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

        // 3. 如果还是没匹配到，且来源分类字段有意义（支付宝的"餐饮美食"等），尝试匹配
        if (categoryId == _findOtherCategoryId(defaultCategories, tx.isExpense) &&
            tx.category != null &&
            tx.category!.isNotEmpty &&
            tx.category != '商户消费' &&
            tx.category != '其他') {
          final matchedCategory = _matchCategoryByDescription(
            tx.category!,
            defaultCategories,
          );
          if (matchedCategory != null) {
            categoryId = matchedCategory;
          }
        }

        // 插入交易记录（商品和备注分别存储）
        await db.insertTransaction({
          'amount': tx.amount,
          'is_expense': tx.isExpense ? 1 : 0,
          'note': tx.note,
          'goods': tx.goods,
          'date': tx.date.toIso8601String(),
          'category_id': categoryId,
          'account_id': defaultAccountId,
        });

        importedCount++;
      }

      // 触发交易数据刷新
      ref.read(transactionRefreshProvider.notifier).state++;

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

  /// 根据交易类型直接映射分类（微信的"交易类型"字段）
  int? _matchByTransactionType(
    String transactionType,
    bool isExpense,
    List<Map<String, dynamic>> expenseCategories,
    List<Map<String, dynamic>> incomeCategories,
  ) {
    // 微信交易类型 → 分类名映射
    final typeMap = <String, String>{
      '转账': '转账',
      '群收款': '其他',      // 群收款归入收入-其他
      '滴滴出行': '交通',
      '微信红包': '其他',    // 红包归入收入-其他
      '二维码收款': '其他',  // 收款归入收入-其他
      '扫二维码付款': '其他', // 付款归入支出-其他
      '充值': '通讯',
      '退款': '其他',        // 退款归入支出-其他
    };

    final mappedName = typeMap[transactionType];
    if (mappedName == null) return null;

    final categories = isExpense ? expenseCategories : incomeCategories;
    for (final cat in categories) {
      if (cat['name'] == mappedName) {
        return cat['id'] as int;
      }
    }
    return null;
  }

  /// 根据描述匹配分类（用于"商户消费"等通用交易类型）
  int? _matchCategoryByDescription(String description, List<Map<String, dynamic>> categories) {
    final descLower = description.toLowerCase();

    final descKeywordMap = <String, List<String>>{
      '餐饮': [
        '美团', '饿了么', '麦当劳', '肯德基', '星巴克', '瑞幸',
        '库迪', 'Cotti', 'Manner', 'Tims', '海底捞', '蜜雪冰城',
        '喜茶', '奈雪', '茶百道', '古茗', '霸王茶姬', '沪上阿姨',
        'CoCo', '一点点', '书亦', '益禾堂', '茶颜悦色',
        'KFC', '汉堡王', '德克士', '必胜客', '西贝', '呷哺', '凑凑', '太二',
        '咖啡', '奶茶', '火锅', '烧烤', '快餐', '小吃',
        '面包', '糕点', '甜品', '饮品', '果汁', '烘焙',
        '超市', '便利店', '水果', '生鲜', '菜市场', '食堂',
        '餐厅', '饭店', '面馆', '粉店', '饺子', '包子',
      ],
      '交通': [
        '滴滴', '打车', '地铁', '公交', '出租', '加油', '停车', '高速',
        '火车', '高铁', '飞机', '机票', 'ETC', '过路费',
        '共享单车', '哈啰', '青桔', '美团单车', 'T3出行', '曹操出行',
        '航空', '铁路', '客运', '洗车', '保养',
      ],
      '购物': [
        '淘宝', '京东', '拼多多', '天猫', '苏宁', '唯品会',
        '闲鱼', '转转', '得物', '1688', '抖音商城',
        '超市', '商场', '百货', '服装', '化妆品', '数码', '电器',
      ],
      '娱乐': [
        '电影', '游戏', 'KTV', '景区', '门票', '酒店', '民宿',
        '演出', '演唱会', '酒吧', '剧本杀', '密室',
        '爱奇艺', '优酷', '腾讯视频', '网易云', 'Spotify',
        'Steam', 'Apple',
      ],
      '居住': [
        '房租', '水电', '物业', '燃气', '宽带', '家具', '装修',
        '保洁', '搬家', '中介', '房贷',
      ],
      '医疗': [
        '医院', '药房', '药店', '诊所', '体检', '挂号',
        '牙科', '眼科', '中医', '保健',
      ],
      '教育': [
        '书店', '图书', '培训', '课程', '学费', '网课', '驾校',
        '考试', '辅导', '留学',
      ],
      '通讯': [
        '话费', '流量', '中国移动', '中国联通', '中国电信',
        '手机充值',
      ],
    };

    for (final entry in descKeywordMap.entries) {
      for (final keyword in entry.value) {
        if (descLower.contains(keyword.toLowerCase())) {
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
    // 兜底：硬编�