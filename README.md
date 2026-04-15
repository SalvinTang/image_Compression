# 图片压缩 - macOS 快速操作

一个简洁高效的 macOS 图片压缩工具，通过右键菜单快速操作实现图片缩放和压缩。

![版本](https://img.shields.io/badge/版本-1.0.1-blue)
![平台](https://img.shields.io/badge/平台-macOS%2012%2B-lightgrey)
![语言](https://img.shields.io/badge/语言-Swift-orange)

## ✨ 特性

- 🚀 **快速操作集成** - 右键菜单 → 快速操作 → 图片压缩
- 📦 **嵌入式架构** - 无需独立应用，不占用 Launchpad
- 🎯 **系统级安装** - 安装到 `/Library/Services/`，自动注册
- 🔧 **灵活配置** - 支持预设比例和自定义尺寸
- 💾 **智能压缩** - 可选 JPEG 压缩，支持多种质量级别
- 🔒 **宽高比锁定** - 单张图片支持锁定/解锁宽高比
- 📊 **批量处理** - 支持同时处理多张图片
- 🌓 **深色模式** - 完美适配 macOS 深色/浅色模式

## 📸 截图

### 单张图片处理
- 预设比例：25%、33%、50%、100%
- 自定义尺寸：手动输入宽高
- 宽高比锁定：保持原图比例

### 多张图片处理
- 批量缩放到相同尺寸
- 统一压缩设置
- 进度显示

## 🚀 安装

### 方法 1：使用 PKG 安装包（推荐）

1. 下载最新的 [图片压缩-1.0.1.pkg](https://github.com/你的用户名/图片压缩/releases)
2. 双击 PKG 文件
3. 按照安装向导操作
4. 输入管理员密码
5. 安装完成后立即可用

### 方法 2：从源码构建

```bash
# 克隆仓库
git clone https://github.com/你的用户名/图片压缩.git
cd 图片压缩

# 构建 workflow
./build_embedded_workflow.sh

# 安装到系统
./install_embedded.sh
```

## 📖 使用方法

1. 在 Finder 中选择一张或多张图片
2. 右键点击
3. 选择 **快速操作 → 图片压缩**
4. 在弹出的对话框中：
   - 选择预设比例或自定义尺寸
   - 选择是否启用压缩
   - 选择压缩质量（质量好/平衡/体积小）
5. 点击"确定"开始处理
6. 处理完成的图片保存在原图同目录，文件名为 `原文件名_resized.扩展名`

## 🛠️ 技术架构

### 核心原则

1. **嵌入式架构** - 可执行文件嵌入在 workflow 内部，不创建独立 `.app`
2. **系统级安装** - 安装到 `/Library/Services/`，无需手动注册
3. **自动服务注册** - 系统自动识别并注册为快速操作
4. **无外部依赖** - workflow 完全自包含

### 项目结构

```
图片压缩/
├── ImageResizeDialog/              # Swift 源代码
│   ├── Sources/
│   │   └── ImageResizeDialog/
│   │       ├── main.swift          # 程序入口
│   │       ├── AppDelegate.swift   # 应用委托
│   │       ├── Models.swift        # 数据模型
│   │       ├── ImageProcessor.swift # 图片处理
│   │       └── ResizeDialogController.swift # UI 控制器
│   └── Package.swift               # Swift Package 配置
├── 图片压缩.workflow/              # Automator Workflow
│   └── Contents/
│       ├── Info.plist              # Bundle 信息
│       ├── document.wflow          # Workflow 配置
│       └── Resources/
│           └── ImageResizeDialog   # 可执行文件（构建时生成）
├── build_embedded_workflow.sh      # 构建脚本
├── install_embedded.sh             # 安装脚本
├── create_pkg.sh                   # PKG 打包脚本
└── README.md                       # 本文件
```

### 技术栈

- **语言**: Swift 5.10
- **平台**: macOS 12+
- **UI**: AppKit (NSPanel, NSTextField, NSButton)
- **图片处理**: sips (系统自带命令行工具)
- **打包**: Automator Workflow + PKG

## 🔧 开发

### 环境要求

- macOS 12.0+
- Xcode Command Line Tools
- Swift 5.10+

### 构建命令

```bash
# 编译 Swift 代码
cd ImageResizeDialog
swift build -c release

# 构建完整 workflow
./build_embedded_workflow.sh

# 创建 PKG 安装包
./create_pkg.sh
```

### 调试

```bash
# 直接运行可执行文件测试
./ImageResizeDialog/.build/release/ImageResizeDialog /path/to/image.jpg

# 查看服务缓存
/System/Library/CoreServices/pbs -dump_cache | grep "图片压缩"

# 刷新服务
/System/Library/CoreServices/pbs -flush
```

## 📝 配置说明

### 关键配置点

1. **输入类型标识符** - 必须使用 `com.apple.Automator.fileSystemObject.image`
2. **Workflow 类型** - 必须设置为 `com.apple.Automator.servicesMenu`
3. **可执行文件路径** - 使用固定路径而非相对路径

详见 [问题解决_快速操作显示位置.md](./问题解决_快速操作显示位置.md)

## 🐛 故障排除

### 快速操作菜单中看不到"图片压缩"

1. 检查 workflow 是否正确安装：
   ```bash
   ls -la /Library/Services/图片压缩.workflow
   ```

2. 刷新服务缓存：
   ```bash
   /System/Library/CoreServices/pbs -flush
   killall Finder
   ```

3. 检查 `document.wflow` 中的 `inputTypeIdentifier` 是否为 `com.apple.Automator.fileSystemObject.image`

### 点击后提示"Shell 脚本错误"

检查可执行文件是否存在且有执行权限：
```bash
ls -la /Library/Services/图片压缩.workflow/Contents/Resources/ImageResizeDialog
```

### 更多问题

查看 [TROUBLESHOOTING_LOG.md](./TROUBLESHOOTING_LOG.md) 和 [问题分析与解决方案.md](./问题分析与解决方案.md)

## 📄 许可证

MIT License

## 🙏 致谢

- 参考项目：[video-info-action](https://github.com/Gecho-Go/video-info-action)
- 灵感来源：macOS 系统自带的快速操作

## 📮 反馈

如有问题或建议，欢迎提交 [Issue](https://github.com/你的用户名/图片压缩/issues)

---

**注意**：本工具使用 macOS 系统自带的 `sips` 命令进行图片处理，无需安装额外依赖。
