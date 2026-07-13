import Foundation
import SwiftData

/// Owns the SwiftData schema and builds the single `ModelContainer` shared by the app,
/// the background refresh task, and previews.
enum PersistenceController {
    static let schema = Schema([
        TrackedProduct.self,
        PriceHistory.self,
        AvailabilityHistory.self
    ])

    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let configuration = ModelConfiguration(
            "PricePulse",
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
    }

    @MainActor
    static var preview: ModelContainer = {
        let container = makeContainer(inMemory: true)
        let context = container.mainContext

        let sample = TrackedProduct(
            title: "PlayStation 5 DualSense Wireless Controller",
            url: URL(string: "https://www.amazon.com/dp/B0BCJPMK5S")!,
            store: .amazon,
            imageURL: URL(string: "https://m.media-amazon.com/images/I/51i9UkokvSL._SL1500_.jpg"),
            currency: "SAR",
            currentPrice: 239,
            previousPrice: 279,
            availability: .inStock
        )
        context.insert(sample)
        context.insert(PriceHistory(price: 279, currency: "SAR", date: .now.addingTimeInterval(-86_400 * 6), product: sample))
        context.insert(PriceHistory(price: 259, currency: "SAR", date: .now.addingTimeInterval(-86_400 * 3), product: sample))
        context.insert(PriceHistory(price: 239, currency: "SAR", date: .now, product: sample))
        context.insert(AvailabilityHistory(status: .inStock, date: .now.addingTimeInterval(-86_400 * 6), product: sample))

        return container
    }()
}
