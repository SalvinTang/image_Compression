#!/bin/bash

# 构建嵌入式 workflow（不创建独立 .app）
# 参考 video-info-action 项目的做法

set -e

echo "======================================"
echo "  构建嵌入式图片压缩工具"
echo "======================================"
echo ""

# 1. 编译可执行文件
echo "▶ [1/4] 编译可执行文件..."
cd ImageResizeDialog
swift build -c release
cd ..
echo "   ✓ 编译完成"
echo ""

# 2. 创建嵌入式 workflow 目录结构
echo "▶ [2/4] 创建嵌入式 workflow..."
WORKFLOW_DIR="图片压缩.workflow"
rm -rf "$WORKFLOW_DIR"
mkdir -p "$WORKFLOW_DIR/Contents/Resources"

# 复制可执行文件到 workflow 内部
cp ImageResizeDialog/.build/release/ImageResizeDialog "$WORKFLOW_DIR/Contents/Resources/"

# 创建 Info.plist（使用与 tinypng 相同的结构）
cat > "$WORKFLOW_DIR/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSServices</key>
	<array>
		<dict>
			<key>NSBackgroundColorName</key>
			<string>background</string>
			<key>NSIconName</key>
			<string>NSActionTemplate</string>
			<key>NSMenuItem</key>
			<dict>
				<key>default</key>
				<string>图片压缩</string>
			</dict>
			<key>NSMessage</key>
			<string>runWorkflowAsService</string>
			<key>NSRequiredContext</key>
			<dict>
				<key>NSApplicationIdentifier</key>
				<string>com.apple.finder</string>
			</dict>
			<key>NSSendFileTypes</key>
			<array>
				<string>public.image</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
EOF

echo "   ✓ 嵌入式 workflow 创建完成"
echo ""

# 3. 创建 workflow 配置文件
echo "▶ [3/4] 创建 workflow 配置..."
cat > "$WORKFLOW_DIR/Contents/document.wflow" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>AMApplicationBuild</key>
	<string>521.1</string>
	<key>AMApplicationVersion</key>
	<string>2.10</string>
	<key>AMDocumentVersion</key>
	<string>2</string>
	<key>actions</key>
	<array>
		<dict>
			<key>action</key>
			<dict>
				<key>AMAccepts</key>
				<dict>
					<key>Container</key>
					<string>List</string>
					<key>Optional</key>
					<false/>
					<key>Types</key>
					<array>
						<string>public.image</string>
					</array>
				</dict>
				<key>AMActionVersion</key>
				<string>2.0.3</string>
				<key>AMApplication</key>
				<array>
					<string>com.apple.automator</string>
				</array>
				<key>AMParameterProperties</key>
				<dict>
					<key>COMMAND_STRING</key>
					<dict/>
					<key>CheckedForUserDefaultShell</key>
					<dict/>
					<key>inputMethod</key>
					<dict/>
					<key>shell</key>
					<dict/>
					<key>source</key>
					<dict/>
				</dict>
				<key>AMProvides</key>
				<dict>
					<key>Container</key>
					<string>List</string>
					<key>Types</key>
					<array>
						<string>com.apple.cocoa.string</string>
					</array>
				</dict>
				<key>ActionBundlePath</key>
				<string>/System/Library/Automator/Run Shell Script.action</string>
				<key>ActionName</key>
				<string>Run Shell Script</string>
				<key>ActionParameters</key>
				<dict>
					<key>COMMAND_STRING</key>
					<string>#!/bin/bash

# Automator 执行时，通过环境变量或固定路径定位可执行文件
# 方法1: 使用 workflow 的固定安装路径
if [ -f "$HOME/Library/Services/图片压缩.workflow/Contents/Resources/ImageResizeDialog" ]; then
    EXECUTABLE="$HOME/Library/Services/图片压缩.workflow/Contents/Resources/ImageResizeDialog"
elif [ -f "/Library/Services/图片压缩.workflow/Contents/Resources/ImageResizeDialog" ]; then
    EXECUTABLE="/Library/Services/图片压缩.workflow/Contents/Resources/ImageResizeDialog"
else
    echo "错误：找不到可执行文件"
    exit 1
fi

