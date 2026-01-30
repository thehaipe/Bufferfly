import AppKit
import SwiftData
import OSLog

@Observable
final class ClipboardService {
    private let logger = Logger(subsystem: "com.bufferly.app", category: "ClipboardService")
    private var timer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    
    private let container: ModelContainer
    private var saver: ClipboardSaver?
    
    init(container: ModelContainer) {
        self.container = container
        self.saver = ClipboardSaver(modelContainer: container)
    }
    
    func startMonitoring() {
        logger.info("Starting clipboard monitoring...")
        //I need to find more optimal way, but rn idk, rly
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkClipboard() {
        let currentChangeCount = NSPasteboard.general.changeCount
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount
        
        logger.debug("Clipboard changed, processing...")
        processNewItem()
    }
    
    private func processNewItem() {
        let pasteboard = NSPasteboard.general
        if let image = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png) {
            saveItem(type: "public.image", binaryData: image)
        } else if let text = pasteboard.string(forType: .string) {
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            saveItem(type: "public.utf8-plain-text", textContent: text)
        }
    }
    
    private func saveItem(type: String, textContent: String? = nil, binaryData: Data? = nil) {
        Task {
            await saver?.save(type: type, textContent: textContent, binaryData: binaryData)
        }
    }
}

//Safe background write to SwiftData
@ModelActor
actor ClipboardSaver {
    func save(type: String, textContent: String?, binaryData: Data?) {
        let fetchDescriptor = FetchDescriptor<ClipboardItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        if let lastItem = try? modelContext.fetch(fetchDescriptor).first {
            if lastItem.textContent == textContent && lastItem.type == type && lastItem.binaryData == binaryData {
                return
            }
        }
        
        let newItem = ClipboardItem(
            type: type,
            textContent: textContent,
            binaryData: binaryData
        )
        
        modelContext.insert(newItem)
        
        do {
            try modelContext.save()
            let savedLimit = UserDefaults.standard.integer(forKey: "historyLimit")
            let limit = savedLimit > 0 ? savedLimit : 20 // 20 is default value
            
            let descriptor = FetchDescriptor<ClipboardItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            let items = try modelContext.fetch(descriptor)
            
            if items.count > limit {
                for itemToDelete in items.suffix(from: limit) {
                    modelContext.delete(itemToDelete)
                }
                try modelContext.save()
            }
        } catch {
            print("Failed to save or prune clipboard items: \(error)")
        }
    }
}
