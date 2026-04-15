import Foundation

// MARK: - Output URL Helpers

/// 生成输出文件路径（无命名冲突版本）
/// 输出格式：{stem}_resized.{ext}，与原图同目录
/// 如果 compress=true，统一输出为 .jpg 格式
func outputURL(for sourceURL: URL, compress: Bool = false) -> URL {
    let directory = sourceURL.deletingLastPathComponent()
    let stem = sourceURL.deletingPathExtension().lastPathComponent
    
    // 压缩时统一使用 .jpg 扩展名
    let ext = compress ? "jpg" : sourceURL.pathExtension.lowercased()
    let filename = "\(stem)_resized.\(ext)"
    return directory.appendingPathComponent(filename)
}

/// 生成输出文件路径（命名冲突处理版本）
/// 先尝试 {stem}_resized.{ext}，冲突时依次尝试 {stem}_resized_2.{ext}、_3.{ext}……
/// 如果 compress=true，统一输出为 .jpg 格式
func outputURL(for sourceURL: URL, existingPaths: Set<URL>, compress: Bool = false) -> URL {
    let directory = sourceURL.deletingLastPathComponent()
    let stem = sourceURL.deletingPathExtension().lastPathComponent
    
    // 压缩时统一使用 .jpg 扩展名
    let ext = compress ? "jpg" : sourceURL.pathExtension.lowercased()

    // 先尝试基础名称
    let base = directory.appendingPathComponent("\(stem)_resized.\(ext)")
    if !existingPaths.contains(base) && !FileManager.default.fileExists(atPath: base.path) {
        return base
    }

    // 依次尝试带数字后缀的名称
    var counter = 2
    while true {
        let candidate = directory.appendingPathComponent("\(stem)_resized_\(counter).\(ext)")
        if !existingPaths.contains(candidate) && !FileManager.default.fileExists(atPath: candidate.path) {
            return candidate
        }
        counter += 1
    }
}

// MARK: - sips Arguments Builder

/// 根据 ProcessConfig 构建 sips 缩放参数数组
/// 返回格式：["-z", "H", "W", inputPath, "--out", outputPath]
/// compress 参数由 process 函数在缩放后单独处理
func buildSipsArguments(config: ProcessConfig, inputPath: String, outputPath: String) -> [String] {
    let w: Int
    let h: Int

    switch config.resizeMode {
    case .preset(let percentage):
        // 需要先读取原图尺寸才能计算目标尺寸；此处返回占位，实际由 process 函数处理
        // 但按接口约定，调用方应在已知尺寸时使用 .custom；
        // 若直接调用此函数且为 preset，则无法获取原图尺寸，返回空参数
        // 实际上 process 函数会先读取尺寸再转换为 .custom 调用，此分支作为兜底
        let targetSize = calculateTargetSize(originalSize: CGSize(width: 1, height: 1), percentage: percentage)
        w = max(1, Int(targetSize.width))
        h = max(1, Int(targetSize.height))
    case .custom(let width, let height):
        w = width
        h = height
    }

    // 使用 -z 参数同时指定高度和宽度（注意顺序是 height width）
    return ["-z", "\(h)", "\(w)", inputPath, "--out", outputPath]
}

// MARK: - ImageProcessor

import CoreGraphics

/// 图片处理器，封装 sips 命令调用
class ImageProcessor {

    // MARK: - Private Helpers

    /// 封装 Process 执行，返回退出码、stdout、stderr
    private func runCommand(_ executable: String, arguments: [String]) -> (exitCode: Int32, stdout: String, stderr: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            return (-1, "", error.localizedDescription)
        }

        process.waitUntilExit()

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""

