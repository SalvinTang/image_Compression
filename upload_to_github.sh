#!/bin/bash

# GitHub 上传辅助脚本

echo "======================================"
echo "  GitHub 上传辅助工具"
echo "======================================"
echo ""

# 检查是否已配置远程仓库
if git remote get-url origin &>/dev/null; then
    REMOTE_URL=$(git remote get-url origin)
    echo "✅ 已配置远程仓库: $REMOTE_URL"
    echo ""
    
    # 推送代码
    echo "正在推送代码到 GitHub..."
    git push -u origin main
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "============================================================"
        echo "  ✅ 代码已成功推送到 GitHub！"
        echo "============================================================"
        echo ""
        echo "访问你的仓库: $REMOTE_URL"
        echo ""
    else
        echo ""
        echo "❌ 推送失败，请检查："
        echo "1. 网络连接"
        echo "2. GitHub 认证信息"
        echo "3. 仓库权限"
        echo ""
    fi
else
    echo "⚠️  尚未配置远程仓库"
    echo ""
    echo "请按照以下步骤操作："
    echo ""
    echo "1. 在 GitHub 创建新仓库"
    echo "   访问: https://github.com/new"
    echo ""
    echo "2. 执行以下命令关联远程仓库（替换为你的仓库地址）："
    echo ""
    echo "   git remote add origin https://github.com/你的用户名/仓库名.git"
    echo ""
    echo "   或使用 SSH:"
    echo "   git remote add origin git@github.com:你的用户名/仓库名.git"
    echo ""
    echo "3. 再次运行此脚本推送代码："
    echo "   ./upload_to_github.sh"
    echo ""
    echo "详细步骤请查看: GITHUB_UPLOAD_GUIDE.md"
    echo ""
fi
