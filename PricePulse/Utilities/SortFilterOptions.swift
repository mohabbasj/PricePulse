import Foundation

enum SortOption: String, CaseIterable, Identifiable, Hashable {
    case recentlyUpdated
    case newest
    case oldest
    case alphabetical
    case priceLowToHigh
    case priceHighToLow
    case biggestDiscount
    case store

    var id: String { rawValue }

    var label: String {
        switch self {
        case .recentlyUpdated: return "Recently Updated"
        case .newest: return "Newest"
        case .oldest: return "Oldest"
        case .alphabetical: return "Alphabetical"
        case .priceLowToHigh: return "Price: Low to High"
        case .priceHighToLow: return "Price: High to Low"
        case .biggestDiscount: return "Biggest Discount"
        case .store: return "Store"
        }
    }

    var systemImage: String {
        switch self {
        case .recentlyUpdated: return "clock.arrow.circlepath"
        case .newest: return "sparkles"
        case .oldest: return "hourglass"
        case .alphabetical: return "textformat"
        case .priceLowToHigh: return "arrow.up.circle"
        case .priceHighToLow: return "arrow.down.circle"
        case .biggestDiscount: return "tag.fill"
        case .store: return "storefront"
        }
    }
}

enum FilterOption: String, CaseIterable, Identifiable, Hashable {
    case all
    case onSale
    case priceIncreased
    case outOfStock
    case available

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All"
        case .onSale: return "Current Discounts"
        case .priceIncreased: return "Price Increased"
        case .outOfStock: return "Out of Stock"
        case .available: return "Available"
        }
    }

    var systemImage: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .onSale: return "arrow.down.right.circle.fill"
        case .priceIncreased: return "arrow.up.right.circle.fill"
        case .outOfStock: return "xmark.circle.fill"
        case .available: return "checkmark.circle.fill"
        }
    }

    func matches(_ product: TrackedProduct) -> Bool {
        switch self {
        case .all: return true
        case .onSale: return product.isOnSale
        case .priceIncreased: return product.isPriceIncrease
        case .outOfStock: return product.availability == .outOfStock
        case .available: return product.availability == .inStock
        }
    }
}
