import Foundation

/// Abstracts how raw HTML is retrieved for a product page, so scrapers don't care whether
/// the page was fetched with a plain HTTP request or rendered inside a headless web view.
protocol HTMLFetching: Sendable {
    func fetchHTML(from url: URL) async throws -> String
}

/// Fast path: a plain `URLSession` request. Works for any server-rendered store page.
struct URLSessionHTMLFetcher: HTMLFetching {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchHTML(from url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 20

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw ProductScrapingError.invalidResponse
        }

        guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            throw ProductScrapingError.parsingFailed("The page encoding wasn't recognized.")
        }
        return html
    }
}
