import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class DashboardViewModel {
    var searchText: String = ""
    var sortOption: SortOption = .recentlyUpdated
    var filterOption: FilterOption = .all
    var isRefreshing: Bool = false
    var errorMessage: String?

    private let monitorService: ProductMonitorService

    init(monitorService: ProductMonitorService = .shared) {
        self.monitorService = monitorService
    }

    func stats(for products: [TrackedProduct]) -> DashboardStats {
        DashboardStats.compute(from: products)
    }

    func filteredAndSorted(_ products: [TrackedProduct]) -> [TrackedProduct] {
        var result = products.filter(filterOption.matches)

        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query) || $0.store.displayName.lowercased().contains(query)
            }
        }

        switch sortOption {
        case .recentlyUpdated:
            result.sort { $0.updatedAt > $1.updatedAt }
        case .newest:
            result.sort { $0.createdAt > $1.createdAt }
        case .oldest:
            result.sort { $0.createdAt < $1.createdAt }
        case .alphabetical:
            result.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .priceLowToHigh:
            result.sort { $0.currentPrice < $1.currentPrice }
        case .priceHighToLow:
            result.sort { $0.currentPrice > $1.currentPrice }
        case .biggestDiscount:
            result.sort { ($0.priceChangePercentage ?? .infinity) < ($1.priceChangePercentage ?? .infinity) }
        case .store:
            result.sort { $0.store.displayName < $1.store.displayName }
        }

        return result
    }

    func refreshAll(products: [TrackedProduct], context: ModelContext) async {
        isRefreshing = true
        errorMessage = nil
        await monitorService.refreshAll(products: products, context: context)
        BackgroundTaskManager.shared.scheduleAppRefresh()
        isRefreshing = false
    }

    func delete(_ product: TrackedProduct, context: ModelContext) {
        context.delete(product)
        try? context.save()
        HapticManager.mediumImpact()
    }
}
