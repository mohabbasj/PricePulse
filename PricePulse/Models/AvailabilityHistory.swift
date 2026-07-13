import Foundation
import SwiftData

@Model
final class AvailabilityHistory: Identifiable {
    @Attribute(.unique) var id: UUID
    var statusRawValue: String
    var date: Date
    var product: TrackedProduct?

    init(id: UUID = UUID(), status: Availability, date: Date = .now, product: TrackedProduct? = nil) {
        self.id = id
        self.statusRawValue = status.rawValue
        self.date = date
        self.product = product
    }

    var status: Availability {
        get { Availability(rawValue: statusRawValue) ?? .unknown }
        set { statusRawValue = newValue.rawValue }
    }

    var productID: UUID? { product?.id }
}
