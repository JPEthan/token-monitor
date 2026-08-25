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

/bin/rm -rf "$APP_DIR"
/bin/mkdir -p \
    "$APP_DIR/Contents/MacOS" \
    "$APP_DIR/Contents/Resources/Mascot" \
    "$APP_DIR/Contents/Resources/Legal"
/usr/bin/ditto --norsrc "$BIN_DIR/$EXECUTABLE_NAME" "$APP_DIR/Contents/MacOS/$EXECUTABLE_NAME"
/usr/bin/strip -S -x "$APP_DIR/Contents/MacOS/$EXECUTABLE_NAME"
/usr/bin/ditto --norsrc "$PROJECT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
/usr/bin/ditto --norsrc "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
/usr/bin/ditto --norsrc "$PROJECT_DIR/Resources/AppIcon.png" "$APP_DIR/Contents/Resources/AppIcon.png"
/usr/bin/ditto --norsrc \
    "$PROJECT_DIR/Resources/Mascot/dragon-chibi-neutral-v4.png" \
    "$APP_DIR/Contents/Resources/Mascot/dragon-chibi-neutral-v4.png"

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
    /usr/bin/ditto --norsrc \
        "$PROJECT_DIR/$legal_document" \
        "$APP_DIR/Contents/Resources/Legal/$legal_document"
done

/usr/bin/xattr -cr "$APP_DIR"
/usr/bin/codesign --force --deep --sign - "$APP_DIR"

/bin/rm -f "$DIST_DIR/$APP_NAME.zip"
/usr/bin/ditto --norsrc -c -k --keepParent "$APP_DIR" "$DIST_DIR/$APP_NAME.zip"

echo "$APP_DIR"
echo "$DIST_DIR/$APP_NAME.zip"
