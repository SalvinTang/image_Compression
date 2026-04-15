#!/bin/bash

# 图片压缩工具 - 完整诊断脚本
# 自动收集所有诊断信息

OUTPUT_FILE="diagnostic_report_$(date +%Y%m%d_%H%M%S).txt"

echo "======================================"
echo "  图片压缩工具 - 完整诊断"
echo "======================================"
echo ""
echo "正在收集诊断信息..."
echo "输出文件: $OUTPUT_FILE"
echo ""

{
    echo "=========================================="
    echo "图片压缩工具 - 诊断报告"
    echo "生成时间: $(date)"
    echo "=========================================="
    echo ""

    # 1. 系统信息
    echo "========== 1. 系统信息 =========="
    echo "macOS版本:"
    sw_vers
    echo ""
    echo "当前用户:"
    whoami
    id
    echo ""

    # 2. 检查workflow是否存在
    echo "========== 2. 检查workflow安装状态 =========="
    echo "检查 /Library/Services/ 目录:"
    ls -la /Library/Services/ | grep 图片 || echo "❌ 未找到图片压缩.workflow"
    echo ""

    if [ -d "/Library/Services/图片压缩.workflow" ]; then
        echo "✅ workflow存在于系统目录"
        echo ""
        
        # 3. 检查workflow结构
        echo "========== 3. workflow内部结构 =========="
        echo "Contents目录:"
        ls -la /Library/Services/图片压缩.workflow/Contents/
        echo ""
        
        echo "Resources目录:"
        ls -la /Library/Services/图片压缩.workflow/Contents/Resources/ 2>/dev/null || echo "❌ Resources目录不存在"
        echo ""
        
        # 4. 检查可执行文件
        echo "========== 4. 可执行文件检查 =========="
        if [ -f "/Library/Services/图片压缩.workflow/Contents/Resources/ImageResizeDialog" ]; then
            echo "✅ 可执行文件存在"
            ls -la /Library/Services/图片压缩.workflow/Contents/Resources/ImageResizeDialog
            echo ""
            echo "文件类型:"
            file /Library/Services/图片压缩.workflow/Contents/Resources/ImageResizeDialog
            echo ""
            echo "可执行权限:"
            if [ -x "/Library/Services/图片压缩.workflow/Contents/Resources/ImageResizeDialog" ]; then
                echo "✅ 具有可执行权限"
            else
                echo "❌ 缺少可执行权限"
            fi
        else
            echo "❌ 可执行文件不存在"
        fi
        echo ""
        
        # 5. 检查Info.plist
        echo "========== 5. Info.plist内容 =========="
        if [ -f "/Library/Services/图片压缩.workflow/Contents/Info.plist" ]; then
            cat /Library/Services/图片压缩.workflow/Contents/Info.plist
        else
            echo "❌ Info.plist不存在"
        fi
        echo ""
        
        # 6. 检查document.wflow关键配置
        echo "========== 6. document.wflow关键配置 =========="
        if [ -f "/Library/Services/图片压缩.workflow/Contents/document.wflow" ]; then
            echo "workflowTypeIdentifier:"
            grep -A 1 "workflowTypeIdentifier" /Library/Services/图片压缩.workflow/Contents/document.wflow
            echo ""
            
            echo "presentationMode:"
            grep -A 1 "presentationMode" /Library/Services/图片压缩.workflow/Contents/document.wflow
            echo ""
            
            echo "serviceInputTypeIdentifier:"
            grep -A 1 "serviceInputTypeIdentifier" /Library/Services/图片压缩.workflow/Contents/document.wflow
            echo ""
            
            echo "inputMethod:"
            grep -A 1 "inputMethod" /Library/Services/图片压缩.workflow/Contents/document.wflow | head -4
            echo ""
        else
            echo "❌ document.wflow不存在"
        fi
        echo ""
        
    else
        echo "❌ workflow不存在于系统目录"
        echo ""
    fi

    # 7. 检查用户级Services目录
    echo "========== 7. 检查用户级Services目录 =========="
    echo "检查 ~/Library/Services/ 目录:"
    ls -la ~/Library/Services/ 2>/dev/null | grep 图片 || echo "未找到相关workflow"
    echo ""

    # 8. 检查本地workflow文件
    echo "========== 8. 检查本地workflow文件 =========="
    if [ -d "图片压缩.workflow" ]; then
        echo "✅ 本地workflow存在"
        ls -la 图片压缩.workflow/Contents/
        echo ""
        echo "本地可执行文件:"
        ls -la 图片压缩.workflow/Contents/Resources/ 2>/dev/null || echo "Resources目录不存在"
    else
        echo "❌ 本地workflow不存在"
    fi
    echo ""

    # 9. 检查编译产物
    echo "========== 9. 检查编译产物 =========="
    if [ -f "ImageResizeDialog/.build/release/ImageResizeDialog" ]; then
        echo "✅ 编译产物存在"
        ls -la ImageResizeDialog/.build/release/ImageResizeDialog
    else
        echo "❌ 编译产物不存在"
        echo "需要运行: cd ImageResizeDialog && swift build -c release"
    fi
    echo ""

    # 10. 检查系统服务
    echo "========== 10. 系统服务状态 =========="
    echo "Services目录权限:"
    ls -lad /Library/Services/
    echo ""

    # 11. 检查Automator进程
    echo "========== 11. Automator相关进程 =========="
    ps aux | grep -i automator | grep -v grep || echo "无Automator进程运行"
    echo ""

    # 12. 检查最近的系统日志
    echo "========== 12. 最近的Automator日志 =========="
    echo "最近5分钟的Automator日志:"
    log show --predicate 'subsystem == "com.apple.automator"' --last 5m 2>/dev/null | tail -20 || echo "无法获取日志"
    echo ""

    # 13. 对比参考项目
    echo "========== 13. 与video-info-action对比 =========="
    echo "我们的配置:"
    if [ -f "/Library/Services/图片压缩.workflow/Contents/document.wflow" ]; then
        echo "- workflowTypeIdentifier: $(grep -A 1 'workflowTypeIdentifier' /Library/Services/图片压缩.workflow/Contents/document.wflow | grep string | sed 's/.*<string>\(.*\)<\/string>.*/\1/')"
        echo "- presentationMode: $(grep -A 1 'presentationMode' /Library/Services/图片压缩.workflow/Contents/document.wflow | grep integer | sed 's/.*<integer>\(.*\)<\/integer>.*/\1/')"
        echo "- serviceInputTypeIdentifier: $(grep -A 1 'serviceInputTypeIdentifier' /Library/Services/图片压缩.workflow/Contents/document.wflow | grep string | sed 's/.*<string>\(.*\)<\/string>.*/\1/')"
    fi
    echo ""
    echo "video-info-action的配置:"
    echo "- workflowTypeIdentifier: com.apple.Automator.servicesMenu"
    echo "- presentationMode: 15"
    echo "- serviceInputTypeIdentifier: com.apple.Automator.fileSystemObject"
    echo ""

    # 14. 建议的修复步骤
    echo "========== 14. 建议的修复步骤 =========="
    
    if [ ! -d "/Library/Services/图片压缩.workflow" ]; then
        echo "❌ workflow未安装"
        echo "建议: 运行 ./manual_install.sh"
    elif [ ! -f "/Library/Services/图片压缩.workflow/Contents/Resources/ImageResizeDialog" ]; then
        echo "❌ 可执行文件缺失"
        echo "建议: 重新编译并复制可执行文件"
    elif [ ! -x "/Library/Services/图片压缩.workflow/Contents/Resources/ImageResizeDialog" ]; then
        echo "❌ 可执行文件缺少执行权限"
        echo "建议: sudo chmod +x /Library/Services/图片压缩.workflow/Contents/Resources/ImageResizeDialog"
    else
        echo "✅ 基本文件结构正确"
        echo "建议: 在Automator中打开并保存workflow"
        echo "命令: open -a Automator /Library/Services/图片压缩.workflow"
    fi
    echo ""

    # 15. 总结
    echo "========== 15. 诊断总结 =========="
    echo "检查项目:"
    
    if [ -d "/Library/Services/图片压缩.workflow" ]; then
        echo "✅ workflow已安装到系统目录"
    else
        echo "❌ workflow未安装到系统目录"
    fi
    
    if [ -f "/Library/Services/图片压缩.workflow/Contents/Resources/ImageResizeDialog" ]; then
        echo "✅ 可执行文件存在"
    else
        echo "❌ 可执行文件不存在"
    fi
    
    if [ -f "/Library/Services/图片压缩.workflow/Contents/document.wflow" ]; then
        echo "✅ workflow配置文件存在"
    else
        echo "❌ workflow配置文件不存在"
    fi
    
    echo ""
    echo "=========================================="
    echo "诊断完成"
    echo "=========================================="

} > "$OUTPUT_FILE" 2>&1

echo "✅ 诊断完成！"
echo ""
echo "报告已保存到: $OUTPUT_FILE"
echo ""
echo "请查看报告内容："
echo "cat $OUTPUT_FILE"
echo ""
echo "或者直接查看关键信息："
cat "$OUTPUT_FILE" | grep -E "^(✅|❌|建议:)" | head -20
echo ""