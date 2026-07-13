import Foundation
import WebKit

/// Slow path: loads the page in a headless `WKWebView` and waits for JavaScript to finish
/// rendering before pulling the resulting DOM. Used when a plain HTTP fetch doesn't contain
/// enough information to build a `ScrapedProduct` (typical of client-side rendered storefronts).
@MainActor
final class WebViewHTMLFetcher: NSObject, HTMLFetching {
    private final class NavigationCoordinator: NSObject, WKNavigationDelegate {
        var onFinish: ((Result<Void, Error>) -> Void)?
        private var didComplete = false

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard !didComplete else { return }
            didComplete = true
            onFinish?(.success(()))
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            guard !didComplete else { return }
            didComplete = true
            onFinish?(.failure(error))
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            guard !didComplete else { return }
            didComplete = true
            onFinish?(.failure(error))
        }
    }

    func fetchHTML(from url: URL) async throws -> String {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()

        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 430, height: 932), configuration: configuration)
        let coordinator = NavigationCoordinator()
        webView.navigationDelegate = coordinator

        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                coordinator.onFinish = { result in
                    continuation.resume(with: result)
                }
                webView.load(URLRequest(url: url))

                // Client-rendered pages sometimes never fire a clean "finish" event
                // (infinite spinners, analytics beacons). Give up gracefully after a timeout.
                Task {
                    try? await Task.sleep(for: .seconds(12))
                    coordinator.onFinish?(.success(()))
                    coordinator.onFinish = nil
                }
            }
        } catch {
            throw ProductScrapingError.javascriptRenderingFailed(error.localizedDescription)
        }

        // Give any late-firing JS a brief moment to settle after the load event.
        try? await Task.sleep(for: .milliseconds(600))

        guard let html = try await webView.evaluateJavaScript("document.documentElement.outerHTML") as? String else {
            throw ProductScrapingError.javascriptRenderingFailed("The page returned no content.")
        }
        return html
    }
}
