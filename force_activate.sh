#!/bin/bash

# 强制激活workflow脚本

echo "======================================"
echo "  强制激活图片压缩workflow"
echo "======================================"
echo ""

echo "▶ [1/5] 临时修改权限以便保存..."
sudo chown -R $(whoami):staff /Library/Services/图片压缩.workflow
echo "   ✓ 权限已修改"
echo ""

echo "▶ [2/5] 在Automator中打开workflow..."
open -a Automator /Library/Services/图片压缩.workflow
echo "   ✓ Automator已打开"
echo ""

echo "⚠️  请在Automator中执行以下操作："
echo "   1. 等待workflow完全加载"
echo "   2. 按 ⌘S 保存"
echo "   3. 关闭Automator"
echo ""
echo "完成后按回车继续..."
read

echo ""
echo "▶ [3/5] 恢复系统权限..."
sudo chown -R root:wheel /Library/Services/图片压缩.workflow
sudo chmod -R 755 /Library/Services/图片压缩.workflow
echo "   ✓ 权限已恢复"
echo ""

echo "▶ [4/5] 强制刷新系统服务..."
# 刷新服务数据库
/System/Library/CoreServices/pbs -flush
# 清除服务缓存
/System/Library/CoreServices/pbs -flush_pboard
# 重启Finder
killall Finder
# 重启SystemUIServer
killall SystemUIServer 2>/dev/null || true
echo "   ✓ 系统服务已刷新"
echo ""

echo "▶ [5/5] 等待系统更新..."
sleep 3
echo "   ✓ 完成"
echo ""

echo "============================================================"
echo "  ✅ 激活完成！"
echo "============================================================"
echo ""
echo "现在请测试："
echo "1. 在Finder中找一张图片文件"
echo "2. 右键点击图片"
echo "3. 查看'快速操作' → '图片压缩'"
echo ""
echo "如果还是没有显示，请尝试："
echo "• 重启电脑"
echo "• 检查系统设置 → 扩展 → Finder扩展"
echo "• 运行: ./full_diagnostic.sh 生成新的诊断报告"
echo ""