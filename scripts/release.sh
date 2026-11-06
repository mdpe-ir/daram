#!/usr/bin/env bash
# =============================================================================
# DARAM interactive release builder
#
# Builds signed Android releases, the production web bundle and the Linux
# bundle. Generates a release keystore on first use (or on demand), writes
# android/key.properties (gitignored), and puts versioned artifacts in dist/.
#
# Usage:
#   ./scripts/release.sh                              # interactive menu
#   ./scripts/release.sh --android [apk|split|aab]
#   ./scripts/release.sh --web
#   ./scripts/release.sh --linux
#   ./scripts/release.sh --all
#   ./scripts/release.sh --keygen
#   ./scripts/release.sh --help
#
# Non-interactive builds (CI) require an existing android/key.properties:
#   ./scripts/release.sh --android aab --non-interactive
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${DIST_DIR:-$ROOT/dist}"
ANDROID_DIR="$ROOT/android"
KEY_PROPERTIES="$ANDROID_DIR/key.properties"
DEFAULT_KEYSTORE="${KEYSTORE_PATH:-$HOME/.daram/keys/daram-release.jks}"
DEFAULT_DNAME="${KEY_DNAME:-CN=DARAM, OU=Mobile, O=DARAM, L=Tehran, ST=Tehran, C=IR}"
KEY_ALIAS="${KEY_ALIAS:-daram}"

ACTION=""
ANDROID_MODE="apk"
CLEAN=false
NON_INTERACTIVE=false

if [[ -t 1 ]]; then
    RED=$'\033[0;31m'
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[1;33m'
    BLUE=$'\033[0;34m'
    CYAN=$'\033[0;36m'
    MAGENTA=$'\033[0;35m'
    BOLD=$'\033[1m'
    NC=$'\033[0m'
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    CYAN=""
    MAGENTA=""
    BOLD=""
    NC=""
fi

SUMMARY=()

info() { echo -e "${BLUE}▶${NC} $*"; }
ok() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
die() { echo -e "${RED}✗ $*${NC}" >&2; exit 1; }
section() {
    echo
    echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
    echo -e "${BOLD}$*${NC}"
    echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
}

usage() {
    cat <<'EOF'
DARAM release builder

Usage:
  scripts/release.sh                              Interactive menu
  scripts/release.sh --android [apk|split|aab]    Android release (default: apk)
  scripts/release.sh --web                        Production web zip
  scripts/release.sh --linux                      Production Linux tar.gz
  scripts/release.sh --all                        Android APK + web + Linux
  scripts/release.sh --keygen                     Generate/renew the Android signing key
  scripts/release.sh --help                       Show this help

Options:
  --clean             Run `flutter clean` before building
  --non-interactive   Never prompt; Android requires an existing key.properties
  -h, --help          Show this help

Signing:
  The first Android release prompts for a keystore. It is created at
  ~/.daram/keys/daram-release.jks by default, and android/key.properties is
  written with 0600 permissions. Both are excluded from git. Back them up:
  losing the key prevents updates to an app already published with it.

Environment:
  KEYSTORE_PATH       Override the keystore output path
  KEYSTORE_PASSWORD   Store/key password (min 6 printable ASCII characters)
  KEY_ALIAS           Key alias (default: daram)
  KEY_DNAME           Certificate distinguished name
  DIST_DIR            Artifact directory (default: ./dist)
  FLUTTER_BIN         Flutter executable (default: ./.tool/flutter, then flutter)
  JAVA_HOME           JDK 21/17 (used for keytool and Gradle)
  ANDROID_HOME        Android SDK root

Outputs (dist/):
  daram-<version>-<build>-android.apk / -android.aab / split ABIs
  daram-<version>-<build>-web.zip
  daram-<version>-<build>-linux-<arch>.tar.gz
  SHA256SUMS

Examples:
  ./scripts/build-android.sh aab
  ./scripts/release.sh --android split --clean
  ./scripts/release.sh --keygen
  KEYSTORE_PATH=/secure/daram.jks KEYSTORE_PASSWORD='...' \
    ./scripts/release.sh --keygen --non-interactive
EOF
}

read_prompt() {
    local prompt="$1"
    local default="${2:-}"
    local result=""
    if [[ -t 0 ]]; then
        read -r -p "$prompt" result || true
    elif [[ -r /dev/tty ]]; then
        read -r -p "$prompt" result < /dev/tty || true
    fi
    printf '%s' "${result:-$default}"
}

read_secret() {
    local prompt="$1"
    local result=""
    if [[ -t 0 ]]; then
        read -r -s -p "$prompt" result
        echo
    elif [[ -r /dev/tty ]]; then
        read -r -s -p "$prompt" result < /dev/tty
        echo
    else
        die "No interactive terminal for a password prompt; set KEYSTORE_PASSWORD."
    fi
    printf '%s' "$result"
}

confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local answer
    answer="$(read_prompt "$prompt" "$default")"
    [[ "$answer" =~ ^[Yy] ]]
}

