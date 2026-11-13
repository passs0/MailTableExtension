import SwiftUI

@main
struct MailTableHostApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(alignment: .leading, spacing: 14) {
                Label("Mail Table Builder", systemImage: "tablecells")
                    .font(.title2.bold())

                Text("To enable the extension inside Apple Mail:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    Text("1. Open Apple Mail.")
                    Text("2. Go to Mail → Settings → Extensions.")
                    Text("3. Enable MailTableExtension.")
                    Text("4. Open a New Message and click the table icon in the compose toolbar.")
                }
                .font(.callout)

                Divider()

                Text("You can also build and copy tables directly here:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TableBuilderView()
            }
            .padding(18)
            .frame(minWidth: 500, minHeight: 460)
        }
    }
}
