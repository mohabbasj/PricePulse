import Foundation
import SwiftSoup

/// Declarative description of where a store hides its product data in the DOM.
/// Every store adapter provides one of these; the actual parsing logic lives once,
/// in `SelectorScrapingEngine`, so new stores never need to duplicate parsing code.
struct SelectorConfig: Sendable {
    let titleSelectors: [String]
    let priceSelectors: [String]
    let imageSelectors: [String]
    let availabilitySelectors: [String]
    let outOfStockKeywords: [String]
}

/// Combines JSON-LD structured data with store-specific CSS selectors to build a
/// `ScrapedProduct`. JSON-LD (when present) is trusted first since it's machine-readable
/// and less likely to break when a store restyles its page; CSS selectors are the fallback.
struct SelectorScrapingEngine: Sendable {
    let store: Store
    let config: SelectorConfig

    func scrape(document: Document, url: URL) throws -> ScrapedProduct {
        let jsonLD = ScraperUtilities.extractJSONLDProduct(from: document)

        guard let title = resolveTitle(document: document, jsonLD: jsonLD) else {
            throw ProductScrapingError.parsingFailed("No product title found on this page.")
        }

        let priceText = ScraperUtilities.firstNonEmptyText(document, selectors: config.priceSelectors)
        guard let price = jsonLD?.price ?? priceText.flatMap(ScraperUtilities.parsePrice(from:)) else {
            throw ProductScrapingError.priceNotFound
        }

        let currency = jsonLD?.currency ?? priceText.map { ScraperUtilities.detectCurrency(from: $0) } ?? "USD"
        let imageURL = resolveImageURL(document: document, jsonLD: jsonLD)
        let availability = resolveAvailability(document: document, jsonLD: jsonLD)

        return ScrapedProduct(
            title: title,
            url: url,
            store: store,
            price: price,
            currency: currency,
            availability: availability,
            imageURL: imageURL
        )
    }

    func needsRendering(document: Document) -> Bool {
        let hasSelectorPrice = ScraperUtilities.firstNonEmptyText(document, selectors: config.priceSelectors) != nil
        let hasJSONLDPrice = ScraperUtilities.extractJSONLDProduct(from: document)?.price != nil
        return !hasSelectorPrice && !hasJSONLDPrice
    }

    private func resolveTitle(document: Document, jsonLD: ScraperUtilities.JSONLDProduct?) -> String? {
        if let title = jsonLD?.title, !title.isEmpty { return title }
        if let title = ScraperUtilities.firstNonEmptyText(document, selectors: config.titleSelectors) { return title }
        if let title = ScraperUtilities.openGraphContent(document, property: "og:title") { return title }
        return nil
    }

    private func resolveImageURL(document: Document, jsonLD: ScraperUtilities.JSONLDProduct?) -> URL? {
        if let imageURL = jsonLD?.imageURL { return imageURL }
        if let src = ScraperUtilities.firstAttribute(document, selectors: config.imageSelectors, attribute: "src") {
            return URL(string: src)
        }
        if let src = ScraperUtilities.firstAttribute(document, selectors: config.imageSelectors, attribute: "data-src") {
            return URL(string: src)
        }
        if let og = ScraperUtilities.openGraphContent(document, property: "og:image") {
            return URL(string: og)
        }
        return nil
    }

    private func resolveAvailability(document: Document, jsonLD: ScraperUtilities.JSONLDProduct?) -> Availability {
        if let availability = jsonLD?.availability, availability != .unknown {
            return availability
        }
        guard let text = ScraperUtilities.firstNonEmptyText(document, selectors: config.availabilitySelectors)?.lowercased() else {
            return .unknown
        }
        for keyword in config.outOfStockKeywords where text.contains(keyword) {
            return .outOfStock
        }
        return .inStock
    }
}
