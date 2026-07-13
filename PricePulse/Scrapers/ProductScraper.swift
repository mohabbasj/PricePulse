import Foundation

/// Conform to this protocol to teach PricePulse how to read products from a new store.
/// Adding support for a new store never requires touching any other file: implement
/// `supports(url:)` and `fetchProduct(from:)`, then register the instance in
/// `ScraperRegistry.allScrapers`.
protocol ProductScraper: Sendable {
    /// The store this scraper knows how to read.
    var store: Store { get }

    /// Whether this scraper can handle product pages at the given URL.
    func supports(url: URL) -> Bool

    /// Fetches and parses the live product data at the given URL.
    func fetchProduct(from url: URL) async throws -> ScrapedProduct
}
