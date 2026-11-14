import MailKit

final class ComposeSessionHandler: NSObject, MEComposeSessionHandler {
    func mailComposeSessionDidBegin(_ session: MEComposeSession) {
        // No-op: table builder is stateless per session.
    }

    func mailComposeSessionDidEnd(_ session: MEComposeSession) {
        // No-op
    }

    func viewController(for session: MEComposeSession) -> MEExtensionViewController {
        TableBuilderViewController()
    }
}
