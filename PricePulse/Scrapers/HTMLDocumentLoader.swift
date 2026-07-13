import Foundation
import SwiftSoup

/// Loads a store page's HTML and hands back a parsed `SwiftSoup.Document`, automatically
/// escalating to a `WKWebView` render pass when the fast static fetch didn't contain enough
/// information (i.e. the site needs JavaScript to paint the price).
enum HTMLDocumentLoader {
    static func loadDocument(
        url: URL,
        staticFetcher: HTMLFetching = URLSessionHTMLFetcher(),
        needsRendering: (Document) -> Bool
    ) async throws -> Document {
        let html: String
        do {
            html = try await staticFetcher.fetchHTML(from: url)
        } catch let error as ProductScrapingError {
            throw error
        } catch {
            throw ProductScrapingError.networkFailure(error.localizedDescription)
        }

        guard let document = try? SwiftSoup.parse(html, url.absoluteString) else {
            throw ProductScrapingError.parsingFailed("The page HTML was malformed.")
        }

        guard needsRendering(document) else { return document }

        do {
            let renderedFetcher = await WebViewHTMLFetcher()
            let renderedHTML = try await renderedFetcher.fetchHTML(from: url)
            if let renderedDocument = try? SwiftSoup.parse(renderedHTML, url.absoluteString) {
                return renderedDocument
            }
        } catch {
            // JS rendering failed; fall through and let the caller work with what the
            // static fetch already produced (it may still be enough for a partial result).
        }

        return document
    }
}
