import AppKit
import SwiftUI

/// Host container app for CellmateExtension.appex with Apple-style onboarding and an embedded playground.
@main
struct CellmateApp: App {
    private enum Section: String, CaseIterable, Identifiable {
        case setup = "Setup"
        case playground = "Playground"

        var id: String { rawValue }

        var symbolName: String {
            switch self {
            case .setup: return "gearshape"
            case .playground: return "tablecells"
            }
        }
    }

    @State private var section: Section = .setup

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 0) {
                topBar
                Divider()

                if section == .setup {
                    setupView
                } else {
                    TableBuilderView()
                }
            }
            .frame(width: 560, height: 470)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text("Cellmate")
                    .font(.headline)
                Text("Tables for Apple Mail")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Picker("", selection: $section) {
                ForEach(Section.allCases) { item in
                    Label(item.rawValue, systemImage: item.symbolName)
                        .tag(item)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 210)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }

    private var setupView: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 8)

            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 84, height: 84)
                .shadow(color: .black.opacity(0.12), radius: 10, y: 4)

            VStack(spacing: 4) {
                Text("Welcome to Cellmate")
                    .font(.title2.bold())
                Text("Build crisp, native tables right inside Apple Mail's compose toolbar.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 12) {
                setupStep(
                    number: "1",
                    symbol: "envelope.fill",
                    title: "Open Mail Settings",
                    detail: "Go to Mail → Settings → Extensions."
                )
                Divider()
                setupStep(
                    number: "2",
                    symbol: "puzzlepiece.extension.fill",
                    title: "Enable Cellmate",
                    detail: "Check Cellmate in the extensions list."
                )
                Divider()
                setupStep(
                    number: "3",
                    symbol: "tablecells",
                    title: "Insert Anywhere",
                    detail: "Click the table icon in any compose toolbar, copy (⌘↩), and paste (⌘V)."
                )
            }
            .padding(14)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 0.75)
            )
            .padding(.horizontal, 28)

            HStack(spacing: 12) {
                Button {
                    section = .playground
                } label: {
                    Label("Try Playground", systemImage: "tablecells")
                }
                .buttonStyle(.bordered)

                Button {
                    openAppleMail()
                } label: {
                    Label("Open Apple Mail", systemImage: "arrow.up.forward.app")
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer(minLength: 8)
        }
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func setupStep(number: String, symbol: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 30, height: 30)
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("\(number). \(title)")
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private func openAppleMail() {
        guard let mailURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.mail") else {
            return
        }
        NSWorkspace.shared.openApplication(
            at: mailURL,
            configuration: NSWorkspace.OpenConfiguration()
        )
    }
}
