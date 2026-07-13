import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class AddProductViewModel {
    var urlText: String = ""
    var isLoading: Bool = false
    var previewProduct: ScrapedProduct?
    var errorMessage: String?
    var didSave: Bool = false

    private let monitorService: ProductMonitorService

    init(monitorService: ProductMonitorService = .shared) {
        self.monitorService = monitorService
    }

    var canFetchPreview: Bool {
        URL(string: urlText.trimmingCharacters(in: .whitespacesAndNewlines))?.host != nil
    }

    func fetchPreview() async {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), url.host != nil else {
            errorMessage = ProductScrapingError.unsupportedURL.errorDescription
            return
        }

        isLoading = true
        errorMessage = nil
        previewProduct = nil

        do {
            previewProduct = try await monitorService.preview(for: url)
            HapticManager.success()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            HapticManager.error()
        }
        isLoading = false
    }

    func save(context: ModelContext) {
        guard let previewProduct else { return }
        monitorService.save(previewProduct, context: context)
        HapticManager.success()
        didSave = true
    }

    func reset() {
        urlText = ""
        previewProduct = nil
        errorMessage = nil
        didSave = false
    }
}
