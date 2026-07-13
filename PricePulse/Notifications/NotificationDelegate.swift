import Foundation
import UserNotifications

/// Routes notification interactions while the app is running. Foreground notifications
/// are still shown as banners, and tapping any PricePulse notification deep-links into
/// that product's detail screen via `DeepLinkRouter`.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, Sendable {
    static let shared = NotificationDelegate()

    private override init() {}

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard
            let idString = response.notification.request.content.userInfo["productID"] as? String,
            let id = UUID(uuidString: idString)
        else { return }

        await MainActor.run {
            DeepLinkRouter.shared.pendingProductID = id
        }
    }
}
