import SwiftUI
import SwiftData
internal import Combine

struct GeneralSettingsView: View {
    @AppStorage("historyLimit") private var historyLimit: Int = 20
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @AppStorage("autoUpdate") private var autoUpdate: Bool = true
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = GeneralSettingsViewModel()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var updateService: UpdateService { viewModel.updateService }

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
            }

            Section("Updates") {
                Toggle("Check for updates automatically", isOn: $autoUpdate)

                updateStatusView
            }

            Section("Permissions") {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.isAccessibilityTrusted ? "checkmark.seal.fill" : "xmark.seal.fill")
                        .foregroundStyle(viewModel.isAccessibilityTrusted ? .green : .red)
                        .font(.system(size: 18))

                    VStack(alignment: .leading) {
                        Text("Accessibility Access")
                            .font(.headline)
                        Text(viewModel.isAccessibilityTrusted ? "Bufferfly has full access to work properly." : "Required for overlay and shortcuts.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if !viewModel.isAccessibilityTrusted {
                        Button("Enable") {
                            viewModel.requestAccessibilityAccess()
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .onReceive(timer) { _ in
                viewModel.refreshAccessibilityStatus()
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
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var updateStatusView: some View {
        switch updateService.status {
        case .idle:
            if !autoUpdate {
                Button("Check for Updates") {
                    Task { await updateService.checkForUpdate() }
                }
            }

        case .checking:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Checking...")
                    .foregroundStyle(.secondary)
            }

        case .noUpdate:
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("You're using the latest version")
                    .foregroundStyle(.secondary)
            }

        case .updateAvailable(let version):
            HStack {
                Text("Version \(version) available")
                Spacer()
                Button("Download") {
                    Task { await updateService.downloadUpdate() }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }

        case .downloading(let progress):
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Downloading...")
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                ProgressView(value: progress)
                    .tint(.blue)
                    .shadow(color: .blue.opacity(0.4), radius: 4)
            }

        case .readyToInstall:
            HStack {
                Text("Ready to install")
                Spacer()
                Button("Install & Relaunch") {
                    updateService.installUpdate()
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }

        case .installing:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Installing...")
                    .foregroundStyle(.secondary)
            }

        case .failed(let message):
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Spacer()
                Button("Retry") {
                    Task { await updateService.checkForUpdate() }
                }
            }
        }
    }
}
