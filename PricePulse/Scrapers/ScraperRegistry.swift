import Foundation

/// Central lookup used by the rest of the app to find the right adapter for a pasted URL.
/// To support a new store, implement `ProductScraper` in its own file and add an instance
/// to `allScrapers` below — nothing else in the app needs to change.
final class ScraperRegistry: Sendable {
    static let shared = ScraperRegistry()

    let allScrapers: [any ProductScraper]
    private let fallback: any ProductScraper

    init(
        scrapers: [any ProductScraper] = [
            AmazonScraper(),
            AdidasScraper(),
            AppleScraper(),
            NikeScraper(),
            BestBuyScraper()
        ],
        fallback: any ProductScraper = GenericScraper()
    ) {
        self.allScrapers = scrapers
        self.fallback = fallback
    }

    func scraper(for url: URL) -> any ProductScraper {
        allScrapers.first { $0.supports(url: url) } ?? fallback
    }
}
