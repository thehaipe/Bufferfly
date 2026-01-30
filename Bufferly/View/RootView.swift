import SwiftUI
import SwiftData

struct RootView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            HotkeySettingsView()
                .tabItem {
                    Label("Keybinding", systemImage: "keyboard")
                }
            
            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 350)
        .padding()
    }
}

#Preview {
    RootView()
}
