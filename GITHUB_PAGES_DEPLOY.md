# 部署到 GitHub Pages 指南

本指南将帮助你通过 GitHub Actions 自动将 Flutter Web 应用部署到 GitHub Pages。

## 1. 准备工作 (已自动完成)

我们已经为你创建了 GitHub Actions 工作流文件 `.github/workflows/deploy.yml`。
每次你推送到 `main` 分支时，它会自动构建并部署应用。

**注意**: 默认配置假设你的项目将部署在 `https://<username>.github.io/<repo-name>/`。
如果你的仓库名是 `msc`，访问地址将是 `https://<username>.github.io/msc/`。

## 2. 创建 GitHub 仓库

1. 登录 [GitHub](https://github.com)。
2. 点击右上角的 **+** 号，选择 **New repository**。
3. Repository name 输入 `msc` (或者你喜欢的名字)。
4. 保持 Public (GitHub Pages 免费版需要 Public 仓库，除非你是 Pro 用户)。
5. 不要勾选 "Initialize this repository with a README/gitignore/license" (因为我们本地已经有了)。
6. 点击 **Create repository**。

## 3. 推送代码

在 VS Code 的终端中运行以下命令 (替换 `<YOUR_USERNAME>` 为你的 GitHub 用户名):

```bash
# 添加所有文件
git add .

# 提交更改
git commit -m "Initial commit: Ready for GitHub Pages deployment"

# 关联远程仓库 (请替换 URL)
git remote add origin https://github.com/<YOUR_USERNAME>/msc.git

# 推送到 GitHub
git push -u origin main
```

## 4. 配置 GitHub Pages

1. 代码推送成功后，回到 GitHub 仓库页面。
2. 点击 **Settings** (设置) 选项卡。
3. 在左侧菜单找到 **Pages**。
4. 在 **Build and deployment** 下:
   - **Source**: 选择 `Deploy from a branch`。
   - **Branch**: 这里应该会自动出现 `gh-pages` 分支 (可能需要等待几分钟 Action 运行完毕)。
     - 如果 `gh-pages` 还没出现，请点击 Actions 选项卡查看构建进度。
     - 构建成功后，刷新 Pages 设置页面，选择 `gh-pages` 分支，文件夹选择 `/(root)`。
5. 点击 **Save**。

## 5. 访问应用

GitHub Pages 设置页面上方会显示你的网站地址，通常是:
`https://<username>.github.io/msc/`

## 常见问题

### 页面空白或 404
如果打开页面是空白的，通常是 `base-href` 配置问题。
检查 `.github/workflows/deploy.yml` 中的构建命令:
```yaml
run: flutter build web --release --web-renderer canvaskit --base-href "/${{ github.event.repository.name }}/"
```
这个配置会自动使用仓库名作为路径。确保你访问的 URL 带有这个路径。

### 路由刷新 404
GitHub Pages 默认不支持 SPA (单页应用) 的路由重写。
如果刷新非首页路径出现 404，这是一个已知限制。
目前的配置适用于简单的部署。如果需要完美支持路由刷新，通常建议使用 HashRouter 策略，或者使用 404.html hack (将 index.html 复制一份为 404.html)。

**解决方法 (可选)**:
我们可以在构建后自动生成 `404.html`。
修改 `.github/workflows/deploy.yml`，在 Build 步骤后添加:
```yaml
      - name: Create 404.html for SPA support
        run: cp ./build/web/index.html ./build/web/404.html
```
(目前的配置未包含此步骤，如果需要可以手动添加)
