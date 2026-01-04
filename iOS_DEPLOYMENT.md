# iOS 上线准备指南

虽然你可以在 Windows 上开发大部分业务逻辑，但 iOS 应用的最终构建和发布必须在 macOS 环境下进行。

## 1. 准备工作

### 硬件需求
- 一台 Mac 电脑（MacBook, Mac Mini, iMac 等）
- iPhone 真机（用于测试）

### 软件需求
- Xcode（从 Mac App Store 下载）
- Flutter SDK（在 Mac 上安装）
- CocoaPods（用于管理 iOS 依赖：`sudo gem install cocoapods`）

## 2. 开发流程 (Windows -> Mac)

1.  **Windows 开发阶段**：
    - 使用 Android 模拟器或 Windows 桌面版进行功能开发和调试。
    - 提交代码到 Git 仓库（GitHub/GitLab）。

2.  **Mac 构建阶段**：
    - 在 Mac 上拉取代码。
    - 运行 `flutter pub get` 安装依赖。
    - 进入 ios 目录运行 `pod install`。
    - 使用 Xcode 打开 `ios/Runner.xcworkspace`。

## 3. iOS 配置 (在 Xcode 中)

1.  **设置 Bundle ID**：
    - 在 Xcode 中选择 Runner target -> General -> Bundle Identifier。
    - 修改为你的唯一 ID (例如 `com.yourname.aichat`)。

2.  **签名与证书 (Signing & Capabilities)**：
    - 需要一个 Apple Developer 账号（每年 $99）。
    - 在 Xcode 中登录账号，勾选 "Automatically manage signing"。
    - 选择你的 Team。

3.  **应用图标与启动图**：
    - 替换 `ios/Runner/Assets.xcassets/AppIcon.appiconset` 中的图标。

4.  **权限配置**：
    - 如果需要相机、麦克风等权限，需在 `ios/Runner/Info.plist` 中添加描述。

## 4. 打包与发布

1.  **构建归档 (Archive)**：
    - 连接真机或选择 "Any iOS Device (arm64)"。
    - 菜单栏 Product -> Archive。

2.  **上传到 App Store Connect**：
    - Archive 完成后，点击 "Distribute App"。
    - 选择 "App Store Connect" -> "Upload"。
    - 验证通过后上传。

3.  **TestFlight 测试**：
    - 在 App Store Connect 网站上，将构建版本推送到 TestFlight。
    - 邀请测试人员安装测试。

4.  **提交审核**：
    - 填写 App 信息、截图、隐私政策。
    - 提交审核（通常需要 1-2 天）。

## 5. 常见问题

- **Windows 上能打包 iOS 吗？**
  - 不能直接打包。可以使用 CI/CD 服务（如 Codemagic, GitHub Actions）在云端 Mac 机器上构建，但首次配置证书通常还是需要 Mac。

- **依赖报错**：
  - 如果遇到 `pod install` 错误，尝试删除 `ios/Podfile.lock` 和 `ios/Pods` 文件夹后重试。
