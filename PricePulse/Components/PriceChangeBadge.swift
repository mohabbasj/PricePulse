import SwiftUI

struct PriceChangeBadge: View {
    let percentage: Double

    private var isIncrease: Bool { percentage > 0 }

    var body: some View {
        Label(String(format: "%.0f%%", abs(percentage)), systemImage: isIncrease ? "arrow.up.right" : "arrow.down.right")
            .font(.caption.weight(.bold))
            .foregroundStyle(isIncrease ? Color.priceIncreaseRed : Color.priceDropGreen)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                (isIncrease ? Color.priceIncreaseRed : Color.priceDropGreen).opacity(0.14),
                in: Capsule()
            )
            .accessibilityLabel(isIncrease ? "Price increased \(String(format: "%.0f", percentage)) percent" : "Price dropped \(String(format: "%.0f", abs(percentage))) percent")
    }
}
