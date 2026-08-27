# Token Monitor（macOS）

[繁體中文](#繁體中文) | [English](#english)

## 繁體中文

> **非官方第三方工具：** 本專案不是 OpenAI 官方產品，也未獲 OpenAI 贊助、認可、背書或合作。顯示的「剩餘 Token」與「預估花銷」都是依 API 彙總用量計算的輔助估算，不是官方帳單、硬性限額、ChatGPT 訊息額度或 context window。使用前請閱讀 [免責聲明](DISCLAIMER.md) 與 [隱私說明](PRIVACY.md)。

這是一個常駐 macOS 選單列的 OpenAI API Token 用量監視器。它會讀取 OpenAI 官方 Organization Usage API，顯示本月的輸入、輸出、快取輸入、請求次數、依照自訂月度 Token 額度計算的剩餘量，以及按 GPT-5.6 Sol／Terra／Luna 標準文字單價推算的美元花銷。

按下「刷新並顯示」後，程式會在桌面右下角顯示一個永遠置頂、可拖曳的透明角色小工具。泡泡可在設定中選擇顯示 Token 使用量或美元預估花銷；角色使用使用者提供的白紫色 AI 生成龍族 Q 版透明圖。小工具右上角可重新刷新或隱藏。

- 點擊龍娘本體會產生 Q 彈動畫、立即刷新，並顯示 Token 氣泡
- 啟動 App 後桌寵會自動顯示；也能從選單列按「刷新並顯示」重新叫出
- 氣泡 8 秒後自動收起，也可以直接點擊氣泡關閉
- 拖曳小工具後會吸附到最近的左右螢幕邊緣
- 吸附到左側時角色與泡泡配置會自動鏡像
- 位置與左右方向會記憶，下次顯示時自動恢復
- 透明無邊框視窗跨桌面空間保持於一般 App 上方
- 人物使用高品質插值與柔化邊緣圖層，縮放時減少鋸齒
- 設定可切換繁體中文、簡體中文與 English，桌面氣泡會同步切換
- 點擊人物或手動刷新時可播放橡皮鴨音效，並可在設定中關閉或試聽
- 可選 GPT-5.6 Sol、Terra 或 Luna 作為美元估價模型
- 主面板直接顯示本月預估花銷，人物氣泡可切換顯示 Token 或預估花銷
- 關閉設定後會同步縮回實際選單視窗高度，不殘留上下透明區域
- App 使用目前的白紫色 Q 版龍娘人物作為 macOS 徽標

### 先說清楚「剩餘 Token」

OpenAI Usage API 只提供已使用量，沒有官方的 `remaining_tokens` 欄位。因此程式顯示的是：

```text
自訂預算剩餘 = 你設定的月度 Token 額度 - 本月 input_tokens - 本月 output_tokens
```

`input_cached_tokens` 已包含在 `input_tokens` 裡，程式只另外展示，不會重複加總。

這不是 ChatGPT Plus／Pro 的訊息額度，也不是單次對話 context window 的剩餘 Token。

### 預估花銷如何計算

程式使用下列 OpenAI API 標準短上下文文字價格（2026-08-26 查核，每 100 萬 Token、美元）：

| 模型 | Input | Cached input | Output |
|---|---:|---:|---:|
| GPT-5.6 Sol | US$4.00 | US$0.40 | US$20.00 |
| GPT-5.6 Terra | US$2.00 | US$0.20 | US$12.00 |
| GPT-5.6 Luna | US$0.20 | US$0.02 | US$1.20 |

```text
預估花銷 = 非快取輸入 × Input 單價
         + 快取輸入 × Cached input 單價
         + 輸出 × Output 單價
```

`input_cached_tokens` 是 `input_tokens` 的一部分，程式會先從總輸入中拆出快取部分，不會同時按完整 Input 價格和 Cached input 價格重複計費。估算假設本月全部 Token 都使用設定中選擇的同一模型，不包含超過 272K Input 的長上下文加價、Batch／Flex／Priority、區域處理、Cache Write、工具呼叫或其他費用。OpenAI 價格可能變動，正式金額必須以 OpenAI 帳單為準；這也不是 ChatGPT 訂閱費用。

### 使用條件

- macOS 13 或以上；目前只公開原始碼，已在 Apple silicon（arm64）開發環境驗證
- OpenAI API 組織的 **Admin API Key**（一般 Project API Key 沒有讀取組織用量的權限）
- 自行設定一個月度 Token 額度，例如 `10,000,000`

官方參考：

- [Completions Usage API](https://developers.openai.com/api/reference/ruby/resources/admin/subresources/organization/subresources/usage/methods/completions)
- [Organization Usage 回應欄位](https://developers.openai.com/api/reference/resources/admin/subresources/organization/subresources/usage)
- [Admin API Keys](https://developers.openai.com/api/reference/resources/admin/subresources/organization/subresources/admin_api_keys)
- [GPT-5.6 模型與標準價格](https://developers.openai.com/api/docs/models)

### 公開範圍

本 GitHub 專案只公開原始碼、測試、建置腳本、必要人物／圖示素材及法律文件，**不提供預先編譯的 `.app`、DMG、PKG 或 App ZIP 下載**。

Apple Developer ID 簽署與 Apple 公證只適用於發布者向其他人提供可執行 App 的情況；單純公開原始碼不需要 Apple 公證。

> **憑證警告：** Admin API Key 是高權限憑證，只應由獲授權的組織管理者使用。不要把真實金鑰放入原始碼、Issue、Pull Request、截圖、聊天或日誌。從 App 刪除 Keychain 項目也不等於在 OpenAI 撤銷金鑰。

### 從原始碼建置

專案不使用第三方套件，只需要 Apple Command Line Tools：

```bash
cd token-monitor
chmod +x build-app.sh
./build-app.sh
```

執行不依賴第三方測試框架的核心驗證：

```bash
chmod +x test.sh
./test.sh
```

建置輸出：

- `dist/Token Monitor.app`
- `dist/Token Monitor.zip`

如需在本機執行完整封裝與隱私檢查，可執行下列命令；產生的 App／ZIP 只供本機 QA，已被 Git 排除，不會由本專案公開：

```bash
chmod +x build-public-release.sh verify-public-release.sh
./build-public-release.sh
./verify-public-release.sh
```

### 資安設計

- Admin API Key 只儲存在 macOS Keychain。
- UserDefaults 只保存自訂 Token 額度、更新頻率、顯示語言、音效開關、估價模型、人物氣泡顯示模式、桌寵位置與左右鏡像方向。
- 程式只向 `https://api.openai.com/v1/organization/usage/completions` 發出讀取請求。
- 桌面角色圖片隨 App 一起打包，不會從網路即時下載。
- 原始碼、設定檔與打包檔不含 API Key。
- 可隨時在設定內刪除 Keychain 中的金鑰。
- API 請求使用不落地快取、不接受 Cookie 的暫時性網路 Session。
- App 不含廣告、分析、遙測、追蹤器、第三方 SDK 或發布者控制的伺服器。

Admin API Key 權限很高，請勿將金鑰貼進截圖、提交到 Git，或交給不信任的程式。

### 公開發布文件

- [MIT 程式碼授權](LICENSE)
- [AI 輔助開發聲明](AI_DISCLOSURE.md)
- [人物與 AppIcon 獨立權利說明](ASSET_LICENSE.md)
- [免責聲明](DISCLAIMER.md)
- [隱私說明](PRIVACY.md)
- [安全政策](SECURITY.md)
- [第三方與素材權利狀態](THIRD_PARTY_NOTICES.md)
- [AI 人物與 AppIcon 權利記錄](ASSET_RIGHTS.md)
- [公開發布檢查清單](PUBLIC_RELEASE_CHECKLIST.md)
- [版本說明](RELEASE_NOTES.md)
- [貢獻指南](CONTRIBUTING.md)
- [行為準則](CODE_OF_CONDUCT.md)

### 授權範圍

程式碼與文件依 [MIT License](LICENSE) 發布。人物圖 `dragon-chibi-neutral-v4.png` 及其衍生的 `AppIcon.png`、`AppIcon.icns` 不包含在 MIT License 中，也沒有由本專案另行授予抽出、修改、再授權或在其他產品中重複使用的權利；詳情見 [ASSET_LICENSE.md](ASSET_LICENSE.md)。

### AI 輔助開發聲明

本專案的大多數程式碼、初始實作、重構建議及部分技術文件由 OpenAI GPT／Codex 協助生成或修改。專案維護者負責提出需求、選擇方案、檢查與修改輸出、執行測試，以及決定最終發布內容。AI 協助不代表程式碼一定正確、安全或無侵權風險，也不代表本專案是 OpenAI 官方產品或獲得 OpenAI 背書。完整中英文說明請見 [AI_DISCLOSURE.md](AI_DISCLOSURE.md)。

專案已附 GitHub Actions 的 macOS 測試／建置驗證工作流程、Issue 範本與 Pull Request 範本。工作流程只驗證程式能否建置，不會上傳或發布編譯完成的 App。GitHub 會為 Tag／Release 自動提供原始碼 ZIP 與 tar.gz，不需要手動附加 App ZIP。

### 更新方式

可選每 1、5 或 15 分鐘自動同步，也可按「立即同步」。這是輪詢式近即時顯示；OpenAI Usage API 本身若有統計延遲，桌面程式無法消除該延遲。

---

## English

> **Unofficial third-party utility:** This project is not an official OpenAI product and is not sponsored, approved, endorsed, or supported by OpenAI. The displayed “remaining tokens” and “estimated cost” values are informational calculations based on aggregate API usage. They are not an official bill, enforced limit, ChatGPT message allowance, or context-window reading. Read the [Disclaimer](DISCLAIMER.md) and [Privacy Notice](PRIVACY.md) before use.

Token Monitor is a macOS menu-bar utility for monitoring OpenAI API token usage. It reads the official OpenAI Organization Usage API and displays the current month's input tokens, output tokens, cached input tokens, request count, remaining amount under a user-defined monthly token budget, and a USD estimate based on GPT-5.6 Sol, Terra, or Luna standard text-token prices.

Selecting “Refresh and Show” displays an always-on-top, draggable, transparent desktop character widget near the lower-right corner of the screen. Its bubble can show token usage or the USD estimate, as selected in Settings. The character uses the user-supplied white-and-purple AI-generated chibi dragon artwork.

- Clicking the character plays a spring animation, refreshes usage immediately, and displays the token bubble.
- The desktop character appears automatically when the app starts and can be shown again from the menu bar.
- The bubble closes automatically after eight seconds and can also be dismissed by clicking it.
- After dragging, the widget snaps to the nearest left or right screen edge.
- The character and bubble layout mirror automatically when attached to the left edge.
- Position and orientation are remembered and restored the next time the widget appears.
- The transparent borderless window remains above ordinary apps across desktop Spaces.
- High-quality interpolation and a softened edge layer reduce visible aliasing while scaling the character.
- Settings support Traditional Chinese, Simplified Chinese, and English; the desktop bubble changes language immediately.
- Clicking the character or refreshing manually can play a synthesized rubber-duck sound, which can be disabled or previewed in Settings.
- GPT-5.6 Sol, Terra, or Luna can be selected as the pricing scenario.
- The main panel shows the estimated monthly cost directly, while the character bubble can switch between tokens and estimated cost.
- Closing Settings restores the actual compact menu-window height without leaving transparent space above or below the UI.
- The current white-and-purple chibi dragon artwork is also used as the macOS app icon.

### What “remaining tokens” means

The OpenAI Usage API reports usage but does not provide an official `remaining_tokens` field. Token Monitor calculates:

```text
Custom budget remaining = configured monthly token budget - this month's input_tokens - this month's output_tokens
```

`input_cached_tokens` is already included in `input_tokens`. It is displayed separately for information and is not counted twice.

This value is not the ChatGPT Plus/Pro message allowance and is not the remaining context window of an individual conversation.

### How estimated cost is calculated

The app uses the following OpenAI API standard short-context text-token prices, checked on 2026-08-26 and expressed in USD per one million tokens:

| Model | Input | Cached input | Output |
|---|---:|---:|---:|
| GPT-5.6 Sol | US$4.00 | US$0.40 | US$20.00 |
| GPT-5.6 Terra | US$2.00 | US$0.20 | US$12.00 |
| GPT-5.6 Luna | US$0.20 | US$0.02 | US$1.20 |

```text
Estimated cost = uncached input × input rate
               + cached input × cached-input rate
               + output × output rate
```

Because `input_cached_tokens` is a subset of `input_tokens`, the cached portion is split out before applying prices and is not charged at both rates. The estimate assumes all monthly tokens used the single model selected in Settings. It excludes the long-context uplift above 272K input tokens, Batch/Flex/Priority processing, regional processing, cache writes, tool calls, and other charges. OpenAI pricing may change, so the OpenAI invoice is authoritative. This is not a ChatGPT subscription charge.

### Requirements

- macOS 13 or later. This repository is source-only and has been verified in an Apple silicon (arm64) development environment.
- An OpenAI API organization **Admin API Key**. An ordinary Project API Key does not have access to organization-level usage.
- A user-defined monthly token budget, such as `10,000,000`.

Official references:

- [Completions Usage API](https://developers.openai.com/api/reference/ruby/resources/admin/subresources/organization/subresources/usage/methods/completions)
- [Organization Usage response fields](https://developers.openai.com/api/reference/resources/admin/subresources/organization/subresources/usage)
- [Admin API Keys](https://developers.openai.com/api/reference/resources/admin/subresources/organization/subresources/admin_api_keys)
- [GPT-5.6 models and standard pricing](https://developers.openai.com/api/docs/models)

### Publication scope

This GitHub project publishes source code, tests, build scripts, required character/icon assets, and legal documents only. It **does not provide a precompiled `.app`, DMG, PKG, or App ZIP download**.

Developer ID signing and Apple notarization are required when a publisher distributes an executable app to other users; they are not required for source-only publication. Users must review and build the app from source themselves.

> **Credential warning:** An Admin API Key is a highly privileged credential and should be used only by an authorized organization administrator. Never place a real key in source code, issues, pull requests, screenshots, chats, or logs. Removing the local Keychain entry from the app does not revoke the key at OpenAI.

### Build from source

The project has no third-party package dependencies. Apple Command Line Tools are sufficient:

```bash
cd token-monitor
chmod +x build-app.sh
./build-app.sh
```

Run the core verification suite:

```bash
chmod +x test.sh
./test.sh
```

Build outputs:

- `dist/Token Monitor.app`
- `dist/Token Monitor.zip`

For complete local packaging, privacy, and archive verification, run the following commands. Generated apps and archives are for local QA only, are ignored by Git, and are not published by this project:

```bash
chmod +x build-public-release.sh verify-public-release.sh
./build-public-release.sh
./verify-public-release.sh
```

### Security design

- The Admin API Key is stored only in macOS Keychain.
- UserDefaults stores only the custom token budget, refresh interval, display language, sound preference, pricing model, bubble display mode, desktop-widget position, and mirrored orientation.
- The app sends usage requests only to `https://api.openai.com/v1/organization/usage/completions`.
- Character artwork is bundled locally and is never fetched dynamically from the network.
- Source files, configuration files, and release packages do not contain an API key.
- The saved Keychain credential can be removed from Settings at any time.
- API requests use an ephemeral URL session with no persistent disk cache and no cookies.
- The app contains no ads, analytics, telemetry, trackers, third-party SDKs, or publisher-operated servers.

Do not place an Admin API Key in screenshots, Git commits, or untrusted software.

### Publication documents

- [MIT License for source code and documentation](LICENSE)
- [AI-assisted development disclosure](AI_DISCLOSURE.md)
- [Separate character and AppIcon rights notice](ASSET_LICENSE.md)
- [Disclaimer](DISCLAIMER.md)
- [Privacy notice](PRIVACY.md)
- [Security policy](SECURITY.md)
- [Third-party notices and asset status](THIRD_PARTY_NOTICES.md)
- [AI character and AppIcon rights record](ASSET_RIGHTS.md)
- [Public release checklist](PUBLIC_RELEASE_CHECKLIST.md)
- [Release notes](RELEASE_NOTES.md)
- [Contributing guide](CONTRIBUTING.md)
- [Code of conduct](CODE_OF_CONDUCT.md)

### Licensing scope

Source code and documentation are provided under the [MIT License](LICENSE). The character file `dragon-chibi-neutral-v4.png` and its derived `AppIcon.png` and `AppIcon.icns` are excluded from the MIT License. This project does not separately grant permission to extract, modify, sublicense, or reuse those assets in another product. See [ASSET_LICENSE.md](ASSET_LICENSE.md).

### AI-assisted development disclosure

Most of this project's source code, initial implementations, refactoring suggestions, and portions of its technical documentation were generated or modified with assistance from OpenAI GPT/Codex. The maintainer provided requirements, selected approaches, reviewed and modified the output, ran tests, and decided what to publish. AI assistance does not guarantee correctness, security, or freedom from infringement risk, and does not make this project an official OpenAI product or imply OpenAI endorsement. See [AI_DISCLOSURE.md](AI_DISCLOSURE.md) for the complete multilingual disclosure.

The included GitHub Actions workflow performs macOS tests and local build verification but does not upload or publish a compiled app. GitHub automatically provides source ZIP and tar.gz archives for tags and releases; no App ZIP is attached.

### Refresh behavior

Automatic refresh can be set to 1, 5, or 15 minutes, and usage can also be refreshed immediately. This is polling-based near-real-time monitoring. Any reporting delay in the OpenAI Usage API cannot be eliminated by the desktop app.