# Escape a value for a Java .properties file. Gradle reads key.properties with
# java.util.Properties, so spaces, ':', '=', '#', '!' and backslashes need the
# properties-file escaping rather than a restrictive password policy.
properties_escape() {
    local value="$1"
    local out=""
    local char
    local i
    for ((i = 0; i < ${#value}; i++)); do
        char="${value:i:1}"
        case "$char" in
            '\') out+='\\' ;;
            ' ') out+='\ ' ;;
            ':') out+='\:' ;;
            '=') out+='\=' ;;
            '#') out+='\#' ;;
            '!') out+='\!' ;;
            $'\t') out+='\t' ;;
            *) out+="$char" ;;
        esac
    done
    printf '%s' "$out"
}

properties_unescape() {
    local value="$1"
    local out=""
    local char
    local i
    for ((i = 0; i < ${#value}; i++)); do
        char="${value:i:1}"
        if [[ "$char" == '\' ]]; then
            i=$((i + 1))
            char="${value:i:1}"
            case "$char" in
                t) out+=$'\t' ;;
                n) out+=$'\n' ;;
                r) out+=$'\r' ;;
                *) out+="$char" ;;
            esac
        else
            out+="$char"
        fi
    done
    printf '%s' "$out"
}

# keytool's PKCS12 implementation rejects any code point above 0x7f. Check
# bytes in the C locale so Persian/Arabic digits pasted from another keyboard
# layout are rejected before keytool runs, regardless of the shell locale.
password_is_ascii() {
    local value="$1"
    local old_lc="${LC_ALL:-}"
    local i char code
    export LC_ALL=C
    for ((i = 0; i < ${#value}; i++)); do
        char="${value:i:1}"
        case "$char" in
            "'") code=39 ;;
            *) printf -v code '%d' "'$char" 2>/dev/null || code=255 ;;
        esac
        if ((code < 32 || code > 126)); then
            [[ -n "$old_lc" ]] && export LC_ALL="$old_lc" || unset LC_ALL
            return 1
        fi
    done
    [[ -n "$old_lc" ]] && export LC_ALL="$old_lc" || unset LC_ALL
    return 0
}

parse_args() {
    while (($#)); do
        case "$1" in
            --android)
                ACTION="android"
                if (($# >= 2)) && [[ "$2" =~ ^(apk|split|aab)$ ]]; then
                    ANDROID_MODE="$2"
                    shift
                fi
                ;;
            --web) ACTION="web" ;;
            --linux) ACTION="linux" ;;
            --all) ACTION="all" ;;
            --keygen|--generate-key) ACTION="keygen" ;;
            --clean) CLEAN=true ;;
            --non-interactive) NON_INTERACTIVE=true ;;
            --help|-h) usage; exit 0 ;;
            apk|split|aab)
                ACTION="android"
                ANDROID_MODE="$1"
                ;;
            *) die "Unknown option: $1 (use --help)" ;;
        esac
        shift
    done
}

load_version() {
    local raw
    raw="$(awk '$1 == "version:" { print $2; exit }' "$ROOT/pubspec.yaml")"
    [[ -n "$raw" ]] || die "Could not read version from pubspec.yaml"
    if [[ "$raw" == *+* ]]; then
        VERSION_NAME="${raw%%+*}"
        VERSION_CODE="${raw##*+}"
    else
        VERSION_NAME="$raw"
        VERSION_CODE="1"
    fi
    [[ "$VERSION_CODE" =~ ^[0-9]+$ ]] || die "Build code must be an integer in pubspec.yaml"
    BASE="daram-${VERSION_NAME}-${VERSION_CODE}"
}

