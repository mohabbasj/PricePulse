import Foundation

/// Adapter for nike.com product pages, which typically embed a schema.org "Product"
/// JSON-LD block, so the shared engine can usually resolve this without a rendered fallback.
struct NikeScraper: ProductScraper {
    let store: Store = .nike

    private static let engine = SelectorScrapingEngine(
        store: .nike,
        config: SelectorConfig(
            titleSelectors: ["h1#pdp_product_title", "h1[data-testid='product_title']"],
            priceSelectors: [
                "[data-testid='currentPrice-container']",
                "div.product-price",
                "[data-testid='OriginalPrice-container']"
            ],
            imageSelectors: ["img[data-testid='HeroImg']", "picture img"],
            availabilitySelectors: ["button[data-testid='add-to-cart-btn']", "div.inventory-message"],
            outOfStockKeywords: ["sold out", "out of stock", "unavailable"]
        )
    )

    func supports(url: URL) -> Bool {
        url.host?.lowercased().contains("nike.") ?? false
    }

    func fetchProduct(from url: URL) async throws -> ScrapedProduct {
        let document = try await HTMLDocumentLoader.loadDocument(url: url) { Self.engine.needsRendering(document: $0) }
        return try Self.engine.scrape(document: document, url: url)
    }
}
