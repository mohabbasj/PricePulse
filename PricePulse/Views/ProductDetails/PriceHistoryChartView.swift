import Charts
import SwiftUI

struct PriceHistoryChartView: View {
    let points: [PriceHistory]
    let currency: String
    @Binding var range: ChartRange

    private var minPrice: Decimal { points.map(\.price).min() ?? 0 }
    private var maxPrice: Decimal { points.map(\.price).max() ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Price History")
                    .font(.headline)
                Spacer()
            }

            Picker("Range", selection: $range) {
                ForEach(ChartRange.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.segmented)

            if points.count < 2 {
                Text("Not enough data yet. Check back after the next price update.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                Chart(points) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        yStart: .value("Min", minPrice.doubleValue),
                        yEnd: .value("Price", point.price.doubleValue)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.25), Color.accentColor.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.monotone)

                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Price", point.price.doubleValue)
                    )
                    .foregroundStyle(Color.accentColor)
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Price", point.price.doubleValue)
                    )
                    .foregroundStyle(Color.accentColor)
                    .symbolSize(24)
                }
                .chartYScale(domain: (minPrice.doubleValue * 0.95)...(maxPrice.doubleValue * 1.05))
                .frame(height: 200)
                .accessibilityLabel("Price history chart showing \(points.count) recorded prices")
            }
        }
        .padding(16)
        .cardStyle()
        .animation(.spring(duration: 0.3), value: range)
    }
}
