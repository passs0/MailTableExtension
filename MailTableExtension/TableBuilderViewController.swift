import MailKit
import SwiftUI

final class TableBuilderViewController: MEExtensionViewController {
    override func loadView() {
        let hostingView = NSHostingView(rootView: TableBuilderView())
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        self.view = hostingView
        self.preferredContentSize = NSSize(width: 520, height: 400)
    }
}
