# Solution

## Architecture Decisions

### MVVM with Service Layer using `@Observable`

ViewModels use Swift's `@Observable` macro (iOS 17+) rather than `ObservableObject`/`@Published`. This eliminates per-property `@Published` boilerplate, avoids unnecessary re-renders (only accessed properties trigger updates), and aligns with Apple's current recommended approach. Views hold ViewModels with `@State private var`, keeping ownership clear.

### Protocol-driven networking for testability

Two protocols carry the abstraction:

- `NetworkingRequesterType` — the raw HTTP layer (injectable mock in `NetworkLayerTests`)
- `CatBreedServiceProtocol` — the domain service (injectable mock for ViewModel tests)

`CatBreedService` accepts an internal `init(requester:)` used by tests and exposes a `public init()` for app use. This keeps the dependency seam internal to the module while still allowing full mock coverage.

### Avoiding Combine — async/await as the public surface

`NetworkingRequester` was scaffolded using Moya + Combine (`Future`/`AnyPublisher`). Rather than rewriting the scaffold entirely, a thin bridge in `NetworkingRequester+Async.swift` wraps each publisher in `withCheckedThrowingContinuation`, so every caller above the network layer uses `try await`. Combine is an implementation detail that never leaks into ViewModels or services.

**Why avoid Combine at the call sites?**

| Concern | Combine | async/await |
|---|---|---|
| **Readability** | Chains of operators (`flatMap`, `mapError`, `eraseToAnyPublisher`) are harder to follow than a linear `do/catch` block | Code reads like synchronous code — easier for any Swift developer to reason about |
| **Testability** | Requires `XCTestExpectation` + `AnyCancellable` storage to test async flows | `async throws` functions test with a plain `try await` call inside an `async` test |
| **Error handling** | Errors propagate via `receiveCompletion`; easy to silently drop them | Thrown errors surface naturally via Swift's error propagation — compiler enforces handling |
| **Cancellation** | Manual `AnyCancellable` storage and `.store(in:)` | Structured concurrency cancels automatically when the `Task` or `async let` scope exits |

Given more time, the Combine internals of `NetworkingRequester` would be replaced entirely with `URLSession.data(for:)`.

### SwiftData for local persistence

`SavedCat` is a `@Model` class with a SwiftData container injected at the app root (`.modelContainer(for: SavedCat.self)`). `MyCatsTabView` reads the collection with `@Query`, which automatically stays in sync as rows are inserted. This is the modern, zero-boilerplate replacement for Core Data in a greenfield project.

**Why SwiftData over `UserDefaults`?**

`UserDefaults` would technically work for storing a small flat list. However, SwiftData is the better choice here because:

- **Querying and sorting**: `@Query(sort: \\SavedCat.createdAt, order: .reverse)` is declarative and efficient. With `UserDefaults` you'd decode the full array, sort it manually, and write it back on every change.
- **Live updates**: `@Query` automatically refreshes the view when the store changes. `UserDefaults` has no equivalent reactive mechanism without wrapping it in `ObservableObject`.
- **Scalability**: If the data model grows (relationships, migrations), SwiftData handles it. `UserDefaults` is a key-value store with no schema — migrations mean manual JSON versioning.
- **Type safety**: `@Model` is fully type-safe. `UserDefaults` requires manual `Codable` encoding/decoding and manual key management.

### Secrets management via `.xcconfig`

API keys are never hardcoded in source. The flow is:

1. **`Secrets.xcconfig`** (gitignored) holds the actual key: `CAT_API_KEY = live_xxx…`
2. **`Project.swift`** (Tuist) references the xcconfig so Xcode injects the variable at build time.
3. **`ApplaudoChallenge-Info.plist`** exposes it as a bundle entry: `<key>CAT_API_KEY</key><string>$(CAT_API_KEY)</string>`
4. **`NetworkingTargetType`** reads it at runtime: `Bundle.main.object(forInfoDictionaryKey: "CAT_API_KEY")`

This means the key travels through the build system as a build setting — it never touches the binary's string segment directly and never appears in source control.

**To run the project locally:**

```bash
# 1. Copy the template
cp ApplaudoChallenge/Config/Secrets.xcconfig.template ApplaudoChallenge/Config/Secrets.xcconfig

# 2. Open the file and paste your key from https://thecatapi.com/
# CAT_API_KEY = live_your_key_here

# 3. Build and run normally in Xcode
```

