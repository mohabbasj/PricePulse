import SwiftUI

struct DashboardStatsHeader: View {
    let stats: DashboardStats

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            StatCardView(
                title: "Tracked Products",
                value: "\(stats.trackedCount)",
                systemImage: "cart.fill",
                tint: .accentColor
            )
            StatCardView(
                title: "On Sale",
                value: "\(stats.onSaleCount)",
                systemImage: "tag.fill",
                tint: .priceDropGreen
            )
            StatCardView(
                title: "Biggest Discount",
                value: stats.biggestDiscount?.priceChangePercentage.map { String(format: "%.0f%%", abs($0)) } ?? "—",
                systemImage: "arrow.down.right.circle.fill",
                tint: .priceDropGreen
            )
            StatCardView(
                title: "Biggest Increase",
                value: stats.biggestIncrease?.priceChangePercentage.map { String(format: "+%.0f%%", $0) } ?? "—",
                systemImage: "arrow.up.right.circle.fill",
                tint: .priceIncreaseRed
            )
        }
    }
}
