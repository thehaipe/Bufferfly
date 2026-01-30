import SwiftUI
struct HotkeySettingsView: View {
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        KeycapView(symbol: "⌃")
                        KeycapView(symbol: "⇧")
                        KeycapView(symbol: "V")
                    }
                    Text("Use this shortcut to summon Bufferly anywhere on your Mac.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 5)
            } header: {
                Text("Global Shortcut")
            }
        }
        .formStyle(.grouped)
    }
}
