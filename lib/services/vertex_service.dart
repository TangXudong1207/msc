import 'package:dio/dio.dart';
import '../config.dart';

class VertexService {
  final Dio _dio;

  VertexService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: EnvConfig.baseUrl, // 使用代理服务器地址 (http://localhost:8080)
          headers: {'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

  Future<String> analyzeMeaning(
    String userMessage,
    List<String> contextHistory, {
    String language = 'chinese',
  }) async {
    try {
      // 直接请求本地代理服务器
      final response = await _dio.post(
        '/analyze-meaning',
        data: {
          'userMessage': userMessage,
          'contextHistory': contextHistory,
          'language': language,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['result'] ?? '分析无结果';
      }

      return '分析无结果';
    } catch (e) {
      // print('Vertex AI Error: $e');
      return '分析失败: $e';
    }
  }
}
