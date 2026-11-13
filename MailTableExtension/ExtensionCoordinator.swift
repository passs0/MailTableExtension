import MailKit

class ExtensionCoordinator: NSObject, MEExtension {
    func handler(for composeSession: MEComposeSession) -> MEComposeSessionHandler {
        ComposeSessionHandler()
    }
}
