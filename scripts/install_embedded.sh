#!/bin/bash

# 嵌入式图片压缩工具安装脚本
# 安装到系统级目录，无需手动注册

set -e

WORKFLOW_NAME="图片压缩.workflow"
SYSTEM_SERVICES_DIR="/Library/Services"
USER_SERVICES_DIR="$HOME/Library/Services"

echo "======================================"
echo "  图片压缩工具安装（嵌入式版本）"
echo "======================================"
echo ""

# 检查 workflow 是否存在
if [ ! -d "$WORKFLOW_NAME" ]; then
    echo "❌ 错误：找不到 $WORKFLOW_NAME"
    echo "请确保在正确的目录中运行此脚本"
    exit 1
fi

echo "▶ [1/3] 清理旧版本..."
# 清理用户级旧版本
rm -rf "$USER_SERVICES_DIR/图片压切.workflow" 2>/dev/null || true
rm -rf "$USER_SERVICES_DIR/图片压缩.workflow" 2>/dev/null || true
rm -rf "$HOME/Applications/ImageResizeDialog.app" 2>/dev/null || true

# 清理系统级旧版本（需要管理员权限）
if [ -d "$SYSTEM_SERVICES_DIR/图片压缩.workflow" ]; then
    echo "需要管理员权限来清理旧版本..."
    sudo rm -rf "$SYSTEM_SERVICES_DIR/图片压缩.workflow"
fi
echo "   ✓ 清理完成"
echo ""

echo "▶ [2/3] 安装到系统目录..."
echo "需要管理员权限来安装到系统目录..."
sudo cp -R "$WORKFLOW_NAME" "$SYSTEM_SERVICES_DIR/"
sudo chown -R root:wheel "$SYSTEM_SERVICES_DIR/$WORKFLOW_NAME"
sudo chmod -R 755 "$SYSTEM_SERVICES_DIR/$WORKFLOW_NAME"
echo "   ✓ 已安装到: $SYSTEM_SERVICES_DIR/$WORKFLOW_NAME"
echo ""

echo "▶ [3/3] 刷新系统服务..."
# 刷新服务缓存
/System/Library/CoreServices/pbs -flush 2>/dev/null || true
# 重启 Finder
killall Finder 2>/dev/null || true
echo "   ✓ 系统服务已刷新"
echo ""

echo "============================================================"
echo "  ✅ 安装成功！"
echo "============================================================"
echo ""
echo "现在你可以："
echo "1. 在 Finder 中选择图片文件"
echo "2. 右键 → 快速操作 → 图片压缩"
echo ""
echo "特点："
echo "✅ 无需手动注册"
echo "✅ 不会在 Launchpad 中显示图标"
echo "✅ 系统级安装，所有用户可用"
echo ""
echo "卸载方法："
echo "sudo rm -rf '$SYSTEM_SERVICES_DIR/$WORKFLOW_NAME'"
echo ""
