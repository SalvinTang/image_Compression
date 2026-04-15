#!/bin/bash

# 手动安装图片压缩workflow
# 绕过PKG安装问题

echo "======================================"
echo "  手动安装图片压缩workflow"
echo "======================================"
echo ""

# 检查workflow是否存在
if [ ! -d "图片压缩.workflow" ]; then
    echo "❌ 错误：找不到 图片压缩.workflow 目录"
    echo "请确保在正确的目录中运行此脚本"
    exit 1
fi

echo "▶ [1/6] 清理旧版本..."
# 清理所有可能的旧版本
sudo rm -rf "/Library/Services/图片压缩.workflow" 2>/dev/null || true
rm -rf "$HOME/Library/Services/图片压切.workflow" 2>/dev/null || true
rm -rf "$HOME/Library/Services/图片压缩.workflow" 2>/dev/null || true
rm -rf "$HOME/Applications/ImageResizeDialog.app" 2>/dev/null || true
echo "   ✓ 旧版本已清理"
echo ""

echo "▶ [2/6] 确保可执行文件是最新的..."
cd ImageResizeDialog
swift build -c release > /dev/null 2>&1
cd ..
cp ImageResizeDialog/.build/release/ImageResizeDialog 图片压缩.workflow/Contents/Resources/
echo "   ✓ 可执行文件已更新"
echo ""

echo "▶ [3/6] 复制workflow到系统目录..."
sudo cp -R 图片压缩.workflow /Library/Services/
echo "   ✓ workflow已复制"
echo ""

echo "▶ [4/6] 设置正确的权限..."
sudo chown -R root:wheel /Library/Services/图片压缩.workflow
sudo chmod -R 755 /Library/Services/图片压缩.workflow
echo "   ✓ 权限已设置"
echo ""

echo "▶ [5/6] 验证安装..."
if [ -d "/Library/Services/图片压缩.workflow" ]; then
    echo "   ✅ workflow已安装到: /Library/Services/图片压缩.workflow"
    ls -la /Library/Services/图片压缩.workflow
else
    echo "   ❌ 安装失败"
    exit 1
fi
echo ""

echo "▶ [6/6] 刷新系统服务..."
/System/Library/CoreServices/pbs -flush 2>/dev/null || true
killall Finder 2>/dev/null || true
echo "   ✓ 系统服务已刷新"
echo ""

echo "============================================================"
echo "  ✅ 手动安装完成！"
echo "============================================================"
echo ""
echo "现在请测试："
echo "1. 在Finder中找一张图片文件"
echo "2. 右键点击图片"
echo "3. 查看 '快速操作' → '图片压缩'"
echo ""
echo "如果还是没有显示，请运行："
echo "./activate_workflow.sh"
echo ""