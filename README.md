# Token Monitor（macOS）

> **非官方第三方工具：** 本專案不是 OpenAI 官方產品，也未獲 OpenAI 贊助、認可、背書或合作。顯示的「剩餘 Token」是使用者自訂額度減去 API 彙總用量所得的輔助估算，不是官方帳單、硬性限額、ChatGPT 訊息額度或 context window。使用前請閱讀 [免責聲明](DISCLAIMER.md) 與 [隱私說明](PRIVACY.md)。

這是一個常駐 macOS 選單列的 OpenAI API Token 用量監視器。它會讀取 OpenAI 官方 Organization Usage API，顯示本月的輸入、輸出、快取輸入、請求次數，以及依照自訂月度 Token 額度計算的剩餘量。

按下「刷新並顯示」後，程式會在桌面右下角顯示一個永遠置頂、可拖曳的透明角色小工具。泡泡內顯示剩餘與已用 Token；角色使用使用者提供的白紫色 AI 生成龍族 Q 版透明圖。小工具右上角可重新刷新或隱藏。

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
- 關閉設定後會同步縮回實際選單視窗高度，不殘留上下透明區域
- App 使用目前的白紫色 Q 版龍娘人物作為 macOS 徽標

## 先說清楚「剩餘 Token」

OpenAI Usage API 只提供已使用量，沒有官方的 `remaining_tokens` 欄位。因此程式顯示的是：

```text
自訂預算剩餘 = 你設定的月度 Token 額度 - 本月 input_tokens - 本月 output_tokens
```

`input_cached_tokens` 已包含在 `input_tokens` 裡，程式只另外展示，不會重複加總。

這不是 ChatGPT Plus／Pro 的訊息額度，也不是單次對話 context window 的剩餘 Token。

## 使用條件

- macOS 13 或以上；目前只公開原始碼，已在 Apple silicon（arm64）開發環境驗證
- OpenAI API 組織的 **Admin API Key**（一般 Project API Key 沒有讀取組織用量的權限）
- 自行設定一個月度 Token 額度，例如 `10,000,000`

官方參考：

- [Completions Usage API](https://developers.openai.com/api/reference/ruby/resources/admin/subresources/organization/subresources/usage/methods/completions)
- [Organization Usage 回應欄位](https://developers.openai.com/api/reference/resources/admin/subresources/organization/subresources/usage)
- [Admin API Keys](https://developers.openai.com/api/reference/resources/admin/subresources/organization/subresources/admin_api_keys)

## 公開範圍

本 GitHub 專案只公開原始碼、測試、建置腳本、必要人物／圖示素材及法律文件，**不提供預先編譯的 `.app`、DMG、PKG 或 App ZIP 下載**。`.build/`、`dist/`、`release-*/` 與本機編譯產物均由 `.gitignore` 排除。

Apple Developer ID 簽署與 Apple 公證只適用於發布者向其他人提供可執行 App 的情況；單純公開原始碼不需要 Apple 公證。使用者需要自行審查並從原始碼建置。

> **憑證警告：** Admin API Key 是高權限憑證，只應由獲授權的組織管理者使用。不要把真實金鑰放入原始碼、Issue、Pull Request、截圖、聊天或日誌。從 App 刪除 Keychain 項目也不等於在 OpenAI 撤銷金鑰。

## 從原始碼建置

專案不使用第三方套件，只需要 Apple Command Line Tools：

```bash
cd TokenMonitor
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

## 資安設計

- Admin API Key 只儲存在 macOS Keychain。
- UserDefaults 只保存自訂 Token 額度、更新頻率、顯示語言、音效開關、桌寵位置與左右鏡像方向。
- 程式只向 `https://api.openai.com/v1/organization/usage/completions` 發出讀取請求。
- 桌面角色圖片隨 App 一起打包，不會從網路即時下載。
- 原始碼、設定檔與打包檔不含 API Key。
- 可隨時在設定內刪除 Keychain 中的金鑰。
- API 請求使用不落地快取、不接受 Cookie 的暫時性網路 Session。
- App 不含廣告、分析、遙測、追蹤器、第三方 SDK 或發布者控制的伺服器。

Admin API Key 權限很高，請勿將金鑰貼進截圖、提交到 Git，或交給不信任的程式。

## 公開發布文件

- [MIT 程式碼授權](LICENSE)
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

## 授權範圍

程式碼與文件依 [MIT License](LICENSE) 發布。人物圖 `dragon-chibi-neutral-v4.png` 及其衍生的 `AppIcon.png`、`AppIcon.icns` 不包含在 MIT License 中，也沒有由本專案另行授予抽出、修改、再授權或在其他產品中重複使用的權利；詳情見 [ASSET_LICENSE.md](ASSET_LICENSE.md)。

專案已附 GitHub Actions 的 macOS 測試／建置驗證工作流程、Issue 範本與 Pull Request 範本。工作流程只驗證程式能否建置，不會上傳或發布編譯完成的 App。GitHub 會為 Tag／Release 自動提供原始碼 ZIP 與 tar.gz，不需要手動附加 App ZIP。

### 尚未完成的發布者責任

目前產品已改名為 **Token Monitor**，程式碼與文件採用 MIT License。人物與 AppIcon 已改用不含 OpenAI Blossom 樣式標誌的版本，並明確排除於 MIT License 之外。公開原始碼前，發布者仍應補齊確切圖像生成產品／模型／日期、當時適用條款與全部參考輸入的權利記錄，並提供公開安全聯絡方式。Bundle ID、Developer ID、公證與乾淨電腦安裝測試不是本次 source-only 發布的必要條件；只有未來公開提供可執行 App 時才需要完成。

## 更新方式

可選每 1、5 或 15 分鐘自動同步，也可按「立即同步」。這是輪詢式近即時顯示；OpenAI Usage API 本身若有統計延遲，桌面程式無法消除該延遲。
