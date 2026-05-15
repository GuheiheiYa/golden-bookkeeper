import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/database/app_database.dart';
import '../domain/ai_service.dart';

/// 智能助手 — AI 对话，根据账单数据给出理财建议
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _service = AiService();
  final _db = AppDatabase();
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = false;
  String? _contextData;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final income = await _db.getTotalIncome(start, end);
    final expense = await _db.getTotalExpense(start, end);
    final categories = await _db.getCategorySummary(start, end, isExpense: true);
    final budgets = await _db.getBudgets();
    final recentTransactions = await _db.getTransactions(limit: 10);

    final fmt = NumberFormat.currency(locale: 'zh_CN', symbol: '¥', decimalDigits: 2);

    final buf = StringBuffer();
    buf.writeln('=== 本月财务概况 ===');
    buf.writeln('本月收入: ${fmt.format(income)}');
    buf.writeln('本月支出: ${fmt.format(expense)}');
    buf.writeln('本月结余: ${fmt.format(income - expense)}');

    buf.writeln('\n=== 支出分类 TOP5 ===');
    final topCategories = categories.take(5).toList();
    for (final c in topCategories) {
      buf.writeln('${c["name"]}: ${fmt.format(c["total"])}');
    }

    if (budgets.isNotEmpty) {
      buf.writeln('\n=== 预算执行 ===');
      final b = budgets.first;
      final totalBudget = (b['total_budget'] as num?)?.toDouble() ?? 0;
      final used = expense;
      final remaining = totalBudget - used;
      buf.writeln('总预算: ${fmt.format(totalBudget)}');
      buf.writeln('已使用: ${fmt.format(used)} (${totalBudget > 0 ? (used / totalBudget * 100).toStringAsFixed(1) : 0}%)');
      buf.writeln('剩余: ${fmt.format(remaining)}');
    }

    buf.writeln('\n=== 最近 10 笔交易 ===');
    for (final tx in recentTransactions) {
      final date = DateFormat('MM/dd').format(DateTime.parse(tx['date'] as String));
      final amount = (tx['amount'] as num).toDouble();
      final isExpense = (tx['is_expense'] as int?) == 1;
      final goods = tx['goods'] as String? ?? '';
      final catName = tx['category_name'] as String? ?? '';
      buf.writeln('$date ${isExpense ? "-" : "+"}${fmt.format(amount)} $goods $catName');
    }

    setState(() => _contextData = buf.toString());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('智能助手', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: _messages.isEmpty ? _buildWelcome() : _buildChatList(isDark),
            ),
          ),
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground;
    final subColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.warmYellow, AppColors.warmYellowDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            Text('智能理财助手', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 8),
            Text('我已加载你本月的账单数据\n可以问我任何理财建议', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: subColor, height: 1.5)),
            const SizedBox(height: 24),
            _buildQuickQuestion('分析本月支出，哪些地方可以优化？'),
            _buildQuickQuestion('根据我的消费习惯，给3条省钱建议'),
            _buildQuickQuestion('下个月预算怎么分配更合理？'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickQuestion(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground;
    final bgColor = isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF3F4F6);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _sendMessage(text),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(text, style: TextStyle(fontSize: 14, color: textColor)),
        ),
      ),
    );
  }

  Widget _buildChatList(bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (ctx, i) {
        final msg = _messages[i];
        final isUser = msg['role'] == 'user';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser
                  ? AppColors.lightPrimary.withValues(alpha: 0.2)
                  : (isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF3F4F6)),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(6),
                bottomRight: isUser ? const Radius.circular(6) : const Radius.circular(18),
              ),
            ),
            child: Text(
              msg['content'] as String,
              style: TextStyle(fontSize: 15, height: 1.5, color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(top: BorderSide(color: isDark ? AppColors.darkOutline : const Color(0xFFF0EBF5), width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(fontSize: 15, color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground),
              decoration: InputDecoration(
                hintText: '输入你的问题...',
                hintStyle: TextStyle(fontSize: 15, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                filled: true,
                fillColor: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (v) => _sendMessage(v),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _loading ? null : () => _sendMessage(_messageController.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: _loading ? null : const LinearGradient(colors: [AppColors.warmYellow, AppColors.warmYellowDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                color: _loading ? AppColors.lightOutline : null,
                shape: BoxShape.circle,
              ),
              child: _loading
                  ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _messageController.clear();

    setState(() {
      _messages.add({'role': 'user', 'content': trimmed});
      _loading = true;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });

    final configured = await _service.isConfigured();
    if (!configured) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': '请先在 AI 配置中设置 API Key。'});
        _loading = false;
      });
      return;
    }

    final reply = await _service.chat(trimmed, contextData: _contextData ?? '暂无数据');

    if (mounted) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
        _loading = false;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      });
    }
  }
}
