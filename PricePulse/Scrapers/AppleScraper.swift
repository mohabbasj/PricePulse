import Foundation

/// Adapter for apple.com product pages.
struct AppleScraper: ProductScraper {
    let store: Store = .apple

    private static let engine = SelectorScrapingEngine(
        store: .apple,
        config: SelectorConfig(
            titleSelectors: ["h1.pd-hero-title", "h1.rf-pdp-title", "h1"],
            priceSelectors: [
                ".rc-prices-fullprice",
                ".pd-price-currentprice",
                ".rf-pdp-currentprice",
                "[data-autom='price-current']"
            ],
            imageSelectors: ["picture img", "img.pd-hero-image"],
            availabilitySelectors: ["[data-autom='shipping-status']", ".as-purchaseinfo-shipmessage"],
            outOfStockKeywords: ["unavailable", "out of stock", "currently unavailable", "sold out"]
        )
    )

    func supports(url: URL) -> Bool {
        url.host?.lowercased().contains("apple.com") ?? false
    }

    func fetchProduct(from url: URL) async throws -> ScrapedProduct {
        let document = try await HTMLDocumentLoader.loadDocument(url: url) { Self.engine.needsRendering(document: $0) }
        return try Self.engine.scrape(document: document, url: url)
    }
}
