import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// AI 服务 — 管理 API 配置和调用
class AiService {
  static const _keyEndpoint = 'ai_endpoint';
  static const _keyApiKey = 'ai_api_key';
  static const _keyModel = 'ai_model';

  static const defaultEndpoint = 'https://api.openai.com/v1/chat/completions';
  static const defaultModel = 'gpt-4o-mini';

  // ═══════════════════════════════════════════
  // 配置读写
  // ═══════════════════════════════════════════

  Future<String> getEndpoint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEndpoint) ?? defaultEndpoint;
  }

  Future<void> setEndpoint(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEndpoint, value);
  }

  Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiKey) ?? '';
  }

  Future<void> setApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiKey, value);
  }

  Future<String> getModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyModel) ?? defaultModel;
  }

  Future<void> setModel(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyModel, value);
  }

  Future<bool> isConfigured() async {
    final key = await getApiKey();
    return key.isNotEmpty;
  }

  // ═══════════════════════════════════════════
  // API 调用
  // ═══════════════════════════════════════════

  /// 测试 API 连接
  Future<String> testConnection() async {
    final endpoint = await getEndpoint();
    final apiKey = await getApiKey();
    final model = await getModel();

    if (apiKey.isEmpty) return '请先配置 API Key';

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': '你好，请回复"连接成功"'},
          ],
          'max_tokens': 50,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] ?? '';
        return content.isNotEmpty ? '连接成功' : '连接成功（空响应）';
      } else {
        final body = jsonDecode(response.body);
        final err = body['error']?['message'] ?? 'HTTP ${response.statusCode}';
        return '连接失败: $err';
      }
    } catch (e) {
      return '连接失败: $e';
    }
  }

  /// 发送消息到 AI，附带账单上下文
  Future<String> chat(String userMessage, {required String contextData}) async {
    final endpoint = await getEndpoint();
    final apiKey = await getApiKey();
    final model = await getModel();

    if (apiKey.isEmpty) return '请先配置 API Key';

    final systemPrompt = '''你是一个专业的个人理财助手。以下是用户的账单数据：

$contextData

请根据以上数据，用中文回答用户的问题。给出具体、可操作的建议。保持简洁。''';

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'max_tokens': 800,
          'temperature': 0.7,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices']?[0]?['message']?['content'] ?? 'AI 未返回有效响应';
      } else {
        final body = jsonDecode(response.body);
        final err = body['error']?['message'] ?? 'HTTP ${response.statusCode}';
        return '请求失败: $err';
      }
    } catch (e) {
      return '请求失败: $e';
    }
  }
}
