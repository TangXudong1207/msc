# AI Chat App

这是一个基于 Flutter 的 AI 聊天应用框架，支持 iOS、Android 和 Windows。

## 项目结构

`	ext
lib/
 main.dart           # 入口文件
 models/             # 数据模型 (Message)
 providers/          # 状态管理 (ChatProvider)
 screens/            # 页面 (ChatScreen)
 services/           # 业务服务 (API, Storage)
 utils/              # 工具类
 widgets/            # 可复用组件
``n
## 快速开始

### 1. 环境准备
确保已安装 Flutter SDK。

### 2. 安装依赖
`ash
flutter pub get
``n
### 3. 运行项目

**Windows:**
`ash
flutter run -d windows
``n
**Android:**
启动模拟器或连接真机，然后运行：
`ash
flutter run -d android
``n
## 功能特性

- [x] 基础聊天界面
- [x] 消息气泡 (用户/AI 区分)
- [x] Markdown 渲染支持
- [x] 模拟 AI 回复 (Loading 状态)
- [ ] 接入真实 AI API (DeepSeek/OpenAI)
- [ ] 聊天记录本地持久化
- [ ] 多会话支持

## iOS 上线
请参考 [iOS_DEPLOYMENT.md](iOS_DEPLOYMENT.md) 了解详细上线流程。
