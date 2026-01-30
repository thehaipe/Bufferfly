import Carbon
import AppKit

final class HotKeyService {
    static let shared = HotKeyService()
    
    var onHotKeyTriggered: (() -> Void)?
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    
    private init() {}
    
    func register(keyCode: UInt32, modifiers: UInt32) {
        unregister()
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x42464C59) // 'BFLY' - unique signature
        hotKeyID.id = 1
        
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status != noErr {
            print("Error registering global hotkey: \(status)")
            return
        }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                DispatchQueue.main.async {
                    HotKeyService.shared.onHotKeyTriggered?()
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )
    }
    
    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandlerRef = eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }
    
    deinit {
        unregister()
    }
}
enum KeyCodes {
    static let v: UInt32 = 9
}

enum Modifiers {
    static let cmd = cmdKey
    static let shift = shiftKey
    static let control = controlKey
    static let option = optionKey
}
