#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h}"
APP_NAME="Token Monitor"
EXECUTABLE_NAME="TokenMonitor"
DIST_DIR="$PROJECT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
MODULE_CACHE_DIR="$PROJECT_DIR/.build/module-cache"
SWIFTPM_CACHE_DIR="$PROJECT_DIR/.build/swiftpm-cache"
SWIFTPM_CONFIG_DIR="$PROJECT_DIR/.build/swiftpm-config"
SWIFTPM_SECURITY_DIR="$PROJECT_DIR/.build/swiftpm-security"
APP_STAGING_ROOT="$(mktemp -d -t TokenMonitorAppBuild)"
STAGED_APP_DIR="$APP_STAGING_ROOT/$APP_NAME.app"
APP_VERIFY_ROOT="$(mktemp -d -t TokenMonitorAppVerification)"

cleanup() {
    /bin/rm -rf "$APP_STAGING_ROOT"
    /bin/rm -rf "$APP_VERIFY_ROOT"
}
trap cleanup EXIT

if [[ -d "/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk" ]]; then
    SDK_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
else
    SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
fi

SWIFTPM_ARGS=(
    --disable-sandbox
    --scratch-path "$PROJECT_DIR/.build"
    --cache-path "$SWIFTPM_CACHE_DIR"
    --config-path "$SWIFTPM_CONFIG_DIR"
    --security-path "$SWIFTPM_SECURITY_DIR"
)

cd "$PROJECT_DIR"
/bin/mkdir -p \
    "$MODULE_CACHE_DIR" \
    "$SWIFTPM_CACHE_DIR" \
    "$SWIFTPM_CONFIG_DIR" \
    "$SWIFTPM_SECURITY_DIR"

/bin/zsh "$PROJECT_DIR/generate-app-icon.sh" >/dev/null

SDKROOT="$SDK_PATH" \
CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR" \
SWIFTPM_MODULECACHE_OVERRIDE="$MODULE_CACHE_DIR" \
swift build -c release "${SWIFTPM_ARGS[@]}"

BIN_DIR="$(
    SDKROOT="$SDK_PATH" \
    CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR" \
    SWIFTPM_MODULECACHE_OVERRIDE="$MODULE_CACHE_DIR" \
    swift build -c release --show-bin-path "${SWIFTPM_ARGS[@]}"
)"

/bin/mkdir -p \
    "$STAGED_APP_DIR/Contents/MacOS" \
    "$STAGED_APP_DIR/Contents/Resources/Mascot" \
    "$STAGED_APP_DIR/Contents/Resources/Legal"
/bin/cp "$BIN_DIR/$EXECUTABLE_NAME" "$STAGED_APP_DIR/Contents/MacOS/$EXECUTABLE_NAME"
/usr/bin/strip -S -x "$STAGED_APP_DIR/Contents/MacOS/$EXECUTABLE_NAME"
/bin/cp "$PROJECT_DIR/Resources/Info.plist" "$STAGED_APP_DIR/Contents/Info.plist"
/bin/cp "$PROJECT_DIR/Resources/AppIcon.icns" "$STAGED_APP_DIR/Contents/Resources/AppIcon.icns"
/bin/cp "$PROJECT_DIR/Resources/AppIcon.png" "$STAGED_APP_DIR/Contents/Resources/AppIcon.png"
/bin/cp \
    "$PROJECT_DIR/Resources/Mascot/dragon-chibi-neutral-v4.png" \
    "$STAGED_APP_DIR/Contents/Resources/Mascot/dragon-chibi-neutral-v4.png"

for legal_document in \
    LICENSE \
    AI_DISCLOSURE.md \
    DISCLAIMER.md \
    PRIVACY.md \
    SECURITY.md \
    THIRD_PARTY_NOTICES.md \
    ASSET_RIGHTS.md \
    ASSET_LICENSE.md
do
    /bin/cp \
        "$PROJECT_DIR/$legal_document" \
        "$STAGED_APP_DIR/Contents/Resources/Legal/$legal_document"
done

/usr/bin/xattr -cr "$STAGED_APP_DIR"
/usr/bin/codesign --force --deep --sign - "$STAGED_APP_DIR"

/bin/mkdir -p "$DIST_DIR"
/bin/rm -f "$DIST_DIR/$APP_NAME.zip"
/usr/bin/ditto --norsrc -c -k --keepParent "$STAGED_APP_DIR" "$DIST_DIR/$APP_NAME.zip"
/bin/rm -rf "$APP_DIR"
/usr/bin/ditto -x -k --norsrc "$DIST_DIR/$APP_NAME.zip" "$DIST_DIR"
/usr/bin/ditto -x -k --norsrc "$DIST_DIR/$APP_NAME.zip" "$APP_VERIFY_ROOT"
/usr/bin/codesign --verify --deep --strict "$APP_VERIFY_ROOT/$APP_NAME.app"

echo "$APP_DIR"
echo "$DIST_DIR/$APP_NAME.zip"
