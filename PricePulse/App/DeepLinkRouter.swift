import Foundation
import Observation

/// Bridges notification taps (and any other future deep link source) into the SwiftUI
/// navigation layer. `DashboardView` observes `pendingProductID` and pushes the matching
/// product's detail screen when it changes.
@MainActor
@Observable
final class DeepLinkRouter {
    static let shared = DeepLinkRouter()

    var pendingProductID: UUID?

    private init() {}
}
