import SwiftUI

enum Availability: String, Codable, CaseIterable, Identifiable, Sendable {
    case inStock
    case outOfStock
    case unknown

    var id: String { rawValue }

    var label: String {
        switch self {
        case .inStock: return "In Stock"
        case .outOfStock: return "Out of Stock"
        case .unknown: return "Unknown"
        }
    }

    var systemImage: String {
        switch self {
        case .inStock: return "checkmark.circle.fill"
        case .outOfStock: return "xmark.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .inStock: return .green
        case .outOfStock: return .red
        case .unknown: return .secondary
        }
    }
}
