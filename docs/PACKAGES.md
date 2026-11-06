# Package selection

All versions below were resolved with Flutter **3.47.7** / Dart **3.13.5** on 2026-11-06. Every package was checked on pub.dev for its latest version, null safety, platform support and publication activity before adoption. Licenses are listed for the audit trail.

## Direct dependencies

| Package | Version | License | Why it is here | Alternatives considered |
|---|---|---|---|---|
| `flutter_riverpod` | 3.4.3 | MIT | State management and dependency injection. Providers are overridden in tests; controllers stay free of `BuildContext`. | `provider`, `bloc`; Riverpod 3's compile-time safety and override ergonomics won. |
| `go_router` | 18.1.3 | BSD-3-Clause | Declarative routing with `StatefulShellRoute.indexedStack` for the four tabs and nested settings/records routes. | `auto_route` (codegen overhead), Navigator 1.0 (no deep links). |
| `drift` / `drift_flutter` | 2.35.3 / 0.3.1 | MIT | Typed SQLite with streams, joins, transactions and migrations. `drift_flutter` sets up native SQLite or the web WASM connection. | `sqflite` (untyped), `isar` (no SQL, binary format); Drift's ledger queries and testability were decisive. |
| `sqlite3` | 3.9.0 | MIT | Native SQLite bindings used by Drift on Android/iOS/Linux; the web build uses the matching `sqlite3.wasm`. `sqlite3_flutter_libs` 0.6 is EOL; Drift 2.35 depends on sqlite3 3.x native assets. | `sqlite3_flutter_libs` (EOL), `sqflite`. |
| `dio` | 5.11.1 | MIT | HTTP client with streaming responses, `CancelToken`, per-request timeouts and interceptors. On web the XHR adapter buffers the stream, so responses arrive on completion. | `http` (weak streaming/cancellation), `chopper` (codegen). |
| `flutter_secure_storage` | 11.2.0 | BSD-3-Clause | Stores the user's API key in Android Keystore, iOS Keychain, Linux libsecret or the browser's WebCrypto-backed store. | `shared_preferences` (plaintext — unacceptable for keys). |
| `shared_preferences` | 2.5.6 | BSD-3-Clause | Non-sensitive settings: theme, currency, digits, provider metadata. | A second Drift table; preferences are simpler and available before the DB is opened. |
| `shamsi_date` | 1.1.1 | MIT | Jalali ↔ Gregorian conversion with correct leap-year handling. | Hand-rolled conversion (rejected: error-prone), `jalali_calendar` (less maintained). |
| `intl` | 0.20.3 | BSD-3-Clause | Number/date formatting primitives; the app supplies its own Persian digit and money formatting on top. | No practical alternative for locale-aware primitives. |
| `fl_chart` | 1.3.0 | MIT | Animated bar and donut charts for the dashboard and in-chat reports. | `syncfusion_flutter_charts` (license), `graphic` (heavier). |
| `flutter_animate` | 4.5.2 | MIT | Declarative entry animations for splash/onboarding/chat; keeps motion code readable. | Raw `AnimationController` everywhere (more boilerplate); Lottie (no suitable licensed asset). |
| `flutter_markdown_plus` | 1.0.12 | BSD-3-Clause | Maintained successor to `flutter_markdown` (which is discontinued). Renders assistant Markdown in chat. | `gpt_markdown` (more chat-specific but less CommonMark coverage); custom renderer (unnecessary risk). |
| `lucide_icons_flutter` | 4.0.2 | ISC | Actively maintained Lucide icon set with the geometric icons used in the design system. | `lucide_icons` 0.257 (no release since 2023), Material Icons (too generic for DARAM). |
| `flutter_svg` | 2.3.2 | MIT | Renders the locally bundled bank logos. | Converting every SVG to PNG (larger assets, lossy at scale). |
| `csv` | 8.0.0 | BSD-3-Clause | CSV encoding with an Excel-friendly BOM. | Hand-rolled quoting (fragile). |
| `pdf` | 3.13.1 | Apache-2.0 | Generates the A4 PDF report. | `printing` (adds a preview engine and platform packages; not needed for file export). |
| `arabic_reshaper` | 0.0.1 | MIT | The PDF renderer does not run OpenType shaping; this produces correct Persian presentation forms. | Accepting broken disconnected letters (unacceptable), `printing` (still needs shaping for PDF fonts). |
| `bidi` | 2.0.13 | MIT | Applies the Unicode BiDi algorithm so mixed Persian/numbers in PDFs appear in the right order. | Manual reversal (wrong for mixed text). |
| `file_picker` | 13.3.2 | MIT | Native save/open dialogs for CSV, PDF and backup files, browser downloads on web, and `zenity`-backed dialogs on Linux. | `share_plus` (shares instead of saves; not a file manager), `path_provider` only (no user choice). |
| `path_provider` | 2.1.6 | BSD-3-Clause | Transitive/platform path access used by Drift and file handling. | — |
| `path` | 1.9.1 | BSD-3-Clause | Cross-platform path joins. | String concatenation (platform bugs). |
| `uuid` | 4.6.0 | MIT | Client-side operation ids, entity ids and message ids for idempotency. | Auto-increment ids (cannot be generated before confirmation, hurts idempotency). |
| `collection` | 1.19.1 | BSD-3-Clause | `firstOrNull` and grouping helpers. | Hand-written helpers (noise). |
| `meta` | 1.19.0 | BSD-3-Clause | `@immutable` on value objects and entities. | — |
| `package_info_plus` | 10.2.2 | BSD-3-Clause | Reads the real version name and build code from Android/iOS, Linux `version.json` and the web `version.json`; shown in Settings and About. | Hardcoded constants (drift between pubspec/APK/web); the constants remain only as a loading fallback. |
| `cupertino_icons` | 1.0.8 | MIT | iOS icon fallbacks in Material widgets. | — |

