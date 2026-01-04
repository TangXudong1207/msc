import 'dart:io';
import 'dart:convert';

// Vertex AI 配置
// Vertex AI 配置 (Removed unused config)

void main() async {
  // 监听本地 8080 端口
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
  print('✅ 代理服务器已启动: http://localhost:8080');
  print('🚀 请保持此窗口运行，不要关闭...');

  await for (HttpRequest request in server) {
    try {
      // 1. 处理 CORS
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      request.response.headers.add(
        'Access-Control-Allow-Methods',
        'POST, OPTIONS',
      );
      request.response.headers.add(
        'Access-Control-Allow-Headers',
        'Content-Type, Authorization',
      );

      if (request.method == 'OPTIONS') {
        request.response.close();
        continue;
      }

      print('收到请求: ${request.uri.path}');

      // === 路由 1: DeepSeek 聊天 ===
      if (request.uri.path == '/chat/completions' && request.method == 'POST') {
        final content = await utf8.decoder.bind(request).join();
        final client = HttpClient();
        final deepSeekRequest = await client.postUrl(
          Uri.parse('https://api.deepseek.com/chat/completions'),
        );

        deepSeekRequest.headers.contentType = ContentType.json;
        final auth = request.headers.value('authorization');
        if (auth != null) deepSeekRequest.headers.set('authorization', auth);
        deepSeekRequest.add(utf8.encode(content));

        final deepSeekResponse = await deepSeekRequest.close();
        final responseBody = await utf8.decoder.bind(deepSeekResponse).join();

        request.response.statusCode = deepSeekResponse.statusCode;
        request.response.headers.contentType = ContentType.json;
        request.response.write(responseBody);
        await request.response.close();
        print('✅ DeepSeek 转发成功');
      }
      // === 路由 2: 意义分析 (已切换为 DeepSeek) ===
      else if (request.uri.path == '/analyze-meaning' &&
          request.method == 'POST') {
        final content = await utf8.decoder.bind(request).join();
        final data = jsonDecode(content) as Map<String, dynamic>;
        final userMessage = data['userMessage'];
        final contextHistory = (data['contextHistory'] as List).cast<String>();
        final language = data['language'] ?? 'chinese'; // Default to chinese

        final languageInstruction = language == 'english' 
            ? 'Output content in English only.' 
            : '只输出中文。';

        final prompt = '''
你是一个哲学家和艺术评论家。请观察用户的话语，结合上下文，判断是否需要生成一张“意义卡”。

### 核心任务 1：评分与筛选
请先根据以下公式对用户的话语进行评分 (0.0 - 1.0)：
**Total_Score = (认知密度 * 0.30) + (结构张力 * 0.25) + (主体重量 * 0.20) + (抽象链接 * 0.10) + (语境关联 * 0.15)**

- **认知密度**: 信息量大小，拒绝流水账。
- **结构张力**: 逻辑转折与冲突 (想要x害怕, 理性x感受)。
- **主体重量**: “我”的在场程度，主观感悟。
- **抽象链接**: 概念化程度。
- **语境关联**: 是否回应了持续的主题。

### 核心任务 2：意义光谱归纳 (Spectrum Classification)
必须将分析结果强制归纳到以下 16 个意义光谱之一 (Spectrum)，选择最匹配的一个：
1. **Conflict** (冲突): 愤怒、对抗、打破规则的力量。
2. **Hubris** (傲慢): 自信过剩、自我中心、挑战神明。
3. **Vitality** (生命力): 纯粹的生存本能、激情、野性。
4. **Rationality** (理性): 逻辑、数学、冷静的分析。
5. **Structure** (结构): 秩序、建筑感、系统的美。
6. **Truth** (真理): 绝对的客观事实、冷酷的现实。
7. **Curiosity** (求知): 对未知的探索、新鲜感。
8. **Mystery** (神秘): 无法解释的事物、隐喻、魔法。
9. **Nihilism** (虚无): 意义的消解、空无、无所谓。
10. **Mortality** (必死性): 对死亡、终结、时间流逝的凝视。
11. **Consciousness** (意识): 觉察、灵性、从高处俯瞰自我。
12. **Empathy** (共情): 感同身受、温暖、爱。
13. **Heritage** (传承): 历史、记忆、家庭、根源。
14. **Melancholy** (忧郁): 蓝色的沉思、必要的悲伤、内省。
15. **Aesthetic** (审美): 纯粹的形式美、艺术感、感官享受。
16. **Entropy** (熵): 混乱之美、衰败、无序。

### 生成规则
- **Noise (< 0.30)**: 判定为不生成 (has_card: false)。
- **Signal (>= 0.35)**: 判定为生成 (has_card: true)。

### 输出要求
**无论 Score 是多少，都请将四个维度融合为一句深刻的话语作为 content。**
即使分数很低，也请尝试生成分析结果。

### 语言风格要求
- 像个哲学家和艺术评论家，冷静、克制、深刻。
- 像一张被轻轻放在桌上的纸条。
- 不安慰、不鼓励、不评判、不建议。
- $languageInstruction

### 上下文
${contextHistory.join('\n')}

### 用户说
$userMessage

请严格按照以下 JSON 格式输出，不要包含 markdown 代码块标记，只输出纯 JSON 字符串：

{
  "has_card": true/false, // 基于 Score >= 0.35
  "score": 0.xx,          // 0.0 - 1.0
  "content": "融合了一句话的内容...",
  "reason": "简短说明评分原因",
  "spectrum": "Conflict" // 必须是上述 16 个英文单词之一，首字母大写
}
''';

        try {
          // 使用 DeepSeek API
          final client = HttpClient();
          final deepSeekRequest = await client.postUrl(
            Uri.parse('https://api.deepseek.com/chat/completions'),
          );

          deepSeekRequest.headers.contentType = ContentType.json;
          // 使用 config.dart 中的 Key
          deepSeekRequest.headers.set(
            'Authorization',
            'Bearer sk-004a5b3a42c84127a69c478aec15f203',
          );

          final body = {
            "model": "deepseek-chat",
            "messages": [
              {"role": "user", "content": prompt}
            ],
            "temperature": 0.2,
            "max_tokens": 512,
            "response_format": { "type": "json_object" }
          };

          deepSeekRequest.add(utf8.encode(jsonEncode(body)));

          final deepSeekResponse = await deepSeekRequest.close();
          final responseBody = await utf8.decoder.bind(deepSeekResponse).join();

          if (deepSeekResponse.statusCode == 200) {
            final jsonResponse = jsonDecode(responseBody);
            String result = '{"error": "No result"}';
            if (jsonResponse['choices'] != null && jsonResponse['choices'].isNotEmpty) {
               result = jsonResponse['choices'][0]['message']['content'] as String;
            }
            
            print('🔍 AI 原始返回内容: $result'); // 添加日志打印

            // 尝试解析 JSON 确保格式正确，如果解析失败则返回原始文本（虽然我们要求了 JSON）
            try {
               jsonDecode(result);
            } catch (e) {
               print('DeepSeek 返回的不是有效 JSON: $result');
               // 如果不是 JSON，尝试包装一下或者保持原样
            }

            request.response.statusCode = 200;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({'result': result}));
            print('✅ DeepSeek 分析成功 (JSON)');
          } else {
            print('❌ DeepSeek 分析失败: ${deepSeekResponse.statusCode} $responseBody');
            request.response.statusCode = 500;
            request.response.write(jsonEncode({'error': 'DeepSeek API Error: $responseBody'}));
          }
          await request.response.close();

          /* 
          // === 原 Vertex AI 代码 (已保留) ===
          final accountCredentials = ServiceAccountCredentials.fromJson(
            _serviceAccountJson,
          );
          final scopes = [AiplatformApi.cloudPlatformScope];
          final client = await clientViaServiceAccount(
            accountCredentials,
            scopes,
          );
          final api = AiplatformApi(client);

          const projectId = 'gen-lang-client-0141413429';
          const location = 'us-central1';
          const publisher = 'google';
          const model = 'gemini-pro';
          const endpoint =
              'projects/$projectId/locations/$location/publishers/$publisher/models/$model';

          final vertexRequest = GoogleCloudAiplatformV1GenerateContentRequest(
            contents: [
              GoogleCloudAiplatformV1Content(
                role: 'user',
                parts: [GoogleCloudAiplatformV1Part(text: prompt)],
              ),
            ],
            generationConfig: GoogleCloudAiplatformV1GenerationConfig(
              temperature: 0.2,
              maxOutputTokens: 256,
            ),
          );

          final response = await api.projects.locations.publishers.models
              .generateContent(vertexRequest, endpoint);
          // ...
          */
        } catch (e) {
          print('❌ 分析出错: $e');
          request.response.statusCode = 500;
          request.response.write(jsonEncode({'error': e.toString()}));
          await request.response.close();
        }
      } else {
        request.response.statusCode = 404;
        request.response.write('Not Found');
        await request.response.close();
      }
    } catch (e) {
      print('❌ 代理出错: $e');
      request.response.statusCode = 500;
      request.response.write('Proxy Error: $e');
      await request.response.close();
    }
  }
}
