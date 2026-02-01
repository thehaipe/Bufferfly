import SwiftUI
import SwiftData

struct ClipboardCarouselView: View {
    @Query(sort: \ClipboardItem.createdAt, order: .reverse) private var items: [ClipboardItem]

    private let windowWidth: CGFloat = 338
    private let windowHeight: CGFloat = 158
    private let itemHeight: CGFloat = 60
    private let spacing: CGFloat = 4
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            if items.isEmpty {
                Text("Empty")
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: spacing) {
                        ForEach(items) { item in
                            ClipboardItemRow(item: item)
                                .contentShape(Rectangle()) 
                                .onTapGesture {
                                    PasteService.shared.paste(item: item)
                                }
                                .frame(height: itemHeight)
                                .scrollTransition { content, phase in
                                    content
                                        .opacity(phase.isIdentity ? 1.0 : 0.6)
                                        .scaleEffect(phase.isIdentity ? 1.0 : 0.85)
                                        .blur(radius: phase.isIdentity ? 0 : 2)
                                }
                        }
                    }
                    .padding(.vertical, 10)
                }
                .scrollClipDisabled()
            }
        }
        .frame(width: windowWidth, height: windowHeight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ClipboardItemRow: View {
    @Bindable var item: ClipboardItem
    @FocusState private var isEditing: Bool
    @FocusState private var isRowFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            if let data = item.binaryData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .background(Color.black.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                    }
            } else {
                Image(systemName: item.type.contains("image") ? "photo" : "text.alignleft")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color.black.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.textContent?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Image")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    TextField("Note", text: Binding(
                        get: { item.note ?? "" },
                        set: { item.note = $0.isEmpty ? nil : $0 }
                    ))
                    .focused($isEditing)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background {
                        Capsule()
                            .fill(Color.black.opacity(0.1))
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    }
                    .frame(width: 80) // Fixed width for the tag to keep layout stable
                    .onTapGesture {
                        isEditing = true
                    }
                    
                    Text(item.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()

            Image(systemName: "return")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .opacity(0.5)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.regularMaterial) 
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        }
        .padding(.horizontal, 10)
        .focusable()
        .focused($isRowFocused)
        .focusEffectDisabled()
        .onKeyPress(.return) {
            if isEditing {
                isEditing = false
                isRowFocused = true
                return .handled
            }
            PasteService.shared.paste(item: item)
            return .handled
        }
    }
}

#Preview {
    ClipboardCarouselView()
        .padding()
        .background(Color.blue)
}
