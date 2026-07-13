import Foundation

enum ChartRange: String, CaseIterable, Identifiable {
    case sevenDays
    case thirtyDays
    case ninetyDays
    case allTime

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sevenDays: return "7 Days"
        case .thirtyDays: return "30 Days"
        case .ninetyDays: return "90 Days"
        case .allTime: return "All Time"
        }
    }

    var days: Int? {
        switch self {
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        case .allTime: return nil
        }
    }

    func filter(_ history: [PriceHistory]) -> [PriceHistory] {
        guard let days else { return history }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .distantPast
        return history.filter { $0.date >= cutoff }
    }
}
