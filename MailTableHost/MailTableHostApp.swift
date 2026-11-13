import SwiftUI

/// Minimal host container required by macOS to register TabulateExtension.appex.
@main
struct TabulateApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(alignment: .leading, spacing: 10) {
                Label("Tabulate", systemImage: "table")
                    .font(.title2.bold())
                Text("Enable Tabulate in Mail → Settings → Extensions, then click the table icon in any compose window.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            .frame(width: 360)
        }
        .windowResizability(.contentSize)
    }
}
