import Foundation

// MARK: - Preset

/// 预设缩放比例
enum Preset: String, CaseIterable {
    case p25   = "25%"
    case p33   = "33%"
    case p50   = "50%"
    case p100  = "100%"
    case custom = "自定义"

    /// 对应的百分比小数值，自定义时为 nil
    var percentage: Double? {
        switch self {
        case .p25:   return 0.25
        case .p33:   return 0.33
        case .p50:   return 0.50
        case .p100:  return 1.00
        case .custom: return nil
        }
    }
}

// MARK: - ResizeMode

/// 缩放模式
enum ResizeMode: Equatable {
    case preset(percentage: Double)
    case custom(width: Int, height: Int)
}

// MARK: - ProcessConfig

/// 处理配置
struct ProcessConfig {
    let resizeMode: ResizeMode
    let compress: Bool
    let quality: String  // JPEG 压缩质量："best", "high", "normal", "low"
    
    init(resizeMode: ResizeMode, compress: Bool, quality: String = "low") {
        self.resizeMode = resizeMode
        self.compress = compress
        self.quality = quality
    }
}

// MARK: - ProcessingError

/// 处理错误类型
enum ProcessingError: Error, Equatable {
    case invalidInput(String)
    case fileNotFound(URL)
    case writePermissionDenied(URL)
    case sipsExecutionFailed(exitCode: Int32, stderr: String)
    case unsupportedFormat(String)
}

// MARK: - ProcessResult

/// 单张图片处理结果
struct ProcessResult {
    let sourceURL: URL
    let outputURL: URL?
    let error: ProcessingError?

    /// 处理是否成功（无错误即为成功）
    var succeeded: Bool { error == nil }
}

// MARK: - ValidationState

/// 输入框验证状态
enum ValidationState: Equatable {
    case valid
    case empty
    case invalidFormat    // 非正整数
    case exceedsMaximum   // > 32767
}

// MARK: - Validation Helpers

/// 验证尺寸输入字符串，返回对应的验证状态
/// - 空字符串 → .empty
/// - 无法解析为整数，或值 ≤ 0 → .invalidFormat
/// - 值 > 32767 → .exceedsMaximum
/// - 1...32767 的正整数 → .valid
func validateDimension(_ input: String) -> ValidationState {
    guard !input.isEmpty else { return .empty }
    guard let value = Int(input), value > 0 else { return .invalidFormat }
    guard value <= 32767 else { return .exceedsMaximum }
    return .valid
}

/// 根据预设和宽高验证状态，判断确定按钮是否可用
/// - 非 .custom 预设：始终返回 true
/// - .custom 预设：仅当 widthState == .valid 且 heightState == .valid 时返回 true
func isConfirmEnabled(preset: Preset, widthState: ValidationState, heightState: ValidationState) -> Bool {
    guard preset == .custom else { return true }
    return widthState == .valid && heightState == .valid
}

// MARK: - Dimension Calculation Helpers

import CoreGraphics

/// 按原图宽高比计算联动值，四舍五入至整数像素
/// - Parameters:
///   - input: 用户输入的像素值
///   - inputIsWidth: true 表示 input 为宽度，false 表示 input 为高度
///   - originalSize: 原图尺寸（用于计算宽高比）
/// - Returns: 联动的另一边像素值；若原图宽或高为 0，直接返回 input
func calculateLinkedDimension(input: Int, inputIsWidth: Bool, originalSize: CGSize) -> Int {
    guard originalSize.width > 0, originalSize.height > 0 else { return input }
    let ratio = originalSize.width / originalSize.height
    if inputIsWidth {
        return Int((Double(input) / ratio).rounded())
    } else {
        return Int((Double(input) * ratio).rounded())
    }
}

/// 按百分比计算目标宽高，四舍五入至整数像素
/// - Parameters:
///   - originalSize: 原图尺寸
///   - percentage: 缩放百分比（如 0.5 表示 50%）
/// - Returns: 目标 CGSize，宽高均四舍五入至整数像素
func calculateTargetSize(originalSize: CGSize, percentage: Double) -> CGSize {
    let targetWidth  = (originalSize.width  * percentage).rounded()
    let targetHeight = (originalSize.height * percentage).rounded()
    return CGSize(width: targetWidth, height: targetHeight)
}

// MARK: - Dialog Title

/// 根据文件列表生成对话框标题
/// - 空数组：返回 "图片 Resize"
/// - 单文件：返回该文件的 lastPathComponent
/// - 多文件：返回 "已选择 N 张图片"
func generateDialogTitle(files: [URL]) -> String {
    switch files.count {
    case 0:
        return "图片压切"
    case 1:
        return files[0].lastPathComponent
    default:
        return "已选择 \(files.count) 张图片"
    }
}

// MARK: - Error Summary

/// 根据处理结果列表生成错误摘要字符串
/// - 若无失败结果，返回空字符串
/// - 否则返回格式化的成功/失败统计及失败文件列表
func generateErrorSummary(results: [ProcessResult]) -> String {
    let failures = results.filter { $0.error != nil }
    guard !failures.isEmpty else { return "" }

    let successCount = results.count - failures.count
    var lines: [String] = ["处理完成：成功 \(successCount) 张，失败 \(failures.count) 张", "失败文件："]

    for result in failures {
        let filename = result.sourceURL.lastPathComponent
        let description: String
        switch result.error! {
        case .fileNotFound:
            description = "文件不存在"
        case .writePermissionDenied:
            description = "无写入权限"
        case .sipsExecutionFailed(let exitCode, _):
            description = "sips 执行失败（exit code \(exitCode)）"
        case .unsupportedFormat:
            description = "不支持的格式"
        case .invalidInput(let msg):
            description = "输入无效：\(msg)"
        }
        lines.append("- \(filename)：\(description)")
    }

    return lines.joined(separator: "\n")
}
