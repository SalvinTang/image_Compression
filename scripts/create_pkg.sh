#!/bin/bash

# 图片压缩工具 PKG 打包脚本
# 创建标准的 macOS 安装包（含内置 pngquant，目标机无需安装 brew）

set -e

PRODUCT_NAME="图片压缩"
VERSION="1.0.4"
IDENTIFIER="com.imagecompress.pkg"
PKG_NAME="pkg/${PRODUCT_NAME}-${VERSION}.pkg"

echo "======================================"
echo "  ${PRODUCT_NAME} PKG 打包脚本"
echo "  版本: ${VERSION}"
echo "======================================"
echo ""

# ---- pngquant 捆绑：从 brew 提取二进制与依赖库，重写 rpath 并 ad-hoc 重签 ----
# 目标布局（与可执行文件同目录 Resources/）：
#   Resources/pngquant
#   Resources/lib/liblcms2.2.dylib
#   Resources/lib/libpng16.16.dylib
# 依赖链：pngquant → liblcms2.2 + libpng16.16 + libz/libiconv/libSystem(均为系统库，无需捆绑)
bundle_pngquant() {
    local target_dir="$1"  # 资源目录，即 Resources/

    # 定位 brew 安装的 pngquant 及其依赖库（Apple Silicon / Intel 均兼容）
    local PNQ_PREFIX LCMS_PREFIX LIBPNG_PREFIX
    PNQ_PREFIX=$(brew --prefix pngquant 2>/dev/null || true)
    LCMS_PREFIX=$(brew --prefix little-cms2 2>/dev/null || true)
    LIBPNG_PREFIX=$(brew --prefix libpng 2>/dev/null || true)

    if [ -z "$PNQ_PREFIX" ] || [ ! -x "$PNQ_PREFIX/bin/pngquant" ]; then
        echo "❌ 错误：未找到 brew 安装的 pngquant。"
        echo "   请先执行：brew install pngquant"
        echo "   （打包机需安装 Homebrew 及 pngquant，目标机无需）"
        exit 1
    fi

    local SRC_BIN="$PNQ_PREFIX/bin/pngquant"
    local SRC_LCMS="$LCMS_PREFIX/lib/liblcms2.2.dylib"
    local SRC_PNG="$LIBPNG_PREFIX/lib/libpng16.16.dylib"

    if [ ! -f "$SRC_LCMS" ] || [ ! -f "$SRC_PNG" ]; then
        echo "❌ 错误：pngquant 依赖库缺失（liblcms2 / libpng16）。"
        echo "   请执行：brew install pngquant"
        exit 1
    fi

    echo "   源二进制: $SRC_BIN"
    echo "   源依赖:   $SRC_LCMS / $SRC_PNG"

    mkdir -p "$target_dir/lib"
    cp "$SRC_BIN" "$target_dir/pngquant"
    cp "$SRC_LCMS" "$target_dir/lib/"
    cp "$SRC_PNG" "$target_dir/lib/"
    chmod +x "$target_dir/pngquant"

    # 重写 pngquant 的依赖路径 → @loader_path/lib/...
    # （@loader_path 解析为 pngquant 所在目录 Resources/，故 lib 子目录即 Resources/lib/）
    install_name_tool -change "$SRC_LCMS" "@loader_path/lib/liblcms2.2.dylib" "$target_dir/pngquant" 2>/dev/null
    install_name_tool -change "$SRC_PNG"  "@loader_path/lib/libpng16.16.dylib" "$target_dir/pngquant" 2>/dev/null

    # 重写依赖库自身身份 → @loader_path/lib/...
    install_name_tool -id "@loader_path/lib/liblcms2.2.dylib"  "$target_dir/lib/liblcms2.2.dylib"  2>/dev/null
    install_name_tool -id "@loader_path/lib/libpng16.16.dylib" "$target_dir/lib/libpng16.16.dylib" 2>/dev/null

    # install_name_tool 会破坏原 adhoc 签名，导致运行被内核 SIGKILL(exit 137)。
    # 必须 ad-hoc 重签（无需开发者证书）。
    codesign -s - --force "$target_dir/pngquant" 2>/dev/null
    codesign -s - --force "$target_dir/lib/liblcms2.2.dylib"  2>/dev/null
    codesign -s - --force "$target_dir/lib/libpng16.16.dylib" 2>/dev/null

    echo "   ✓ pngquant 已捆绑并 ad-hoc 重签"
}

# 1. 清理并创建临时目录
echo "▶ [1/7] 准备打包环境..."
rm -rf pkg_temp
mkdir -p pkg
mkdir -p pkg_temp/payload/Library/Services
mkdir -p pkg_temp/scripts
echo "   ✓ 打包环境准备完成"
echo ""

# 2. 确保使用最新的可执行文件
echo "▶ [2/7] 更新可执行文件..."
cd ImageResizeDialog
swift build -c release > /dev/null
cd ..
cp ImageResizeDialog/.build/release/ImageResizeDialog 图片压缩.workflow/Contents/Resources/
echo "   ✓ 可执行文件已更新"
echo ""

# 3. 复制 workflow 到 payload
echo "▶ [3/7] 准备安装载荷..."
cp -R 图片压缩.workflow pkg_temp/payload/Library/Services/
echo "   ✓ 载荷准备完成"
echo ""

# 4. 捆绑 pngquant（含依赖库 + rpath 重写 + ad-hoc 重签）
echo "▶ [4/7] 捆绑 pngquant..."
PAYLOAD_RESOURCES="pkg_temp/payload/Library/Services/图片压缩.workflow/Contents/Resources"
bundle_pngquant "$PAYLOAD_RESOURCES"
echo "   ✓ pngquant 捆绑完成"
echo ""

# 5. 创建安装前脚本
echo "▶ [5/7] 创建安装脚本..."
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

# 6. 创建安装后脚本
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

# 7. 构建 PKG 包
echo "▶ [6/7] 构建 PKG 安装包..."
pkgbuild --root pkg_temp/payload \
         --scripts pkg_temp/scripts \
         --identifier "$IDENTIFIER" \
         --version "$VERSION" \
         --install-location "/" \
         "$PKG_NAME"
echo "   ✓ PKG 包构建完成"
echo ""

# 8. 清理临时文件
echo "▶ [7/7] 清理临时文件..."
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
echo "  ✅ 内置 pngquant，PNG 压缩无需额外安装"
echo "  ✅ 自动清理旧版本"
echo "  ✅ 自动刷新系统服务"
echo "  ✅ 无需手动注册"
echo "  ✅ 不会在 Launchpad 显示图标"
echo ""
