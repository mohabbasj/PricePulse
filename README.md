# PricePulse

PricePulse is a native iOS app for tracking product prices across multiple online
stores. Paste a product URL, PricePulse detects the store and extracts the current
price, title, image, and availability, then checks it periodically — in the
foreground and in the background — and notifies you the moment the price or
availability changes.

## Highlights

- **Store-agnostic tracking.** Paste any supported store's product URL; PricePulse
  detects the store automatically and previews the product before saving.
- **Full price history.** Every detected price is stored permanently, powering a
  Swift Charts price-over-time chart (7 / 30 / 90 days / all time) and a change
  timeline.
- **Background monitoring.** A `BGAppRefreshTask` re-checks every tracked product on
  a user-configurable interval, even when the app isn't running, within iOS's
  background execution budget.
- **Local notifications.** Price drop, price increase, back-in-stock, and
  out-of-stock alerts, each deep-linking straight to that product's detail screen.
- **Extensible scraper architecture.** Adding a new store is a single new file that
  conforms to `ProductScraper` — nothing else in the app changes.

## Requirements

- Xcode 16 or later
- iOS 17.0+ deployment target
- Swift 6 language mode

## Getting Started

1. Open `PricePulse.xcodeproj` in Xcode.
2. Xcode will automatically resolve the single Swift Package dependency
   ([SwiftSoup](https://github.com/scinfu/SwiftSoup), used for HTML parsing) the
   first time you open or build the project. Wait for package resolution to finish
   in the status bar.
3. Select the `PricePulse` scheme and an iOS 17+ simulator (or a device with your
   own development team selected under **Signing & Capabilities**).
4. Build and run (`⌘R`).

No API keys, backend services, or paid third-party APIs are required — all
scraping happens on-device.

## Architecture

PricePulse follows strict MVVM with a protocol-oriented service layer:

```
PricePulse/
├── App/                Composition root: PricePulseApp, AppDelegate, RootView, DeepLinkRouter
├── Models/              SwiftData models (TrackedProduct, PriceHistory, AvailabilityHistory)
│                         and value types (Store, Availability, ScrapedProduct, ProductScrapingError)
├── Scrapers/            ProductScraper protocol + one adapter per store + shared parsing engine
├── Services/             ProductMonitorService (orchestration), BackgroundTaskManager
├── Persistence/          PersistenceController (SwiftData ModelContainer)
├── Notifications/        NotificationManager, NotificationDelegate
├── ViewModels/           One @Observable view model per screen
├── Views/                Dashboard, AddProduct, ProductDetails, Settings
├── Components/           Reusable SwiftUI views (cards, badges, charts, empty/loading states)
├── Utilities/            Formatters, haptics, logging, sort/filter/chart-range types
├── Extensions/            Small, focused extensions (Decimal currency formatting, color theme)
└── Resources/            Info.plist, Assets.xcassets, LaunchScreen.storyboard
```

### Data flow

1. **Add Product** — `AddProductViewModel` asks `ProductMonitorService.preview(for:)`
   to scrape a URL without persisting anything, so the user can confirm before saving.
2. **Save** — `ProductMonitorService.save(_:context:)` inserts a `TrackedProduct`
   plus its first `PriceHistory` and `AvailabilityHistory` rows.
3. **Refresh** (pull-to-refresh, manual refresh button, or background task) —
   `ProductMonitorService.refresh(_:context:)` re-scrapes the product, compares the
   result against the stored price/availability, writes new history rows on any
   change, and asks `NotificationManager` to fire the appropriate alert.
4. **Background** — `BackgroundTaskManager` registers a `BGAppRefreshTask` at launch
   and reschedules itself after every run (including failures), so monitoring
   continues across app launches within the limits iOS grants background tasks.

### Adding a new store

Create a new file in `Scrapers/`, conform to `ProductScraper`:

```swift
struct MyStoreScraper: ProductScraper {
    let store: Store = .other // add a new case to Store if it deserves a badge/icon

    func supports(url: URL) -> Bool {
        url.host?.lowercased().contains("mystore.") ?? false
    }

    func fetchProduct(from url: URL) async throws -> ScrapedProduct {
        // Reuse SelectorScrapingEngine + HTMLDocumentLoader for the common
        // "static HTML, fall back to WKWebView, prefer JSON-LD" pipeline,
        // or implement fully custom parsing if the store needs it.
    }
}
```

Then register it in `ScraperRegistry.allScrapers`. `GenericScraper` remains as a
catch-all fallback for any store without a dedicated adapter, using JSON-LD and
Open Graph meta tags — most commerce sites work out of the box even before a
dedicated adapter is written.

### Scraping engine

- `URLSessionHTMLFetcher` does a fast static HTTP fetch first.
- If the parsed document doesn't contain a usable price (typical of client-rendered
  storefronts), `HTMLDocumentLoader` automatically escalates to
  `WebViewHTMLFetcher`, which renders the page in a headless `WKWebView` and reads
  back `document.documentElement.outerHTML` after JavaScript executes.
- `SelectorScrapingEngine` parses the resulting HTML with SwiftSoup, preferring
  schema.org `Product` JSON-LD (via `ScraperUtilities.extractJSONLDProduct`) and
  falling back to store-specific CSS selectors and Open Graph tags.
- Failures never crash the app or wipe existing data: `ProductMonitorService`
  catches every `ProductScrapingError`, records a user-friendly message on
  `TrackedProduct.lastError`, and leaves the last known-good price/availability in
  place for the next attempt.

## Notifications

PricePulse requests notification authorization on first launch. Four alert types
are supported, each individually toggleable in Settings:

| Event | Title |
|---|---|
| Price drop | ⬇️ Price Drop |
| Price increase | ⬆️ Price Increase |
| Back in stock | ✅ Back in Stock |
| Out of stock | ⛔️ Out of Stock |

Tapping a notification sets `DeepLinkRouter.pendingProductID`, which
`DashboardView` observes to push straight to that product's detail screen.

## Background Refresh

Background monitoring uses `BGTaskScheduler` with the identifier
`com.pricepulse.refresh` (already declared in `Info.plist` under
`BGTaskSchedulerPermittedIdentifiers`, alongside the `fetch`/`processing`
background modes). The check frequency (15 min / 30 min / 1 hr / 3 hr / 6 hr) is
configurable in Settings — actual firing is still governed by iOS based on device
usage patterns, battery, and network conditions, per Apple's standard
`BGAppRefreshTask` behavior.

To test background refresh in the simulator/device during development, pause at a
breakpoint after `BackgroundTaskManager.scheduleAppRefresh()` runs and use the
LLDB command:

```
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.pricepulse.refresh"]
```

## Persistence

All data is stored on-device using SwiftData (`PersistenceController`). Three
models: `TrackedProduct` (current state), `PriceHistory` (append-only price log),
and `AvailabilityHistory` (append-only stock-status log), related via cascade-delete
relationships so removing a product removes its history too.

## Privacy

PricePulse only fetches the specific product page URLs you add. No account,
analytics SDK, or third-party network service is used — price data lives entirely
in the app's local SwiftData store.
