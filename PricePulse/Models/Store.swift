import SwiftUI

enum Store: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case amazon
    case adidas
    case apple
    case nike
    case bestBuy
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .amazon: return "Amazon"
        case .adidas: return "Adidas"
        case .apple: return "Apple"
        case .nike: return "Nike"
        case .bestBuy: return "Best Buy"
        case .other: return "Other"
        }
    }

    var iconSystemName: String {
        switch self {
        case .amazon: return "cart.fill"
        case .adidas: return "figure.run"
        case .apple: return "apple.logo"
        case .nike: return "checkmark.seal.fill"
        case .bestBuy: return "tag.fill"
        case .other: return "storefront.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .amazon: return .orange
        case .adidas: return .black
        case .apple: return .gray
        case .nike: return .red
        case .bestBuy: return .blue
        case .other: return .purple
        }
    }

    /// Matches hostnames (and their subdomains) to a known store.
    static func detect(from url: URL) -> Store {
        guard let host = url.host?.lowercased() else { return .other }
        if host.contains("amazon.") { return .amazon }
        if host.contains("adidas.") { return .adidas }
        if host.contains("apple.com") { return .apple }
        if host.contains("nike.") { return .nike }
        if host.contains("bestbuy.") { return .bestBuy }
        return .other
    }
}
