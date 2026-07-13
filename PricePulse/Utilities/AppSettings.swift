import Foundation
import SwiftUI

enum BackgroundRefreshInterval: Int, CaseIterable, Identifiable {
    case fifteenMinutes = 900
    case thirtyMinutes = 1_800
    case oneHour = 3_600
    case threeHours = 10_800
    case sixHours = 21_600

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .fifteenMinutes: return "15 Minutes"
        case .thirtyMinutes: return "30 Minutes"
        case .oneHour: return "1 Hour"
        case .threeHours: return "3 Hours"
        case .sixHours: return "6 Hours"
        }
    }

    var timeInterval: TimeInterval { TimeInterval(rawValue) }
}

enum AppColorScheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Thin, testable wrapper around `UserDefaults` for every user-facing preference.
/// Views read/write these through `@AppStorage` using the same keys, so `AppSettings`
/// stays the single source of truth for key names and defaults.
@MainActor
enum AppSettings {
    enum Keys {
        static let priceDropNotifications = "settings.priceDropNotifications"
        static let priceIncreaseNotifications = "settings.priceIncreaseNotifications"
        static let backInStockNotifications = "settings.backInStockNotifications"
        static let outOfStockNotifications = "settings.outOfStockNotifications"
        static let backgroundRefreshInterval = "settings.backgroundRefreshInterval"
        static let colorScheme = "settings.colorScheme"
    }

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Keys.priceDropNotifications: true,
            Keys.priceIncreaseNotifications: true,
            Keys.backInStockNotifications: true,
            Keys.outOfStockNotifications: true,
            Keys.backgroundRefreshInterval: BackgroundRefreshInterval.oneHour.rawValue,
            Keys.colorScheme: AppColorScheme.system.rawValue
        ])
    }

    static var backgroundRefreshInterval: BackgroundRefreshInterval {
        let raw = UserDefaults.standard.integer(forKey: Keys.backgroundRefreshInterval)
        return BackgroundRefreshInterval(rawValue: raw) ?? .oneHour
    }

    static var priceDropNotificationsEnabled: Bool {
        UserDefaults.standard.bool(forKey: Keys.priceDropNotifications)
    }

    static var priceIncreaseNotificationsEnabled: Bool {
        UserDefaults.standard.bool(forKey: Keys.priceIncreaseNotifications)
    }

    static var backInStockNotificationsEnabled: Bool {
        UserDefaults.standard.bool(forKey: Keys.backInStockNotifications)
    }

    static var outOfStockNotificationsEnabled: Bool {
        UserDefaults.standard.bool(forKey: Keys.outOfStockNotifications)
    }
}
