#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h}"
DIST_DIR="$PROJECT_DIR/dist"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PROJECT_DIR/Resources/Info.plist")"
APP_ARCHIVE_NAME="Token-Monitor-$VERSION-macOS.zip"
SOURCE_ARCHIVE_NAME="TokenMonitor-$VERSION-source.zip"
APP_ARCHIVE="$DIST_DIR/$APP_ARCHIVE_NAME"
SOURCE_ARCHIVE="$DIST_DIR/$SOURCE_ARCHIVE_NAME"
CHECKSUMS="$DIST_DIR/SHA256SUMS.txt"
STAGING_ROOT="$(mktemp -d -t TokenMonitorPublicRelease)"
SOURCE_ROOT="$STAGING_ROOT/TokenMonitor-$VERSION"

cleanup() {
    /bin/rm -rf "$STAGING_ROOT"
}
trap cleanup EXIT

/bin/zsh "$PROJECT_DIR/build-app.sh" >/dev/null
/bin/mkdir -p "$SOURCE_ROOT"

for file in \
    .gitignore \
    LICENSE \
    AI_DISCLOSURE.md \
    Package.swift \
    README.md \
    CONTRIBUTING.md \
    CODE_OF_CONDUCT.md \
    DISCLAIMER.md \
    PRIVACY.md \
    SECURITY.md \
    THIRD_PARTY_NOTICES.md \
    ASSET_RIGHTS.md \
    ASSET_LICENSE.md \
    PUBLIC_RELEASE_CHECKLIST.md \
    RELEASE_NOTES.md \
    build-app.sh \
    generate-app-icon.sh \
    test.sh \
    build-public-release.sh \
    verify-public-release.sh
do
    /usr/bin/ditto --norsrc "$PROJECT_DIR/$file" "$SOURCE_ROOT/$file"
done

for directory in Sources Tests Tools Verification .github
do
    while IFS= read -r -d '' source_file
    do
        relative_path="${source_file#$PROJECT_DIR/}"
        destination="$SOURCE_ROOT/$relative_path"
        /bin/mkdir -p "${destination:h}"
        /usr/bin/ditto --norsrc "$source_file" "$destination"
    done < <(/usr/bin/find "$PROJECT_DIR/$directory" -type f ! -name '.DS_Store' -print0)
done

/bin/mkdir -p "$SOURCE_ROOT/Resources/Mascot"
/usr/bin/ditto --norsrc \
    "$PROJECT_DIR/Resources/Info.plist" \
    "$SOURCE_ROOT/Resources/Info.plist"
/usr/bin/ditto --norsrc \
    "$PROJECT_DIR/Resources/AppIcon.icns" \
    "$SOURCE_ROOT/Resources/AppIcon.icns"
/usr/bin/ditto --norsrc \
    "$PROJECT_DIR/Resources/AppIcon.png" \
    "$SOURCE_ROOT/Resources/AppIcon.png"
/usr/bin/ditto --norsrc \
    "$PROJECT_DIR/Resources/Mascot/dragon-chibi-neutral-v4.png" \
    "$SOURCE_ROOT/Resources/Mascot/dragon-chibi-neutral-v4.png"

/usr/bin/xattr -cr "$SOURCE_ROOT"
/bin/rm -f "$APP_ARCHIVE" "$SOURCE_ARCHIVE" "$CHECKSUMS"
/usr/bin/ditto --norsrc \
    "$DIST_DIR/Token Monitor.zip" \
    "$APP_ARCHIVE"
/usr/bin/ditto --norsrc -c -k --keepParent "$SOURCE_ROOT" "$SOURCE_ARCHIVE"

(
    cd "$DIST_DIR"
    /usr/bin/shasum -a 256 "$APP_ARCHIVE_NAME" "$SOURCE_ARCHIVE_NAME"
) > "$CHECKSUMS"

/bin/zsh "$PROJECT_DIR/verify-public-release.sh"

echo "$APP_ARCHIVE"
echo "$SOURCE_ARCHIVE"
echo "$CHECKSUMS"
