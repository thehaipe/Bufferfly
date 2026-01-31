import SwiftUI
import SwiftData
struct GeneralSettingsView: View {
    @AppStorage("historyLimit") private var historyLimit: Int = 20
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @Environment(\.modelContext) private var modelContext
    @State private var showingClearAlert = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("History Limit")
                        Spacer()
                        Text("\(historyLimit) items")
                            .foregroundStyle(.secondary)
                    }
                    
                    Slider(value: Binding(
                        get: { Double(historyLimit) },
                        set: { historyLimit = Int($0) }
                    ), in: 10...50, step: 5)
                }
                
                if historyLimit >= 45  {
                    Text("⚠️ Higher limits may impact performance.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                Button(role: .destructive) {
                    showingClearAlert = true
                } label: {
                    Text("Clear Clipboard History")
                }
                .alert("Are you sure?", isPresented: $showingClearAlert) {
                    Button("Clear", role: .destructive) {
                        do { try modelContext.delete(model: ClipboardItem.self) } catch {}
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This action cannot be undone.")
                }
            }
        }
        .formStyle(.grouped)
    }
}
