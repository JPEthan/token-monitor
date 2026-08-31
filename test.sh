#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h}"
MODULE_CACHE_DIR="$PROJECT_DIR/.build/module-cache"
SWIFTPM_CACHE_DIR="$PROJECT_DIR/.build/swiftpm-cache"
SWIFTPM_CONFIG_DIR="$PROJECT_DIR/.build/swiftpm-config"
SWIFTPM_SECURITY_DIR="$PROJECT_DIR/.build/swiftpm-security"
VERIFY_DIR="$PROJECT_DIR/.build/verification"

if [[ -d "/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk" ]]; then
    SDK_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
else
    SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
fi

/bin/mkdir -p \
    "$MODULE_CACHE_DIR" \
    "$SWIFTPM_CACHE_DIR" \
    "$SWIFTPM_CONFIG_DIR" \
    "$SWIFTPM_SECURITY_DIR" \
    "$VERIFY_DIR"

cd "$PROJECT_DIR"
TESTING_PROBE="$VERIFY_DIR/TestingToolchainProbe.swift"
print -r -- $'import XCTest\nimport Testing' > "$TESTING_PROBE"
if SDKROOT="$SDK_PATH" \
    CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR" \
    swiftc \
        -sdk "$SDK_PATH" \
        -module-cache-path "$MODULE_CACHE_DIR" \
        -typecheck "$TESTING_PROBE" >/dev/null 2>&1; then
    SDKROOT="$SDK_PATH" \
    CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR" \
    SWIFTPM_MODULECACHE_OVERRIDE="$MODULE_CACHE_DIR" \
    swift test \
        --disable-sandbox \
        --enable-xctest \
        --disable-swift-testing \
        --scratch-path "$PROJECT_DIR/.build" \
        --cache-path "$SWIFTPM_CACHE_DIR" \
        --config-path "$SWIFTPM_CONFIG_DIR" \
        --security-path "$SWIFTPM_SECURITY_DIR"
else
    echo "注意：目前 Swift、XCTest 與 Swift Testing 版本不相容；略過 SwiftPM 測試 runner，繼續執行獨立回歸驗證。"
fi

SDKROOT="$SDK_PATH" \
CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR" \
swiftc \
    -sdk "$SDK_PATH" \
    -module-cache-path "$MODULE_CACHE_DIR" \
    -o "$VERIFY_DIR/TokenQuotaVerification" \
    "$PROJECT_DIR"/Sources/TokenQuotaCore/*.swift \
    "$PROJECT_DIR/Verification/main.swift"

"$VERIFY_DIR/TokenQuotaVerification"

SDKROOT="$SDK_PATH" \
CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR" \
swiftc \
    -sdk "$SDK_PATH" \
    -module-cache-path "$MODULE_CACHE_DIR" \
    -o "$VERIFY_DIR/LocalizationVerification" \
    "$PROJECT_DIR/Sources/TokenMonitor/Localization.swift" \
    "$PROJECT_DIR/Verification/LocalizationCheck.swift"

"$VERIFY_DIR/LocalizationVerification"

SDKROOT="$SDK_PATH" \
CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR" \
swiftc \
    -sdk "$SDK_PATH" \
    -module-cache-path "$MODULE_CACHE_DIR" \
    -o "$VERIFY_DIR/MascotScaleVerification" \
    "$PROJECT_DIR/Sources/TokenMonitor/MascotScaleSetting.swift" \
    "$PROJECT_DIR/Verification/MascotScaleCheck.swift"

"$VERIFY_DIR/MascotScaleVerification"

SDKROOT="$SDK_PATH" \
CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR" \
swiftc \
    -sdk "$SDK_PATH" \
    -module-cache-path "$MODULE_CACHE_DIR" \
    -framework AppKit \
    -framework SwiftUI \
    -o "$VERIFY_DIR/MenuBarWindowSizingVerification" \
    "$PROJECT_DIR/Sources/TokenMonitor/MenuBarWindowSizer.swift" \
    "$PROJECT_DIR/Verification/MenuBarWindowSizingCheck.swift"

"$VERIFY_DIR/MenuBarWindowSizingVerification"

SDKROOT="$SDK_PATH" \
CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR" \
swiftc \
    -sdk "$SDK_PATH" \
    -module-cache-path "$MODULE_CACHE_DIR" \
    -framework AppKit \
    -o "$VERIFY_DIR/ImageAlphaVerification" \
    "$PROJECT_DIR/Verification/ImageAlphaCheck.swift"

"$VERIFY_DIR/ImageAlphaVerification" \
    "$PROJECT_DIR/Resources/Mascot/dragon-chibi-neutral-v4.png"
