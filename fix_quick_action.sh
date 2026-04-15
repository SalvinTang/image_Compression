#!/bin/bash

# 修复快速操作显示问题
# 解决方案：清理冲突的用户级workflow，确保只有系统级workflow存在

echo "======================================"
echo "  修复快速操作显示问题"
echo "======================================"
echo ""

echo "▶ [1/7] 关闭Automator进程..."
killall Automator 2>/dev/null || true
sleep 1
echo "   ✓ Automator已关闭"
echo ""

echo "▶ [2/7] 清理用户级workflow（可能导致冲突）..."
rm -rf "$HOME/Library/Services/图片压缩.workflow" 2>/dev/null || true
rm -rf "$HOME/Library/Services/图片压切.workflow" 2>/dev/null || true
echo "   ✓ 用户级workflow已清理"
echo ""

echo "▶ [3/7] 清理系统级旧版本..."
sudo rm -rf "/Library/Services/图片压缩.workflow" 2>/dev/null || true
echo "   ✓ 系统级旧版本已清理"
echo ""

echo "▶ [4/7] 重新编译可执行文件..."
cd ImageResizeDialog
swift build -c release > /dev/null 2>&1
cd ..
cp ImageResizeDialog/.build/release/ImageResizeDialog 图片压缩.workflow/Contents/Resources/
echo "   ✓ 可执行文件已更新"
echo ""

echo "▶ [5/7] 安装到系统目录..."
sudo cp -R 图片压缩.workflow /Library/Services/
sudo chown -R root:wheel /Library/Services/图片压缩.workflow
sudo chmod -R 755 /Library/Services/图片压缩.workflow
echo "   ✓ 已安装到系统目录"
echo ""

echo "▶ [6/7] 刷新系统服务缓存..."
# 刷新服务缓存
/System/Library/CoreServices/pbs -flush 2>/dev/null || true
# 重启Finder
killall Finder 2>/dev/null || true
# 触摸workflow文件以更新时间戳
sudo touch /Library/Services/图片压缩.workflow
echo "   ✓ 系统服务已刷新"
echo ""

echo "▶ [7/7] 验证安装..."
if [ -d "/Library/Services/图片压缩.workflow" ]; then
    echo "   ✅ 系统级workflow: 存在"
else
    echo "   ❌ 系统级workflow: 不存在"
fi

if [ -d "$HOME/Library/Services/图片压缩.workflow" ]; then
    echo "   ⚠️  用户级workflow: 存在（可能导致冲突）"
else
    echo "   ✅ 用户级workflow: 不存在（正确）"
fi

if [ -x "/Library/Services/图片压缩.workflow/Contents/Resources/ImageResizeDialog" ]; then
    echo "   ✅ 可执行文件: 存在且可执行"
else
    echo "   ❌ 可执行文件: 不存在或无执行权限"
fi
echo ""

echo "============================================================"
echo "  ✅ 修复完成！"
echo "============================================================"
echo ""
echo "📋 下一步操作："
echo ""
echo "1. 等待5-10秒让系统识别服务"
echo ""
echo "2. 测试快速操作："
echo "   - 在Finder中找一张图片"
echo "   - 右键点击"
echo "   - 查看 '快速操作' 菜单"
echo "   - 应该能看到 '图片压缩' 选项"
echo ""
echo "3. 如果还是看不到，请尝试："
echo "   a) 注销并重新登录"
echo "   b) 或者重启电脑"
echo ""
echo "4. 检查系统设置："
echo "   系统设置 → 扩展 → Finder扩展"
echo "   确保没有禁用相关服务"
echo ""
