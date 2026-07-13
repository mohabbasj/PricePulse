import Foundation
import SwiftData

enum RefreshOutcome {
    case updated(priceChanged: Bool, availabilityChanged: Bool)
    case unchanged
    case failed(ProductScrapingError)
}

/// Orchestrates the full lifecycle of a tracked product: fetching a preview for the Add
/// Product screen, saving a new product with its first price point, and refreshing an
/// existing product by comparing freshly scraped data against what's stored.
///
/// This is the one place price-history and availability-history rows get written, so
/// every code path (pull-to-refresh, manual refresh, background task) shares identical
/// "detect change -> persist -> notify" behavior.
@MainActor
final class ProductMonitorService {
    static let shared = ProductMonitorService()

    private let registry: ScraperRegistry
    private let notificationManager: NotificationManager

    init(registry: ScraperRegistry = .shared, notificationManager: NotificationManager = .shared) {
        self.registry = registry
        self.notificationManager = notificationManager
    }

    /// Scrapes a URL without persisting anything, for the Add Product preview step.
    func preview(for url: URL) async throws -> ScrapedProduct {
        guard url.scheme == "http" || url.scheme == "https" else {
            throw ProductScrapingError.unsupportedURL
        }
        let scraper = registry.scraper(for: url)
        return try await scraper.fetchProduct(from: url)
    }

    /// Persists a freshly-previewed product along with its first price and availability entries.
    @discardableResult
    func save(_ scraped: ScrapedProduct, context: ModelContext) -> TrackedProduct {
        let product = TrackedProduct(
            title: scraped.title,
            url: scraped.url,
            store: scraped.store,
            imageURL: scraped.imageURL,
            currency: scraped.currency,
            currentPrice: scraped.price,
            availability: scraped.availability
        )
        context.insert(product)
        context.insert(PriceHistory(price: scraped.price, currency: scraped.currency, product: product))
        context.insert(AvailabilityHistory(status: scraped.availability, product: product))
        try? context.save()
        return product
    }

    /// Re-scrapes a single tracked product, records any change, and fires a notification
    /// if the price or availability actually moved. Never throws: failures are recorded
    /// on the product itself (`lastError`) so the UI can show a friendly message while the
    /// last known-good data stays intact.
    @discardableResult
    func refresh(_ product: TrackedProduct, context: ModelContext) async -> RefreshOutcome {
        product.isRefreshing = true
        defer { product.isRefreshing = false }

        let scraper = registry.scraper(for: product.url)
        do {
            let scraped = try await scraper.fetchProduct(from: product.url)
            product.lastError = nil

            let priceChanged = scraped.price != product.currentPrice
            let availabilityChanged = scraped.availability != product.availability

            if priceChanged {
                let oldPrice = product.currentPrice
                product.previousPrice = oldPrice
                product.currentPrice = scraped.price
                context.insert(PriceHistory(price: scraped.price, currency: scraped.currency, product: product))
                await notificationManager.notifyPriceChange(
                    for: product,
                    previousPrice: oldPrice,
                    newPrice: scraped.price,
                    currency: scraped.currency
                )
            }

            if availabilityChanged {
                context.insert(AvailabilityHistory(status: scraped.availability, product: product))
                product.availability = scraped.availability
                await notificationManager.notifyAvailabilityChange(for: product, newStatus: scraped.availability)
            }

            product.title = scraped.title
            product.currency = scraped.currency
            if let imageURL = scraped.imageURL {
                product.imageURL = imageURL
            }
            product.lastChecked = .now
            product.updatedAt = .now
            try? context.save()

            return priceChanged || availabilityChanged
                ? .updated(priceChanged: priceChanged, availabilityChanged: availabilityChanged)
                : .unchanged
        } catch {
            let scrapingError = (error as? ProductScrapingError) ?? .networkFailure(error.localizedDescription)
            product.lastError = scrapingError.errorDescription
            product.lastChecked = .now
            try? context.save()
            return .failed(scrapingError)
        }
    }

    /// Refreshes every product sequentially. Sequential (rather than concurrent) on purpose:
    /// all mutations share one `ModelContext`, and this keeps saves race-free without needing
    /// a locking scheme, at the cost of a refresh-all taking `O(n)` request round-trips.
    func refreshAll(products: [TrackedProduct], context: ModelContext) async {
        for product in products {
            await refresh(product, context: context)
        }
    }
}
