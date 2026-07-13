import Foundation

/// Adapter for bestbuy.com product pages, which publish schema.org "Product" JSON-LD
/// with accurate pricing and availability.
struct BestBuyScraper: ProductScraper {
    let store: Store = .bestBuy

    private static let engine = SelectorScrapingEngine(
        store: .bestBuy,
        config: SelectorConfig(
            titleSelectors: ["h1.heading-5", ".sku-title h1"],
            priceSelectors: [
                "div.priceView-hero-price span[aria-hidden='true']",
                ".priceView-customer-price span"
            ],
            imageSelectors: ["img.primary-image", "picture img"],
            availabilitySelectors: ["button.add-to-cart-button", "div.fulfillment-add-to-cart-button"],
            outOfStockKeywords: ["sold out", "out of stock", "coming soon", "unavailable"]
        )
    )

    func supports(url: URL) -> Bool {
        url.host?.lowercased().contains("bestbuy.") ?? false
    }

    func fetchProduct(from url: URL) async throws -> ScrapedProduct {
        let document = try await HTMLDocumentLoader.loadDocument(url: url) { Self.engine.needsRendering(document: $0) }
        return try Self.engine.scrape(document: document, url: url)
    }
}
