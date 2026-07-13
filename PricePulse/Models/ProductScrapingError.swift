import Foundation

enum ProductScrapingError: LocalizedError, Sendable {
    case unsupportedURL
    case invalidResponse
    case networkFailure(String)
    case parsingFailed(String)
    case priceNotFound
    case javascriptRenderingFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedURL:
            return "This URL isn't from a store PricePulse supports yet."
        case .invalidResponse:
            return "The store's server returned an unexpected response."
        case .networkFailure(let reason):
            return "Couldn't reach the store's website. \(reason)"
        case .parsingFailed(let reason):
            return "Couldn't read the product page. \(reason)"
        case .priceNotFound:
            return "Couldn't find a price on this product page."
        case .javascriptRenderingFailed(let reason):
            return "Couldn't render the page. \(reason)"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkFailure, .javascriptRenderingFailed, .invalidResponse:
            return true
        case .unsupportedURL, .parsingFailed, .priceNotFound:
            return false
        }
    }
}
