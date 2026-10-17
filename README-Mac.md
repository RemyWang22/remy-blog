# Remy's Blog · Mac 使用说明

原项目已经恢复在此文件夹，使用 Hugo 0.157.0 + PaperMod。
Hugo 和 GitHub CLI 安装在本项目的 `.tools` 中，可直接使用，不需要 Homebrew 或 Node.js。

## 首次连接 GitHub

在 Finder 中双击 **连接GitHub.command**，按终端提示登录 **RemyWang22**。
如果显示是否使用 GitHub 凭据认证 Git，输入 `Y` 并按回车。
随后在 GitHub 网页输入终端显示的一次性验证码，完成授权。
登录信息由 GitHub CLI 管理，认证相关目录已从 Git 提交中排除。

如果 macOS 提示无法打开脚本，可在终端进入本文件夹后运行：

```bash
bash scripts/connect-github.sh
```

## 预览和写文章

双击 **预览博客.command**，再在浏览器中访问 <http://localhost:1313/>。
预览会包含草稿，并在保存文章时自动更新。终端按 `Control+C` 停止。
如果提示端口 1313 已被占用，先关闭已经运行的预览。

文章保存在 `content/posts/`，图片保存在 `static/images/`。
图片在文章中使用 `/images/文件名.jpg`，文件名大小写应与实际文件一致。
例如：

```markdown
+++
title = '新文章标题'
date = 2026-10-11T12:00:00+08:00
draft = true
+++

这里写正文。

{{< figure src="/images/elephant2.jpg" caption="照片说明" >}}
```

确认要上线时，将 `draft = true` 改成 `draft = false`。
正式构建只包含已发布且日期已到的文章。

## 发布网站

双击 **发布博客.command**，输入更新备注，例如“发布日本旅行照片”。
脚本先构建网站并检查账号权限，再备份源码和上传生成的网站。
成功后访问 <https://remywang22.github.io/>；GitHub Pages 更新可能需要等待片刻。

也可以在终端执行：

```bash
bash scripts/publish.sh "发布日本旅行照片"
```

只检查构建和仓库配置、不上传：

```bash
bash scripts/publish.sh --check
```

两个仓库保留原来的分工：

- `remy-blog`：文章、图片、配置、主题和本次新增的 Mac 脚本。
- `.deploy/pages`：独立克隆的 `RemyWang22.github.io`，用于上传网站成品。

构建输出在 `.build/site`，预览输出在 `.build/preview`；这些临时目录不会进入源码提交。
旧项目中的 `public` 文件保留作为历史产物，Mac 发布脚本使用新的构建目录。

如果远端分支有新修改或本地 Pages 目录有未提交内容，脚本会停下并说明原因。
如果源码上传完成后网站上传失败，已有提交和文件仍会保留；修复网络或登录问题后可重试。

## 将来再次换电脑

在终端克隆源码仓库，然后运行：

```bash
git clone https://github.com/RemyWang22/remy-blog.git
cd remy-blog
bash scripts/setup-mac.sh
bash scripts/install-github-cli.sh
bash scripts/connect-github.sh
```

安装脚本下载官方版本并检查 SHA-256，工具仅安装到项目内。
Git 提交身份沿用已有配置；新电脑没有配置时，会沿用源码最后一次提交的作者信息。
如果需要调整，在本文件夹和 `.deploy/pages` 中分别运行 `git config --local user.name`、`git config --local user.email`。
