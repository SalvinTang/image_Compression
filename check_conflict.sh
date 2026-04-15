#!/bin/bash

# 快速检查workflow冲突状态

echo "======================================"
echo "  检查workflow冲突状态"
echo "======================================"
echo ""

SYSTEM_WORKFLOW="/Library/Services/图片压缩.workflow"
USER_WORKFLOW="$HOME/Library/Services/图片压缩.workflow"

echo "📍 检查workflow位置..."
echo ""

# 检查系统级
if [ -d "$SYSTEM_WORKFLOW" ]; then
    echo "✅ 系统级workflow: 存在"
    echo "   路径: $SYSTEM_WORKFLOW"
    if [ -x "$SYSTEM_WORKFLOW/Contents/Resources/ImageResizeDialog" ]; then
        echo "   可执行文件: ✅ 存在"
    else
        echo "   可执行文件: ❌ 不存在或无执行权限"
    fi
else
    echo "❌ 系统级workflow: 不存在"
fi

echo ""

# 检查用户级
if [ -d "$USER_WORKFLOW" ]; then
    echo "⚠️  用户级workflow: 存在 (这会导致冲突！)"
    echo "   路径: $USER_WORKFLOW"
    if [ -d "$USER_WORKFLOW/Contents/Resources" ]; then
        echo "   结构: 包含Resources目录"
    else
        echo "   结构: 不包含Resources目录 (不完整)"
    fi
else
    echo "✅ 用户级workflow: 不存在 (正确)"
fi

echo ""
echo "======================================"

# 判断状态
if [ -d "$SYSTEM_WORKFLOW" ] && [ ! -d "$USER_WORKFLOW" ]; then
    echo "状态: 🟢 正常 - 只有系统级workflow"
    echo ""
    echo "如果快速操作还是不显示，请尝试："
    echo "1. 注销并重新登录"
    echo "2. 或者重启系统"
elif [ -d "$SYSTEM_WORKFLOW" ] && [ -d "$USER_WORKFLOW" ]; then
    echo "状态: 🔴 冲突 - 同时存在系统级和用户级workflow"
    echo ""
    echo "解决方案："
    echo "./fix_quick_action.sh"
elif [ ! -d "$SYSTEM_WORKFLOW" ]; then
    echo "状态: 🔴 未安装 - 系统级workflow不存在"
    echo ""
    echo "解决方案："
    echo "./manual_install.sh"
fi

echo "======================================"
