import Foundation
import SwiftSoup

/// Shared parsing helpers used by every store adapter. Individual scrapers try their
/// store-specific CSS selectors first, then fall back to these generic strategies
/// (JSON-LD structured data and Open Graph meta tags), which are present on most
/// commerce sites regardless of how the rest of the page is built.
enum ScraperUtilities {

    // MARK: - JSON-LD "Product" schema

    struct JSONLDProduct {
        var title: String?
        var imageURL: URL?
        var price: Decimal?
        var currency: String?
        var availability: Availability?
    }

    static func extractJSONLDProduct(from document: Document) -> JSONLDProduct? {
        guard let scripts = try? document.select("script[type=application/ld+json]") else { return nil }

        for script in scripts.array() {
            guard let json = try? script.html(),
                  let data = json.data(using: .utf8) else { continue }

            let objects = decodeJSONObjects(from: data)
            for object in objects {
                if let product = productFromJSONObject(object) {
                    return product
                }
                // Some sites wrap the product inside an @graph array.
                if let graph = object["@graph"] as? [[String: Any]] {
                    for entry in graph {
                        if let product = productFromJSONObject(entry) {
                            return product
                        }
                    }
                }
            }
        }
        return nil
    }

    private static func decodeJSONObjects(from data: Data) -> [[String: Any]] {
        guard let raw = try? JSONSerialization.jsonObject(with: data) else { return [] }
        if let dict = raw as? [String: Any] { return [dict] }
        if let array = raw as? [[String: Any]] { return array }
        return []
    }

    private static func productFromJSONObject(_ object: [String: Any]) -> JSONLDProduct? {
        let type = object["@type"] as? String
        let types = object["@type"] as? [String]
        guard type == "Product" || (types?.contains("Product") ?? false) else { return nil }

        var result = JSONLDProduct()
        result.title = object["name"] as? String

        if let imageString = object["image"] as? String {
            result.imageURL = URL(string: imageString)
        } else if let imageArray = object["image"] as? [String], let first = imageArray.first {
            result.imageURL = URL(string: first)
        } else if let imageObject = object["image"] as? [String: Any], let urlString = imageObject["url"] as? String {
            result.imageURL = URL(string: urlString)
        }

        var offer = object["offers"] as? [String: Any]
        if offer == nil, let offerArray = object["offers"] as? [[String: Any]] {
            offer = offerArray.first
        }

        if let offer {
            if let priceString = offer["price"] as? String {
                result.price = Decimal(string: priceString)
            } else if let priceNumber = offer["price"] as? NSNumber {
                result.price = priceNumber.decimalValue
            } else if let priceDouble = offer["price"] as? Double {
                result.price = Decimal(priceDouble)
            }
            result.currency = offer["priceCurrency"] as? String
            if let availabilityString = offer["availability"] as? String {
                result.availability = mapSchemaAvailability(availabilityString)
            }
        }

        return result
    }

    private static func mapSchemaAvailability(_ raw: String) -> Availability {
        let normalized = raw.lowercased()
        if normalized.contains("instock") || normalized.contains("in_stock") {
            return .inStock
        }
        if normalized.contains("outofstock") || normalized.contains("out_of_stock") || normalized.contains("soldout") {
            return .outOfStock
        }
        return .unknown
    }

    // MARK: - Open Graph fallback

    static func openGraphContent(_ document: Document, property: String) -> String? {
        guard let element = try? document.select("meta[property=\(property)]").first() else { return nil }
        return try? element.attr("content")
    }

    static func metaContent(_ document: Document, name: String) -> String? {
        guard let element = try? document.select("meta[name=\(name)]").first() else { return nil }
        return try? element.attr("content")
    }

    // MARK: - Price text parsing

    /// Extracts a decimal price from freeform text like "SAR 1,249.00", "$19.99", or "1 249,00 ر.س".
    static func parsePrice(from text: String) -> Decimal? {
        let cleaned = text
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let match = cleaned.range(of: #"[0-9]{1,3}(?:[,\s][0-9]{3})*(?:[.,][0-9]{1,2})?"#, options: .regularExpression) else {
            return nil
        }

        var numeric = String(cleaned[match])
        // Normalize thousands separators, keep the final separator as the decimal point.
        let hasComma = numeric.contains(",")
        let hasDot = numeric.contains(".")

        if hasComma && hasDot {
            if numeric.firstIndex(of: ",")! < numeric.firstIndex(of: ".")! {
                numeric = numeric.replacingOccurrences(of: ",", with: "")
            } else {
                numeric = numeric.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            }
        } else if hasComma {
            let parts = numeric.split(separator: ",")
            if let last = parts.last, last.count == 2 {
                numeric = numeric.replacingOccurrences(of: ",", with: ".")
            } else {
                numeric = numeric.replacingOccurrences(of: ",", with: "")
            }
        }
        numeric = numeric.replacingOccurrences(of: " ", with: "")

        return Decimal(string: numeric)
    }

    /// Best-effort detection of a three-letter ISO currency code from page text or a symbol.
    static func detectCurrency(from text: String, fallback: String = "USD") -> String {
        let upper = text.uppercased()
        let knownCodes = ["USD", "EUR", "GBP", "SAR", "AED", "EGP", "KWD", "QAR", "BHD", "OMR", "CAD", "AUD", "JPY", "CNY"]
        for code in knownCodes where upper.contains(code) {
            return code
        }
        if text.contains("$") { return "USD" }
        if text.contains("€") { return "EUR" }
        if text.contains("£") { return "GBP" }
        if text.contains("ر.س") || text.contains("﷼") { return "SAR" }
        return fallback
    }

    static func firstNonEmptyText(_ document: Document, selectors: [String]) -> String? {
        for selector in selectors {
            if let element = try? document.select(selector).first() {
                let text = (try? element.text()) ?? ""
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return text.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return nil
    }

    static func firstAttribute(_ document: Document, selectors: [String], attribute: String) -> String? {
        for selector in selectors {
            if let element = try? document.select(selector).first(),
               let value = try? element.attr(attribute),
               !value.isEmpty {
                return value
            }
        }
        return nil
    }
}
