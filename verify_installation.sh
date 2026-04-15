#!/bin/bash

# PKG安装后验证脚本

echo "======================================"
echo "  图片压缩PKG安装验证"
echo "======================================"
echo ""

echo "▶ [1/5] 检查安装位置..."
if [ -d "/Library/Services/图片压缩.workflow" ]; then
    echo "✅ workflow已安装到系统目录"
    ls -la /Library/Services/图片压缩.workflow
else
    echo "❌ workflow未安装到系统目录"
    echo "请重新安装PKG包"
    exit 1
fi
echo ""

echo "▶ [2/5] 检查文件结构..."
echo "Info.plist:"
if [ -f "/Library/Services/图片压缩.workflow/Contents/Info.plist" ]; then
    echo "✅ Info.plist存在"
else
    echo "❌ Info.plist缺失"
fi

echo "document.wflow:"
if [ -f "/Library/Services/图片压缩.workflow/Contents/document.wflow" ]; then
    echo "✅ document.wflow存在"
else
    echo "❌ document.wflow缺失"
fi

echo "可执行文件:"
if [ -f "/Library/Services/图片压缩.workflow/Contents/Resources/ImageResizeDialog" ]; then
    echo "✅ ImageResizeDialog存在"
    ls -la /Library/Services/图片压缩.workflow/Contents/Resources/ImageResizeDialog
else
    echo "❌ ImageResizeDialog缺失"
fi
echo ""

echo "▶ [3/5] 检查权限..."
ls -la /Library/Services/图片压缩.workflow/Contents/
echo ""

echo "▶ [4/5] 检查workflow配置..."
echo "检查文件类型配置:"
if grep -q "public.image" /Library/Services/图片压缩.workflow/Contents/document.wflow; then
    echo "✅ 配置为处理图片文件 (public.image)"
else
    echo "❌ 文件类型配置错误"
    echo "当前配置:"
    grep -A 3 -B 1 "Types" /Library/Services/图片压缩.workflow/Contents/document.wflow | head -10
fi
echo ""

echo "▶ [5/5] 尝试激活服务..."
echo "刷新系统服务..."
/System/Library/CoreServices/pbs -flush
echo "重启Finder..."
killall Finder
echo "✅ 服务已刷新"
echo ""

echo "============================================================"
echo "  验证完成"
echo "============================================================"
echo ""
echo "现在请测试:"
echo "1. 在Finder中找一张图片文件 (.jpg, .png, .gif等)"
echo "2. 右键点击图片"
echo "3. 查看是否有 '快速操作' → '图片压缩'"
echo ""
echo "如果仍然没有显示，请尝试:"
echo "1. 重启电脑"
echo "2. 或运行: open -a Automator /Library/Services/图片压缩.workflow"
echo "   然后按⌘S保存一次"
echo ""