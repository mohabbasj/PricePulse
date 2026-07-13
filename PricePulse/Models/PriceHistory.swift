import Foundation
import SwiftData

@Model
final class PriceHistory: Identifiable {
    @Attribute(.unique) var id: UUID
    var price: Decimal
    var currency: String
    var date: Date
    var product: TrackedProduct?

    init(id: UUID = UUID(), price: Decimal, currency: String, date: Date = .now, product: TrackedProduct? = nil) {
        self.id = id
        self.price = price
        self.currency = currency
        self.date = date
        self.product = product
    }

    var productID: UUID? { product?.id }
}
