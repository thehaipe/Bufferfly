import Foundation
import SwiftData

@Model
final class ClipboardItem {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var type: String
    var textContent: String?
    var note: String?
    @Attribute(.externalStorage) var binaryData: Data?
    var isPinned: Bool = false
    
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        type: String,
        textContent: String? = nil,
        note: String? = nil,
        binaryData: Data? = nil,
        isPinned: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.type = type
        self.textContent = textContent
        self.note = note
        self.binaryData = binaryData
        self.isPinned = isPinned
    }
}