# 收集输入文件
FILES=()
if [ $# -gt 0 ]; then
    FILES=("$@")
else
    while IFS= read -r file; do
        FILES+=("$file")
    done
fi

# 启动程序
if [ ${#FILES[@]} -gt 0 ]; then
    "$EXECUTABLE" "${FILES[@]}"
else
    echo "错误：没有选择文件"
    exit 1
fi</string>
					<key>CheckedForUserDefaultShell</key>
					<true/>
					<key>inputMethod</key>
					<integer>0</integer>
					<key>shell</key>
					<string>/bin/bash</string>
					<key>source</key>
					<string></string>
				</dict>
				<key>BundleIdentifier</key>
				<string>com.apple.RunShellScript</string>
				<key>CFBundleVersion</key>
				<string>2.0.3</string>
				<key>CanShowSelectedItemsWhenRun</key>
				<false/>
				<key>CanShowWhenRun</key>
				<true/>
				<key>Category</key>
				<array>
					<string>AMCategoryUtilities</string>
				</array>
				<key>Class Name</key>
				<string>RunShellScriptAction</string>
				<key>InputUUID</key>
				<string>F4B4B7A1-1234-4321-ABCD-000000000001</string>
				<key>Keywords</key>
				<array>
					<string>图片</string>
					<string>压缩</string>
					<string>缩放</string>
				</array>
				<key>OutputUUID</key>
				<string>F4B4B7A1-1234-4321-ABCD-000000000002</string>
				<key>UUID</key>
				<string>F4B4B7A1-1234-4321-ABCD-000000000003</string>
				<key>UnlocalizedApplications</key>
				<array>
					<string>Automator</string>
				</array>
				<key>arguments</key>
				<dict>
					<key>0</key>
					<dict>
						<key>default value</key>
						<integer>0</integer>
						<key>name</key>
						<string>inputMethod</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>0</string>
					</dict>
					<key>1</key>
					<dict>
						<key>default value</key>
						<string></string>
						<key>name</key>
						<string>shell</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>1</string>
					</dict>
					<key>2</key>
					<dict>
						<key>default value</key>
						<string></string>
						<key>name</key>
						<string>COMMAND_STRING</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>2</string>
					</dict>
				</dict>
				<key>isViewVisible</key>
				<true/>
				<key>location</key>
				<string>309.000000:253.000000</string>
				<key>nibPath</key>
				<string>/System/Library/Automator/Run Shell Script.action/Contents/Resources/Base.lproj/main.nib</string>
			</dict>
			<key>isViewVisible</key>
			<true/>
		</dict>
	</array>
	<key>connectors</key>
	<dict/>
	<key>workflowMetaData</key>
	<dict>
		<key>applicationBundleIDsByPath</key>
		<dict/>
		<key>applicationPaths</key>
		<array/>
		<key>inputTypeIdentifier</key>
		<string>com.apple.Automator.fileSystemObject.image</string>
		<key>outputTypeIdentifier</key>
		<string>com.apple.Automator.nothing</string>
		<key>presentationMode</key>
		<integer>15</integer>
		<key>processesInput</key>
		<integer>1</integer>
		<key>serviceApplicationBundleID</key>
		<string>com.apple.finder</string>
		<key>serviceInputTypeIdentifier</key>
		<string>com.apple.Automator.fileSystemObject.image</string>
		<key>serviceOutputTypeIdentifier</key>
		<string>com.apple.Automator.nothing</string>
		<key>serviceProcessesInput</key>
		<integer>1</integer>
		<key>systemImageName</key>
		<string>NSActionTemplate</string>
		<key>useAutomaticInputType</key>
		<integer>0</integer>
		<key>workflowTypeIdentifier</key>
		<string>com.apple.Automator.servicesMenu</string>
	</dict>
</dict>
</plist>
EOF

echo "   ✓ workflow 配置创建完成"
echo ""

# 4. 创建安装脚本
echo "▶ [4/4] 创建安装脚本..."
cat > "install_embedded.sh" << 'INSTALL_SCRIPT'
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
INSTALL_SCRIPT

chmod +x install_embedded.sh

echo "   ✓ 安装脚本创建完成"
echo ""

echo "============================================================"
echo "  ✅ 构建完成！"
echo "============================================================"
echo ""
echo "生成的文件："
echo "- $WORKFLOW_DIR/ (嵌入式 workflow)"
echo "- install_embedded.sh (安装脚本)"
echo ""
echo "安装方法："
echo "./install_embedded.sh"
echo ""
echo "特点："
echo "✅ 可执行文件嵌入在 workflow 中"
echo "✅ 安装到系统级目录 /Library/Services/"
echo "✅ 不会在 Launchpad 显示图标"
echo "✅ 无需手动注册"
echo "✅ 显示在「右键菜单 → 快速操作」中"
echo ""