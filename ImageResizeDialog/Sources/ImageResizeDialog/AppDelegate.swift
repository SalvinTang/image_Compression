import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    var files: [URL] = []
    private var dialogController: ResizeDialogController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        dialogController = ResizeDialogController(files: files)
        dialogController?.showWindow(nil)

        NSApp.activate(ignoringOtherApps: true)
    }
}
