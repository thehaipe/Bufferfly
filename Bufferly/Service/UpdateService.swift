import Foundation
import AppKit

struct GitHubRelease: Codable {
    let tagName: String
    let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case assets
    }
}

struct GitHubAsset: Codable {
    let name: String
    let browserDownloadURL: String
    let size: Int

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
        case size
    }
}

enum UpdateStatus: Equatable {
    case idle
    case checking
    case noUpdate
    case updateAvailable(version: String)
    case downloading(progress: Double)
    case readyToInstall
    case installing
    case failed(message: String)
}

@Observable
@MainActor
final class UpdateService {
    static let shared = UpdateService()

    var status: UpdateStatus = .idle
    var downloadedZipPath: URL?

    private var pendingDownloadURL: URL?
    private var pendingAssetSize: Int?

    private init() {}

    // MARK: - Check

    func checkForUpdate() async {
        status = .checking

        guard let url = URL(string: "https://api.github.com/repos/thehaipe/Bufferfly/releases/latest") else {
            status = .failed(message: "Invalid GitHub URL")
            return
        }

        do {
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                status = .failed(message: "GitHub API returned an error")
                return
            }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)

            // Parse version from tag like "v.0.3" or "v0.3" → "0.3"
            let remoteVersion = release.tagName
                .replacingOccurrences(of: "v.", with: "")
                .replacingOccurrences(of: "v", with: "")

            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

            if remoteVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                // Find the zip asset
                if let zipAsset = release.assets.first(where: { $0.name.hasSuffix(".zip") }) {
                    pendingDownloadURL = URL(string: zipAsset.browserDownloadURL)
                    pendingAssetSize = zipAsset.size
                    status = .updateAvailable(version: remoteVersion)
                } else {
                    status = .failed(message: "No zip asset found in release")
                }
            } else {
                status = .noUpdate
            }

            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastUpdateCheck")
        } catch {
            status = .failed(message: error.localizedDescription)
        }
    }

    // MARK: - Download

    func downloadUpdate() async {
        guard let downloadURL = pendingDownloadURL else {
            status = .failed(message: "No download URL available")
            return
        }

        status = .downloading(progress: 0)

        do {
            let request = URLRequest(url: downloadURL)
            let (bytes, response) = try await URLSession.shared.bytes(for: request)

            let totalSize = pendingAssetSize ?? Int(response.expectedContentLength)
            let tempDir = FileManager.default.temporaryDirectory
            let zipPath = tempDir.appendingPathComponent("Bufferfly-update.zip")

            // Remove old download if exists
            try? FileManager.default.removeItem(at: zipPath)

            var data = Data()
            data.reserveCapacity(totalSize)

            for try await byte in bytes {
                data.append(byte)

                let progress = Double(data.count) / Double(totalSize)
                // Throttle UI updates
                if Int(progress * 100) != Int((Double(data.count - 1) / Double(totalSize)) * 100) {
                    status = .downloading(progress: min(progress, 1.0))
                }
            }

            try data.write(to: zipPath)
            downloadedZipPath = zipPath
            status = .readyToInstall
        } catch {
            status = .failed(message: "Download failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Install

    func installUpdate() {
        guard let zipPath = downloadedZipPath else {
            status = .failed(message: "No downloaded file found")
            return
        }

        status = .installing

        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("Bufferfly-extracted")

        do {
            // Clean extraction directory
            try? fileManager.removeItem(at: tempDir)
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

            // Unzip using ditto
            let unzipProcess = Process()
            unzipProcess.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            unzipProcess.arguments = ["-xk", zipPath.path, tempDir.path]
            try unzipProcess.run()
            unzipProcess.waitUntilExit()

            guard unzipProcess.terminationStatus == 0 else {
                status = .failed(message: "Failed to extract update")
                return
            }

            // Find the .app in extracted directory
            let contents = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            guard let newApp = contents.first(where: { $0.pathExtension == "app" }) else {
                status = .failed(message: "No .app found in archive")
                return
            }

            // Current app path
            let currentAppURL = Bundle.main.bundleURL
            let appName = currentAppURL.lastPathComponent
            let parentDir = currentAppURL.deletingLastPathComponent()
            let destinationURL = parentDir.appendingPathComponent(appName)

            // Trash the current app
            try fileManager.trashItem(at: currentAppURL, resultingItemURL: nil)

            // Copy new app
            try fileManager.copyItem(at: newApp, to: destinationURL)

            // Remove quarantine attribute
            let xattrProcess = Process()
            xattrProcess.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
            xattrProcess.arguments = ["-cr", destinationURL.path]
            try xattrProcess.run()
            xattrProcess.waitUntilExit()

            // Cleanup temp files
            try? fileManager.removeItem(at: zipPath)
            try? fileManager.removeItem(at: tempDir)

            // Relaunch
            let relaunchPath = destinationURL.path
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/sh")
            task.arguments = ["-c", "sleep 1 && open \"\(relaunchPath)\""]
            try task.run()

            NSApp.terminate(nil)
        } catch {
            status = .failed(message: "Install failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Background Auto-Check

    func backgroundAutoCheck() async {
        let autoUpdate = UserDefaults.standard.bool(forKey: "autoUpdate")

        // Default to true if key was never set
        if UserDefaults.standard.object(forKey: "autoUpdate") == nil {
            UserDefaults.standard.set(true, forKey: "autoUpdate")
        }

        guard autoUpdate || UserDefaults.standard.object(forKey: "autoUpdate") == nil else { return }

        let lastCheck = UserDefaults.standard.double(forKey: "lastUpdateCheck")
        let hoursSinceLastCheck = (Date().timeIntervalSince1970 - lastCheck) / 3600

        guard hoursSinceLastCheck >= 24 else { return }

        await checkForUpdate()

        if case .updateAvailable = status {
            await downloadUpdate()
        }
    }
}
