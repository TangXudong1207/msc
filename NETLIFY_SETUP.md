# Netlify 部署指南 (Vercel 的替代方案)

如果 Vercel 无法注册，**Netlify** 是一个非常优秀的替代方案。它同样支持免费托管静态网站和 Serverless 函数，而且通常可以直接使用 GitHub 账号登录，无需复杂的手机验证。

## 1. 准备工作

确保你的代码已经推送到 GitHub 仓库。

## 2. 部署步骤

1.  访问 [www.netlify.com](https://www.netlify.com/)。
2.  点击 **Sign up** -> **Sign up with GitHub**。
3.  登录后，点击 **Add new site** -> **Import an existing project**。
4.  选择 **GitHub**。
5.  授权 Netlify 访问你的 GitHub 仓库，并选择 `msc` 项目。
6.  **配置构建设置 (Build Settings)**:
    *   Netlify 通常会自动读取我们刚刚创建的 `netlify.toml` 文件，所以你可能不需要手动填写这些，但请检查确认：
    *   **Build command**: `rm -rf flutter_sdk && git clone ...` (会自动从 netlify.toml 读取，包含 Flutter 安装脚本)
    *   **Publish directory**: `build/web`
7.  点击 **Deploy msc**。

## 3. 等待构建

Our `netlify.toml` 包含了一个脚本，会在构建时自动下载 Flutter SDK。因此，Netlify 应该能成功自动构建。

**注意**: Netlify 的构建环境默认没有安装 Flutter，但我们的脚本解决了这个问题。

### 如果构建仍然失败:

最简单的方法是使用我们已经生成的 `build/web` 产物，而不是让 Netlify 去编译 Flutter。

**推荐方案 (本地构建，只上传产物):**

1.  在本地运行: `flutter build web --release`
2.  在 Netlify 部署页面，选择 **"Deploys"** -> **"Drag and drop your site folder here"** (如果你没有连接 GitHub)。
    *   或者，如果你连接了 GitHub，但不想配置复杂的 Flutter 构建环境：
    *   你可以直接把 `build/web` 文件夹里的内容手动拖拽到 Netlify 的 Drop zone (在 "Sites" -> 你的站点 -> "Deploys" 底部)。

**高级方案 (让 Netlify 自动构建 Flutter):**
这需要配置环境变量或构建脚本来下载 Flutter SDK，比较麻烦。鉴于你想快速解决，**推荐直接拖拽上传 `build/web` 文件夹**，或者使用 GitHub Pages 托管前端 + Netlify 托管后端 (比较复杂)。

**最稳妥的混合方案 (GitHub Pages + Netlify Functions):**
由于你已经成功部署了 GitHub Pages，我们可以只用 Netlify 来托管后端 API。

1.  按照上面的步骤连接 GitHub 部署到 Netlify。
2.  不用管前端页面是否构建成功，只要 Functions 部署成功即可。
3.  Netlify 会给你一个域名，比如 `https://msc-cool-name.netlify.app`。
4.  修改 `lib/config.dart`:
    ```dart
    static const String baseUrl = 'https://msc-cool-name.netlify.app';
    ```
5.  重新构建并推送到 GitHub Pages。

## 总结

为了最快解决问题：
1.  **注册 Netlify** (用 GitHub)。
2.  **导入项目**。
3.  如果 Netlify 构建失败，不要慌。
4.  在本地运行 `flutter build web --release`。
5.  找到 `build/web` 文件夹。
6.  在 Netlify 网站上找到 **"Manual Deploys"** (手动部署) 区域，把 `build/web` 文件夹整个拖进去。
7.  部署成功后，你就有了一个支持 API 转发的网站了！
