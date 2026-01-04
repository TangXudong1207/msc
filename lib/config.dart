class EnvConfig {
  // 1. 在这里粘贴你的 API Key
  // 比如: static const String apiKey = 'sk-xxxxxxxxxxxxxxxx';
  static const String apiKey = 'sk-004a5b3a42c84127a69c478aec15f203';

  // 2. 如果是 DeepSeek，通常不需要改这个链接
  // 如果是其他服务商，请替换为对应的 Base URL
  // static const String baseUrl = 'https://api.deepseek.com';

  // [Web开发专用] 使用本地代理解决跨域问题
  // 运行: dart proxy_server.dart
  static const String baseUrl = 'http://localhost:8080';

  // Supabase 配置
  static const String supabaseUrl = 'https://fuhnjqkvlmomdrdfzieb.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ1aG5qcWt2bG1vbWRyZGZ6aWViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY3NzI1MjUsImV4cCI6MjA4MjM0ODUyNX0.Wgad8u9waqn45quKYRn3wlh0hD8PFbKATXYIp1YC5MM';

  // 3. 模型名称
  // deepseek-chat (V3) 或 deepseek-reasoner (R1)
  static const String modelName = 'deepseek-reasoner';
}
