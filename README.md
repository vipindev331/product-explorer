# Product Explorer

A Flutter app for browsing products and viewing product details from the
[DummyJSON Products API](https://dummyjson.com/docs/products).

| Product listing | Product details | Specifications | Reviews |
| --- | --- | --- | --- |
| <img src="docs/screenshots/product_list.png" width="220" alt="Product listing"> | <img src="docs/screenshots/product_detail.png" width="220" alt="Product details"> | <img src="docs/screenshots/product_detail_specs.png" width="220" alt="Product specifications"> | <img src="docs/screenshots/product_detail_reviews.png" width="220" alt="Customer reviews"> |

**Demo video:** [docs/screenshots/demo.mp4](docs/screenshots/demo.mp4) (screen recording on the iPhone 16 Pro simulator)

## Features

**Product listing**
- Image, title, price (with original price when discounted), category, brand and rating on every card
- Responsive grid: two columns on phones, more on tablets
- Infinite scroll pagination (`limit`/`skip`), pull to refresh
- Debounced search using `GET /products/search`
- Loading skeleton, empty state (with “Clear search” for searches), and error state with **Try again**

**Product details**
- Swipeable image gallery with page dots and a full-screen, pinch-to-zoom viewer
- Title, description, price, discount, rating, brand, category, stock level
- Specifications: SKU, stock, minimum order quantity, weight, dimensions
- Shipping, warranty, return policy and availability
- Tags, customer reviews, barcode and listing dates
- Hero animation from the card image into the gallery

**Offline support (optional enhancement)**
- Every successful API response is cached on the device
- When the network or server fails, the last cached response is shown with a banner saying you’re offline
- Details screens open instantly with the product from the list, then refresh from `GET /products/{id}`

## Requirements

- Flutter 3.27 or newer (Dart 3.6+). Check with `flutter --version`.
- Android Studio / Xcode for running on an emulator, simulator or device.

## Setup

```bash
git clone <this-repo-url>
cd product_explorer
flutter pub get
flutter run
```

If the `android/` or `ios/` folders are missing (for example after a fresh
export of the Dart sources), generate them first:

```bash
./tool/setup_platforms.sh
```

The script runs `flutter create .` (which never overwrites existing files) and
adds the `INTERNET` permission to the Android release manifest.

No API keys or secrets are needed; the DummyJSON API is public.

## Running the tests

```bash
flutter test
```

With coverage:

```bash
flutter test --coverage
```

The tests never call the live API. Network calls go through
`package:http`’s `MockClient`, which serves a fake catalogue from
`test/helpers/test_helpers.dart`, and the offline cache uses an in-memory
store.

| Area | File |
| --- | --- |
| JSON parsing, discount maths | `test/data/models/product_test.dart` |
| HTTP endpoints and error mapping | `test/data/datasources/product_remote_data_source_test.dart` |
| On-device cache | `test/data/datasources/product_local_data_source_test.dart` |
| Network-first + offline fallback | `test/data/repositories/product_repository_test.dart` |
| Listing state, pagination, search, retry | `test/presentation/providers/product_list_provider_test.dart` |
| Details refresh and offline behaviour | `test/presentation/providers/product_detail_provider_test.dart` |
| Reusable widgets | `test/presentation/widgets/common_widgets_test.dart` |
| Listing screen states and navigation | `test/presentation/screens/product_list_screen_test.dart` |
| Details screen content | `test/presentation/screens/product_detail_screen_test.dart` |

A GitHub Actions workflow (`.github/workflows/flutter.yml`) runs
`flutter analyze` and `flutter test` on every push.

## Architecture

The app uses a layered architecture with `provider` for dependency injection
and state management.

```
lib/
├── main.dart                 Composition root: builds the repository and runs the app
├── app.dart                  MaterialApp, theme and providers
├── core/                     Constants, typed errors, theme, formatters, JSON helpers
├── data/
│   ├── models/               Product, ProductPage (+ reviews, dimensions, meta)
│   ├── datasources/          Remote (http) and local (shared_preferences) sources
│   └── repositories/         ProductRepository: network first, cache fallback
└── presentation/
    ├── providers/            ProductListProvider, ProductDetailProvider (ChangeNotifier)
    ├── screens/              ProductListScreen, ProductDetailScreen
    └── widgets/              Reusable UI: cards, price tag, rating, gallery, state views…
```

**Data flow**

```
Screen ──watch──> Provider (ChangeNotifier) ──> ProductRepository
                                                   ├─> ProductRemoteDataSource ─> DummyJSON API
                                                   └─> ProductLocalDataSource  ─> shared_preferences
```

- **Remote data source** builds the request URLs and converts sockets,
  timeouts and HTTP status codes into typed `AppException`s
  (`NetworkException`, `ServerException`, `NotFoundException`).
- **Repository** decodes responses into models, caches the raw JSON per
  request (`query + limit + skip`, or product id), and falls back to the cache
  on network or server errors. Each result says whether it came from the cache.
- **Providers** hold UI state (`loading / loaded / empty / error`), handle
  pagination, search and retry, and ignore stale responses when a newer request
  has started.
- **Widgets** only render state; everything reusable lives in
  `presentation/widgets`.

The repository is injected into `ProductExplorerApp`, which is what lets the
widget tests run the whole app against a fake API.

## Known limitations

- Product images are cached in memory only, so images that haven’t been viewed
  in the current session may not appear while offline. Product data is
  available offline.
- Weight and dimensions are shown as provided by the API, which doesn’t
  specify units.
