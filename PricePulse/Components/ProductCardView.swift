import SwiftUI

struct ProductCardView: View {
    let product: TrackedProduct

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ProductImageView(url: product.imageURL, cornerRadius: 14)
                .frame(width: 88, height: 88)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: product.store.iconSystemName)
                        .font(.caption2)
                    Text(product.store.displayName)
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.secondary)

                Text(product.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(product.currentPrice.formatted(currency: product.currency))
                        .font(.headline)

                    if let previousPrice = product.previousPrice, previousPrice != product.currentPrice {
                        Text(previousPrice.formatted(currency: product.currency))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .strikethrough()
                    }
                }

                HStack(spacing: 8) {
                    if let percentage = product.priceChangePercentage, percentage != 0 {
                        PriceChangeBadge(percentage: percentage)
                    }
                    AvailabilityBadge(availability: product.availability)
                }

                Text("Checked \(DateFormatters.lastChecked(product.lastChecked))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}
