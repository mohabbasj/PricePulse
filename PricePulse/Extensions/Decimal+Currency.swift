import Foundation

extension Decimal {
    func formatted(currency: String) -> String {
        self.formatted(.currency(code: currency).precision(.fractionLength(0...2)))
    }

    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}
