import AppKit
import CoreGraphics
import Foundation

// MARK: - ResizeDialogController

class ResizeDialogController: NSWindowController {

    // MARK: - Properties

    private let files: [URL]
    private let processor: ImageProcessor

    /// 第一张图片的原始尺寸（用于宽高比联动和预设计算）
    private var originalImageSize: CGSize? {
        didSet { updateFieldsFromPreset() }
    }

    /// 防止宽高联动时循环触发
    private var isUpdatingLinkedField = false
    
    /// 是否为多选模式（2张及以上图片）
    private var isMultipleFiles: Bool {
        return files.count >= 2
    }
    
    /// 宽高比是否锁定（单张图片时可切换，多张图片时固定为 false）
    private var isAspectRatioLocked: Bool = true

    // MARK: - UI Elements
    
    // 容器视图
    private let resolutionContainer = NSBox()
    private let compressionContainer = NSBox()

    private let titleLabel        = NSTextField(labelWithString: "")
    private let presetLabel       = NSTextField(labelWithString: "尺寸：")
    private let presetPopUp       = NSPopUpButton()
    private let resolutionLabel   = NSTextField(labelWithString: "分辨率：")
    private let widthField        = NSTextField()
    private let lockButton        = NSButton()
    private let xLabel            = NSTextField(labelWithString: "×")
    private let heightField       = NSTextField()
    private let pxLabel           = NSTextField(labelWithString: "px")
    private let errorLabel        = NSTextField(labelWithString: "")
    private let compressCheckbox  = NSButton(checkboxWithTitle: "启用压缩", target: nil, action: nil)
    private let qualityLabel      = NSTextField(labelWithString: "质量：")
    private let qualityPopUp      = NSPopUpButton()
    private let confirmButton     = NSButton(title: "确定", target: nil, action: nil)
    private let cancelButton      = NSButton(title: "取消", target: nil, action: nil)
    private let progressIndicator = NSProgressIndicator()

    // MARK: - Init

    init(files: [URL], processor: ImageProcessor = ImageProcessor()) {
        self.files = files
        self.processor = processor

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 210, height: 285),
            styleMask: [.titled, .closable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "图片压缩"
        panel.isFloatingPanel = true
        panel.center()

        super.init(window: panel)
        
        // 设置窗口代理以处理关闭事件
        panel.delegate = self

        setupUI()
        setupActions()
        loadOriginalImageSize()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        // 分辨率容器（白色圆角背景 - 浅色模式，灰色 - 深色模式）
        resolutionContainer.boxType = .custom
        resolutionContainer.borderType = .lineBorder
        resolutionContainer.borderColor = NSColor(named: NSColor.Name("containerBorder")) ?? NSColor.separatorColor
        resolutionContainer.borderWidth = 1
        resolutionContainer.cornerRadius = 6
        resolutionContainer.fillColor = NSColor(named: NSColor.Name("containerBackground")) ?? NSColor.controlBackgroundColor
        resolutionContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(resolutionContainer)
        
        // 压缩容器（白色圆角背景 - 浅色模式，灰色 - 深色模式）
        compressionContainer.boxType = .custom
        compressionContainer.borderType = .lineBorder
        compressionContainer.borderColor = NSColor(named: NSColor.Name("containerBorder")) ?? NSColor.separatorColor
        compressionContainer.borderWidth = 1
        compressionContainer.cornerRadius = 6
        compressionContainer.fillColor = NSColor(named: NSColor.Name("containerBackground")) ?? NSColor.controlBackgroundColor
        compressionContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(compressionContainer)

        // 文件名标签（左对齐，自动适配颜色）
        titleLabel.stringValue = generateDialogTitle(files: files)
        titleLabel.alignment = .left
        titleLabel.isEditable = false
        titleLabel.isBordered = false
        titleLabel.backgroundColor = .clear
        titleLabel.textColor = .labelColor  // 自动适配深色/浅色模式
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        // 预设标签（自动适配颜色）
        presetLabel.stringValue = "尺寸："
        presetLabel.isEditable = false
        presetLabel.isBordered = false
        presetLabel.backgroundColor = .clear
        presetLabel.textColor = .labelColor  // 自动适配深色/浅色模式
        presetLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(presetLabel)

        // 预设下拉
        for preset in Preset.allCases {
            presetPopUp.addItem(withTitle: preset.rawValue)
        }
        presetPopUp.selectItem(withTitle: Preset.p100.rawValue)
        presetPopUp.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(presetPopUp)

        // 分辨率标签（改为"宽："）
        resolutionLabel.stringValue = "宽："
        resolutionLabel.isEditable = false
        resolutionLabel.isBordered = false
        resolutionLabel.backgroundColor = .clear
        resolutionLabel.textColor = .labelColor  // 自动适配深色/浅色模式
        resolutionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(resolutionLabel)

        // 宽输入框
        widthField.placeholderString = ""
        widthField.delegate = self
        widthField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(widthField)

        // 锁定按钮
        lockButton.isBordered = false
        lockButton.bezelStyle = .inline
        lockButton.setButtonType(.momentaryChange)
        lockButton.title = isAspectRatioLocked ? "🔒" : "🔓"
        lockButton.font = NSFont.systemFont(ofSize: 14)
        lockButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(lockButton)

        // × 分隔符（改为"高："）
        xLabel.stringValue = "高："
        xLabel.isEditable = false
        xLabel.isBordered = false
        xLabel.backgroundColor = .clear
        xLabel.textColor = .labelColor  // 自动适配深色/浅色模式
        xLabel.alignment = .left
        xLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(xLabel)

        // 高输入框
        heightField.placeholderString = ""
        heightField.delegate = self
        heightField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(heightField)

        // px 单位标签（隐藏）
        pxLabel.isHidden = true
        pxLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pxLabel)

