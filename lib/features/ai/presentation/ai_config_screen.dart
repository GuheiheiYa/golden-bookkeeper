import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/ai_service.dart';

/// AI 配置页面 — 设置 API Key / Endpoint / Model
class AiConfigScreen extends StatefulWidget {
  const AiConfigScreen({super.key});

  @override
  State<AiConfigScreen> createState() => _AiConfigScreenState();
}

class _AiConfigScreenState extends State<AiConfigScreen> {
  final _apiKeyController = TextEditingController();
  final _endpointController = TextEditingController();
  final _modelController = TextEditingController();
  final _service = AiService();
  bool _loading = false;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    _apiKeyController.text = await _service.getApiKey();
    _endpointController.text = await _service.getEndpoint();
    _modelController.text = await _service.getModel();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _endpointController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('AI 配置', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('API 密钥', '使用 OpenAI 兼容接口的 API Key'),
            const SizedBox(height: 8),
            _buildApiKeyField(isDark),
            const SizedBox(height: 20),
            _buildSection('接口地址', '默认使用 OpenAI 官方接口'),
            const SizedBox(height: 8),
            _buildInput(
              controller: _endpointController,
              hint: 'https://api.openai.com/v1/chat/completions',
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            _buildSection('模型名称', '如 gpt-4o-mini、gpt-3.5-turbo、deepseek-chat 等'),
            const SizedBox(height: 8),
            _buildInput(
              controller: _modelController,
              hint: 'gpt-4o-mini',
              isDark: isDark,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildOutlinedButton('测试连接', _loading ? null : _testConnection),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: _buildGradientButton('保存配置', _saveConfig),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFB8A9E8), letterSpacing: 0.5),
        ),
        const SizedBox(height: 2),
        Text(desc, style: const TextStyle(fontSize: 12, color: Color(0x88FFFFFF))),
      ],
    );
  }

  Widget _buildApiKeyField(bool isDark) {
    return TextField(
      controller: _apiKeyController,
      obscureText: _obscureKey,
      style: TextStyle(fontSize: 15, height: 1.5, color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground),
      decoration: InputDecoration(
        hintText: 'sk-...',
        hintStyle: TextStyle(fontSize: 15, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF3F4F6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        suffixIcon: IconButton(
          icon: Icon(_obscureKey ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
          onPressed: () => setState(() => _obscureKey = !_obscureKey),
        ),
      ),
    );
  }

  Widget _buildInput({required TextEditingController controller, required String hint, required bool isDark}) {
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: 15, height: 1.5, color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 15, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF3F4F6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildOutlinedButton(String label, VoidCallback? onPressed) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          side: const BorderSide(color: AppColors.lightOutline),
        ),
        child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.lightOnSurfaceVariant)),
      ),
    );
  }

  Widget _buildGradientButton(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(colors: [AppColors.warmYellow, AppColors.warmYellowDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: AppColors.warmYellow.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
          child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.warmYellowText)),
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() => _loading = true);
    final result = await _service.testConnection();
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    }
  }

  Future<void> _saveConfig() async {
    await _service.setApiKey(_apiKeyController.text.trim());
    await _service.setEndpoint(_endpointController.text.trim());
    await _service.setModel(_modelController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI 配置已保存')));
    }
  }
}
