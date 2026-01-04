class EnvConfig {
  // 1. 在这里粘贴你的 API Key
  // 比如: static const String apiKey = 'sk-xxxxxxxxxxxxxxxx';
  static const String apiKey = 'sk-004a5b3a42c84127a69c478aec15f203';

  // 2. API 基础路径配置
  // [Netlify/Vercel 部署] 使用相对路径，自动适配当前域名
  // 这样部署后会自动请求 https://你的域名/chat/completions -> /api/chat (或 /.netlify/functions/chat)
  static const String baseUrl = '';

  // [备用] 如果部署在 GitHub Pages，需要填写完整的 Vercel 后端地址
  // static const String baseUrl = 'https://msc-yourname.vercel.app';

  // [本地开发] 使用本地代理
  // static const String baseUrl = 'http://localhost:8080';

  // Supabase 配置
  static const String supabaseUrl = 'https://fuhnjqkvlmomdrdfzieb.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ1aG5qcWt2bG1vbWRyZGZ6aWViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY3NzI1MjUsImV4cCI6MjA4MjM0ODUyNX0.Wgad8u9waqn45quKYRn3wlh0hD8PFbKATXYIp1YC5MM';

  // 3. 模型名称
  // deepseek-chat (V3) 或 deepseek-reasoner (R1)
  static const String modelName = 'deepseek-reasoner';
}