        // 错误提示（红色，默认隐藏）
        errorLabel.textColor = .systemRed
        errorLabel.font = NSFont.systemFont(ofSize: 11)
        errorLabel.isEditable = false
        errorLabel.isBordered = false
        errorLabel.backgroundColor = .clear
        errorLabel.isHidden = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(errorLabel)

        // 压缩复选框（默认选中）
        compressCheckbox.state = .on
        compressCheckbox.translatesAutoresizingMaskIntoConstraints = false
        // 设置复选框文字颜色以适配深色模式
        if let cell = compressCheckbox.cell as? NSButtonCell {
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor.labelColor
            ]
            cell.attributedTitle = NSAttributedString(string: "启用压缩", attributes: attributes)
        }
        contentView.addSubview(compressCheckbox)

        // 压缩质量标签
        qualityLabel.isEditable = false
        qualityLabel.isBordered = false
        qualityLabel.backgroundColor = .clear
        qualityLabel.textColor = .labelColor  // 自动适配深色/浅色模式
        qualityLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(qualityLabel)

        // 压缩质量下拉（默认选择平衡）
        qualityPopUp.addItem(withTitle: "质量好")
        qualityPopUp.addItem(withTitle: "平衡")
        qualityPopUp.addItem(withTitle: "体积小")
        qualityPopUp.selectItem(at: 1)  // 默认选择"平衡"
        qualityPopUp.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(qualityPopUp)

        // 取消按钮
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1B}"
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cancelButton)

        // 确定按钮
        confirmButton.bezelStyle = .rounded
        confirmButton.keyEquivalent = "\r"
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(confirmButton)

        // 进度指示器（默认隐藏）
        progressIndicator.style = .spinning
        progressIndicator.controlSize = .small
        progressIndicator.isHidden = true
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(progressIndicator)

        setupConstraints(in: contentView)
    }

    private func setupConstraints(in contentView: NSView) {
        let m: CGFloat = 15       // 边距
        let sp: CGFloat = 10      // 行间距
        let fh: CGFloat = 20      // 控件高度
        let labelW: CGFloat = 43  // 左侧标签宽度
        let upOffset: CGFloat = 5  // 整体向上偏移量
        let fieldOffset: CGFloat = 2  // 输入框和下拉框向上偏移量

        NSLayoutConstraint.activate([
            // ── 文件名 ──
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: m - upOffset),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: m),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -m),
            
            // ── 分辨率容器 ──
            resolutionContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: m - upOffset),
            resolutionContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: m),
            resolutionContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -m),
            resolutionContainer.heightAnchor.constraint(equalToConstant: 110),

            // ── 预设行 ──
            presetLabel.topAnchor.constraint(equalTo: resolutionContainer.topAnchor, constant: 15),
            presetLabel.leadingAnchor.constraint(equalTo: resolutionContainer.leadingAnchor, constant: 15),
            presetLabel.widthAnchor.constraint(equalToConstant: labelW),
            presetLabel.lastBaselineAnchor.constraint(equalTo: presetPopUp.lastBaselineAnchor),

            presetPopUp.topAnchor.constraint(equalTo: resolutionContainer.topAnchor, constant: 15 - fieldOffset),
            presetPopUp.leadingAnchor.constraint(equalTo: presetLabel.trailingAnchor, constant: 7),
            presetPopUp.widthAnchor.constraint(equalToConstant: 76),
            presetPopUp.heightAnchor.constraint(equalToConstant: fh),

            // ── 分辨率行（宽） ──
            resolutionLabel.topAnchor.constraint(equalTo: presetPopUp.bottomAnchor, constant: sp),
            resolutionLabel.leadingAnchor.constraint(equalTo: resolutionContainer.leadingAnchor, constant: 15),
            resolutionLabel.widthAnchor.constraint(equalToConstant: 29),
            resolutionLabel.lastBaselineAnchor.constraint(equalTo: widthField.lastBaselineAnchor),

            widthField.topAnchor.constraint(equalTo: presetPopUp.bottomAnchor, constant: sp - fieldOffset),
            widthField.leadingAnchor.constraint(equalTo: resolutionLabel.trailingAnchor, constant: 21),
            widthField.widthAnchor.constraint(equalToConstant: 76),
            widthField.heightAnchor.constraint(equalToConstant: fh),

            // ── 锁定按钮 ──
            lockButton.leadingAnchor.constraint(equalTo: widthField.trailingAnchor, constant: 4),
            lockButton.topAnchor.constraint(equalTo: widthField.bottomAnchor, constant: sp / 2 - 16),
            lockButton.widthAnchor.constraint(equalToConstant: 24),
            lockButton.heightAnchor.constraint(equalToConstant: 24),

            // ── 分辨率行（高） ──
            xLabel.topAnchor.constraint(equalTo: widthField.bottomAnchor, constant: sp),
            xLabel.leadingAnchor.constraint(equalTo: resolutionContainer.leadingAnchor, constant: 15),
            xLabel.widthAnchor.constraint(equalToConstant: 29),
            xLabel.lastBaselineAnchor.constraint(equalTo: heightField.lastBaselineAnchor),

            heightField.topAnchor.constraint(equalTo: widthField.bottomAnchor, constant: sp - fieldOffset),
            heightField.leadingAnchor.constraint(equalTo: xLabel.trailingAnchor, constant: 21),
            heightField.widthAnchor.constraint(equalToConstant: 76),
            heightField.heightAnchor.constraint(equalToConstant: fh),

            // ── 错误提示 ──
            errorLabel.topAnchor.constraint(equalTo: heightField.bottomAnchor, constant: 4),
            errorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: m),
            errorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -m),
            
            // ── 压缩容器 ──
            compressionContainer.topAnchor.constraint(equalTo: resolutionContainer.bottomAnchor, constant: sp - upOffset),
            compressionContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: m),
            compressionContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -m),
            compressionContainer.heightAnchor.constraint(equalToConstant: 75),

            // ── 压缩复选框 ──
            compressCheckbox.topAnchor.constraint(equalTo: compressionContainer.topAnchor, constant: 12),
            compressCheckbox.leadingAnchor.constraint(equalTo: compressionContainer.leadingAnchor, constant: 15),

            // ── 压缩质量行 ──
            qualityLabel.topAnchor.constraint(equalTo: compressCheckbox.bottomAnchor, constant: 15),
            qualityLabel.leadingAnchor.constraint(equalTo: compressionContainer.leadingAnchor, constant: 15),
            qualityLabel.widthAnchor.constraint(equalToConstant: 43),
            qualityLabel.lastBaselineAnchor.constraint(equalTo: qualityPopUp.lastBaselineAnchor),

            qualityPopUp.topAnchor.constraint(equalTo: compressCheckbox.bottomAnchor, constant: 15 - fieldOffset),
            qualityPopUp.leadingAnchor.constraint(equalTo: qualityLabel.trailingAnchor, constant: 6),
            qualityPopUp.widthAnchor.constraint(equalToConstant: 86),
            qualityPopUp.heightAnchor.constraint(equalToConstant: fh),

            // ── 按钮行 ──
            cancelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: m),
            cancelButton.widthAnchor.constraint(equalToConstant: 80),
            cancelButton.heightAnchor.constraint(equalToConstant: fh),
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -m),

            confirmButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -m),
            confirmButton.widthAnchor.constraint(equalToConstant: 84),
            confirmButton.heightAnchor.constraint(equalToConstant: fh),
            confirmButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -m),

            // ── 进度指示器 ──
            progressIndicator.topAnchor.constraint(equalTo: qualityPopUp.bottomAnchor, constant: sp),
            progressIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: m),
        ])
    }

    private func setupActions() {
        presetPopUp.target = self
        presetPopUp.action = #selector(presetChanged(_:))
        lockButton.target = self
        lockButton.action = #selector(lockButtonClicked(_:))
        confirmButton.target = self
        confirmButton.action = #selector(confirmAction(_:))
        cancelButton.target = self
        cancelButton.action = #selector(cancelAction(_:))
    }

    // MARK: - Load Original Image Size

    private func loadOriginalImageSize() {
        guard let firstFile = files.first else { return }
        
        // 多张图片时，锁定按钮默认解锁且禁用
        if isMultipleFiles {
            isAspectRatioLocked = false
            lockButton.title = "🔓"
            lockButton.isEnabled = false
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let size = self?.processor.imageSize(for: firstFile)
            DispatchQueue.main.async {
                self?.originalImageSize = size  // didSet 会触发 updateFieldsFromPreset
            }
        }
    }

    /// 根据当前预设和原图尺寸更新宽高输入框（不触发 delegate）
    private func updateFieldsFromPreset() {
        let selectedTitle = presetPopUp.titleOfSelectedItem ?? ""
        let preset = Preset(rawValue: selectedTitle) ?? .p100

        // 多选模式
        if isMultipleFiles {
            isUpdatingLinkedField = true
            if preset == .custom {
                // 自定义模式：显示 1024
                widthField.stringValue = "1024"
                heightField.stringValue = "1024"
                applyFieldValidation(.valid, to: widthField)
                applyFieldValidation(.valid, to: heightField)
            } else {
                // 预设模式：显示为空（每张图片尺寸不同）
                widthField.stringValue = ""
                heightField.stringValue = ""
                widthField.placeholderString = ""
                heightField.placeholderString = ""
            }
            isUpdatingLinkedField = false
            clearError()
            updateConfirmButton()
            return
        }

        // 单选模式：原有逻辑
        guard let size = originalImageSize else { return }
        guard let pct = preset.percentage else { return }  // 自定义时不覆盖用户输入

        let target = calculateTargetSize(originalSize: size, percentage: pct)
        isUpdatingLinkedField = true
        widthField.stringValue = "\(Int(target.width))"
        heightField.stringValue = "\(Int(target.height))"
        applyFieldValidation(.valid, to: widthField)
        applyFieldValidation(.valid, to: heightField)
        isUpdatingLinkedField = false
        clearError()
        updateConfirmButton()
    }

    // MARK: - Preset Changed

    @objc func presetChanged(_ sender: NSPopUpButton) {
        clearError()
        updateFieldsFromPreset()   // 预设切换时同步更新宽高
        updateConfirmButton()
    }
    
    // MARK: - Lock Button Clicked
    
    @objc func lockButtonClicked(_ sender: NSButton) {
        // 多张图片时不响应点击
        guard !isMultipleFiles else { return }
        
        // 切换锁定状态
        isAspectRatioLocked.toggle()
        lockButton.title = isAspectRatioLocked ? "🔒" : "🔓"
        
        // 从解锁变回锁上时，根据当前宽的值重新计算高
        if isAspectRatioLocked {
            let text = widthField.stringValue
            let state = validateDimension(text)
            if state == .valid, let size = originalImageSize, let value = Int(text) {
                isUpdatingLinkedField = true
                let linked = calculateLinkedDimension(input: value, inputIsWidth: true, originalSize: size)
                heightField.stringValue = "\(linked)"
                applyFieldValidation(.valid, to: heightField)
                isUpdatingLinkedField = false
                clearError()
            }
        }
    }

    // MARK: - Width / Height Changed

    @objc func widthChanged(_ sender: NSTextField) {
        guard !isUpdatingLinkedField else { return }

        // 手动输入 → 切换为"自定义"
        presetPopUp.selectItem(withTitle: Preset.custom.rawValue)

        let text = widthField.stringValue
        let state = validateDimension(text)
        applyFieldValidation(state, to: widthField)

        // 多选模式：不联动，只验证
        if isMultipleFiles {
            if state == .valid {
                clearError()
            } else {
                showError(for: state)
            }
            updateConfirmButton()
            return
        }

        // 单选模式：根据锁定状态决定是否联动
        if isAspectRatioLocked {
            // 锁定状态：联动计算高度
            if state == .valid, let size = originalImageSize, let value = Int(text) {
                clearError()
                isUpdatingLinkedField = true
                let linked = calculateLinkedDimension(input: value, inputIsWidth: true, originalSize: size)
                heightField.stringValue = "\(linked)"
                applyFieldValidation(.valid, to: heightField)
                isUpdatingLinkedField = false
            } else {
                showError(for: state)
            }
        } else {
            // 解锁状态：不联动，只验证
            if state == .valid {
                clearError()
            } else {
                showError(for: state)
            }
        }
        updateConfirmButton()
    }

    @objc func heightChanged(_ sender: NSTextField) {
        guard !isUpdatingLinkedField else { return }

        // 手动输入 → 切换为"自定义"
        presetPopUp.selectItem(withTitle: Preset.custom.rawValue)

        let text = heightField.stringValue
        let state = validateDimension(text)
        applyFieldValidation(state, to: heightField)

        // 多选模式：不联动，只验证
        if isMultipleFiles {
            if state == .valid {
                clearError()
            } else {
                showError(for: state)
            }
            updateConfirmButton()
            return
        }

        // 单选模式：根据锁定状态决定是否联动
        if isAspectRatioLocked {
            // 锁定状态：联动计算宽度
            if state == .valid, let size = originalImageSize, let value = Int(text) {
                clearError()
                isUpdatingLinkedField = true
                let linked = calculateLinkedDimension(input: value, inputIsWidth: false, originalSize: size)
                widthField.stringValue = "\(linked)"
                applyFieldValidation(.valid, to: widthField)
                isUpdatingLinkedField = false
            } else {
                showError(for: state)
            }
        } else {
            // 解锁状态：不联动，只验证
            if state == .valid {
                clearError()
            } else {
                showError(for: state)
            }
        }
        updateConfirmButton()
    }

    // MARK: - Update Confirm Button

    private func updateConfirmButton() {
        let selectedTitle = presetPopUp.titleOfSelectedItem ?? ""
        let preset = Preset(rawValue: selectedTitle) ?? .p100
        let widthState = validateDimension(widthField.stringValue)
        let heightState = validateDimension(heightField.stringValue)
        confirmButton.isEnabled = isConfirmEnabled(preset: preset, widthState: widthState, heightState: heightState)
    }

    // MARK: - Confirm Action

    @objc func confirmAction(_ sender: NSButton) {
        let config = buildProcessConfig()
        confirmButton.isEnabled = false
        cancelButton.isEnabled = false
        progressIndicator.isHidden = false
        progressIndicator.startAnimation(nil)

        let filesToProcess = files
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let results = self.processor.processBatch(files: filesToProcess, config: config) { _, _ in }

            DispatchQueue.main.async {
                self.progressIndicator.stopAnimation(nil)
                self.progressIndicator.isHidden = true

                let failures = results.filter { !$0.succeeded }
                if failures.isEmpty {
                    // 成功：直接关闭窗口，不显示任何提示
                    self.window?.close()
                    // 优雅地终止应用
                    NSApplication.shared.terminate(nil)
                } else {
                    // 失败：显示错误信息
                    self.confirmButton.isEnabled = true
                    self.cancelButton.isEnabled = true
                    let alert = NSAlert()
                    alert.messageText = "处理结果"
                    alert.informativeText = generateErrorSummary(results: results)
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "确定")
                    if let window = self.window {
                        alert.beginSheetModal(for: window) { _ in }
                    } else {
                        alert.runModal()
                    }
                }
            }
        }
    }

    // MARK: - Cancel Action

    @objc func cancelAction(_ sender: NSButton) {
        window?.close()
        // 优雅地终止应用
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Validation Helpers

    private func applyFieldValidation(_ state: ValidationState, to field: NSTextField) {
        field.wantsLayer = true
        switch state {
        case .valid, .empty:
            field.layer?.borderWidth = 0
        case .invalidFormat, .exceedsMaximum:
            field.layer?.borderColor = NSColor.systemRed.cgColor
            field.layer?.borderWidth = 1.5
            field.layer?.cornerRadius = 3
        }
    }

    private func showError(for state: ValidationState) {
        switch state {
        case .valid, .empty:
            clearError()
        case .invalidFormat:
            errorLabel.stringValue = "请输入正整数"
            errorLabel.isHidden = false
        case .exceedsMaximum:
            errorLabel.stringValue = "尺寸不能超过 32767 像素"
            errorLabel.isHidden = false
        }
    }

    private func clearError() {
        errorLabel.stringValue = ""
        errorLabel.isHidden = true
    }

    // MARK: - Config Building

    private func buildProcessConfig() -> ProcessConfig {
        let selectedTitle = presetPopUp.titleOfSelectedItem ?? ""
        let preset = Preset(rawValue: selectedTitle) ?? .p100
        let compress = compressCheckbox.state == .on
        
        // 获取压缩质量
        let qualityIndex = qualityPopUp.indexOfSelectedItem
        let quality: String
        switch qualityIndex {
        case 0: quality = "best"      // 质量最好
        case 1: quality = "normal"    // 平衡（默认）
        case 2: quality = "low"       // 体积最小
        default: quality = "normal"
        }

        let resizeMode: ResizeMode
        if preset == .custom {
            let w = Int(widthField.stringValue) ?? 0
            let h = Int(heightField.stringValue) ?? 0
            resizeMode = .custom(width: w, height: h)
        } else {
            resizeMode = .preset(percentage: preset.percentage ?? 1.0)
        }
        return ProcessConfig(resizeMode: resizeMode, compress: compress, quality: quality)
    }
}

// MARK: - NSTextFieldDelegate

extension ResizeDialogController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        guard let field = obj.object as? NSTextField else { return }
        if field === widthField {
            widthChanged(field)
        } else if field === heightField {
            heightChanged(field)
        }
    }
}

// MARK: - NSWindowDelegate

extension ResizeDialogController: NSWindowDelegate {
    /// 窗口即将关闭时调用
    func windowWillClose(_ notification: Notification) {
        // 用户点击关闭按钮时，退出应用
        NSApplication.shared.terminate(nil)
    }
    
    /// 窗口是否应该关闭（返回 true 允许关闭）
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return true
    }
}
