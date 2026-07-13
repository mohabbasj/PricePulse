import SwiftUI

struct AvailabilityBadge: View {
    let availability: Availability

    var body: some View {
        Label(availability.label, systemImage: availability.systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(availability.tintColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(availability.tintColor.opacity(0.14), in: Capsule())
            .accessibilityLabel("Availability: \(availability.label)")
    }
}
