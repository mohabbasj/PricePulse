import Foundation

/// Catch-all adapter used when no store-specific scraper claims a URL. Relies entirely on
/// JSON-LD structured data and Open Graph / generic meta tags, which cover a large share of
/// commerce sites out of the box. This is what lets PricePulse track "unlimited future
/// stores" without a dedicated adapter for every single one, while still allowing a proper
/// adapter to be dropped in later for better accuracy.
struct GenericScraper: ProductScraper {
    let store: Store = .other

    private static let engine = SelectorScrapingEngine(
        store: .other,
        config: SelectorConfig(
            titleSelectors: ["h1", "[itemprop='name']"],
            priceSelectors: [
                "[itemprop='price']",
                ".price",
                ".product-price",
                "[data-testid*='price']",
                "[class*='price']"
            ],
            imageSelectors: ["[itemprop='image']", "picture img", "img"],
            availabilitySelectors: ["[itemprop='availability']", ".availability", ".stock-status"],
            outOfStockKeywords: ["sold out", "out of stock", "unavailable", "notify me"]
        )
    )

    func supports(url: URL) -> Bool { true }

    func fetchProduct(from url: URL) async throws -> ScrapedProduct {
        let document = try await HTMLDocumentLoader.loadDocument(url: url) { Self.engine.needsRendering(document: $0) }
        let scraped = try Self.engine.scrape(document: document, url: url)
        return ScrapedProduct(
            title: scraped.title,
            url: scraped.url,
            store: Store.detect(from: url),
            price: scraped.price,
            currency: scraped.currency,
            availability: scraped.availability,
            imageURL: scraped.imageURL
        )
    }
}
