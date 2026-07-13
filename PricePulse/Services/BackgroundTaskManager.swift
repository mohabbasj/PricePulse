import BackgroundTasks
import Foundation
import SwiftData

/// Wraps `BGTaskScheduler` so PricePulse can keep checking prices after the app is
/// backgrounded or closed, within the execution budget iOS grants background refresh tasks.
@MainActor
final class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    static let refreshTaskIdentifier = "com.pricepulse.refresh"

    private var modelContainer: ModelContainer?

    private init() {}

    func configure(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    /// Must be called before `application(_:didFinishLaunchingWithOptions:)` returns.
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.refreshTaskIdentifier, using: nil) { [weak self] task in
            guard let appRefreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            Task { @MainActor in
                await self?.handleAppRefresh(task: appRefreshTask)
            }
        }
    }

    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: AppSettings.backgroundRefreshInterval.timeInterval)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            AppLogger.background.error("Failed to schedule background refresh: \(error.localizedDescription)")
        }
    }

    private func handleAppRefresh(task: BGAppRefreshTask) async {
        // Always schedule the next refresh first so a failure below doesn't stop future checks.
        scheduleAppRefresh()

        guard let modelContainer else {
            task.setTaskCompleted(success: false)
            return
        }

        let context = ModelContext(modelContainer)
        let refreshWork = Task {
            let descriptor = FetchDescriptor<TrackedProduct>()
            guard let products = try? context.fetch(descriptor) else { return }
            await ProductMonitorService.shared.refreshAll(products: products, context: context)
        }

        task.expirationHandler = {
            refreshWork.cancel()
        }

        await refreshWork.value
        task.setTaskCompleted(success: !refreshWork.isCancelled)
    }
}
