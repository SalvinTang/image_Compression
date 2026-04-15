import AppKit
import Foundation

// 跳过第一个参数（可执行文件路径），解析剩余参数为文件 URL
let args = CommandLine.arguments.dropFirst()
let fileURLs = args.map { URL(fileURLWithPath: $0) }
    .filter { FileManager.default.fileExists(atPath: $0.path) }

guard !fileURLs.isEmpty else {
    print("Usage: ImageResizeDialog <image1> [image2 ...]")
    exit(1)
}

let app = NSApplication.shared
let delegate = AppDelegate()
delegate.files = fileURLs
app.delegate = delegate
app.run()
