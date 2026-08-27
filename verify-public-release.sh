#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h}"
DIST_DIR="$PROJECT_DIR/dist"
BUNDLE_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PROJECT_DIR/Resources/Info.plist")"
BUILD_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$PROJECT_DIR/Resources/Info.plist")"
RELEASE_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :TokenMonitorReleaseVersion' "$PROJECT_DIR/Resources/Info.plist")"
DIST_APP_DIR="$DIST_DIR/Token Monitor.app"
APP_ARCHIVE_NAME="Token-Monitor-$RELEASE_VERSION-macOS.zip"
SOURCE_ARCHIVE_NAME="TokenMonitor-$RELEASE_VERSION-source.zip"
APP_ARCHIVE="$DIST_DIR/$APP_ARCHIVE_NAME"
SOURCE_ARCHIVE="$DIST_DIR/$SOURCE_ARCHIVE_NAME"
CHECKSUMS="$DIST_DIR/SHA256SUMS.txt"
VERIFY_ROOT="$(mktemp -d -t TokenMonitorVerify)"

cleanup() {
    /bin/rm -rf "$VERIFY_ROOT"
}
trap cleanup EXIT

fail() {
    echo "公開發布驗證失敗：$1" >&2
    exit 1
}

for required in "$DIST_APP_DIR" "$APP_ARCHIVE" "$SOURCE_ARCHIVE" "$CHECKSUMS"
do
    [[ -e "$required" ]] || fail "缺少 $required"
done

/usr/bin/unzip -tq "$APP_ARCHIVE"
/usr/bin/unzip -tq "$SOURCE_ARCHIVE"
/usr/bin/ditto -x -k --norsrc "$APP_ARCHIVE" "$VERIFY_ROOT/app"
APP_DIR="$VERIFY_ROOT/app/Token Monitor.app"
[[ -d "$APP_DIR" ]] || fail "無法解開 App"
/usr/bin/codesign --verify --deep --strict "$APP_DIR"

app_listing="$(/usr/bin/unzip -Z1 "$APP_ARCHIVE")"
source_listing="$(/usr/bin/unzip -Z1 "$SOURCE_ARCHIVE")"

if print -r -- "$app_listing" | /usr/bin/grep -Eq '(^|/)(__MACOSX|\.DS_Store|\._[^/]+|\.build|xcuserdata)(/|$)'; then
    fail "App ZIP 含 macOS 私人中繼資料或建置快取"
fi
if print -r -- "$source_listing" | /usr/bin/grep -Eq '(^|/)(__MACOSX|\.DS_Store|\._[^/]+|\.build|dist|\.git|\.swiftpm|xcuserdata)(/|$)'; then
    fail "來源 ZIP 含私人中繼資料、版本庫或建置輸出"
fi
if print -r -- "$source_listing" | /usr/bin/grep -Eq 'dragon-chibi-v1\.png|dragon-chibi-v2\.png|dragon-chibi-openai-v3\.png'; then
    fail "來源 ZIP 含未使用的舊人物素材"
fi

[[ "$(find "$APP_DIR/Contents/Resources/Mascot" -type f | wc -l | tr -d ' ')" == "1" ]] \
    || fail "App 應只包含一個實際使用的人物素材"
[[ -f "$APP_DIR/Contents/Resources/Mascot/dragon-chibi-neutral-v4.png" ]] \
    || fail "App 未包含中性 v4 人物素材"
print -r -- "$source_listing" | /usr/bin/grep -Eq '/Resources/Mascot/dragon-chibi-neutral-v4\.png$' \
    || fail "來源 ZIP 未包含中性 v4 人物素材"

for legal_document in LICENSE AI_DISCLOSURE.md DISCLAIMER.md PRIVACY.md SECURITY.md THIRD_PARTY_NOTICES.md ASSET_RIGHTS.md ASSET_LICENSE.md
do
    [[ -f "$APP_DIR/Contents/Resources/Legal/$legal_document" ]] \
        || fail "App 缺少 $legal_document"
done

print -r -- "$source_listing" | /usr/bin/grep -Eq '/LICENSE$' \
    || fail "來源 ZIP 缺少 MIT License"
print -r -- "$source_listing" | /usr/bin/grep -Eq '/AI_DISCLOSURE\.md$' \
    || fail "來源 ZIP 缺少 AI 輔助開發聲明"
