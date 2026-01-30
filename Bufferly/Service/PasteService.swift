import AppKit
import Carbon

final class PasteService {
    static let shared = PasteService()
    
    private init() {}
    
    @MainActor
    func paste(item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        if let data = item.binaryData, item.type == "public.image" {
            pasteboard.setData(data, forType: .png)
        } else if let text = item.textContent {
            pasteboard.setString(text, forType: .string)
        }

        OverlayWindowService.shared.closeWindow()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.simulatePasteCommand()
        }
    }
    
    private func simulatePasteCommand() {
        let source = CGEventSource(stateID: .hidSystemState)
        
        let kVK_ANSI_V = 0x09
        let cmdFlag = CGEventFlags.maskCommand
        //It dosent work rn, i should fix it
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true) else { return }
        keyDown.flags = cmdFlag
        keyDown.post(tap: .cghidEventTap)

        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false) else { return }
        keyUp.flags = cmdFlag
        keyUp.post(tap: .cghidEventTap)
    }
}
