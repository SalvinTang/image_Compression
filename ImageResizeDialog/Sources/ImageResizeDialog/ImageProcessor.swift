import Foundation

// MARK: - Output URL Helpers

/// 生成输出文件路径（无命名冲突版本）
/// 输出格式：{stem}_resized.{ext}，与原图同目录
/// - targetExtension：目标扩展名；为 nil 时沿用原图扩展名
func outputURL(for sourceURL: URL, targetExtension: String? = nil) -> URL {
    let directory = sourceURL.deletingLastPathComponent()
    let stem = sourceURL.deletingPathExtension().lastPathComponent

    let ext = targetExtension ?? sourceURL.pathExtension.lowercased()
    let filename = "\(stem)_resized.\(ext)"
    return directory.appendingPathComponent(filename)
}

/// 生成输出文件路径（命名冲突处理版本）
/// 先尝试 {stem}_resized.{ext}，冲突时依次尝试 {stem}_resized_2.{ext}、_3.{ext}……
/// - targetExtension：目标扩展名；为 nil 时沿用原图扩展名
func outputURL(for sourceURL: URL, existingPaths: Set<URL>, targetExtension: String? = nil) -> URL {
    let directory = sourceURL.deletingLastPathComponent()
    let stem = sourceURL.deletingPathExtension().lastPathComponent

    let ext = targetExtension ?? sourceURL.pathExtension.lowercased()

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

    /// 清理临时文件（忽略错误）
    private func cleanupTemp(_ url: URL?) {
        guard let url = url else { return }
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Public Interface

    /// 读取图片原始尺寸（使用 sips --getProperty pixelWidth/pixelHeight）
    func imageSize(for url: URL) -> CGSize? {
        let result = CommandRunner.run("/usr/bin/sips", arguments: [
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

        // 2. 识别源格式
        let format = ImageFormat.detect(from: file)

        // 3. 计算目标扩展名：
        //    - 压缩 PNG → 保持 png（pngquant 保留透明通道，不转 JPEG）
        //    - 压缩非 PNG → jpg（既有行为：统一转 JPEG）
        //    - 不压缩 → 沿用原扩展名
        let targetExtension: String?
        if config.compress {
            targetExtension = (format == .png) ? "png" : "jpg"
        } else {
            targetExtension = nil
        }

        // 4. 计算输出路径
        let output = outputURL(for: file, existingPaths: [], targetExtension: targetExtension)

        // 5. 检查目标目录写权限
        let directory = output.deletingLastPathComponent()
        guard FileManager.default.isWritableFile(atPath: directory.path) else {
            return ProcessResult(sourceURL: file, outputURL: nil, error: .writePermissionDenied(directory))
        }

        // 6. 确定实际缩放尺寸（与既有逻辑一致：预设需读原图尺寸；自定义多选按主维度等比）
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
                compress: config.compress,
                quality: config.quality
            )
        case .custom(let w, let h):
            // 多选等比模式：以主维度为基准，按每张图片各自长宽比计算目标尺寸，避免变形
            if let master = config.proportionalMaster {
                guard let originalSize = imageSize(for: file) else {
                    return ProcessResult(sourceURL: file, outputURL: nil,
                                         error: .sipsExecutionFailed(exitCode: -1, stderr: "无法读取图片尺寸"))
                }
                let value = (master == .width) ? w : h
                let (tw, th) = proportionalTarget(master: master, value: value, originalSize: originalSize)
                finalConfig = ProcessConfig(
                    resizeMode: .custom(width: tw, height: th),
                    compress: config.compress,
                    quality: config.quality
                )
            } else {
                // 单选模式：直接使用精确宽高
                finalConfig = config
            }
        }

        // 7. 分发：
        //    - PNG + 压缩 → pngquant（保持 PNG，保留透明）
        //    - 其余 → 标准路径（缩放/复制 + 可选 sips 转 JPEG）
        if format == .png && config.compress {
            return processPngCompressed(file: file, config: finalConfig, output: output)
        } else {
            return processStandard(file: file, config: finalConfig, output: output, compress: config.compress)
        }
    }

    /// 标准处理路径：缩放或复制，压缩时统一转 JPEG（既有行为）
    private func processStandard(file: URL, config: ProcessConfig, output: URL, compress: Bool) -> ProcessResult {
        // 检查是否需要缩放
        let needsResize: Bool
        if case .custom(let width, let height) = config.resizeMode,
           let originalSize = imageSize(for: file) {
            needsResize = (Int(originalSize.width) != width || Int(originalSize.height) != height)
        } else {
            needsResize = true
        }

        // 执行缩放或复制
        if needsResize {
            let sipsArgs = buildSipsArguments(config: config, inputPath: file.path, outputPath: output.path)
            let sipsResult = CommandRunner.run("/usr/bin/sips", arguments: sipsArgs)
            guard sipsResult.exitCode == 0 else {
                return ProcessResult(sourceURL: file, outputURL: nil,
                                     error: .sipsExecutionFailed(exitCode: sipsResult.exitCode, stderr: sipsResult.stderr))
            }
        } else {
            do {
                try FileManager.default.copyItem(at: file, to: output)
            } catch {
                return ProcessResult(sourceURL: file, outputURL: nil,
                                     error: .sipsExecutionFailed(exitCode: -1, stderr: "文件复制失败: \(error.localizedDescription)"))
            }
        }

        // 压缩处理（非 PNG：统一转换为 JPEG）
        if compress {
            // quality 可选值："best", "high", "normal", "low"
            let _ = CommandRunner.run("/usr/bin/sips", arguments: [
                "-s", "format", "jpeg",
                "-s", "formatOptions", config.quality,
                output.path
            ])
        }

        return ProcessResult(sourceURL: file, outputURL: output, error: nil)
    }

    /// PNG + 压缩处理路径：先 sips 缩放到临时 PNG，再 pngquant 压缩为最终 PNG。
    /// pngquant 未写出时（质量不达标 / 不值得转换 / 二进制缺失）回退输出已缩放的 PNG，保证仍有产物。
    private func processPngCompressed(file: URL, config: ProcessConfig, output: URL) -> ProcessResult {
        let quality = config.quality

        // 判断是否需要缩放
        let needsResize: Bool
        if case .custom(let width, let height) = config.resizeMode,
           let originalSize = imageSize(for: file) {
            needsResize = (Int(originalSize.width) != width || Int(originalSize.height) != height)
        } else {
            needsResize = true
        }

        // 准备喂给 pngquant 的工作 PNG
        var workingURL: URL
        var tempFile: URL?
        if needsResize {
            // 缩放到临时 PNG（避免 pngquant 读写同一文件）
            tempFile = output.deletingLastPathComponent()
                .appendingPathComponent(".pngquant_tmp_\(UUID().uuidString).png")
            workingURL = tempFile!
            let sipsArgs = buildSipsArguments(config: config, inputPath: file.path, outputPath: workingURL.path)
            let sipsResult = CommandRunner.run("/usr/bin/sips", arguments: sipsArgs)
            if sipsResult.exitCode != 0 {
                cleanupTemp(tempFile)
                return ProcessResult(sourceURL: file, outputURL: nil,
                                     error: .sipsExecutionFailed(exitCode: sipsResult.exitCode, stderr: sipsResult.stderr))
            }
        } else {
            // 不需缩放：直接用原图
            workingURL = file
        }

        // pngquant 压缩（写 output）
        let compressor = PngQuantCompressor()
        let (_, _, stderr) = compressor.compress(input: workingURL, output: output, quality: quality)
        let outputExists = FileManager.default.fileExists(atPath: output.path)

        // output 已存在：pngquant 成功写入（或 output 本就存在被跳过）——视为成功
        if outputExists {
            cleanupTemp(tempFile)
            return ProcessResult(sourceURL: file, outputURL: output, error: nil)
        }

        // pngquant 未写出 output（exit 99 质量不达标 / --skip-if-larger / 二进制缺失）。
        // 回退：输出已缩放的 PNG（未压缩），保证仍有产物。
        do {
            if let temp = tempFile, FileManager.default.fileExists(atPath: temp.path) {
                try FileManager.default.copyItem(at: temp, to: output)
            } else {
                try FileManager.default.copyItem(at: file, to: output)
            }
        } catch {
            cleanupTemp(tempFile)
            return ProcessResult(sourceURL: file, outputURL: nil,
                                 error: .sipsExecutionFailed(exitCode: -1, stderr: "pngquant 回退复制失败: \(stderr) \(error.localizedDescription)"))
        }

        cleanupTemp(tempFile)
        guard FileManager.default.fileExists(atPath: output.path) else {
            return ProcessResult(sourceURL: file, outputURL: nil,
                                 error: .sipsExecutionFailed(exitCode: -1, stderr: "pngquant 未生成输出且回退失败"))
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
