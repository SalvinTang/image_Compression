#!/bin/bash

# 诊断图片压缩workflow的脚本

echo "======================================"
echo "  图片压缩workflow诊断"
echo "======================================"
echo ""

echo "▶ 检查安装状态..."
if [ -d "/Library/Services/图片压缩.workflow" ]; then
    echo "✅ workflow已安装到系统目录"
    ls -la /Library/Services/图片压缩.workflow
else
    echo "❌ workflow未安装到系统目录"
fi
echo ""

echo "▶ 检查workflow结构..."
if [ -f "/Library/Services/图片压缩.workflow/Contents/document.wflow" ]; then
    echo "✅ document.wflow存在"
else
    echo "❌ document.wflow缺失"
fi

if [ -f "/Library/Services/图片压缩.workflow/Contents/Info.plist" ]; then
    echo "✅ Info.plist存在"
else
    echo "❌ Info.plist缺失"
fi

if [ -f "/Library/Services/图片压缩.workflow/Contents/Resources/ImageResizeDialog" ]; then
    echo "✅ 可执行文件存在"
else
    echo "❌ 可执行文件缺失"
fi
echo ""

echo "▶ 检查权限..."
ls -la /Library/Services/图片压缩.workflow/Contents/
echo ""

echo "▶ 检查系统服务..."
echo "正在刷新系统服务..."
/System/Library/CoreServices/pbs -flush
echo "✅ 系统服务已刷新"
echo ""

echo "▶ 重启Finder..."
killall Finder
echo "✅ Finder已重启"
echo ""

echo "============================================================"
echo "  诊断完成"
echo "============================================================"
echo ""
echo "如果快速操作仍然不显示，请尝试："
echo ""
echo "1. 打开系统设置 → 扩展 → Finder扩展"
echo "   查看是否有'图片压缩'选项并确保已启用"
echo ""
echo "2. 确保选择的是图片文件："
echo "   • .jpg, .jpeg"
echo "   • .png"
echo "   • .gif"
echo "   • .bmp"
echo "   • .tiff"
echo ""
echo "3. 尝试选择多张图片文件，有时单张图片不显示"
echo ""
echo "4. 如果以上都不行，请运行："
echo "   open -a Automator /Library/Services/图片压缩.workflow"
echo "   然后按⌘S保存一次"
echo ""