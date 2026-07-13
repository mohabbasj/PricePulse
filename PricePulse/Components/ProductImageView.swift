import SwiftUI

/// Consistent async image loading + placeholder/error states for both the dashboard
/// card thumbnail and the product detail hero image. Relies on `URLCache.shared`
/// (configured at launch in `PricePulseApp`) for on-disk/in-memory image caching.
struct ProductImageView: View {
    let url: URL?
    var cornerRadius: CGFloat = 16

    var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.25))) { phase in
            switch phase {
            case .empty:
                ZStack {
                    Color.secondary.opacity(0.08)
                    ProgressView()
                }
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(8)
            case .failure:
                ZStack {
                    Color.secondary.opacity(0.08)
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            @unknown default:
                Color.secondary.opacity(0.08)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityHidden(true)
    }
}
