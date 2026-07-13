import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class ProductDetailViewModel {
    var isRefreshing: Bool = false
    var errorMessage: String?
    var chartRange: ChartRange = .thirtyDays

    private let monitorService: ProductMonitorService

    init(monitorService: ProductMonitorService = .shared) {
        self.monitorService = monitorService
    }

    func chartPoints(for product: TrackedProduct) -> [PriceHistory] {
        chartRange.filter(product.sortedPriceHistory)
    }

    func refresh(_ product: TrackedProduct, context: ModelContext) async {
        isRefreshing = true
        errorMessage = nil

        let outcome = await monitorService.refresh(product, context: context)
        switch outcome {
        case .failed(let error):
            errorMessage = error.errorDescription
            HapticManager.error()
        case .updated:
            HapticManager.success()
        case .unchanged:
            break
        }

        isRefreshing = false
    }

    func delete(_ product: TrackedProduct, context: ModelContext) {
        context.delete(product)
        try? context.save()
        HapticManager.mediumImpact()
    }
}
