import Foundation
import UserNotifications

/// Owns every user-facing notification PricePulse sends: authorization, and composing
/// the four alert types (price drop, price increase, back in stock, out of stock).
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    func notifyPriceChange(for product: TrackedProduct, previousPrice: Decimal, newPrice: Decimal, currency: String) async {
        let isDecrease = newPrice < previousPrice
        if isDecrease, !AppSettings.priceDropNotificationsEnabled { return }
        if !isDecrease, !AppSettings.priceIncreaseNotificationsEnabled { return }

        let percentChange = previousPrice == 0 ? 0 : abs((NSDecimalNumber(decimal: newPrice - previousPrice).doubleValue / NSDecimalNumber(decimal: previousPrice).doubleValue) * 100)
        let previousFormatted = previousPrice.formatted(.currency(code: currency))
        let newFormatted = newPrice.formatted(.currency(code: currency))
        let sign = isDecrease ? "\u{2212}" : "+"

        let content = UNMutableNotificationContent()
        content.title = isDecrease ? "\u{2B07}\u{FE0F} Price Drop" : "\u{2B06}\u{FE0F} Price Increase"
        content.body = "\(product.title)\n\(previousFormatted) \u{2192} \(newFormatted)\n\(sign)\(String(format: "%.0f", percentChange))%"
        content.sound = .default
        content.userInfo = ["productID": product.id.uuidString]

        await schedule(content: content)
    }

    func notifyAvailabilityChange(for product: TrackedProduct, newStatus: Availability) async {
        guard newStatus != .unknown else { return }
        if newStatus == .inStock, !AppSettings.backInStockNotificationsEnabled { return }
        if newStatus == .outOfStock, !AppSettings.outOfStockNotificationsEnabled { return }

        let content = UNMutableNotificationContent()
        content.title = newStatus == .inStock ? "\u{2705} Back in Stock" : "\u{26D4}\u{FE0F} Out of Stock"
        content.body = product.title
        content.sound = .default
        content.userInfo = ["productID": product.id.uuidString]

        await schedule(content: content)
    }

    private func schedule(content: UNMutableNotificationContent) async {
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try? await center.add(request)
    }
}
