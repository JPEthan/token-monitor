#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h}"
SOURCE_IMAGE="$PROJECT_DIR/Resources/Mascot/dragon-chibi-neutral-v4.png"
OUTPUT_ICON="$PROJECT_DIR/Resources/AppIcon.icns"
OUTPUT_PREVIEW="$PROJECT_DIR/Resources/AppIcon.png"
MODULE_CACHE_DIR="$PROJECT_DIR/.build/module-cache"
GENERATOR="$PROJECT_DIR/.build/AppIconGenerator"

/bin/mkdir -p "$MODULE_CACHE_DIR"

if [[ -d "/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk" ]]; then
    SDK_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
else
    SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
fi

SDKROOT="$SDK_PATH" \
CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR" \
swiftc \
    -sdk "$SDK_PATH" \
    -module-cache-path "$MODULE_CACHE_DIR" \
    -framework AppKit \
    -o "$GENERATOR" \
    "$PROJECT_DIR/Tools/AppIconGenerator.swift"

"$GENERATOR" "$SOURCE_IMAGE" "$OUTPUT_ICON" "$OUTPUT_PREVIEW"
echo "$OUTPUT_ICON"
echo "$OUTPUT_PREVIEW"
