import SwiftUI
import AppKit
import SwiftData

@MainActor
final class OverlayWindowService {
    static let shared = OverlayWindowService()
    
    private var panel: NSPanel?
    private var container: ModelContainer?
    private var resignActiveObserver: NSObjectProtocol?
    
    private init() {}
    
    func setup(with container: ModelContainer) {
        self.container = container
    }
    
    func toggleWindow() {
        if panel == nil {
            createPanel()
        }
        
        guard let panel = panel else { return }
        
        if panel.isVisible {
            closeWindow()
        } else {
            showWindow()
        }
    }
    
    func showWindow() {
        guard let panel = panel else {
            createPanel()
            if panel != nil { showWindow() }
            return
        }

        let mouseLocation = NSEvent.mouseLocation
        let windowSize = panel.frame.size
        let screenFrame = NSScreen.main?.frame ?? .zero
        
        var x = mouseLocation.x - (windowSize.width / 2)
        var y = mouseLocation.y - (windowSize.height / 2) 
        
        if x < screenFrame.minX { x = screenFrame.minX + 10 }
        if x + windowSize.width > screenFrame.maxX { x = screenFrame.maxX - windowSize.width - 10 }
        if y - windowSize.height < screenFrame.minY { y = screenFrame.minY + windowSize.height + 10 }
        
        panel.setFrameOrigin(NSPoint(x: x, y: y))
        
        // Activate app to allow text input
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        startMonitoringFocus()
    }
    
    func closeWindow() {
        panel?.orderOut(nil)
        stopMonitoringFocus()
        //Hide app to ensure focus returns to previous app immediately
        NSApp.hide(nil)
    }
    
    private func startMonitoringFocus() {
        stopMonitoringFocus()
        resignActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.closeWindow()
        }
    }
    
    private func stopMonitoringFocus() {
        if let observer = resignActiveObserver {
            NotificationCenter.default.removeObserver(observer)
            resignActiveObserver = nil
        }
    }
    
    private func createPanel() {
        guard let container = container else {
            return
        }
        
        let visualEffect = NSVisualEffectView()
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.material = .hudWindow
        
        let hostingController = NSHostingController(rootView: 
            ClipboardCarouselView()
                .modelContainer(container) //Important! Share context
        )
        
        // Remove .nonactivatingPanel to allow taking focus
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 338, height: 158),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentViewController = hostingController
        panel.hidesOnDeactivate = true
        
        self.panel = panel
    }
}

class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
