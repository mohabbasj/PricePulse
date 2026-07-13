import Foundation

/// The immutable result of scraping a store's product page at a point in time.
struct ScrapedProduct: Sendable, Equatable {
    let title: String
    let url: URL
    let store: Store
    let price: Decimal
    let currency: String
    let availability: Availability
    let imageURL: URL?
}
