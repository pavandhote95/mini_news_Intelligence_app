# NewsIntel — Mini News Intelligence App

A clean, scalable Flutter app that turns a public news API into a focused **business news intelligence** experience: category headlines with pagination, debounced API search with filters, rich article detail, and offline favourites.

Built with **Flutter 3 · Dart 3 (null safety) · Riverpod · Hive · Dio · go_router**, following **Clean Architecture**.

## 📱 Try the app

**[⬇️ Download APK (Google Drive)](https://drive.google.com/file/d/1EKCgmnhJPHuEp4GM5jOZAS9k9y6UDgxc/view?usp=sharing)**

**Demo login:** any valid email + a password of 6+ characters (e.g. `demo@test.com` / `123456`).

> Android only. If prompted, allow **"Install from unknown sources"** for your browser or file manager.

---

## ✅ Requirement coverage

| Requirement (from the brief) | Where / how |
|---|---|
| **Auth – simple login** | `features/auth` — validated email/password form, loading + error states |
| **Auth – persist login state** | Session saved in Hive (`auth_box`); router reads it synchronously on launch, so a logged-in user lands straight on the feed |
| **Feed – category based listing** | 7 NewsAPI categories (Business first) as chips; each category has its own cached state (`feedProvider.family`) |
| **Feed – pagination** | Infinite scroll (loads next page 400px before the end), de-duplication, inline retry on page errors, stops at API limit |
| **Feed – pull-to-refresh** | `RefreshIndicator`; a failed refresh keeps the current list and shows a snackbar |
| **Search – using API** | NewsAPI `/everything` endpoint |
| **Search – efficient filtering** | 500 ms debounce · min. 2 chars · stale responses ignored · server filters (sort / date range / language) · instant client-side source filter (no network) · recent searches |
| **Article detail – full view** | Hero image, source, author, date, reading time, description and body; **Read full article** opens the publisher page in an in-app browser tab |
| **Article detail – save as favourite** | FAB + bookmark buttons everywhere, with snackbar feedback |
| **Favourites – offline persistent storage** | Typed Hive box with a custom `TypeAdapter`; works with no network, local filter, swipe-to-delete with **Undo**, clear all |
| Clean architecture | `domain` / `data` / `presentation` per feature, dependency rule enforced (see below) |
| State management (Riverpod) | `Notifier`, `FamilyNotifier`, derived `Provider`s, `select`, overrides in tests |
| Local storage (Hive) | 4 boxes: auth, favourites, feed cache, search history |
| Error handling & loaders | Sealed `Failure` hierarchy, `Result<T>` return type, skeleton loaders, contextual error screens with retry, offline banner |

**Extras:** offline fallback for the feed (last fetched page per category), light/dark theme, reading-time estimate, unit + widget tests.

---

## 🚀 Getting started

### 1. Prerequisites
- Flutter **3.27+** (`flutter --version`)
- A free API key from **https://newsapi.org/register**

### 2. Generate platform folders
The repository contains only the app source (`lib/`, `test/`, config). Create the Android/iOS runners once:

```bash
flutter create . --org com.newsintel --project-name mini_news_intelligence --platforms=android,ios
```
`flutter create` never overwrites existing files, so `lib/`, `test/`, `pubspec.yaml` and this README stay untouched.
(Or just run `./scripts/setup.sh` / `scripts\setup.bat`, which does steps 2–3 for you.)

> **Android release builds:** add `<uses-permission android:name="android.permission.INTERNET"/>` to `android/app/src/main/AndroidManifest.xml` (debug builds already include it). The setup script does this automatically.

### 3. Add your API key
```bash
cp env.example.json env.json      # Windows: copy env.example.json env.json
# edit env.json and paste your key
```
`env.json` is git-ignored — the key is never committed.

### 4. Run
```bash
flutter pub get
flutter run --dart-define-from-file=env.json
```
VS Code: add `"args": ["--dart-define-from-file=env.json"]` to your launch configuration.

If you forget the key the app still runs and shows a clear **"API key problem"** screen instead of crashing.

**Login:** any valid email + a password of 6+ characters (see *Key decisions*).

### 5. Tests
```bash
flutter test
```

---

## 🏛️ Architecture

Clean Architecture, organised **feature-first**. Each feature is split into three layers, and dependencies only point inwards:

```
presentation  ──▶  domain  ◀──  data
 (widgets,          (entities,      (models, data sources,
  Riverpod           repository      repository implementations,
  notifiers)         interfaces,     Dio, Hive)
                     use cases)
```

- **Domain** is pure Dart: entities, repository *interfaces* and use cases. It doesn't know about JSON, Dio, Hive or Flutter widgets.
- **Data** implements the interfaces. Data sources throw exceptions; repositories catch them and return `Result<T>` (`Success` / `Err(Failure)`), so exceptions never leak upward.
- **Presentation** holds Riverpod notifiers (state + intent methods) and widgets that render that state.
- **DI** lives in each feature's `di/` folder as Riverpod providers. Swapping an implementation (or a fake in tests) is a single `overrideWithValue`.

### Request flow (feed example)

```
FeedScreen ──watch──▶ feedProvider(category)  (FeedNotifier)
                         │ calls
                         ▼
                   GetTopHeadlines (use case)
                         │
                         ▼
                 NewsRepository (interface)  ◀── implemented by NewsRepositoryImpl
                                                     ├─ NewsApiRemoteDataSource (Dio → NewsAPI)
                                                     └─ NewsLocalDataSource   (Hive cache)
```

On success the first page is cached in Hive. On a network/timeout failure the repository returns the cached page flagged `isFromCache`, and the UI shows an **offline banner**.

---

## 📁 Folder structure

```
lib/
├── main.dart                     # Entry point: error hooks, bootstrap, ProviderScope
├── app.dart                      # MaterialApp.router + themes
├── bootstrap.dart                # Hive init, adapter registration, safe box opening
│
├── core/                         # Cross-cutting, feature-agnostic code
│   ├── config/env.dart           # --dart-define values (API key)
│   ├── constants/                # Page size, debounce, limits, suggested topics
│   ├── error/                    # exceptions, sealed Failures, ErrorMapper (Dio/NewsAPI → Failure)
│   ├── network/                  # Dio provider, endpoints
│   ├── router/                   # go_router config with auth redirect, route names
│   ├── storage/hive_boxes.dart   # Box names & type ids in one place
│   ├── theme/                    # Material 3 light/dark theme
│   ├── utils/                    # Result<T>, validators, date formatting
│   └── widgets/                  # ErrorView, EmptyView, skeletons, offline banner, pagination footer
│
├── shared/                       # The Article model used by several features
│   ├── domain/entities/article.dart
│   ├── data/models/              # ArticleModel (JSON) + hand-written Hive TypeAdapter
│   └── presentation/widgets/     # ArticleCard
│
└── features/
    ├── auth/
    │   ├── domain/   (User, AuthRepository, Login/Logout/GetCurrentUser)
    │   ├── data/     (UserModel, AuthLocalDataSource, AuthRepositoryImpl)
    │   ├── di/       (providers)
    │   └── presentation/ (AuthController, LoginScreen)
    ├── news/                     # Feed + Search + Article detail
    │   ├── domain/   (NewsCategory, SearchFilters, PagedArticles, repositories, use cases)
    │   ├── data/     (NewsAPI remote source, Hive cache, response model, repositories)
    │   ├── di/
    │   └── presentation/ (feed & search notifiers, screens, widgets)
    ├── favorites/
    │   ├── domain/ data/ di/
    │   └── presentation/ (FavoritesNotifier, FavoritesScreen, FavoriteButton)
    └── home/presentation/home_shell.dart   # Bottom navigation shell

test/
├── helpers/fakes.dart            # Fake repositories
├── core/error_mapper_test.dart   # Error mapping, validators, date formatting
├── shared/article_test.dart      # Entity logic & JSON parsing
├── features/news/                # Feed pagination/refresh/errors, search debounce/filters
└── widget_test.dart              # Login form validation & session
```

---

## 🧠 Key decisions

**NewsAPI.org.** Well-documented, has category headlines *and* full-text search with sort/date/language filters — exactly what the feed and search screens need. The key is sent in the `X-Api-Key` header (never in URLs or logs) and injected at build time with `--dart-define-from-file`.

**Riverpod `Notifier` / `FamilyNotifier` without code generation.** Keeps the build simple (no `build_runner`) while still giving compile-time safety. The feed uses a `family` keyed by category, so every category keeps its own list, page and scroll data; switching back is instant. Derived providers (`favoriteUrlsProvider`, `isFavoriteProvider`) give O(1) bookmark lookups and rebuild only the icons that change.

**Explicit state classes over `AsyncValue` for lists.** Paginated lists need more than loading/data/error: *loading more*, *load-more error*, *has more*, *from cache*. A small immutable state with `copyWith` models that precisely, and lets a failed refresh keep the current list visible.

**`Result<T>` + sealed `Failure`s.** Repositories never throw. The UI pattern-matches on failure type to show the right icon and copy (offline, timeout, API key, rate limit, …). Because `Failure` is `sealed`, adding a new type without handling it is a compile error.

**Race-condition safety.** Every first-page/search request gets an id; responses from superseded requests (e.g. you typed more, or refreshed while a page was loading) are dropped. Search is debounced (500 ms) and requires 2+ characters.

**Hive with a hand-written `TypeAdapter`.** Favourites are a typed `Box<ArticleModel>`; field indices are documented so the schema can evolve. Article URLs can exceed Hive's 255-char ASCII key limit, so keys are a stable FNV-1a hash. Corrupted boxes are deleted and recreated at startup instead of crashing the app.

**Simple login is local.** Public news APIs have no user accounts, so `AuthRepositoryImpl` validates credentials, creates a session and persists it in Hive. It sits behind the `AuthRepository` interface — plugging in a real backend means adding a remote data source; nothing in the domain or UI changes.

**Full article view.** NewsAPI's free tier returns only a ~200-character snippet of the body. The detail screen shows everything the API provides and opens the publisher's page in an in-app browser tab (Custom Tabs / SFSafariViewController) for the complete story.

**go_router with `StatefulShellRoute`.** Each bottom tab keeps its own stack and scroll position. Auth redirects are driven by a `ValueNotifier` fed from Riverpod, so the router is built once and never recreated.

### Known limitations / next steps
- NewsAPI's free plan: 100 requests/day, max 100 results per query, and production (non-localhost) web requests are blocked — mobile builds work.
- Add integration tests and golden tests for key screens.
- Replace the local login with Firebase Auth or a real backend.

---

## 📝 Commit history
Commits are small and scoped using Conventional Commits (`feat`, `test`, `docs`, `chore`), one per layer/feature, so the history reads as the build-up of the app.