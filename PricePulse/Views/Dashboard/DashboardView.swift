import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TrackedProduct.updatedAt, order: .reverse) private var products: [TrackedProduct]

    @State private var viewModel = DashboardViewModel()
    @State private var showingAddProduct = false
    @State private var navigationPath = NavigationPath()

    @Environment(DeepLinkRouter.self) private var deepLinkRouter

    private var visibleProducts: [TrackedProduct] {
        viewModel.filteredAndSorted(products)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if products.isEmpty {
                    EmptyStateView(
                        systemImage: "cart.badge.plus",
                        title: "No Products Yet",
                        message: "Paste a product URL to start tracking its price across stores.",
                        actionTitle: "Add Product"
                    ) {
                        showingAddProduct = true
                    }
                } else if visibleProducts.isEmpty {
                    EmptyStateView(
                        systemImage: "magnifyingglass",
                        title: "No Matches",
                        message: "Try a different search term or filter."
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            DashboardStatsHeader(stats: viewModel.stats(for: products))
                                .padding(.horizontal)
                                .padding(.top, 4)

                            LazyVStack(spacing: 12) {
                                ForEach(visibleProducts) { product in
                                    NavigationLink(value: product.id) {
                                        ProductCardView(product: product)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            viewModel.delete(product, context: modelContext)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                viewModel.delete(product, context: modelContext)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 24)
                    }
                    .refreshable {
                        await viewModel.refreshAll(products: products, context: modelContext)
                    }
                }
            }
            .background(Color.screenBackground)
            .navigationTitle("PricePulse")
            .searchable(text: $viewModel.searchText, prompt: "Search products or stores")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SortFilterMenu(sortOption: $viewModel.sortOption, filterOption: $viewModel.filterOption)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddProduct = true
                        HapticManager.lightImpact()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .accessibilityLabel("Add Product")
                }
            }
            .navigationDestination(for: UUID.self) { productID in
                if let product = products.first(where: { $0.id == productID }) {
                    ProductDetailView(product: product)
                }
            }
            .sheet(isPresented: $showingAddProduct) {
                AddProductView()
            }
            .onChange(of: deepLinkRouter.pendingProductID) { _, newValue in
                guard let newValue else { return }
                navigationPath.append(newValue)
                deepLinkRouter.pendingProductID = nil
            }
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(PersistenceController.preview)
        .environment(DeepLinkRouter.shared)
}
