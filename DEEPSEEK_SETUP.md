# DeepSeek API 配置指南

为了让聊天功能正常工作，你需要配置 API Key。

## 1. 获取 API Key
1. 访问 [DeepSeek 开放平台](https://platform.deepseek.com/)。
2. 注册/登录账号。
3. 在 "API Keys" 菜单中创建一个新的 Key。

## 2. 配置项目
1. 打开项目中的 `lib/config.dart` 文件。
2. 找到 `static const String apiKey = '在此处粘贴你的Key';` 这一行。
3. 将 `'在此处粘贴你的Key'` 替换为你刚才复制的 Key。

**示例：**
```dart
class AppConfig {
  // 替换前
  // static const String apiKey = '在此处粘贴你的Key';
  
  // 替换后 (注意保留单引号)
  static const String apiKey = 'sk-a1b2c3d4e5f6...'; 
  
  // ... 其他配置保持不变
}
```

## 3. 常见问题
- **报错 401**: Key 错误或已过期。
- **报错 402**: 余额不足，请充值。
- **报错 500/503**: 服务器繁忙，稍后重试。
