import SwiftData
import SwiftUI

struct ProductDetailView: View {
    @Bindable var product: TrackedProduct

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ProductDetailViewModel()
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ProductImageView(url: product.imageURL, cornerRadius: 20)
                    .frame(height: 260)
                    .frame(maxWidth: .infinity)
                    .cardStyle(cornerRadius: 20)

                header

                priceStatsGrid

                PriceHistoryChartView(
                    points: viewModel.chartPoints(for: product),
                    currency: product.currency,
                    range: $viewModel.chartRange
                )

                PriceTimelineView(history: product.priceHistory, currency: product.currency)

                availabilitySection

                metaSection
            }
            .padding()
        }
        .background(Color.screenBackground)
        .navigationTitle(product.store.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await viewModel.refresh(product, context: modelContext) }
                } label: {
                    if viewModel.isRefreshing {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(viewModel.isRefreshing)
                .accessibilityLabel("Refresh product")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete product")
            }
        }
        .confirmationDialog(
            "Delete this product?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                viewModel.delete(product, context: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes \"\(product.title)\" and its entire price history.")
        }
        .alert(
            "Couldn't Refresh",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: product.store.iconSystemName)
                Text(product.store.displayName)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)

            Text(product.title)
                .font(.title3.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(product.currentPrice.formatted(currency: product.currency))
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                if let previous = product.previousPrice, previous != product.currentPrice {
                    Text(previous.formatted(currency: product.currency))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .strikethrough()
                }

                if let percentage = product.priceChangePercentage, percentage != 0 {
                    PriceChangeBadge(percentage: percentage)
                }
            }

            HStack {
                AvailabilityBadge(availability: product.availability)
                Spacer()
                Text("Checked \(DateFormatters.lastChecked(product.lastChecked))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let lastError = product.lastError {
                Label(lastError, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardStyle()
    }

    private var priceStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCardView(
                title: "Lowest",
                value: product.lowestPrice.formatted(currency: product.currency),
                systemImage: "arrow.down.circle.fill",
                tint: .priceDropGreen
            )
            StatCardView(
                title: "Highest",
                value: product.highestPrice.formatted(currency: product.currency),
                systemImage: "arrow.up.circle.fill",
                tint: .priceIncreaseRed
            )
            StatCardView(
                title: "Average",
                value: product.averagePrice.formatted(currency: product.currency),
                systemImage: "chart.bar.fill",
                tint: .accentColor
            )
        }
    }

    private var availabilitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Availability History")
                .font(.headline)

            if product.sortedAvailabilityHistory.isEmpty {
                Text("No availability changes recorded yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(product.sortedAvailabilityHistory) { entry in
                    HStack {
                        AvailabilityBadge(availability: entry.status)
                        Spacer()
                        Text(DateFormatters.mediumDate.string(from: entry.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var metaSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Tracking Since")
                Spacer()
                Text(DateFormatters.shortDate.string(from: product.createdAt))
                    .foregroundStyle(.secondary)
            }
            Divider()
            HStack {
                Text("Product URL")
                Spacer()
                Link(product.url.host ?? product.url.absoluteString, destination: product.url)
                    .lineLimit(1)
            }
        }
        .font(.subheadline)
        .padding(16)
        .cardStyle()
    }
}

#Preview {
    let container = PersistenceController.preview
    let product = try! container.mainContext.fetch(FetchDescriptor<TrackedProduct>()).first!
    return NavigationStack {
        ProductDetailView(product: product)
    }
    .modelContainer(container)
}
