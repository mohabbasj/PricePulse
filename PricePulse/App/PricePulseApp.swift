import SwiftData
import SwiftUI

@main
@MainActor
struct PricePulseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage(AppSettings.Keys.colorScheme) private var colorSchemeRaw = AppColorScheme.system.rawValue

    private let modelContainer: ModelContainer
    private let deepLinkRouter = DeepLinkRouter.shared

    init() {
        modelContainer = PersistenceController.makeContainer()
        BackgroundTaskManager.shared.configure(modelContainer: modelContainer)
        AppSettings.registerDefaults()

        URLCache.shared = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(deepLinkRouter)
                .preferredColorScheme(AppColorScheme(rawValue: colorSchemeRaw)?.colorScheme)
                .task {
                    await NotificationManager.shared.requestAuthorizationIfNeeded()
                    BackgroundTaskManager.shared.scheduleAppRefresh()
                }
        }
        .modelContainer(modelContainer)
    }
}
