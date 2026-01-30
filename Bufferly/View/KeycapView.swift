import SwiftUI
struct KeycapView: View {
    let symbol: String
    var body: some View {
        Text(symbol)
            .font(.system(size: 16, weight: .semibold, design: .monospaced))
            .frame(width: 32, height: 32)
            .background(Color(nsColor: .windowBackgroundColor))
            .cornerRadius(6)
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}
