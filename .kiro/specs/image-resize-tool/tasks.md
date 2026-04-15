chuang'k# 实现计划：image-resize-tool

## 概述

按照"Automator Quick Action + Swift 弹窗应用"架构，分步实现图片缩放工具。先搭建数据模型与纯函数逻辑，再实现 UI 层，最后集成 Automator Workflow 与安装脚本。

## 任务

- [x] 1. 搭建项目结构与核心数据模型
  - 创建 `ImageResizeDialog/` 目录结构
  - 在 `Models.swift` 中定义 `Preset`、`ProcessConfig`、`ResizeMode`、`ProcessResult`、`ProcessingError`、`ValidationState` 枚举与结构体
  - 配置 Swift Package 或 Xcode 项目，引入 SwiftCheck 依赖（用于属性测试）
  - _需求：2.3、3.1、3.2、4.1_

- [x] 2. 实现输入验证与 UI 状态纯函数
  - [x] 2.1 在 `Models.swift` 中实现 `validateDimension(_:) -> ValidationState`
    - 空字符串返回 `.empty`，非正整数返回 `.invalidFormat`，> 32767 返回 `.exceedsMaximum`，否则返回 `.valid`
    - _需求：3.1、3.2_
  - [ ]* 2.2 为 `validateDimension` 编写属性测试
    - **属性 2：非正整数输入验证**
    - **验证：需求 3.1**
  - [ ]* 2.3 为 `validateDimension` 编写属性测试（超出最大值）
    - **属性 3：超出最大值输入验证**
    - **验证：需求 3.2**
  - [x] 2.4 实现 `isConfirmEnabled(preset:widthState:heightState:) -> Bool`
    - 非自定义模式始终返回 `true`；自定义模式下宽高均为 `.valid` 时返回 `true`，否则返回 `false`
    - _需求：3.3、3.4_
  - [ ]* 2.5 为 `isConfirmEnabled` 编写属性测试
    - **属性 4：确定按钮可用性**
    - **验证：需求 3.3、3.4**

- [x] 3. 实现尺寸计算纯函数
  - [x] 3.1 实现 `calculateLinkedDimension(input:inputIsWidth:originalSize:) -> Int`
    - 按原图宽高比计算联动值，四舍五入至整数像素
    - _需求：3.5、3.6_
  - [ ]* 3.2 为 `calculateLinkedDimension` 编写属性测试
    - **属性 5：宽高比联动计算（双向）**
    - **验证：需求 3.5、3.6**
  - [x] 3.3 实现 `calculateTargetSize(originalSize:percentage:) -> CGSize`
    - 按百分比计算目标宽高，四舍五入至整数像素
    - _需求：4.2_
  - [ ]* 3.4 为 `calculateTargetSize` 编写属性测试
    - **属性 6：预设百分比目标尺寸计算**
    - **验证：需求 4.2**

- [x] 4. 实现输出路径生成逻辑
  - [x] 4.1 在 `ImageProcessor.swift` 中实现 `outputURL(for:) -> URL`
    - 输出路径与原图同目录，文件名格式为 `{stem}_resized.{ext}`，扩展名不变
    - _需求：5.1、5.2、5.4_
  - [ ]* 4.2 为 `outputURL(for:)` 编写属性测试
    - **属性 8：输出路径规则**
    - **验证：需求 5.1、5.2、5.4**
  - [x] 4.3 实现 `outputURL(for:existingPaths:) -> URL`（命名冲突处理）
    - 冲突时追加 `_N`（N 从 2 递增），确保批量处理时每个输出路径唯一
    - _需求：5.3、5.5_
  - [ ]* 4.4 为命名冲突处理编写属性测试
    - **属性 9：命名冲突处理**
    - **验证：需求 5.3、5.5**

- [x] 5. 实现 sips 命令构建与图片处理核心
  - [x] 5.1 实现 `buildSipsArguments(config:inputPath:outputPath:) -> [String]`
    - 按 `ResizeMode` 生成缩放参数；`compress == true` 且 JPEG 时追加 `formatOptions 75`
    - _需求：4.1、4.3、4.4、4.5_
  - [ ]* 5.2 为 `buildSipsArguments` 编写属性测试
    - **属性 7：sips 压缩参数构建**
    - **验证：需求 4.4、4.5**
  - [x] 5.3 实现 `ImageProcessor.process(file:config:) -> ProcessResult`
    - 调用 `sips` 执行缩放，捕获 stderr 与退出码，映射到 `ProcessingError`
    - PNG 压缩：优先调用 `pngcrush`，不可用时直接输出
    - _需求：4.1、4.3、4.4、4.5_
  - [x] 5.4 实现 `ImageProcessor.processBatch(files:config:progress:) -> [ProcessResult]`
    - 逐张处理，通过 `progress` 回调上报进度，单张失败不中断整体
    - _需求：4.1、6.1、6.3_
  - [x] 5.5 实现 `ImageProcessor.imageSize(for:) -> CGSize?`
    - 使用 `sips --getProperty pixelWidth/pixelHeight` 读取原始尺寸
    - _需求：3.5、3.6_

