import Foundation

/// Adapter for adidas.com storefronts. Adidas product pages are largely client-rendered,
/// so this adapter leans heavily on the `WKWebView` fallback inside `HTMLDocumentLoader`.
struct AdidasScraper: ProductScraper {
    let store: Store = .adidas

    private static let engine = SelectorScrapingEngine(
        store: .adidas,
        config: SelectorConfig(
            titleSelectors: ["h1[data-testid='product-title']", "h1.product-title"],
            priceSelectors: [
                "[data-testid='gl-price-item']",
                "[data-testid='main-price']",
                "div.gl-price-item"
            ],
            imageSelectors: ["img[data-testid='product-image']", "picture img"],
            availabilitySelectors: ["[data-testid='add-to-bag']", "button[data-testid='availability-message']"],
            outOfStockKeywords: ["sold out", "out of stock", "notify me"]
        )
    )

    func supports(url: URL) -> Bool {
        url.host?.lowercased().contains("adidas.") ?? false
    }

    func fetchProduct(from url: URL) async throws -> ScrapedProduct {
        let document = try await HTMLDocumentLoader.loadDocument(url: url) { Self.engine.needsRendering(document: $0) }
        return try Self.engine.scrape(document: document, url: url)
    }
}