## Dev dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_test`, `flutter_lints`, `flutter_localizations` | SDK | Tests, lints, Persian Material localizations. |
| `drift_dev` | 2.35.2 | Generates the database code. |
| `build_runner` | 2.17.1 | Runs Drift codegen. |
| `flutter_launcher_icons` | 0.14.4 | Generates Android legacy/adaptive/monochrome, iOS and web/PWA icons from the original 1024 px asset. |
| `fake_async` | 1.3.3 | Available for time-dependent tests. |

## Platform support

| Capability | Android | iOS | Linux | Web |
|---|---|---|---|---|
| Drift database | SQLite (native assets) | SQLite (native assets) | SQLite (native assets) | WASM + IndexedDB/OPFS |
| Secure API key | Keystore-backed | Keychain | libsecret keyring | WebCrypto (HTTPS/localhost) |
| File export/import | SAF picker | UIDocumentPicker | GTK/zenity dialog | Browser download/upload |
| Preferences | SharedPreferences | NSUserDefaults | XDG config | localStorage |
| AI streaming | SSE, incremental | SSE, incremental | SSE, incremental | buffered until completion |
| AI network access | direct | direct | direct | provider CORS required |

The web database worker is generated from `tool/drift_worker.dart` with
`dart compile js -O4 tool/drift_worker.dart -o web/drift_worker.js`. It embeds
drift's SQLite loader and must be regenerated whenever `drift` or `sqlite3`
changes; `web/sqlite3.wasm` must match the `sqlite3` package version.

## Deliberately not used

| Candidate | Reason |
|---|---|
| `langchain_dart` | Adds an abstraction layer whose tool-call and SSE behavior would still need provider-specific handling. DARAM needs byte-level control over OpenAI/Anthropic/Gemini streams, cancellation, custom base URLs and a strict JSON fallback; the custom ~1,200-line AI layer is smaller, fully typed and tested. |
| `firebase_*` | Explicit Phase 1 constraint (no Firebase, no Google services, local-first). |
| `google_fonts` | Would fetch fonts at runtime; DARAM bundles Vazirmatn for offline use. |
| `flutter_markdown` | Discontinued; replaced by `flutter_markdown_plus`. |
| `lucide_icons` | No release since 2023; `lucide_icons_flutter` 4.0.2 is current. |
| `sqlite3_flutter_libs` | 0.6.0 is EOL and a no-op; Drift 2.35 uses `sqlite3` 3.x native assets. |
| `rxdart` | Drift streams + Riverpod cover the app's reactive needs; an extra dependency was unnecessary. |
| `printing` | PDFs are exported as files; a preview engine is not required in Phase 1. |
| `share_plus` | The product needs "save to a chosen location", not a share sheet. |
| Prebuilt chat UI kits | They would compromise DARAM's custom design and the pending-action workflow. |

## Version policy

- Dependencies use caret constraints from the verified resolution (`pubspec.lock` is committed).
- Generated Drift code is committed so the app builds without running codegen.
- Before upgrading, run `flutter analyze`, `flutter test`, and an Android build. Any database column change requires a schema migration and test.
