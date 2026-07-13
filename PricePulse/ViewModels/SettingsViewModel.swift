import Foundation
import Observation
import UIKit
import UserNotifications

@MainActor
@Observable
final class SettingsViewModel {
    var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationAuthorizationStatus = settings.authorizationStatus
    }

    func requestNotificationAuthorization() async {
        _ = await NotificationManager.shared.requestAuthorizationIfNeeded()
        await refreshAuthorizationStatus()
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