setup_flutter() {
    if [[ -n "${FLUTTER_BIN:-}" ]]; then
        :
    elif [[ -x "$ROOT/.tool/flutter" ]]; then
        FLUTTER_BIN="$ROOT/.tool/flutter"
        if [[ -d "$ROOT/.tool/pub-cache" ]]; then
            export PUB_CACHE="$ROOT/.tool/pub-cache"
        fi
    elif command -v flutter >/dev/null 2>&1; then
        FLUTTER_BIN="$(command -v flutter)"
    else
        die "Flutter was not found. Set FLUTTER_BIN or add flutter to PATH."
    fi
    [[ -x "$FLUTTER_BIN" ]] || die "Flutter executable is not executable: $FLUTTER_BIN"
}

prepare_java() {
    local candidate
    if [[ -n "${JAVA_HOME:-}" && -x "$JAVA_HOME/bin/keytool" && "$JAVA_HOME" != *java-26* ]]; then
        :
    else
        for candidate in /usr/lib/jvm/java-21-openjdk /usr/lib/jvm/java-17-openjdk; do
            if [[ -x "$candidate/bin/keytool" ]]; then
                export JAVA_HOME="$candidate"
                break
            fi
        done
    fi

    if [[ -n "${JAVA_HOME:-}" && -x "$JAVA_HOME/bin/keytool" ]]; then
        KEYTOOL="$JAVA_HOME/bin/keytool"
        export PATH="$JAVA_HOME/bin:$PATH"
    elif command -v keytool >/dev/null 2>&1; then
        KEYTOOL="$(command -v keytool)"
    else
        die "keytool was not found. Install a JDK (21 recommended) or set JAVA_HOME."
    fi
    export JAVA_HOME
}

prepare_android() {
    prepare_java

    if [[ -z "${ANDROID_HOME:-}" ]]; then
        if [[ -d "$HOME/Android/Sdk" ]]; then
            export ANDROID_HOME="$HOME/Android/Sdk"
        elif [[ -d "/opt/android-sdk" ]]; then
            export ANDROID_HOME="/opt/android-sdk"
        fi
    fi
    [[ -n "${ANDROID_HOME:-}" && -d "$ANDROID_HOME" ]] || \
        die "Android SDK not found. Set ANDROID_HOME."

    if [[ -d "$ROOT/.tool/android-home" ]]; then
        export ANDROID_USER_HOME="$ROOT/.tool/android-home"
    fi
    if [[ -d "$ROOT/.tool/gradle-home" ]]; then
        export GRADLE_USER_HOME="$ROOT/.tool/gradle-home"
    fi
    export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin"

    # This checkout uses a read-only Flutter SDK and a writable symlinked view
    # for Gradle. Normal developer machines do not have .tool/flutter-sdk.
    if [[ -d "$ROOT/.tool/flutter-sdk" ]]; then
        local local_props="$ANDROID_DIR/local.properties"
        local tmp
        touch "$local_props"
        tmp="$(mktemp)"
        awk -v sdk="$ROOT/.tool/flutter-sdk" '
            BEGIN { found = 0 }
            /^flutter.sdk=/ { print "flutter.sdk=" sdk; found = 1; next }
            { print }
            END { if (!found) print "flutter.sdk=" sdk }
        ' "$local_props" > "$tmp"
        mv "$tmp" "$local_props"
    fi

    APKSIGNER=""
    APKSIGNER="$(find "$ANDROID_HOME/build-tools" -maxdepth 2 -type f -name apksigner 2>/dev/null | sort -V | tail -1 || true)"
}

pub_get() {
    info "Resolving Flutter dependencies…"
    "$FLUTTER_BIN" pub get
}

clean_build() {
    info "Cleaning previous build artifacts…"
    "$FLUTTER_BIN" clean
    pub_get
}

signing_configured() {
    [[ -s "$KEY_PROPERTIES" ]]
}

