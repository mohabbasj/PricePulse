import Foundation
import SwiftData

@Model
final class TrackedProduct: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var url: URL
    var storeRawValue: String
    var imageURL: URL?
    var currency: String
    var currentPrice: Decimal
    var previousPrice: Decimal?
    var availabilityRawValue: String
    var lastChecked: Date
    var createdAt: Date
    var updatedAt: Date
    var lastError: String?
    var isRefreshing: Bool

    @Relationship(deleteRule: .cascade, inverse: \PriceHistory.product)
    var priceHistory: [PriceHistory] = []

    @Relationship(deleteRule: .cascade, inverse: \AvailabilityHistory.product)
    var availabilityHistory: [AvailabilityHistory] = []

    init(
        id: UUID = UUID(),
        title: String,
        url: URL,
        store: Store,
        imageURL: URL?,
        currency: String,
        currentPrice: Decimal,
        previousPrice: Decimal? = nil,
        availability: Availability,
        lastChecked: Date = .now,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.storeRawValue = store.rawValue
        self.imageURL = imageURL
        self.currency = currency
        self.currentPrice = currentPrice
        self.previousPrice = previousPrice
        self.availabilityRawValue = availability.rawValue
        self.lastChecked = lastChecked
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastError = nil
        self.isRefreshing = false
    }

    var store: Store {
        get { Store(rawValue: storeRawValue) ?? .other }
        set { storeRawValue = newValue.rawValue }
    }

    var availability: Availability {
        get { Availability(rawValue: availabilityRawValue) ?? .unknown }
        set { availabilityRawValue = newValue.rawValue }
    }

    /// Difference between the current price and the previous price. Positive means the price rose.
    var priceDifference: Decimal? {
        guard let previousPrice else { return nil }
        return currentPrice - previousPrice
    }

    var priceChangePercentage: Double? {
        guard let previousPrice, previousPrice != 0, let difference = priceDifference else { return nil }
        return (NSDecimalNumber(decimal: difference).doubleValue / NSDecimalNumber(decimal: previousPrice).doubleValue) * 100
    }

    var isOnSale: Bool {
        guard let priceDifference else { return false }
        return priceDifference < 0
    }

    var isPriceIncrease: Bool {
        guard let priceDifference else { return false }
        return priceDifference > 0
    }

    var lowestPrice: Decimal {
        priceHistory.map(\.price).min() ?? currentPrice
    }

    var highestPrice: Decimal {
        priceHistory.map(\.price).max() ?? currentPrice
    }

    var averagePrice: Decimal {
        guard !priceHistory.isEmpty else { return currentPrice }
        let total = priceHistory.reduce(Decimal(0)) { $0 + $1.price }
        return total / Decimal(priceHistory.count)
    }

    var sortedPriceHistory: [PriceHistory] {
        priceHistory.sorted { $0.date < $1.date }
    }

    var sortedAvailabilityHistory: [AvailabilityHistory] {
        availabilityHistory.sorted { $0.date > $1.date }
    }
}
