# ⚠️ 架构规则 - 禁止修改

## 🚨 核心原则（任何代码修改都不得违反）

### 1. 嵌入式架构
- ✅ 可执行文件必须嵌入在 workflow 内部
- ❌ 禁止创建独立的 `.app` 文件

### 2. 系统级安装
- ✅ 必须安装到 `/Library/Services/`
- ❌ 禁止安装到 `~/Library/Services/`

### 3. 自动注册
- ✅ 系统自动识别服务
- ❌ 禁止要求用户手动注册

### 4. 无外部依赖
- ✅ workflow 完全自包含
- ❌ 禁止依赖外部应用路径

## 📋 检查清单

修改代码后必须验证：
- [ ] `/Library/Services/图片压缩.workflow` 存在
- [ ] 右键图片能看到"图片压缩"选项
- [ ] Launchpad 中无新增图标
- [ ] `~/Applications/` 中无相关文件

## 📚 详细文档

完整架构说明请查看：`CORE_ARCHITECTURE.md`

---
**参考项目**：[video-info-action](https://github.com/Gecho-Go/video-info-action)