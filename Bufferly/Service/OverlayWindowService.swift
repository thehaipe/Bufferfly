import SwiftUI
import AppKit
import SwiftData

@MainActor
final class OverlayWindowService {
    static let shared = OverlayWindowService()
    
    private var panel: NSPanel?
    private var container: ModelContainer?
    private var globalClickMonitor: Any?
    
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

        panel.orderFrontRegardless()

        startMonitoringClicks()
    }
    
    func closeWindow() {
        panel?.orderOut(nil)
        stopMonitoringClicks()
    }
    
    private func startMonitoringClicks() {
        stopMonitoringClicks()

        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.closeWindow()
            }
        }
    }
    
    private func stopMonitoringClicks() {
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
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
        
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 338, height: 158),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        

        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentViewController = hostingController
        panel.hidesOnDeactivate = false 
        
        self.panel = panel
    }
}
