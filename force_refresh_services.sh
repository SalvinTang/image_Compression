#!/bin/bash

# 强制刷新macOS服务注册
# 使用多种方法确保系统识别workflow

echo "======================================"
echo "  强制刷新系统服务"
echo "======================================"
echo ""

echo "▶ [1/8] 验证workflow存在..."
if [ ! -d "/Library/Services/图片压缩.workflow" ]; then
    echo "   ❌ workflow不存在，需要先安装"
    exit 1
fi
echo "   ✓ workflow存在"
echo ""

echo "▶ [2/8] 关闭所有相关进程..."
killall Automator 2>/dev/null || true
killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true
sleep 2
echo "   ✓ 进程已关闭"
echo ""

echo "▶ [3/8] 清理服务缓存..."
# 清理pbs缓存
/System/Library/CoreServices/pbs -flush 2>/dev/null || true
/System/Library/CoreServices/pbs -flush_pboard 2>/dev/null || true
/System/Library/CoreServices/pbs -flush_cache 2>/dev/null || true
echo "   ✓ pbs缓存已清理"
echo ""

echo "▶ [4/8] 更新workflow时间戳..."
sudo touch /Library/Services/图片压缩.workflow
sudo touch /Library/Services/图片压缩.workflow/Contents/Info.plist
sudo touch /Library/Services/图片压缩.workflow/Contents/document.wflow
echo "   ✓ 时间戳已更新"
echo ""

echo "▶ [5/8] 重建LaunchServices数据库..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
echo "   ✓ LaunchServices数据库已重建"
echo ""

echo "▶ [6/8] 刷新系统UI..."
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
echo "   ✓ 系统UI已刷新"
echo ""

echo "▶ [7/8] 等待系统重新加载服务..."
sleep 3
echo "   ✓ 等待完成"
echo ""

echo "▶ [8/8] 验证安装..."
if [ -d "/Library/Services/图片压缩.workflow" ]; then
    echo "   ✅ workflow存在"
    if [ -x "/Library/Services/图片压缩.workflow/Contents/Resources/ImageResizeDialog" ]; then
        echo "   ✅ 可执行文件存在"
    else
        echo "   ❌ 可执行文件不存在"
    fi
else
    echo "   ❌ workflow不存在"
fi
echo ""

echo "============================================================"
echo "  ✅ 强制刷新完成！"
echo "============================================================"
echo ""
echo "📋 现在请测试："
echo ""
echo "1. 等待10秒让系统完全加载"
echo ""
echo "2. 在Finder中右键点击图片文件"
echo ""
echo "3. 查看'快速操作'菜单"
echo ""
echo "4. 如果还是看不到，请尝试："
echo "   - 注销并重新登录（最有效）"
echo "   - 或者重启电脑"
echo ""
echo "5. 另一个可能的原因："
echo "   系统设置 → 扩展 → Finder扩展"
echo "   检查是否有相关服务被禁用"
echo ""
