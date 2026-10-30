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
    /// 定位顺序（与 WebpCompressor 共用 BundledBinary）：
    /// 1. 可执行文件同目录（PKG 打包路径：Resources/pngquant）
    /// 2. /opt/homebrew/bin/pngquant（Apple Silicon 开发路径）
    /// 3. /usr/local/bin/pngquant（Intel 开发路径）
    func binaryURL() -> URL? {
        BundledBinary.locate("pngquant")
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
