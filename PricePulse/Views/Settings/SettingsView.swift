import SwiftUI
import UserNotifications

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()

    @AppStorage(AppSettings.Keys.priceDropNotifications) private var priceDropNotifications = true
    @AppStorage(AppSettings.Keys.priceIncreaseNotifications) private var priceIncreaseNotifications = true
    @AppStorage(AppSettings.Keys.backInStockNotifications) private var backInStockNotifications = true
    @AppStorage(AppSettings.Keys.outOfStockNotifications) private var outOfStockNotifications = true
    @AppStorage(AppSettings.Keys.backgroundRefreshInterval) private var backgroundRefreshIntervalRaw = BackgroundRefreshInterval.oneHour.rawValue
    @AppStorage(AppSettings.Keys.colorScheme) private var colorSchemeRaw = AppColorScheme.system.rawValue

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if viewModel.notificationAuthorizationStatus == .denied {
                        Button {
                            viewModel.openSystemSettings()
                        } label: {
                            Label("Enable Notifications in Settings", systemImage: "bell.badge.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                    Toggle(isOn: $priceDropNotifications) {
                        Label("Price Drops", systemImage: "arrow.down.circle.fill")
                    }
                    .tint(.priceDropGreen)

                    Toggle(isOn: $priceIncreaseNotifications) {
                        Label("Price Increases", systemImage: "arrow.up.circle.fill")
                    }
                    .tint(.priceIncreaseRed)

                    Toggle(isOn: $backInStockNotifications) {
                        Label("Back in Stock", systemImage: "checkmark.circle.fill")
                    }
                    .tint(.green)

                    Toggle(isOn: $outOfStockNotifications) {
                        Label("Out of Stock", systemImage: "xmark.circle.fill")
                    }
                    .tint(.red)
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("PricePulse notifies you whenever a tracked product's price or availability changes.")
                }

                Section {
                    Picker(selection: $backgroundRefreshIntervalRaw) {
                        ForEach(BackgroundRefreshInterval.allCases) { interval in
                            Text(interval.label).tag(interval.rawValue)
                        }
                    } label: {
                        Label("Check Frequency", systemImage: "arrow.triangle.2.circlepath")
                    }
                } header: {
                    Text("Background Refresh")
                } footer: {
                    Text("Actual refresh timing depends on iOS background execution limits and device conditions like battery and network.")
                }

                Section("Appearance") {
                    Picker(selection: $colorSchemeRaw) {
                        ForEach(AppColorScheme.allCases) { scheme in
                            Text(scheme.label).tag(scheme.rawValue)
                        }
                    } label: {
                        Label("Appearance", systemImage: "circle.righthalf.filled")
                    }
                    .pickerStyle(.segmented)
                    .listRowSeparator(.hidden)
                }

                Section("About") {
                    LabeledContent("Version") {
                        Text(Bundle.main.appVersionString)
                    }
                    Link(destination: URL(string: "https://example.com/pricepulse/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                    Link(destination: URL(string: "https://example.com/pricepulse/support")!) {
                        Label("Support", systemImage: "questionmark.circle.fill")
                    }
                }

                Section {
                    Text("PricePulse tracks product prices you choose to monitor. Price data is stored only on your device and is never sold or shared with third parties.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Privacy")
                }
            }
            .navigationTitle("Settings")
            .task {
                await viewModel.refreshAuthorizationStatus()
            }
        }
    }
}

private extension Bundle {
    var appVersionString: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    SettingsView()
}