        return (process.terminationStatus, stdout, stderr)
    }

    // MARK: - Public Interface

    /// 读取图片原始尺寸（使用 sips --getProperty pixelWidth/pixelHeight）
    func imageSize(for url: URL) -> CGSize? {
        let result = runCommand("/usr/bin/sips", arguments: [
            "--getProperty", "pixelWidth",
            "--getProperty", "pixelHeight",
            url.path
        ])

        guard result.exitCode == 0 else { return nil }

        let output = result.stdout
        var width: CGFloat?
        var height: CGFloat?

        for line in output.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("pixelWidth:") {
                let value = trimmed.dropFirst("pixelWidth:".count).trimmingCharacters(in: .whitespaces)
                if let w = Double(value) { width = CGFloat(w) }
            } else if trimmed.hasPrefix("pixelHeight:") {
                let value = trimmed.dropFirst("pixelHeight:".count).trimmingCharacters(in: .whitespaces)
                if let h = Double(value) { height = CGFloat(h) }
            }
        }

        guard let w = width, let h = height, w > 0, h > 0 else { return nil }
        return CGSize(width: w, height: h)
    }

    /// 处理单张图片
    func process(file: URL, config: ProcessConfig) -> ProcessResult {
        // 1. 检查文件是否存在
        guard FileManager.default.fileExists(atPath: file.path) else {
            return ProcessResult(sourceURL: file, outputURL: nil, error: .fileNotFound(file))
        }

        // 2. 计算输出路径（压缩时统一使用 .jpg 扩展名）
        let output = outputURL(for: file, existingPaths: [], compress: config.compress)

        // 3. 检查目标目录写权限
        let directory = output.deletingLastPathComponent()
        guard FileManager.default.isWritableFile(atPath: directory.path) else {
            return ProcessResult(sourceURL: file, outputURL: nil, error: .writePermissionDenied(directory))
        }

        // 4. 确定实际缩放尺寸
        let finalConfig: ProcessConfig
        switch config.resizeMode {
        case .preset(let percentage):
            // 读取原图尺寸以计算目标像素
            guard let originalSize = imageSize(for: file) else {
                return ProcessResult(sourceURL: file, outputURL: nil,
                                     error: .sipsExecutionFailed(exitCode: -1, stderr: "无法读取图片尺寸"))
            }
            let targetSize = calculateTargetSize(originalSize: originalSize, percentage: percentage)
            finalConfig = ProcessConfig(
                resizeMode: .custom(width: Int(targetSize.width), height: Int(targetSize.height)),
                compress: config.compress
            )
        case .custom:
            finalConfig = config
        }

        // 5. 检查是否需要缩放
        let needsResize: Bool
        if case .custom(let width, let height) = finalConfig.resizeMode,
           let originalSize = imageSize(for: file) {
            needsResize = (Int(originalSize.width) != width || Int(originalSize.height) != height)
        } else {
            needsResize = true
        }

        // 6. 执行缩放或复制
        if needsResize {
            // 需要缩放：使用 sips 缩放命令
            let sipsArgs = buildSipsArguments(config: finalConfig, inputPath: file.path, outputPath: output.path)
            let sipsResult = runCommand("/usr/bin/sips", arguments: sipsArgs)

            guard sipsResult.exitCode == 0 else {
                return ProcessResult(sourceURL: file, outputURL: nil,
                                     error: .sipsExecutionFailed(exitCode: sipsResult.exitCode, stderr: sipsResult.stderr))
            }
        } else {
            // 不需要缩放：直接复制文件
            do {
                try FileManager.default.copyItem(at: file, to: output)
            } catch {
                return ProcessResult(sourceURL: file, outputURL: nil,
                                     error: .sipsExecutionFailed(exitCode: -1, stderr: "文件复制失败: \(error.localizedDescription)"))
            }
        }

        // 7. 压缩处理（统一转换为 JPEG 格式）
        if config.compress {
            // 无论原格式是什么，都转换为 JPEG 并压缩
            // quality 可选值："best", "high", "normal", "low"
            let _ = runCommand("/usr/bin/sips", arguments: [
                "-s", "format", "jpeg",
                "-s", "formatOptions", config.quality,
                output.path
            ])
        }

        return ProcessResult(sourceURL: file, outputURL: output, error: nil)
    }

    /// 批量处理图片
    func processBatch(files: [URL], config: ProcessConfig, progress: (Int, Int) -> Void) -> [ProcessResult] {
        var results: [ProcessResult] = []
        let total = files.count

        for (index, file) in files.enumerated() {
            let result = process(file: file, config: config)
            results.append(result)
            progress(index + 1, total)
        }

        return results
    }
}
