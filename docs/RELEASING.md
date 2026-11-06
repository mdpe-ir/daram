# Releasing DARAM

One interactive script builds every production artifact into `dist/` with
versioned names and a `SHA256SUMS` file:

```bash
./scripts/release.sh
```

The menu offers:

1. Android APK (universal, signed release)
2. Android APK (split per ABI)
3. Android App Bundle (AAB, Play Store)
4. Web (production zip)
5. Linux (production tar.gz)
6. All: Android APK + Web + Linux
7. Generate / renew the Android release key
0. Exit

Direct wrappers:

```bash
./scripts/build-android.sh          # APK
./scripts/build-android.sh aab      # Play Store bundle
./scripts/build-android.sh split    # per-ABI APKs
./scripts/build-web.sh
./scripts/build-linux.sh
./scripts/release.sh --all --clean
```

All paths are relative to the repository root. Artifacts are written to
`dist/` (gitignored) as:

```
daram-<version>-<build>-android.apk
daram-<version>-<build>-android.aab
daram-<version>-<build>-android-<abi>.apk
daram-<version>-<build>-web.zip
daram-<version>-<build>-linux-<arch>.tar.gz
SHA256SUMS
```

The version comes from `pubspec.yaml`:

```yaml
version: 1.0.0+1
#         name  build code
```

Edit that line before a release; the scripts do not bump it silently.

## Android release signing

### First build

The first Android release asks whether to create a keystore. It creates:

- **Keystore:** `~/.daram/keys/daram-release.jks` by default (you can choose
  another path), 4096-bit RSA, 10,000 days.
- **`android/key.properties`:** points Gradle at the keystore, chmod `0600`.
  This file is already gitignored.

You are prompted for:

- a store/key password (minimum 6 characters; letters, digits and
  `._@#%+!-` are accepted so the Java properties file stays valid),
- the key alias (default `daram`),
- the certificate distinguished name (a sensible Iran/DARAM default is offered).

The password is passed to `keytool` through an environment variable, not as a
command-line argument, and is never printed. The script prints the SHA-256
certificate fingerprint.

> **Back up the keystore and `key.properties` now.** If you lose them you cannot
> publish updates to an app users already installed with that signature. Keep a
> copy in a password manager or an encrypted offline backup. Never commit them.

### Generate or renew manually

```bash
./scripts/release.sh --keygen
```

Non-interactive (for provisioning, not for a normal desktop release):

```bash
KEYSTORE_PATH="$HOME/.daram/keys/daram-release.jks" \
KEYSTORE_PASSWORD='a-strong-password' \
KEY_ALIAS=daram \
KEY_DNAME='CN=DARAM, OU=Mobile, O=DARAM, L=Tehran, ST=Tehran, C=IR' \
./scripts/release.sh --keygen --non-interactive
```

If `android/key.properties` already exists, the script refuses to overwrite it
non-interactively. Deleting or replacing a release key is a deliberate,
destructive action; back it up first.

### How Gradle uses it

`android/app/build.gradle.kts` reads `android/key.properties` when present and
uses the `release` signing config. When the release script runs, it also passes
`-PrequireReleaseSigning=true`; a production build therefore **fails** instead of
silently falling back to the Android debug key. A plain `flutter run --release`
without `key.properties` still works locally for quick testing (debug key).

The generated `key.properties` looks like this (values are secret):

```properties
storePassword=…
keyPassword=…
keyAlias=daram
storeFile=/home/you/.daram/keys/daram-release.jks
```

### Verify a build

```bash
apksigner verify --print-certs dist/daram-1.0.0-1-android.apk
jarsigner -verify -verbose -certs dist/daram-1.0.0-1-android.aab
```

The script runs `apksigner` automatically when it is available in
`$ANDROID_HOME/build-tools`.

For Play Store distribution, enroll in **Play App Signing** and upload the AAB.
Keep the upload key and its password safe; Google holds the app-signing key.

## CI example (GitHub Actions)

Store the keystore as base64 and the passwords/alias as repository secrets. Never
put them in the workflow file.

