import Foundation

// MARK: - BundledBinary

/// 定位内置二进制的共享工具。
///
/// PNG 压缩器（pngquant）与 WebP 压缩器（cwebp）的二进制定位逻辑完全一致：
/// 1. 可执行文件同目录（PKG 打包路径：Resources/<name>）
/// 2. /opt/homebrew/bin/<name>（Apple Silicon 开发路径）
/// 3. /usr/local/bin/<name>（Intel 开发路径）
/// 由 PngQuantCompressor 与 WebpCompressor 共用，避免重复实现。
enum BundledBinary {

    /// 定位内置二进制；找不到返回 nil
    /// - Parameter name: 二进制文件名（如 "pngquant" / "cwebp"）
    static func locate(_ name: String) -> URL? {
        var baseDirs: [URL] = []

        // 1. 可执行文件同目录（PKG 打包路径）
        //    直接调用二进制时 arguments[0] 即可执行文件路径
        if let exe = CommandLine.arguments.first {
            baseDirs.append(executableDirectory(from: exe))
        }

        // 去重（按规范路径）
        var seen = Set<String>()
        let dirs = baseDirs.filter { seen.insert($0.path).inserted }

        for dir in dirs {
            let candidate = dir.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }

        // 2. 开发环境兜底：brew 安装路径
        let brewCandidates = [
            URL(fileURLWithPath: "/opt/homebrew/bin/\(name)"),
            URL(fileURLWithPath: "/usr/local/bin/\(name)"),
        ]
        return brewCandidates.first { FileManager.default.fileExists(atPath: $0.path) }
    }

    /// 由可执行文件路径解析其所在目录（解析符号链接 + 相对路径补全）
    static func executableDirectory(from exePath: String) -> URL {
        var url = URL(fileURLWithPath: exePath)
        // 相对路径基于当前工作目录补全为绝对路径
        if !url.path.hasPrefix("/") {
            url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(url.path)
        }
        return url.resolvingSymlinksInPath().deletingLastPathComponent()
    }
}