**For CI/CD**, set `CAT_API_KEY` as a secret environment variable in your pipeline and inject it before building

> **Note:** `Project.swift` was modified from the original scaffold to wire in the xcconfig. If you regenerate the Xcode project with `tuist generate`, the secrets integration will be included. If you encounter build settings issues after regeneration, verify that `Secrets.xcconfig` exists and is referenced correctly in the generated scheme.

### Pagination strategy

Pagination triggers when the list item three positions from the end becomes visible (via `.task` on each row). This is a threshold-scroll approach — no `ScrollView` position tracking or `onAppear` + debounce needed. 

### SwiftUI views broken into smaller computed properties

Rather than putting all layout in a single `body`, each screen is split into focused private computed properties and helper functions. This makes each piece individually readable, independently previewable, and easier to refactor without touching unrelated layout.

### `AppCard` extended to display real remote images

`AppCard` was modified with an optional `imageURL: String?` parameter. When a URL is provided, a private `CardThumbnail` subview uses `AsyncImage` to load the remote image and display it in the circular thumbnail. When no URL is available (or loading fails), it falls back to the SF Symbol icon. This means the breed list shows actual cat photos from the API alongside the breed name, which significantly improves scannability.

---

## Trade-offs and Assumptions

| Area | Trade-off / Assumption |
|---|---|
| **Combine in `NetworkLayer` internals** | The networking core uses Combine internally (scaffold constraint). The async bridge works correctly, but Combine adds a transitive dependency that wouldn't exist with a pure `URLSession`-async implementation. |
| **Client-side search** | Search filters the in-memory list rather than hitting the API. This misses breeds that haven't been paginated in yet. The Cat API has a finite breed set, so this is acceptable, but a server-side search param would be more correct.  |
| **Image caching** | `AsyncImage` is used directly. It benefits from the system URL cache but provides no disk persistence. High-traffic usage would benefit from an explicit caching layer. |
| **No repository layer** | ViewModels call services directly. Adding a repository would be the right move for aggregation (e.g., combining local + remote data), but for this scope it would be premature abstraction. |
| **iOS 17+ minimum** | `@Observable` and `@Query` both require iOS 17. This was a conscious choice to use modern APIs cleanly rather than carrying backwards-compatibility shims. |

---

## README Observations

The `README.md` setup instructions appear to have drifted from the current project state. Unless this is intentionally part of the challenge evaluation, the following items are worth updating:

### 1. Ruby / Bundler setup is no longer needed

The README instructs candidates to install a Ruby version manager, install Ruby 3.1.0, install Bundler, and run `bundle install`. However, there is no `Gemfile` in the repository, so Bundler has nothing to install.

### 2. `tuist fetch` is deprecated — use `tuist install`

**Recommendation:** Replace `tuist fetch` with `tuist install`.

---

## What I Would Improve Given More Time

1. **Server-side search.** Pass `searchText` as a query parameter to the `/breeds/search` endpoint rather than filtering client-side. This makes search accurate regardless of how many pages have been loaded.

2. **Explicit image caching.** Add an `NSCache`-backed `AsyncImage` wrapper (or adopt SDWebImageSwiftUI / Kingfisher) so breed images survive scroll recycling and app relaunch without re-downloading.

3. **Pagination error recovery.** When `loadNextPage` fails silently, show an inline "Failed to load more — Tap to retry" footer instead of discarding the error. The current behavior is functional but the failure is invisible to the user.

4. **Structured string constants and localization.** Replace inline string literals (`"Cat Breeds"`, `"Add New Cat"`, `"My Cats"`, etc.) with a typed `Strings` enum and wire it to a `Localizable.xcstrings` catalog. This makes copy changes and internationalization a single-file operation instead of a grep-and-replace across all view files.

5. **Clean Architecture for a larger scope.** The current two-layer setup (Service → ViewModel) is appropriate for this project size. If the app grew to handle multiple domains or more complex data flows, introducing Use Cases between the service and the ViewModel (Clean Architecture style) would improve separation of concerns and make business logic independently testable without involving the presentation layer.

6. **UI Tests.** Add `XCUITest` coverage for the multi-step Add Cat form (validation, step navigation, save, success screen) and for the breed list (pagination trigger, search, detail navigation).

7. **Accessibility.** Audit the component library for `accessibilityLabel`, `accessibilityHint`, and correct trait assignments. `AppCard` in particular renders an image + two text labels that VoiceOver would read as three separate elements without explicit grouping.
