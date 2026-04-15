#!/bin/bash

# 图片压缩工具 PKG 打包脚本
# 创建标准的 macOS 安装包

set -e

PRODUCT_NAME="图片压缩"
VERSION="1.0.1"
IDENTIFIER="com.imagecompress.pkg"
PKG_NAME="${PRODUCT_NAME}-${VERSION}.pkg"

echo "======================================"
echo "  ${PRODUCT_NAME} PKG 打包脚本"
echo "  版本: ${VERSION}"
echo "======================================"
echo ""

# 1. 清理并创建临时目录
echo "▶ [1/6] 准备打包环境..."
rm -rf pkg_temp
mkdir -p pkg_temp/payload/Library/Services
mkdir -p pkg_temp/scripts
echo "   ✓ 打包环境准备完成"
echo ""

# 2. 确保使用最新的可执行文件
echo "▶ [2/6] 更新可执行文件..."
cd ImageResizeDialog
swift build -c release > /dev/null
cd ..
cp ImageResizeDialog/.build/release/ImageResizeDialog 图片压缩.workflow/Contents/Resources/
echo "   ✓ 可执行文件已更新"
echo ""

# 3. 复制 workflow 到 payload
echo "▶ [3/6] 准备安装载荷..."
cp -R 图片压缩.workflow pkg_temp/payload/Library/Services/
echo "   ✓ 载荷准备完成"
echo ""

# 4. 创建安装前脚本
echo "▶ [4/6] 创建安装脚本..."
cat > pkg_temp/scripts/preinstall << 'EOF'
#!/bin/bash

# 安装前脚本：清理旧版本

# 清理可能存在的旧版本
rm -rf "/Library/Services/图片压缩.workflow" 2>/dev/null || true
rm -rf "$HOME/Library/Services/图片压切.workflow" 2>/dev/null || true
rm -rf "$HOME/Library/Services/图片压缩.workflow" 2>/dev/null || true
rm -rf "$HOME/Applications/ImageResizeDialog.app" 2>/dev/null || true

exit 0
EOF

# 5. 创建安装后脚本
cat > pkg_temp/scripts/postinstall << 'EOF'
#!/bin/bash

# 安装后脚本：刷新系统服务

# 设置正确的权限
chown -R root:wheel "/Library/Services/图片压缩.workflow"
chmod -R 755 "/Library/Services/图片压缩.workflow"

# 刷新系统服务缓存
/System/Library/CoreServices/pbs -flush 2>/dev/null || true

# 重启 Finder 以刷新快速操作
killall Finder 2>/dev/null || true

exit 0
EOF

chmod +x pkg_temp/scripts/preinstall
chmod +x pkg_temp/scripts/postinstall
echo "   ✓ 安装脚本创建完成"
echo ""

# 5. 构建 PKG 包
echo "▶ [5/6] 构建 PKG 安装包..."
pkgbuild --root pkg_temp/payload \
         --scripts pkg_temp/scripts \
         --identifier "$IDENTIFIER" \
         --version "$VERSION" \
         --install-location "/" \
         "$PKG_NAME"
echo "   ✓ PKG 包构建完成"
echo ""

# 6. 清理临时文件
echo "▶ [6/6] 清理临时文件..."
rm -rf pkg_temp
echo "   ✓ 清理完成"
echo ""

echo "============================================================"
echo "  ✅ PKG 打包完成！"
echo "============================================================"
echo ""
echo "  输出文件：${PKG_NAME}"
echo "  文件大小：$(du -h "$PKG_NAME" | cut -f1)"
echo ""
echo "  安装方法："
echo "  1. 双击 ${PKG_NAME}"
echo "  2. 按照安装向导操作"
echo "  3. 输入管理员密码"
echo "  4. 安装完成后立即可用"
echo ""
echo "  特点："
echo "  ✅ 系统级安装到 /Library/Services/"
echo "  ✅ 自动清理旧版本"
echo "  ✅ 自动刷新系统服务"
echo "  ✅ 无需手动注册"
echo "  ✅ 不会在 Launchpad 显示图标"
echo ""