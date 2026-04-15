#!/bin/bash

# 版本号自动更新脚本
# 每次编译前运行此脚本会自动增加版本号的最后一位

VERSION_FILE="ImageResizeDialog/Sources/ImageResizeDialog/ResizeDialogController.swift"

# 获取当前版本号
CURRENT_VERSION=$(grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' "$VERSION_FILE" | head -1)

if [ -z "$CURRENT_VERSION" ]; then
    echo "未找到版本号，使用默认版本 v1.0.1"
    NEW_VERSION="v1.0.1"
else
    # 提取版本号各部分
    MAJOR=$(echo $CURRENT_VERSION | cut -d'.' -f1 | sed 's/v//')
    MINOR=$(echo $CURRENT_VERSION | cut -d'.' -f2)
    PATCH=$(echo $CURRENT_VERSION | cut -d'.' -f3)
    
    # 增加补丁版本号
    NEW_PATCH=$((PATCH + 1))
    NEW_VERSION="v${MAJOR}.${MINOR}.${NEW_PATCH}"
    
    echo "当前版本: $CURRENT_VERSION"
    echo "新版本: $NEW_VERSION"
    
    # 更新文件中的版本号
    sed -i '' "s/$CURRENT_VERSION/$NEW_VERSION/g" "$VERSION_FILE"
    
    echo "版本号已更新到 $NEW_VERSION"
fi

# 编译项目
echo "开始编译..."
cd ImageResizeDialog
swift build -c release
cd ..

echo "编译完成！"