# Platforms and builds

DARAM uses one Flutter codebase for Android, iOS, Linux and the web. The core
experience is identical; storage, secure storage and a few browser limits differ
by platform.

| Platform | Status in this repository | Local data | API-key storage |
|---|---|---|---|
| Android | **built and verified** (`app-debug.apk`) | SQLite file in app storage | Android Keystore / encrypted prefs |
| iOS | configured; **not built here** (no macOS/Xcode) | SQLite file in app storage | Keychain |
| Linux | **built and smoke-tested** (debug + release) | SQLite file via `path_provider` | libsecret keyring |
| Web | **built and verified in Chrome** | IndexedDB via drift WASM (OPFS when available) | WebCrypto in the browser |

Flutter **3.47.7** / Dart **3.13.5**. The generated drift code is committed, so
`dart run build_runner build` is only needed after changing tables.

## Android

```bash
flutter build apk --debug
# build/app/outputs/flutter-apk/app-debug.apk
```

`minSdk 24`, `applicationId ir.daram.daram`, label «دارام». Use
`./scripts/build-android.sh` for a signed release: the first run generates a
release keystore and `android/key.properties` (gitignored), and the script passes
`-PrequireReleaseSigning=true` so production builds cannot fall back to the debug
key. See [`RELEASING.md`](RELEASING.md) and the environment note in the README
for this machine's read-only Flutter SDK workaround.

## iOS

The `ios/` project is configured and uses the same plugins. Build on macOS:

```bash
flutter build ios --release
```

It was not built in this environment. The iOS deployment target is whatever
Flutter 3.47 generates; adjust in Xcode if a plugin raises it.

## Linux

### Prerequisites

Flutter's Linux toolchain plus:

- Debian/Ubuntu: `clang cmake ninja-build pkg-config libgtk-3-dev libsecret-1-dev liblzma-dev`
- Arch: `clang cmake ninja pkgconf gtk3 libsecret`
- A running keyring (GNOME Keyring or KWallet) for saving the AI API key.
- `zenity` or `qarma` for the file export/import dialogs.

`flutter doctor` should report the Linux toolchain as ready.

### Build and run

```bash
flutter build linux --release
./build/linux/x64/release/bundle/daram
```

The debug variant is `build/linux/x64/debug/bundle/daram`. The default window is
480 × 900 and resizable; wider windows keep the phone-first layout centered in a
600 px frame.

### Data and security

- The database is `daram.sqlite` in the directory returned by
  `getApplicationDocumentsDirectory()` (normally `~/Documents`; `~` when XDG user
  directories are not configured).
- The API key is stored through `flutter_secure_storage_linux` / libsecret. If no
  keyring is available, saving the key reports an error; all local (non-AI)
  features keep working.
- CSV/PDF/backup export uses the native file dialog through `file_picker_linux`.

### Verification

A debug build was launched on a real X11 display with isolated
`HOME`/`XDG_*` directories. It initialized the database, seeded categories and
stayed running until the test timeout. A release build is produced at the path
above.

## Web

### Build and serve

```bash
flutter build web --release --no-web-resources-cdn
python3 -m http.server 8080 --directory build/web
# open http://localhost:8080
```

`--no-web-resources-cdn` bundles CanvasKit and the engine resources locally, so
the app does not call Google's CDN for rendering. This matters on restricted
networks.

For development, `flutter run -d chrome` also works. The generated PWA is
installable; the Flutter service worker caches the app shell.

### Required web files

The browser build needs two files at the **web root** (already committed under
`web/` and copied into `build/web/` by Flutter):

| File | Purpose | Source |
|---|---|---|
| `sqlite3.wasm` | SQLite compiled to WASM | sqlite3.dart **3.9.0** release assets |
| `drift_worker.js` | drift's database worker | compiled from `tool/drift_worker.dart` |

The worker is compiled from this project's dependency graph:

```bash
dart compile js -O4 tool/drift_worker.dart -o web/drift_worker.js
```

**Keep the worker and `sqlite3.wasm` in sync.** The worker embeds drift's SQLite
JS loader; using a newer `sqlite3.wasm` with an older worker can fail at
`WebAssembly.instantiate()` with a missing import. When upgrading `drift` or
`sqlite3`, regenerate both and re-test the browser build.

### Storage

- Drift opens a WASM database backed by **IndexedDB** (the verified path) and
  uses **OPFS** when browser isolation features permit. The app remains
  local-first; nothing is sent to a DARAM server.
- Data is scoped to the browser and origin. Clearing site data deletes the
  database, settings and the encrypted API key. Use the JSON backup regularly.
- The web build gets a dark branded boot screen while `main.dart.js` and the
  database initialize.

### AI on the web

- **CORS:** a browser can only call an AI endpoint that allows the app's origin.
  OpenAI-compatible endpoints commonly block direct browser calls; Anthropic's
  direct-browser header is sent automatically by DARAM, and Gemini/custom
  endpoints vary. If a provider blocks CORS, use the Android/Linux build. The AI
  settings screen shows this warning and connection errors explain it.
- **Streaming:** the browser adapter buffers the response, so token-by-token
  typing is not shown; the full text and tool calls appear when the response
  completes. Tool calling, drafts, confirmation and undo behave normally.
- **Key storage:** `flutter_secure_storage_web` uses WebCrypto and needs a secure
  context — **HTTPS or localhost**. On plain HTTP over a LAN IP, saving the key
  fails gracefully and the app remains usable without AI.
- **Downloads:** CSV/PDF/backup export triggers a normal browser download;
  import uses the browser file picker.

### Market prices on the web

- Bonbast requires a `Cookie` header and `X-Requested-With` and Chand publishes
  no CORS headers, so those two sources cannot be called from a browser. The
  web build still fetches the CORS-enabled sources when available, reports the
  blocked ones in the market snapshot, and the asset editor always accepts a
  manual rate. Use the Android/Linux build for the full live-rate experience.
- The market layer caches one snapshot for five minutes and is shared by the
  asset editor and the assistant, so a single refresh covers both.

### Verification

The release/profile build was served locally and driven in headless Chrome via
the DevTools protocol:

- startup completed and the WASM database reported `sharedIndexedDb`;
- onboarding could be skipped;
- the chat screen, settings banner and dashboard rendered in RTL with the
  bundled Vazirmatn font;
- no runtime exceptions were logged after the database opened.

Screenshots: [web chat](screenshots/web-chat-light.png) ·
[web dashboard](screenshots/web-dashboard-light.png) ·
[web desktop frame](screenshots/web-desktop-light.png).

## Checks

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
flutter build linux --release
```
