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
                Picker("History Limit", selection: $historyLimit) {
                    Text("10 items").tag(10)
                    Text("20 items").tag(20)
                    Text("50 items").tag(50)
                }
                
                if historyLimit == 50 {
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
