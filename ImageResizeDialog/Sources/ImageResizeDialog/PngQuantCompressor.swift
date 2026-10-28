import Foundation

// MARK: - PngQuantCompressor

/// PNG 压缩器，封装 pngquant 命令调用。
///
/// pngquant 将 24/32-bit PNG 转为 8-bit 调色板 PNG（带 alpha），通常减小 60-80%，
/// 且原生保留透明通道——因此透明 PNG 经压缩后仍为带透明的 PNG，不会变为 JPEG。
///
/// 二进制定位顺序：
/// 1. 可执行文件同目录（PKG 打包路径：Resources/pngquant）
/// 2. /opt/homebrew/bin/pngquant（Apple Silicon 开发路径）
/// 3. /usr/local/bin/pngquant（Intel 开发路径）
/// 开发期用 brew 安装的 pngquant 即可；分发 PKG 时由打包脚本将二进制与依赖库
/// 一并放入 Resources 并重写 rpath，最终用户无需额外安装。
class PngQuantCompressor {

    /// 定位 pngquant 二进制；找不到返回 nil
    ///
    /// 定位顺序：
    /// 1. 可执行文件同目录（PKG 打包路径：Resources/pngquant）
    ///    arguments[0] 即可执行文件路径；路径经符号链接解析，相对路径基于当前工作目录补全。
    /// 2. /opt/homebrew/bin/pngquant（Apple Silicon 开发路径）
    /// 3. /usr/local/bin/pngquant（Intel 开发路径）
    func binaryURL() -> URL? {
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
            let candidate = dir.appendingPathComponent("pngquant")
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }

        // 2. 开发环境兜底：brew 安装路径
        let brewCandidates = [
            URL(fileURLWithPath: "/opt/homebrew/bin/pngquant"),
            URL(fileURLWithPath: "/usr/local/bin/pngquant"),
        ]
        return brewCandidates.first { FileManager.default.fileExists(atPath: $0.path) }
    }

    /// 由可执行文件路径解析其所在目录（解析符号链接 + 相对路径补全）
    private func executableDirectory(from exePath: String) -> URL {
        var url = URL(fileURLWithPath: exePath)
        // 相对路径基于当前工作目录补全为绝对路径
        if !url.path.hasPrefix("/") {
            url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(url.path)
        }
        return url.resolvingSymlinksInPath().deletingLastPathComponent()
    }

    /// 压缩 PNG：读 input，写 output（pngquant -o <output> <input>）。
    /// 返回 (exitCode, stdout, stderr)。
    /// - exitCode 0：成功写入 output
    /// - exitCode 99：质量不达标，未写入（output 不存在）
    /// - exitCode 15：output 已存在，跳过转换（output 已存在）
    /// - 其他非 0：出错或 --skip-if-larger 判定不值得转换
    func compress(input: URL, output: URL, quality: String) -> (exitCode: Int32, stdout: String, stderr: String) {
        guard let binary = binaryURL() else {
            return (-1, "", "pngquant 二进制未找到")
        }
        var args = pngQuantArguments(quality: quality)
        args.append("--strip")
        args.append("--skip-if-larger")
        args.append("-o")
        args.append(output.path)
        args.append(input.path)
        return CommandRunner.run(binary.path, arguments: args)
    }
}
