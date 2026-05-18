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
  bool _saving = false;
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
    final textColor = isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground;
    final subColor = isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('AI 配置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 区块标题
                    Text('连接配置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor)),
                    const SizedBox(height: 4),
                    Text('使用 OpenAI 兼容接口，支持 DeepSeek 等模型', style: TextStyle(fontSize: 13, color: subColor)),
                    const SizedBox(height: 24),

                    // API Key
                    _buildFieldLabel('API 密钥', '在模型平台获取，通常以 sk- 开头'),
                    const SizedBox(height: 8),
                    _buildApiKeyField(isDark),
                    const SizedBox(height: 20),

                    // Endpoint
                    _buildFieldLabel('接口地址', 'OpenAI 兼容的 Chat Completions 端点'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _endpointController,
                      hint: AiService.defaultEndpoint,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),

                    // Model
                    _buildFieldLabel('模型名称', '例如 deepseek-chat、gpt-4o-mini 等'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _modelController,
                      hint: AiService.defaultModel,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 32),

                    // 按钮行：测试连接 + 保存配置
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildOutlinedButton('测试连接', _loading ? null : _testConnection),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 7,
                          child: _buildGradientButton('保存配置', _saving ? null : _saveConfig),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 连接提示
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF8F6FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 18, color: subColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '测试连接会直接使用上方输入框中的配置进行验证，无需先保存。',
                              style: TextStyle(fontSize: 12, color: subColor, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String title, String desc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground),
        ),
        const SizedBox(height: 2),
        Text(desc, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary)),
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
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_apiKeyController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  _apiKeyController.clear();
                  setState(() {});
                },
              ),
            IconButton(
              icon: Icon(_obscureKey ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
              onPressed: () => setState(() => _obscureKey = !_obscureKey),
            ),
          ],
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required bool isDark}) {
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
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, __) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () {
                controller.clear();
              },
            );
          },
        ),
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
        child: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.lightOnSurfaceVariant))
            : Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.lightOnSurfaceVariant)),
      ),
    );
  }

  Widget _buildGradientButton(String label, VoidCallback? onPressed) {
    return SizedBox(
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(colors: [AppColors.warmYellow, AppColors.warmYellowDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: AppColors.warmYellow.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.warmYellowText))
              : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.warmYellowText)),
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() => _loading = true);
    final result = await _service.testConnectionWith(
      endpoint: _endpointController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      model: _modelController.text.trim(),
    );
    if (mounted) {
      setState(() => _loading = false);
      final isSuccess = result.contains('成功');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: isSuccess ? AppColors.success : null,
        ),
      );
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _saving = true);
    await _service.setApiKey(_apiKeyController.text.trim());
    await _service.setEndpoint(_endpointController.text.trim());
    await _service.setModel(_modelController.text.trim());
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI 配置已保存')),
      );
    }
  }
}
