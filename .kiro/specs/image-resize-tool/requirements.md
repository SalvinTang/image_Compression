# 需求文档

## 简介

本功能为 macOS 用户提供一个图片处理工具，集成于 Finder 的"快速操作"（Quick Actions）菜单中。用户可在 Finder 中右键点击图片文件，通过弹窗界面快速完成图片分辨率调整与压缩，处理结果保存为新文件，原图不受影响。

## 词汇表

- **Quick_Action**：macOS Finder 快速操作，通过右键菜单或预览面板触发的自动化工作流（基于 Automator 或 Swift/AppleScript）
- **Resize_Tool**：本工具的核心处理组件，负责接收参数并执行图片缩放与压缩
- **Dialog**：弹出的原生风格参数配置窗口，供用户输入处理参数
- **Image_Processor**：负责实际执行图片缩放和压缩操作的后端处理模块
- **Output_File**：处理完成后生成的新图片文件，与原图位于同一目录
- **Preset**：预设缩放比例选项，包括 25%、33%、50%、100%
- **Custom_Size**：用户手动输入的自定义宽高像素值

---

## 需求

### 需求 1：Finder 快速操作入口

**用户故事：** 作为 macOS 用户，我希望在 Finder 中右键图片文件时能看到"图片 resize"快速操作选项，以便快速启动图片处理流程。

#### 验收标准

1. WHEN 用户在 Finder 中右键点击图片文件（支持格式：JPEG、PNG、TIFF、HEIC、WebP），THE Quick_Action SHALL 在"快速操作"子菜单中显示"图片 resize"选项。
2. WHEN 用户同时选中多个图片文件并右键，THE Quick_Action SHALL 在"快速操作"子菜单中显示"图片 resize"选项。
3. WHEN 用户右键点击非图片文件，THE Quick_Action SHALL 不在"快速操作"子菜单中显示"图片 resize"选项。

---

### 需求 2：参数配置弹窗

**用户故事：** 作为 macOS 用户，我希望点击"图片 resize"后弹出一个原生风格的配置窗口，以便直观地设置处理参数。

#### 验收标准

1. WHEN 用户点击"图片 resize"快速操作，THE Dialog SHALL 在 500ms 内弹出原生 macOS 风格的参数配置窗口。
2. THE Dialog SHALL 在窗口顶部显示所选图片的文件名（多选时显示"已选择 N 张图片"）。
3. THE Dialog SHALL 提供预设分辨率下拉菜单，选项包括：25%、33%、50%、100%、自定义。
4. WHEN 用户在下拉菜单中选择"自定义"，THE Dialog SHALL 显示宽（px）和高（px）两个可编辑输入框。
5. WHILE 下拉菜单选中非"自定义"选项，THE Dialog SHALL 隐藏宽高输入框。
6. WHEN 用户在宽或高输入框中手动输入数值，THE Dialog SHALL 自动将预设下拉菜单切换为"自定义"。
7. THE Dialog SHALL 提供"是否压缩"复选框，默认为选中状态。
8. THE Dialog SHALL 提供"确定"按钮用于触发处理操作。
9. THE Dialog SHALL 提供"取消"按钮用于关闭窗口且不执行任何操作。

---

### 需求 3：自定义尺寸输入验证与宽高比联动

**用户故事：** 作为 macOS 用户，我希望在输入自定义宽高时得到即时的输入验证反馈，并能自动保持宽高比，以便避免因无效输入导致处理失败，同时快速得到比例正确的目标尺寸。

#### 验收标准

1. WHEN 用户在宽或高输入框中输入非正整数值，THE Dialog SHALL 将对应输入框标红并显示错误提示"请输入正整数"。
2. WHEN 用户在宽或高输入框中输入大于 32767 的值，THE Dialog SHALL 将对应输入框标红并显示错误提示"尺寸不能超过 32767 像素"。
3. WHEN 宽或高输入框存在验证错误，THE Dialog SHALL 禁用"确定"按钮。
4. WHEN 用户选择"自定义"且宽高输入框均为空，THE Dialog SHALL 禁用"确定"按钮。
5. WHEN 用户在宽输入框中输入有效正整数，THE Dialog SHALL 根据原图宽高比自动计算并填充高输入框的值（四舍五入至整数像素）。
6. WHEN 用户在高输入框中输入有效正整数，THE Dialog SHALL 根据原图宽高比自动计算并填充宽输入框的值（四舍五入至整数像素）。

---

### 需求 4：图片处理执行

**用户故事：** 作为 macOS 用户，我希望点击"确定"后工具能按照我设置的参数处理图片，以便得到符合预期的输出文件。

#### 验收标准

1. WHEN 用户点击"确定"按钮，THE Image_Processor SHALL 按照所选 Preset 或 Custom_Size 对图片进行缩放处理。
2. WHEN 用户选择百分比 Preset（25%、33%、50%、100%），THE Image_Processor SHALL 按照原图宽高乘以对应百分比计算目标尺寸，并保持原始宽高比。
3. WHEN 用户选择"自定义"并输入宽高，THE Image_Processor SHALL 按照用户输入的像素值设置输出图片的宽和高。
4. WHEN 用户勾选"是否压缩"，THE Image_Processor SHALL 对输出图片应用有损压缩，JPEG 质量参数设置为 75，PNG 使用无损压缩优化。
5. WHEN 用户未勾选"是否压缩"，THE Image_Processor SHALL 以原始质量输出图片，不应用额外压缩。

---

### 需求 5：输出文件管理

**用户故事：** 作为 macOS 用户，我希望处理后的图片保存在原图所在目录并有清晰的命名，以便快速找到处理结果且不担心原图被覆盖。

#### 验收标准

1. THE Image_Processor SHALL 将 Output_File 保存在与原图相同的目录中。
2. THE Image_Processor SHALL 以"原文件名\_resized.扩展名"格式命名 Output_File（例：photo.jpg → photo_resized.jpg）。
3. WHEN Output_File 的目标路径已存在同名文件，THE Image_Processor SHALL 以"原文件名\_resized\_N.扩展名"格式命名（N 从 2 开始递增，例：photo_resized_2.jpg）。
4. THE Image_Processor SHALL 保持 Output_File 的图片格式与原图一致。
5. WHEN 用户同时处理多张图片，THE Image_Processor SHALL 对每张图片独立执行上述命名规则。

---

### 需求 6：处理进度与结果反馈

**用户故事：** 作为 macOS 用户，我希望在图片处理过程中和完成后得到明确的状态反馈，以便了解操作是否成功。

#### 验收标准

1. WHEN 图片处理正在进行，THE Dialog SHALL 显示进度指示器并禁用"确定"和"取消"按钮。
2. WHEN 所有图片处理成功完成，THE Dialog SHALL 关闭窗口并通过 macOS 系统通知显示"处理完成，已生成 N 张图片"。
3. IF 单张图片处理失败，THEN THE Dialog SHALL 在处理完成后显示错误摘要，列出失败的文件名及错误原因。
4. IF 目标目录不可写，THEN THE Image_Processor SHALL 通过 Dialog 显示错误提示"无法写入目标目录，请检查权限"。

---

### 需求 6：处理进度与结果反馈
