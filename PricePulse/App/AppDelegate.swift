import BackgroundTasks
import UIKit
import UserNotifications

/// `BGTaskScheduler` requires its handler to be registered before
/// `application(_:didFinishLaunchingWithOptions:)` returns, which the SwiftUI `App`
/// lifecycle alone can't guarantee early enough — hence this small `UIApplicationDelegate`
/// bridge, wired in via `@UIApplicationDelegateAdaptor`.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        BackgroundTaskManager.shared.registerBackgroundTasks()
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        BackgroundTaskManager.shared.scheduleAppRefresh()
    }
}
