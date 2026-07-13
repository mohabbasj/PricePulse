import SwiftUI

struct SortFilterMenu: View {
    @Binding var sortOption: SortOption
    @Binding var filterOption: FilterOption

    var body: some View {
        Menu {
            Section("Filter") {
                ForEach(FilterOption.allCases) { option in
                    Button {
                        filterOption = option
                        HapticManager.selectionChanged()
                    } label: {
                        Label(option.label, systemImage: option.systemImage)
                        if filterOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            Section("Sort By") {
                ForEach(SortOption.allCases) { option in
                    Button {
                        sortOption = option
                        HapticManager.selectionChanged()
                    } label: {
                        Label(option.label, systemImage: option.systemImage)
                        if sortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Sort and filter products")
    }
}
