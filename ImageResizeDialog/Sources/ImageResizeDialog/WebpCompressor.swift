import Foundation

// MARK: - WebpCompressor

/// WebP 压缩器，封装 cwebp 命令调用。
///
/// cwebp 是 libwebp 的官方 CLI 编码器，支持有损（-q）与无损（-lossless）编码，
/// 且可直接读取 WebP/PNG/JPEG 等输入。macOS 的 sips 与 ImageIO 均无法编码 WebP，
/// 因此 WebP 的压缩与改分辨率都依赖 cwebp。
///
/// 二进制定位顺序（与 pngquant 共用 BundledBinary）：
/// 1. 可执行文件同目录（PKG 打包路径：Resources/cwebp）
/// 2. /opt/homebrew/bin/cwebp（Apple Silicon 开发路径）
/// 3. /usr/local/bin/cwebp（Intel 开发路径）
/// 开发期用 brew 安装的 cwebp 即可；分发 PKG 时由打包脚本将二进制与依赖库
/// 一并放入 Resources 并重写 rpath，最终用户无需额外安装。
class WebpCompressor {

    /// 定位 cwebp 二进制；找不到返回 nil
    ///
    /// 定位顺序（与 PngQuantCompressor 共用 BundledBinary）：
    /// 1. 可执行文件同目录（PKG 打包路径：Resources/cwebp）
    /// 2. /opt/homebrew/bin/cwebp（Apple Silicon 开发路径）
    /// 3. /usr/local/bin/cwebp（Intel 开发路径）
    func binaryURL() -> URL? {
        BundledBinary.locate("cwebp")
    }

    /// 压缩 WebP：读 input，写 output（cwebp -q <quality> -metadata none -quiet -o <output> <input>）。
    /// 返回 (exitCode, stdout, stderr)。
    /// - exitCode 0：成功写入 output
    /// - exitCode 非 0：出错（输入无效 / 二进制缺失等），output 可能未生成
    func compress(input: URL, output: URL, quality: String) -> (exitCode: Int32, stdout: String, stderr: String) {
        guard let binary = binaryURL() else {
            return (-1, "", "cwebp 二进制未找到")
        }
        var args = webpCompressArguments(quality: quality)
        args.append("-metadata")
        args.append("none")
        args.append("-quiet")
        args.append("-o")
        args.append(output.path)
        args.append(input.path)
        return CommandRunner.run(binary.path, arguments: args)
    }
}
