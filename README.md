# 图片压缩 - macOS 快速操作

一个简洁高效的 macOS 图片压缩工具，通过右键菜单快速操作实现图片缩放和压缩。

![版本](https://img.shields.io/badge/版本-1.0.1-blue)
![平台](https://img.shields.io/badge/平台-macOS%2012%2B-lightgrey)
![语言](https://img.shields.io/badge/语言-Swift-orange)

## ✨ 特性

- 🚀 **操作方便** - 右键菜单 → 快速操作 → 图片压缩
- 🔧 **灵活配置** - 支持预设比例和自定义尺寸
- 💾 **智能压缩** - 可选压缩率
- 🔒 **宽高比锁定** - 单张图片支持锁定/解锁宽高比
- 📊 **批量处理** - 支持同时处理多张图片
- 🌓 **深色模式** - 适配 macOS 深色/浅色模式

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


## 📄 许可证

MIT License

## 🙏 致谢

- 参考项目：[video-info-action](https://github.com/Gecho-Go/video-info-action)

## 📮 反馈

如有问题或建议，欢迎提交 [Issue](https://github.com/你的用户名/图片压缩/issues)

---

