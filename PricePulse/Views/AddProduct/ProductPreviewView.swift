import SwiftUI

struct ProductPreviewView: View {
    let product: ScrapedProduct

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Preview")
                .font(.headline)

            HStack(alignment: .top, spacing: 14) {
                ProductImageView(url: product.imageURL, cornerRadius: 14)
                    .frame(width: 100, height: 100)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: product.store.iconSystemName)
                        Text(product.store.displayName)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                    Text(product.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(3)

                    Text(product.price.formatted(currency: product.currency))
                        .font(.title3.weight(.bold))

                    AvailabilityBadge(availability: product.availability)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .cardStyle()
    }
}

#Preview {
    ProductPreviewView(
        product: ScrapedProduct(
            title: "Adidas Galaxy 7 Running Shoes",
            url: URL(string: "https://www.adidas.com/us/galaxy-7")!,
            store: .adidas,
            price: 299,
            currency: "SAR",
            availability: .inStock,
            imageURL: nil
        )
    )
    .padding()
}