print -r -- "$source_listing" | /usr/bin/grep -Eq '/ASSET_LICENSE\.md$' \
    || fail "來源 ZIP 缺少人物素材獨立授權說明"
print -r -- "$source_listing" | /usr/bin/grep -Eq '/CONTRIBUTING\.md$' \
    || fail "來源 ZIP 缺少貢獻指南"
print -r -- "$source_listing" | /usr/bin/grep -Eq '/CODE_OF_CONDUCT\.md$' \
    || fail "來源 ZIP 缺少行為準則"
print -r -- "$source_listing" | /usr/bin/grep -Eq '/\.github/workflows/test\.yml$' \
    || fail "來源 ZIP 缺少 GitHub Actions 工作流程"

if /usr/bin/xattr -p com.apple.quarantine "$APP_DIR" >/dev/null 2>&1; then
    fail "App 保留 quarantine 延伸屬性"
fi
if /usr/bin/xattr -lr "$APP_DIR" 2>/dev/null | /usr/bin/grep -q 'com.apple.quarantine'; then
    fail "App 內部資源保留 quarantine 延伸屬性"
fi

EXECUTABLE="$APP_DIR/Contents/MacOS/TokenMonitor"
if LC_ALL=C /usr/bin/grep -aEq '/(Users|home)/[A-Za-z0-9._-]{1,64}/' "$EXECUTABLE"; then
    fail "Mach-O 仍包含私人本機路徑或使用者名稱"
fi
if LC_ALL=C /usr/bin/grep -aEq 'sk-(admin-|proj-)?[A-Za-z0-9_-]{20,}|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY' "$EXECUTABLE"; then
    fail "Mach-O 疑似包含憑證或私鑰"
fi

/usr/bin/ditto -x -k --norsrc "$SOURCE_ARCHIVE" "$VERIFY_ROOT/source"
SOURCE_ROOT="$(find "$VERIFY_ROOT/source" -mindepth 1 -maxdepth 1 -type d -print -quit)"
[[ -n "$SOURCE_ROOT" ]] || fail "無法解開來源包"

if LC_ALL=C /usr/bin/grep -RIlE '/(Users|home)/[A-Za-z0-9._-]{1,64}/' "$SOURCE_ROOT" | /usr/bin/grep -q .; then
    fail "公開來源包包含私人本機路徑或使用者名稱"
fi
if LC_ALL=C /usr/bin/grep -RIlE 'sk-(admin-|proj-)?[A-Za-z0-9_-]{20,}|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY' "$SOURCE_ROOT" | /usr/bin/grep -q .; then
    fail "公開來源包疑似包含 API Key 或私鑰"
fi

bundle_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_DIR/Contents/Info.plist")"
[[ "$bundle_version" == "$BUNDLE_VERSION" ]] || fail "App Bundle 版本與來源版本不一致"
build_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_DIR/Contents/Info.plist")"
[[ "$build_version" == "$BUILD_VERSION" ]] || fail "App Build 版本與來源版本不一致"
release_version="$(/usr/libexec/PlistBuddy -c 'Print :TokenMonitorReleaseVersion' "$APP_DIR/Contents/Info.plist")"
[[ "$release_version" == "$RELEASE_VERSION" ]] || fail "App 預公開版本與來源版本不一致"
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$APP_DIR/Contents/Info.plist")" == "Token Monitor" ]] \
    || fail "App 顯示名稱不是 Token Monitor"
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleName' "$APP_DIR/Contents/Info.plist")" == "Token Monitor" ]] \
    || fail "App Bundle 名稱不是 Token Monitor"
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP_DIR/Contents/Info.plist")" == "TokenMonitor" ]] \
    || fail "App 執行檔名稱不是 TokenMonitor"
if /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_DIR/Contents/Info.plist" | /usr/bin/grep -Eqi 'gpt|openai'; then
    fail "Bundle Identifier 不應含 GPT 或 OpenAI 品牌字樣"
fi
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIconFile' "$APP_DIR/Contents/Info.plist")" == "AppIcon.icns" ]] \
    || fail "App 徽標設定不正確"

(
    cd "$DIST_DIR"
    /usr/bin/shasum -a 256 -c "$(basename "$CHECKSUMS")"
)

echo "✓ 公開 App、來源包、私人路徑、秘密、中繼資料、法律文件與雜湊驗證通過"
