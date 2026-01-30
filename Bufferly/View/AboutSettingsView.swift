import SwiftUI
struct AboutSettingsView: View {
    var body: some View {
        Form {
            Section {
                HStack(spacing: 15) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bufferly").font(.headline)
                        Text("Version 1.0.0 (Alpha)").font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 5)
            }
            
            Section("Links") {
                Link(destination: URL(string: "https://github.com/thehaipe/Bufferly")!) {
                    Label("GitHub Repository", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                Link(destination: URL(string: "https://github.com/sponsors/thehaipe")!) {
                    Label("Support Development", systemImage: "heart.fill")
                }
            }
        }
        .formStyle(.grouped)
    }
}