validate_signing() {
    prepare_java
    [[ -s "$KEY_PROPERTIES" ]] || die "android/key.properties is missing or empty."

    local store_file alias store_pass key_password store_path
    store_file="$(sed -n 's/^storeFile=//p' "$KEY_PROPERTIES" | head -1)"
    alias="$(sed -n 's/^keyAlias=//p' "$KEY_PROPERTIES" | head -1)"
    store_pass="$(properties_unescape "$(sed -n 's/^storePassword=//p' "$KEY_PROPERTIES" | head -1)")"
    key_password="$(properties_unescape "$(sed -n 's/^keyPassword=//p' "$KEY_PROPERTIES" | head -1)")"

    [[ -n "$store_file" && -n "$alias" && -n "$store_pass" ]] || \
        die "android/key.properties must contain storeFile, storePassword, keyAlias and keyPassword."
    [[ -n "$key_password" ]] || die "android/key.properties is missing keyPassword."

    store_path="$store_file"
    if [[ "$store_path" != /* ]]; then
        store_path="$ANDROID_DIR/$store_path"
    fi
    [[ -f "$store_path" ]] || die "Keystore not found: $store_path"

    export DARAM_STOREPASS="$store_pass"
    if ! "$KEYTOOL" -list -keystore "$store_path" -alias "$alias" \
        -storepass:env DARAM_STOREPASS >/dev/null 2>&1; then
        unset DARAM_STOREPASS
        die "Keystore check failed (wrong password/alias or corrupt file)."
    fi
    unset DARAM_STOREPASS
    ok "Release signing configured (alias: $alias)"
}

generate_keystore() {
    prepare_java

    if signing_configured; then
        if [[ "$NON_INTERACTIVE" == true ]]; then
            die "android/key.properties already exists; refusing to overwrite it non-interactively."
        fi
        warn "A release signing configuration already exists at android/key.properties."
        if ! confirm "Replace it and generate a new keystore? [y/N] " n; then
            info "Keeping the existing signing configuration."
            return 0
        fi
    fi

    local key_path="${KEYSTORE_PATH:-$DEFAULT_KEYSTORE}"
    if [[ "$key_path" != /* ]]; then
        key_path="$ROOT/$key_path"
    fi

    if [[ "$NON_INTERACTIVE" != true ]]; then
        key_path="$(read_prompt "Keystore path [$key_path]: " "$key_path")"
        [[ "$key_path" == /* ]] || key_path="$ROOT/$key_path"
        KEY_ALIAS="$(read_prompt "Key alias [$KEY_ALIAS]: " "$KEY_ALIAS")"
    fi

    [[ "$KEY_ALIAS" =~ ^[A-Za-z0-9._-]+$ ]] || die "Key alias may only contain letters, digits, dot, dash or underscore."

    local store_pass="${KEYSTORE_PASSWORD:-}"
    if [[ -z "$store_pass" ]]; then
        if [[ "$NON_INTERACTIVE" == true ]]; then
            die "KEYSTORE_PASSWORD is required for --non-interactive --keygen."
        fi
        store_pass="$(read_secret "Keystore password (min 6 chars, printable ASCII; symbols allowed): ")"
        local confirm_pass
        confirm_pass="$(read_secret "Confirm keystore password: ")"
        [[ "$store_pass" == "$confirm_pass" ]] || die "Passwords do not match."
    fi
    [[ ${#store_pass} -ge 6 ]] || die "Keystore password must be at least 6 characters."
    if ! password_is_ascii "$store_pass"; then
        die "The password contains a non-ASCII character (for example Persian/Arabic digits from a non-English keyboard layout). keytool only accepts ASCII. Switch to an English layout, or use KEYSTORE_PASSWORD='...' with --keygen --non-interactive."
    fi

    local dname="$DEFAULT_DNAME"
    if [[ "$NON_INTERACTIVE" != true ]]; then
        dname="$(read_prompt "Certificate DN [$dname]: " "$dname")"
    fi

    if [[ -e "$key_path" ]]; then
        if [[ "$NON_INTERACTIVE" == true ]]; then
            die "Keystore already exists at $key_path; refusing to overwrite it non-interactively."
        fi
        warn "A file already exists at $key_path."
        if confirm "Overwrite it? A timestamped backup will be kept. [y/N] " n; then
            mv "$key_path" "${key_path}.bak-$(date +%Y%m%d-%H%M%S)"
        else
            die "Choose a different KEYSTORE_PATH or move the existing keystore."
        fi
    fi

    mkdir -p "$(dirname "$key_path")"
    chmod 700 "$(dirname "$key_path")"

    section "Generating Android release keystore"
    echo "Path    : $key_path"
    echo "Alias   : $KEY_ALIAS"
    echo "DN      : $dname"
    echo "Validity: 10000 days"

    export DARAM_STOREPASS="$store_pass"
    if ! "$KEYTOOL" -genkeypair \
        -keystore "$key_path" \
        -storetype PKCS12 \
        -alias "$KEY_ALIAS" \
        -keyalg RSA \
        -keysize 4096 \
        -validity 10000 \
        -storepass:env DARAM_STOREPASS \
        -keypass:env DARAM_STOREPASS \
        -dname "$dname"; then
        unset DARAM_STOREPASS
        rm -f "$key_path"
        die "keytool failed. It only accepts ASCII passwords. Switch to an English keyboard layout, or run: KEYSTORE_PASSWORD='your-ascii-password' ./scripts/release.sh --keygen --non-interactive"
    fi

    echo
    ok "Keystore fingerprint:"
    "$KEYTOOL" -list -v -keystore "$key_path" -alias "$KEY_ALIAS" \
        -storepass:env DARAM_STOREPASS | grep -E "SHA256:|Valid from:" | head -2 || true
    unset DARAM_STOREPASS

    local old_umask
    old_umask="$(umask)"
    umask 077
    local escaped_pass
    escaped_pass="$(properties_escape "$store_pass")"
    cat > "$KEY_PROPERTIES" <<EOF
storePassword=$escaped_pass
keyPassword=$escaped_pass
keyAlias=$KEY_ALIAS
storeFile=$key_path
EOF
    umask "$old_umask"
    chmod 600 "$KEY_PROPERTIES"
    chmod 600 "$key_path" 2>/dev/null || true

    echo
    ok "Wrote android/key.properties (gitignored, chmod 600)."
    warn "BACK UP the keystore and key.properties now. Losing them prevents updates to an installed release build."
    warn "Never commit either file. Do not share the password."
    echo
}

ensure_signing() {
    prepare_java
    if signing_configured; then
        validate_signing
        return 0
    fi

    if [[ "$NON_INTERACTIVE" == true ]]; then
        die "No release signing configuration. Create android/key.properties and retry."
    fi

    warn "No Android release signing key is configured."
    if confirm "Generate one now? [Y/n] " y; then
        generate_keystore
        validate_signing
    else
        die "Release build aborted: a signing key is required."
    fi
}

apk_certificate_summary() {
    local apk="$1"
    if [[ -z "${APKSIGNER:-}" || ! -x "$APKSIGNER" ]]; then
        warn "apksigner not found; skipped signature verification."
        return 0
    fi
    if ! "$APKSIGNER" verify "$apk" >/dev/null 2>&1; then
        die "APK signature verification failed: $apk"
    fi
    "$APKSIGNER" verify --print-certs "$apk" | sed -n \
        -e 's/^Signer #1 certificate DN: /  Signer: /p' \
        -e 's/^V[0-9] Signer: certificate DN: /  Signer: /p' \
        -e 's/^Signer #1 certificate SHA-256 digest: /  SHA-256: /p' \
        -e 's/^V[0-9] Signer: certificate SHA-256 digest: /  SHA-256: /p' | head -4
}

find_android_output() {
    local pattern="$1"
    local found
    found="$(find "$ROOT/build/app/outputs" "$ANDROID_DIR/app/build/outputs" \
        -type f -name "$pattern" 2>/dev/null | head -1 || true)"
    printf '%s' "$found"
}

build_android() {
    local mode="${1:-apk}"
    [[ "$mode" =~ ^(apk|split|aab)$ ]] || die "Unknown Android mode: $mode"

    ensure_signing
    prepare_android
    pub_get

    local direct=false
    if [[ -d "$ROOT/.tool/flutter-sdk" && -x "$ANDROID_DIR/gradlew" ]]; then
        direct=true
    fi

    section "Building Android release (${mode})"
    if [[ "$direct" == true ]]; then
        mkdir -p "$DIST_DIR"
        chmod +x "$ANDROID_DIR/gradlew"
        local task="assembleRelease"
        [[ "$mode" == "aab" ]] && task="bundleRelease"
        local -a gradle_args=("-PrequireReleaseSigning=true")
        [[ "$mode" == "split" ]] && gradle_args+=("-Psplit-per-abi=true")

        info "Using the repository's Gradle/Flutter SDK wrapper (read-only SDK workaround)."
        (
            cd "$ANDROID_DIR"
            ./gradlew "$task" "${gradle_args[@]}"
        )
    else
        case "$mode" in
            aab) "$FLUTTER_BIN" build appbundle --release ;;
            split) "$FLUTTER_BIN" build apk --release --split-per-abi ;;
            *) "$FLUTTER_BIN" build apk --release ;;
        esac
    fi

    local output_root="$ROOT/build/app/outputs"
    local -a built=()
    if [[ "$mode" == "aab" ]]; then
        local aab="$output_root/bundle/release/app-release.aab"
        [[ -f "$aab" ]] || aab="$(find_android_output "app-release.aab")"
        [[ -f "$aab" ]] || die "Release AAB was not produced."
        built+=("$aab")
    elif [[ "$mode" == "split" ]]; then
        local apk
        while IFS= read -r apk; do
            [[ -n "$apk" ]] && built+=("$apk")
        done < <(find "$output_root/flutter-apk" "$ANDROID_DIR/app/build/outputs" \
            -maxdepth 3 -type f -name "app-*-release.apk" 2>/dev/null | sort -u)
        ((${#built[@]} > 0)) || die "Split release APKs were not produced."
    else
        local apk="$output_root/flutter-apk/app-release.apk"
        [[ -f "$apk" ]] || apk="$(find_android_output "app-release.apk")"
        [[ -f "$apk" ]] || die "Release APK was not produced."
        built+=("$apk")
    fi

    mkdir -p "$DIST_DIR"
    local src dest
    for src in "${built[@]}"; do
        case "$mode" in
            aab)
                dest="$DIST_DIR/${BASE}-android.aab"
                ;;
            split)
                local abi
                abi="$(basename "$src")"
                abi="${abi#app-}"
                abi="${abi%-release.apk}"
                dest="$DIST_DIR/${BASE}-android-${abi}.apk"
                ;;
            *)
                dest="$DIST_DIR/${BASE}-android.apk"
                ;;
        esac
        cp -f "$src" "$dest"
        SUMMARY+=("$dest")

        if [[ "$mode" != "aab" ]]; then
            apk_certificate_summary "$dest"
        fi
        ok "Built $(basename "$dest") ($(du -h "$dest" | cut -f1))"
    done
}

build_web() {
    setup_flutter
    pub_get
    section "Building production web bundle"

    "$FLUTTER_BIN" build web --release --no-web-resources-cdn

    local required
    for required in index.html sqlite3.wasm drift_worker.js version.json manifest.json; do
        [[ -f "$ROOT/build/web/$required" ]] || die "Web build is missing $required"
    done

    local built_version
    built_version="$(sed -n 's/.*"version":"\([^"]*\)".*/\1/p' "$ROOT/build/web/version.json")"
    [[ "$built_version" == "$VERSION_NAME" ]] || \
        warn "version.json reports '$built_version' but pubspec says '$VERSION_NAME'."

    command -v zip >/dev/null 2>&1 || die "zip is required to package the web build."
    mkdir -p "$DIST_DIR"
    local zip_path="$DIST_DIR/${BASE}-web.zip"
    rm -f "$zip_path"
    (cd "$ROOT/build/web" && zip -qr "$zip_path" .)
    SUMMARY+=("$zip_path")
    ok "Built $(basename "$zip_path") ($(du -h "$zip_path" | cut -f1))"
    echo "  Unzip and serve: unzip $(basename "$zip_path") -d daram-web && python3 -m http.server 8080 --directory daram-web"
}

build_linux() {
    setup_flutter
    pub_get
    section "Building production Linux bundle"

    if ! "$FLUTTER_BIN" build linux --release; then
        die "Linux release build failed. On a read-only SDK machine, use the documented environment workaround."
    fi

    local binary bundle_dir
    binary="$(find "$ROOT/build/linux" -type f -name daram -path '*/release/bundle/daram' 2>/dev/null | head -1 || true)"
    [[ -n "$binary" && -x "$binary" ]] || die "Linux release binary was not produced."
    bundle_dir="$(dirname "$binary")"

    local arch
    case "$(uname -m)" in
        x86_64|amd64) arch="x64" ;;
        aarch64|arm64) arch="arm64" ;;
        *) arch="$(uname -m)" ;;
    esac

    command -v tar >/dev/null 2>&1 || die "tar is required."
    mkdir -p "$DIST_DIR"
    local tar_path="$DIST_DIR/${BASE}-linux-${arch}.tar.gz"
    tar -C "$bundle_dir" -czf "$tar_path" .
    SUMMARY+=("$tar_path")
    ok "Built $(basename "$tar_path") ($(du -h "$tar_path" | cut -f1))"
    echo "  Run with: mkdir -p daram-linux && tar xzf $(basename "$tar_path") -C daram-linux && ./daram-linux/daram"
}

