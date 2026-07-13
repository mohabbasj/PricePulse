import SwiftUI

struct PriceTimelineView: View {
    let history: [PriceHistory]
    let currency: String

    private var chronological: [PriceHistory] {
        history.sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Price Timeline")
                .font(.headline)

            if chronological.isEmpty {
                Text("No price changes recorded yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(chronological.enumerated()), id: \.element.id) { index, entry in
                        TimelineRow(
                            entry: entry,
                            previous: index + 1 < chronological.count ? chronological[index + 1] : nil,
                            currency: currency,
                            isLast: index == chronological.count - 1
                        )
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }
}

private struct TimelineRow: View {
    let entry: PriceHistory
    let previous: PriceHistory?
    let currency: String
    let isLast: Bool

    private var change: Decimal? {
        guard let previous else { return nil }
        return entry.price - previous.price
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 9, height: 9)
                if !isLast {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.25))
                        .frame(width: 2)
                }
            }
            .frame(width: 9)
            .padding(.top, 5)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(entry.price.formatted(currency: currency))
                        .font(.subheadline.weight(.semibold))
                    if let change, change != 0 {
                        Image(systemName: change < 0 ? "arrow.down.right" : "arrow.up.right")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(change < 0 ? Color.priceDropGreen : Color.priceIncreaseRed)
                    }
                }
                Text(DateFormatters.mediumDate.string(from: entry.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, isLast ? 0 : 14)

            Spacer()
        }
    }

    private var dotColor: Color {
        guard let change else { return .secondary }
        if change < 0 { return .priceDropGreen }
        if change > 0 { return .priceIncreaseRed }
        return .secondary
    }
}
