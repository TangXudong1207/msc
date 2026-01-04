import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Added
import '../config.dart';

class DeepSeekService {
  final Dio _dio;
  final SupabaseClient _supabase = Supabase.instance.client; // Added

  DeepSeekService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: EnvConfig.baseUrl,
          headers: {
            'Authorization': 'Bearer ${EnvConfig.apiKey}',
            'Content-Type': 'application/json',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

  Future<String> sendMessage(String content, {String? systemPrompt}) async {
    try {
      final messages = <Map<String, String>>[];
      if (systemPrompt != null) {
        messages.add({'role': 'system', 'content': systemPrompt});
      }
      messages.add({'role': 'user', 'content': content});

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': EnvConfig.modelName,
          'messages': messages,
          'temperature': 0.7,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final content = data['choices'][0]['message']['content'];
        
        // Log Usage
        if (data['usage'] != null) {
          _logUsage(data['usage']);
        }

        return content ?? 'AI 没有返回内容';
      } else {
        return '请求失败: ${response.statusCode}';
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return 'API 错误: ${e.response?.statusCode} - ${e.response?.data}';
      }
      return '网络错误: ${e.message}';
    } catch (e) {
      return '发生未知错误: $e';
    }
  }

  void _logUsage(Map<String, dynamic> usage) {
    try {
      _supabase.from('api_usage_logs').insert({
        'provider': 'deepseek',
        'tokens_input': usage['prompt_tokens'] ?? 0,
        'tokens_output': usage['completion_tokens'] ?? 0,
        'model_name': EnvConfig.modelName,
      }).then((_) {}); // Fire and forget
    } catch (e) {
      print('Failed to log usage: $e');
    }
  }
}