record_checksums() {
    ((${#SUMMARY[@]} > 0)) || return 0
    command -v sha256sum >/dev/null 2>&1 || { warn "sha256sum not found; skipped checksums."; return 0; }
    mkdir -p "$DIST_DIR"
    (
        cd "$DIST_DIR"
        shopt -s nullglob
        local -a files=(daram-*)
        : > SHA256SUMS
        local file
        for file in "${files[@]}"; do
            [[ -f "$file" ]] && sha256sum "$file" >> SHA256SUMS
        done
    )
    ok "Checksums written to $DIST_DIR/SHA256SUMS"
}

print_summary() {
    ((${#SUMMARY[@]} > 0)) || return 0
    section "Release artifacts"
    local file
    for file in "${SUMMARY[@]}"; do
        printf '  %-52s %s\n' "$(basename "$file")" "$(du -h "$file" | cut -f1)"
    done
    echo
    echo "  Directory: $DIST_DIR"
    echo "  Checksums: $DIST_DIR/SHA256SUMS"
}

show_banner() {
    echo
    echo -e "${MAGENTA}============================================================${NC}"
    echo -e "${MAGENTA}${BOLD}                 DARAM release builder                     ${NC}"
    echo -e "${MAGENTA}============================================================${NC}"
    echo "  Version : ${VERSION_NAME} (${VERSION_CODE})"
    echo "  Output  : ${DIST_DIR}"
    if signing_configured; then
        echo -e "  Signing : ${GREEN}release key configured${NC}"
    else
        echo -e "  Signing : ${YELLOW}not configured (Android will offer to create one)${NC}"
    fi
    echo -e "${MAGENTA}============================================================${NC}"
    echo
}

interactive_menu() {
    show_banner
    echo -e "${BOLD}What do you want to build?${NC}"
    echo "  1) Android APK (universal, release)"
    echo "  2) Android APK (split per ABI)"
    echo "  3) Android App Bundle (AAB, Play Store)"
    echo "  4) Web (production zip)"
    echo "  5) Linux (production tar.gz)"
    echo "  6) All: Android APK + Web + Linux"
    echo "  7) Generate / renew Android release key"
    echo "  0) Exit"
    echo

    local choice
    choice="$(read_prompt "Choice [0-7]: " "0")"
    case "$choice" in
        1) ACTION="android"; ANDROID_MODE="apk" ;;
        2) ACTION="android"; ANDROID_MODE="split" ;;
        3) ACTION="android"; ANDROID_MODE="aab" ;;
        4) ACTION="web" ;;
        5) ACTION="linux" ;;
        6) ACTION="all" ;;
        7) ACTION="keygen" ;;
        0|"") echo "Bye."; exit 0 ;;
        *) die "Invalid choice: $choice" ;;
    esac
}

