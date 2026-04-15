#!/bin/bash

# 激活图片压缩workflow的脚本
# 解决PKG安装后需要手动激活的问题

echo "======================================"
echo "  激活图片压缩快速操作"
echo "======================================"
echo ""

echo "▶ [1/4] 检查安装状态..."
if [ ! -d "/Library/Services/图片压缩.workflow" ]; then
    echo "❌ 错误：未找到已安装的workflow"
    echo "请先安装PKG包：图片压缩-1.0.1.pkg"
    exit 1
fi
echo "   ✓ workflow已安装"
echo ""

echo "▶ [2/4] 临时修改权限..."
sudo chown -R $(whoami):staff /Library/Services/图片压缩.workflow
echo "   ✓ 权限已修改"
echo ""

echo "▶ [3/4] 在Automator中激活workflow..."
echo "正在打开Automator..."
open -a Automator /Library/Services/图片压缩.workflow

echo ""
echo "⚠️  请在Automator中执行以下操作："
echo "1. 按 ⌘S 保存workflow"
echo "2. 关闭Automator"
echo "3. 按任意键继续..."
read -n 1 -s

echo ""
echo "▶ [4/4] 恢复系统权限并刷新服务..."
sudo chown -R root:wheel /Library/Services/图片压缩.workflow
sudo chmod -R 755 /Library/Services/图片压缩.workflow
/System/Library/CoreServices/pbs -flush
killall Finder
echo "   ✓ 激活完成"
echo ""

echo "============================================================"
echo "  ✅ 激活成功！"
echo "============================================================"
echo ""
echo "现在你可以："
echo "1. 在Finder中选择图片文件"
echo "2. 右键 → 快速操作 → 图片压缩"
echo ""
echo "如果还是没有显示，请检查："
echo "• 系统设置 → 扩展 → Finder扩展"
echo "• 确保选择的是图片文件（.jpg, .png, .gif等）"
echo ""