import Foundation

/// Adapter for amazon.com and its regional TLDs (amazon.sa, amazon.ae, amazon.co.uk, ...).
struct AmazonScraper: ProductScraper {
    let store: Store = .amazon

    private static let engine = SelectorScrapingEngine(
        store: .amazon,
        config: SelectorConfig(
            titleSelectors: ["#productTitle"],
            priceSelectors: [
                ".a-price .a-offscreen",
                "#corePrice_feature_div .a-offscreen",
                "#priceblock_ourprice",
                "#priceblock_dealprice",
                "#tp_price_block_total_price_ww .a-offscreen"
            ],
            imageSelectors: ["#landingImage", "#imgBlkFront", "#main-image"],
            availabilitySelectors: ["#availability span", "#availability"],
            outOfStockKeywords: ["currently unavailable", "out of stock", "unavailable"]
        )
    )

    func supports(url: URL) -> Bool {
        url.host?.lowercased().contains("amazon.") ?? false
    }

    func fetchProduct(from url: URL) async throws -> ScrapedProduct {
        let document = try await HTMLDocumentLoader.loadDocument(url: url) { Self.engine.needsRendering(document: $0) }
        return try Self.engine.scrape(document: document, url: url)
    }
}