- [x] 6. 检查点 — 确保所有测试通过
  - 运行全部单元测试与属性测试，确保通过，如有问题请向用户说明。

- [x] 7. 实现错误摘要生成与对话框标题纯函数
  - [x] 7.1 实现 `generateDialogTitle(files:) -> String`
    - 单文件返回文件名，多文件返回"已选择 N 张图片"
    - _需求：2.2_
  - [ ]* 7.2 为 `generateDialogTitle` 编写属性测试
    - **属性 1：标题文本生成**
    - **验证：需求 2.2**
  - [x] 7.3 实现 `generateErrorSummary(results:) -> String`
    - 汇总失败结果，输出包含每个失败文件名及错误原因的摘要字符串
    - _需求：6.3_
  - [ ]* 7.4 为 `generateErrorSummary` 编写属性测试
    - **属性 10：错误摘要生成**
    - **验证：需求 6.3**

- [x] 8. 实现 ResizeDialogController（UI 层）
  - [x] 8.1 在 `ResizeDialogController.swift` 中创建 `NSPanel` 弹窗，布局所有 UI 元素
    - 文件名标签、预设下拉菜单、宽高输入框（默认隐藏）、压缩复选框、确定/取消按钮、进度指示器
    - _需求：2.1、2.2、2.3、2.4、2.5、2.7、2.8、2.9_
  - [x] 8.2 实现预设切换逻辑（`presetChanged`）
    - 选中"自定义"时显示宽高输入框，否则隐藏
    - _需求：2.4、2.5_
  - [x] 8.3 实现宽高输入框实时验证与联动（`widthChanged` / `heightChanged`）
    - 调用 `validateDimension`，验证失败时标红并显示提示；验证通过时调用 `calculateLinkedDimension` 填充另一侧；手动输入时自动切换预设为"自定义"
    - _需求：2.6、3.1、3.2、3.3、3.4、3.5、3.6_
  - [x] 8.4 实现确定按钮状态绑定（调用 `isConfirmEnabled`）
    - _需求：3.3、3.4_
  - [x] 8.5 实现 `confirmAction`：构建 `ProcessConfig`，调用 `processBatch`，显示进度指示器，处理完成后关闭窗口或显示错误摘要
    - _需求：4.1、6.1、6.2、6.3、6.4_
  - [x] 8.6 实现 `cancelAction`：关闭窗口，不执行任何操作
    - _需求：2.9_
  - [ ]* 8.7 为 UI 状态逻辑编写单元测试
    - 测试预设切换、输入验证触发、确定按钮启用/禁用等场景
    - _需求：2.4、2.5、3.1、3.2、3.3、3.4_

- [x] 9. 实现 AppDelegate 与 main.swift 入口
  - 在 `main.swift` 中解析命令行参数（文件路径列表），转换为 `[URL]`
  - 在 `AppDelegate.swift` 中初始化 `NSApplication`，创建并展示 `ResizeDialogController`
  - 处理完成或取消后退出进程
  - _需求：2.1_

- [x] 10. 创建 Automator Workflow（Quick Action 入口）
  - 创建 `ImageResizeTool.workflow/Contents/Info.plist`，声明支持 JPEG、PNG、TIFF、HEIC、WebP 文件类型及 Finder 上下文
  - 创建 `ImageResizeTool.workflow/Contents/document.wflow`，配置 "Run Shell Script" 步骤，将选中文件路径传递给 Swift 可执行文件
  - _需求：1.1、1.2、1.3_

- [x] 11. 编写安装脚本
  - 创建 `install.sh`：编译 Swift 应用，将 `.workflow` 文件复制到 `~/Library/Services/`，输出安装成功提示
  - _需求：1.1_

- [ ] 12. 集成测试
  - [ ]* 12.1 编写端到端集成测试（JPEG、PNG 各一张）
    - 调用 `ImageProcessor.process`，验证输出文件存在、尺寸正确、格式不变
    - _需求：4.1、4.2、4.3、5.1、5.2、5.4_
  - [ ]* 12.2 编写批量处理集成测试（3 张图片）
    - 验证每张图片均生成独立输出文件，进度回调次数正确
    - _需求：5.5、6.1_
  - [ ]* 12.3 编写命名冲突集成测试
    - 预先创建 `_resized` 文件，验证输出路径自动递增
    - _需求：5.3_

- [x] 13. 最终检查点 — 确保所有测试通过
  - 运行全部单元测试、属性测试与集成测试，确保通过，如有问题请向用户说明。

## 备注

- 标有 `*` 的子任务为可选项，可跳过以加快 MVP 交付
- 每个任务均引用具体需求条款以保证可追溯性
- 属性测试使用 SwiftCheck，每个属性至少运行 100 次迭代
- 检查点确保增量验证，避免问题积累