main() {
    parse_args "$@"
    load_version
    setup_flutter

    if [[ "$ACTION" == "keygen" ]]; then
        generate_keystore
        if [[ "$NON_INTERACTIVE" == true ]]; then
            ok "Signing setup complete. Run the Android build when ready."
            exit 0
        fi
        if confirm "Build an Android APK now? [y/N] " n; then
            ACTION="android"
            ANDROID_MODE="apk"
        else
            echo "Signing setup complete. Run ./scripts/build-android.sh when ready."
            exit 0
        fi
    elif [[ -z "$ACTION" ]]; then
        [[ "$NON_INTERACTIVE" == true ]] && die "Choose --android, --web, --linux or --all in non-interactive mode."
        interactive_menu
    fi

    if [[ "$CLEAN" != true && "$ACTION" != "keygen" && "$NON_INTERACTIVE" != true ]]; then
        if confirm "Clean previous build artifacts first? [y/N] " n; then
            CLEAN=true
        fi
    fi
    if [[ "$CLEAN" == true ]]; then
        clean_build
    fi

    mkdir -p "$DIST_DIR"
    case "$ACTION" in
        android) build_android "$ANDROID_MODE" ;;
        web) build_web ;;
        linux) build_linux ;;
        all)
            build_android "apk"
            build_web
            build_linux
            ;;
        *) die "Nothing to build (action: $ACTION)" ;;
    esac

    record_checksums
    print_summary
    echo
    ok "Done."
}

main "$@"
