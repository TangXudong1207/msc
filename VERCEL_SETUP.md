# Vercel 部署指南 (解决跨域问题)

为了彻底解决 DeepSeek API 的跨域 (CORS) 问题，我们将使用 Vercel 部署一个云端代理服务，并同时托管你的 Flutter 网页应用。

## 1. 准备工作

确保你已经安装了 Node.js (如果没有，可以跳过，直接使用 Vercel 网页版)。
最好安装 Vercel CLI 工具 (可选，但推荐):
```bash
npm install -g vercel
```

## 2. 部署步骤

### 方法 A: 使用 Vercel CLI (推荐)

1.  在 VS Code 终端中运行以下命令登录 Vercel:
    ```bash
    vercel login
    ```
    (按照提示在浏览器中登录 GitHub 或邮箱)

2.  部署项目:
    ```bash
    vercel
    ```
    - Set up and deploy? **Yes**
    - Which scope? **(选择你的用户名)**
    - Link to existing project? **No**
    - Project name? **msc** (或者你喜欢的名字)
    - In which directory? **./** (直接回车)
    - Want to modify these settings? **No** (直接回车)

3.  等待部署完成。你会得到一个 Production 链接，例如: `https://msc-yourname.vercel.app`

### 方法 B: 使用 Vercel 网页版

1.  将你的代码推送到 GitHub。
2.  访问 [vercel.com](https://vercel.com) 并登录。
3.  点击 "Add New..." -> "Project"。
4.  导入你的 GitHub 仓库 (`msc`)。
5.  Framework Preset 选择 **Other** (或者它会自动识别)。
6.  Build Command 填写: `flutter build web --release`
7.  Output Directory 填写: `build/web`
8.  点击 **Deploy**。

## 3. 更新配置

一旦你获得了 Vercel 的域名 (例如 `https://msc-xyz.vercel.app`):

1.  打开 `lib/config.dart`。
2.  修改 `baseUrl`:
    ```dart
    // 替换为你自己的 Vercel 域名
    static const String baseUrl = 'https://msc-xyz.vercel.app'; 
    ```
3.  保存文件。

## 4. 重新部署

因为我们修改了 `config.dart`，需要重新构建并更新部署。

- 如果使用 CLI:
  再次运行:
  ```bash
  flutter build web --release
  vercel --prod
  ```

- 如果使用 GitHub 集成:
  只需提交并推送代码更改 (`git push`)，Vercel 会自动重新构建。

## 验证

打开你的 Vercel 链接，尝试发送消息。现在请求会经过 `/api/chat` 路由，由 Vercel 的 Serverless Function 转发给 DeepSeek，从而完美避开跨域限制。
