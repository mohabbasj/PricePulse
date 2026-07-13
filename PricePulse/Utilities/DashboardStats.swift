import Foundation

/// Aggregate figures shown at the top of the Dashboard. Computed on demand from the
/// currently tracked products, never persisted.
struct DashboardStats {
    let trackedCount: Int
    let onSaleCount: Int
    let biggestDiscount: TrackedProduct?
    let biggestIncrease: TrackedProduct?
    let averagePriceChangePercentage: Double?
    let newestProduct: TrackedProduct?

    static func compute(from products: [TrackedProduct]) -> DashboardStats {
        let onSale = products.filter(\.isOnSale)
        let increased = products.filter(\.isPriceIncrease)

        let biggestDiscount = onSale.min { lhs, rhs in
            (lhs.priceChangePercentage ?? 0) < (rhs.priceChangePercentage ?? 0)
        }
        let biggestIncrease = increased.max { lhs, rhs in
            (lhs.priceChangePercentage ?? 0) < (rhs.priceChangePercentage ?? 0)
        }

        let changedProducts = products.compactMap { $0.priceChangePercentage }
        let averageChange = changedProducts.isEmpty ? nil : changedProducts.reduce(0, +) / Double(changedProducts.count)

        let newest = products.max { $0.createdAt < $1.createdAt }

        return DashboardStats(
            trackedCount: products.count,
            onSaleCount: onSale.count,
            biggestDiscount: biggestDiscount,
            biggestIncrease: biggestIncrease,
            averagePriceChangePercentage: averageChange,
            newestProduct: newest
        )
    }
}
