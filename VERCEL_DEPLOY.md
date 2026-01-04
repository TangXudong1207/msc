# 部署到 Vercel 指南

将 Flutter Web 应用部署到 Vercel 非常简单。这里有两种推荐的方法。

## 方法一：使用 Vercel CLI（推荐，最简单）

这种方法在本地构建应用，然后直接上传构建好的文件。不需要在 Vercel 服务器上配置 Flutter 环境。

### 1. 安装 Vercel CLI
如果你还没有安装 Vercel CLI，请在终端运行：
```bash
npm install -g vercel
```

### 2. 编译 Web 版本
在项目根目录下运行以下命令进行构建。我们使用 CanvasKit 渲染器以获得更好的性能（类似 Skia 引擎）。
```bash
flutter build web --release --web-renderer canvaskit
```

### 3. 部署
构建完成后，运行以下命令进行部署：
```bash
vercel build/web
```
*   按照提示操作（登录、选择项目名称等）。
*   `Want to modify these settings?` -> 选择 `N` (默认即可)。

部署完成后，你会得到一个 `.vercel.app` 的网址。

---

## 方法二：Git 集成（自动化部署）

如果你希望每次推送到 GitHub 时自动部署，可以使用此方法。由于 Vercel 默认环境没有安装 Flutter，我们需要配置构建命令。

### 1. 推送代码到 GitHub
确保你的代码已经提交并推送到 GitHub 仓库。

### 2. 在 Vercel 导入项目
1.  登录 [Vercel Dashboard](https://vercel.com/dashboard)。
2.  点击 **"Add New..."** -> **"Project"**。
3.  选择你的 GitHub 仓库并点击 **Import**。

### 3. 配置构建设置 (Build Settings)
在 "Configure Project" 页面，展开 **Build and Output Settings**，填写以下内容：

*   **Framework Preset**: 选择 `Other`。
*   **Build Command**: 复制并粘贴以下脚本（这将下载 Flutter 并构建）：
    ```bash
    if cd flutter; then git pull && cd .. ; else git clone https://github.com/flutter/flutter.git -b stable flutter; fi && ls && flutter/bin/flutter doctor -v && flutter/bin/flutter config --enable-web && flutter/bin/flutter build web --release --web-renderer canvaskit
    ```
*   **Output Directory**: 输入 `build/web`。

### 4. 点击 Deploy
点击部署按钮。Vercel 将会拉取 Flutter SDK，构建你的应用并上线。

## 注意事项

### 1. 路由配置 (`vercel.json`)
我已经为你创建了 `vercel.json` 文件。这个文件非常重要，它确保了当用户刷新非首页页面（如 `/chat`）时，Vercel 会将请求重定向回 `index.html`，从而让 Flutter 接管路由，避免出现 404 错误。

### 2. 跨域图片 (CORS)
如果你的应用无法加载 Supabase 的图片，请确保 Supabase Storage 的 Bucket 设置了允许跨域访问（CORS）。
`vercel.json` 中已经配置了 `Cross-Origin-Opener-Policy` 和 `Cross-Origin-Embedder-Policy` 头，这有助于提升 CanvasKit 的性能，但可能会对跨域资源有严格要求。如果遇到图片加载问题，可以尝试移除 `vercel.json` 中的 `headers` 部分。
