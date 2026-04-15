# GitHub 上传指南

## 📋 准备工作

✅ 已完成：
- [x] 初始化 Git 仓库
- [x] 创建 .gitignore
- [x] 创建 README.md
- [x] 创建 LICENSE
- [x] 首次提交完成

## 🚀 上传到 GitHub

### 步骤 1：在 GitHub 创建仓库

1. 访问 https://github.com/new
2. 填写仓库信息：
   - **Repository name**: `image-compression-macos` 或 `图片压缩`
   - **Description**: `一个简洁高效的 macOS 图片压缩工具，通过右键菜单快速操作实现图片缩放和压缩`
   - **Public** 或 **Private**（根据需要选择）
   - ⚠️ **不要**勾选 "Add a README file"（我们已经有了）
   - ⚠️ **不要**勾选 "Add .gitignore"（我们已经有了）
   - ⚠️ **不要**选择 "Choose a license"（我们已经有了）
3. 点击 **Create repository**

### 步骤 2：关联远程仓库

在终端中执行（替换 `你的用户名` 为你的 GitHub 用户名）：

```bash
# 添加远程仓库
git remote add origin https://github.com/你的用户名/image-compression-macos.git

# 或者使用 SSH（如果已配置 SSH key）
git remote add origin git@github.com:你的用户名/image-compression-macos.git
```

### 步骤 3：推送代码

```bash
# 推送到 GitHub
git push -u origin main
```

如果使用 HTTPS 方式，会提示输入 GitHub 用户名和密码（或 Personal Access Token）。

### 步骤 4：创建 Release（可选）

1. 在 GitHub 仓库页面，点击右侧的 **Releases**
2. 点击 **Create a new release**
3. 填写信息：
   - **Tag version**: `v1.0.1`
   - **Release title**: `图片压缩 v1.0.1`
   - **Description**: 复制下面的内容

```markdown
## ✨ 功能特性

- 🚀 快速操作集成 - 右键菜单 → 快速操作 → 图片压缩
- 📦 嵌入式架构 - 无需独立应用，不占用 Launchpad
- 🎯 系统级安装 - 安装到 `/Library/Services/`，自动注册
- 🔧 灵活配置 - 支持预设比例和自定义尺寸
- 💾 智能压缩 - 可选 JPEG 压缩，支持多种质量级别
- 🔒 宽高比锁定 - 单张图片支持锁定/解锁宽高比
- 📊 批量处理 - 支持同时处理多张图片
- 🌓 深色模式 - 完美适配 macOS 深色/浅色模式

## 📦 安装

下载 `图片压缩-1.0.1.pkg`，双击安装即可。

## 📖 使用方法

1. 在 Finder 中选择图片
2. 右键 → 快速操作 → 图片压缩
3. 配置缩放和压缩选项
4. 点击确定

## 🔧 技术栈

- Swift 5.10
- macOS 12+
- Automator Workflow
```

4. 上传 `图片压缩-1.0.1.pkg` 文件
5. 点击 **Publish release**

## 📝 后续更新

当你修改代码后：

```bash
# 查看修改
git status

# 添加修改的文件
git add .

# 提交
git commit -m "描述你的修改"

# 推送到 GitHub
git push
```

## 🔑 GitHub Personal Access Token

如果使用 HTTPS 方式推送，需要创建 Personal Access Token：

1. 访问 https://github.com/settings/tokens
2. 点击 **Generate new token (classic)**
3. 勾选 `repo` 权限
4. 生成并保存 token
5. 推送时使用 token 作为密码

## 📚 更新 README

记得在 README.md 中更新以下内容：

1. 替换所有 `你的用户名` 为实际的 GitHub 用户名
2. 更新下载链接
3. 添加实际的截图（可选）

## ✅ 检查清单

上传前确认：

- [ ] README.md 中的链接已更新
- [ ] .gitignore 已正确配置
- [ ] 敏感信息已移除
- [ ] 代码已测试通过
- [ ] 文档完整清晰
- [ ] LICENSE 文件存在

## 🎉 完成！

上传成功后，你的项目将在：
`https://github.com/你的用户名/image-compression-macos`

---

**提示**：如果遇到问题，可以参考 [GitHub 官方文档](https://docs.github.com/cn)