```yaml
- uses: actions/checkout@v4
- uses: actions/setup-java@v4
  with:
    distribution: temurin
    java-version: '21'
- uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.47.7'
    channel: stable
- name: Build signed AAB
  env:
    KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
    STORE_PASSWORD: ${{ secrets.ANDROID_STORE_PASSWORD }}
    KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
    KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
  run: |
    echo "$KEYSTORE_BASE64" | base64 --decode > "$RUNNER_TEMP/daram-release.jks"
    {
      printf 'storePassword=%s\n' "$STORE_PASSWORD"
      printf 'keyPassword=%s\n' "$KEY_PASSWORD"
      printf 'keyAlias=%s\n' "$KEY_ALIAS"
      printf 'storeFile=%s\n' "$RUNNER_TEMP/daram-release.jks"
    } > android/key.properties
    chmod 600 android/key.properties
    ./scripts/release.sh --android aab --non-interactive
- uses: actions/upload-artifact@v4
  with:
    name: daram-android-aab
    path: dist/*.aab
```

`--non-interactive` requires a valid `android/key.properties` and an existing
keystore; it never prompts.

## Web production

```bash
./scripts/build-web.sh
```

This runs:

```bash
flutter build web --release --no-web-resources-cdn
```

and packages **`build/web/`** into
`dist/daram-<version>-<build>-web.zip`. It checks that `sqlite3.wasm`,
`drift_worker.js`, `index.html`, `manifest.json` and `version.json` are present
and that `version.json` matches `pubspec.yaml`.

```bash
unzip dist/daram-1.0.0-1-web.zip -d daram-web
python3 -m http.server 8080 --directory daram-web
# http://localhost:8080
```

Deploy the contents of `build/web/` (or the zip) to any static host. The app uses
the hash URL strategy, so no server rewrite is required. CanvasKit is bundled
locally, so rendering does not depend on Google's CDN. API-key storage needs
**HTTPS or localhost**; AI calls are subject to provider CORS. See
[`docs/PLATFORMS.md`](PLATFORMS.md#web) for the web caveats.

## Linux production

```bash
./scripts/build-linux.sh
```

This builds the release bundle and packages it as
`dist/daram-<version>-<build>-linux-<arch>.tar.gz`. The archive contains the
binary, `lib/` and `data/`:

```bash
mkdir -p daram-linux
tar xzf dist/daram-1.0.0-1-linux-x64.tar.gz -C daram-linux
./daram-linux/daram
```

Prerequisites: Clang, CMake, Ninja, GTK 3 and libsecret. The keyring is needed to
save the AI API key; local finance features work without it. Details:
[`docs/PLATFORMS.md`](PLATFORMS.md#linux).

## Clean builds

```bash
./scripts/release.sh --android aab --clean
./scripts/build-web.sh --clean
./scripts/build-linux.sh --clean
```

`--clean` runs `flutter clean` and re-resolves dependencies before building. Use
it when switching Flutter versions or after changing native configuration.

## Environment overrides

| Variable | Purpose |
|---|---|
| `DIST_DIR` | Artifact directory (default `./dist`) |
| `FLUTTER_BIN` | Flutter executable (default: `./.tool/flutter`, then `flutter`) |
| `ANDROID_HOME` | Android SDK root |
| `JAVA_HOME` | JDK 21/17 used for Gradle and keytool |
| `KEYSTORE_PATH` | Keystore path for `--keygen` (default `~/.daram/keys/daram-release.jks`) |
| `KEYSTORE_PASSWORD` | Store/key password for non-interactive key generation |
| `KEY_ALIAS` | Key alias (default `daram`) |
| `KEY_DNAME` | Certificate distinguished name |

The script detects the repository's `.tool/flutter` wrapper. On this machine the
Flutter SDK is on a read-only mount, so release tasks that update engine stamps
need write access to the SDK cache; that is an environment constraint, not a
requirement on a normal developer machine. The Android build then uses the
project's documented direct-Gradle path automatically.

## Security checklist

- [ ] Keystore and `android/key.properties` backed up in two safe places.
- [ ] Neither file is tracked by git (`git check-ignore android/key.properties`).
- [ ] Passwords are not in shell history, CI logs, issues or screenshots.
- [ ] `dist/` and `build/` are not committed.
- [ ] AAB/APK signed with the expected certificate fingerprint.
- [ ] `SHA256SUMS` published with the binaries.
- [ ] Play App Signing enabled before the first Play upload.
