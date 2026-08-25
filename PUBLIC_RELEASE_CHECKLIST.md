# 公開發布檢查表

目標版本：1.5.0

## 已完成的技術檢查

- [x] 原始碼掃描未發現內嵌的 OpenAI API Key、私鑰、密碼、電子郵件地址或個人姓名。
- [x] 已從公開文件移除私人家目錄的絕對路徑與本機使用者名稱。
- [x] 公開原始碼壓縮包不包含 `.build`、`dist`、`.DS_Store`、編輯器狀態、未使用的舊人物素材或延伸屬性側檔。
- [x] App 壓縮包不包含 `__MACOSX`、`._*`、`.DS_Store`、建置快取或隔離屬性中繼資料。
- [x] Admin API Key 儲存在 macOS Keychain，不會寫入偏好設定或發布檔案。
- [x] 程式碼的網路存取限於 OpenAI Usage API；OpenAI 官方用量頁面只會在使用者點擊後開啟。
- [x] 已加入免責聲明、隱私權說明、安全政策、第三方聲明及 App 內法律提示。
- [x] 已加入可重複執行的秘密資訊／封裝驗證及 SHA-256 雜湊清單。
- [x] 核心功能、多語言及視窗尺寸迴歸測試均已通過。
- [x] 發布版 App 建置成功，並通過本機程式碼簽章與 ZIP 完整性檢查。
- [x] 已將目前使用的人物與 AppIcon 替換成 `dragon-chibi-neutral-v4.png`；目視及中繼資料檢查未發現 OpenAI Blossom 樣式標誌或內嵌的 OpenAI／C2PA 文字。
- [x] 產品、App、執行檔、Swift 模組及版本化 ZIP 已改為不含「GPT」的 `Token Monitor`／`TokenMonitor` 名稱。
- [x] 程式碼與文件採用 MIT License；人物與 AppIcon 已透過 `ASSET_LICENSE.md` 明確排除於 MIT License 之外。
- [x] 新版 Keychain 服務名稱會自動遷移舊版儲存的 API Key，避免更名後遺失使用者設定。
- [x] 已加入 GitHub Actions 測試／封裝流程、Issue 範本、Pull Request 範本、貢獻指南與行為準則。
- [x] 本次發布範圍確定為 GitHub source-only，不提供 `.app`、DMG、PKG 或 App ZIP。
- [x] `.build/`、`dist/`、`release-*/`、`.swiftpm/`、`.vscode/` 及本機中繼資料均已從 Git 排除。
- [x] GitHub Actions 只進行測試與建置驗證，沒有上傳或發布二進位產物的步驟。

## 公開原始碼前仍需發布者完成的事項

- [ ] **AI 圖像權利記錄：**已記錄為 OpenAI GPT 圖像生成，並記錄目前 OpenAI Terms of Use 對 Output 的一般性權利條款；但仍須補上確切產品／模型／生成日期、生成當時實際適用條款及 Prompt／全部參考輸入的來源與使用權，並完成相似性風險評估。僅有「GPT 生成」這項事實，不能單獨確定著作權或再散布權。
- [ ] **安全聯絡方式：**加入有人持續監看的私人安全聯絡管道，或在原始碼儲存庫啟用私人漏洞回報功能。
- [ ] **支援與隱私權網址：**建立 GitHub 儲存庫後，把文件中的相對連結確認為可正常開啟，並提供穩定的安全／支援入口。
- [ ] **發布目的地：**建立實際的 GitHub 公開儲存庫，確認名稱、簡介、Topics、預設分支及版本標籤正確。

## 未來若公開提供可執行 App 才需要

- [ ] 將 `local.codex.TokenMonitor` 改成發布者實際控制的 reverse-DNS Bundle Identifier。
- [ ] 建立並測試 Universal Binary，或清楚標示只支援 Apple Silicon。
- [ ] 使用 Developer ID Application 簽署、啟用 Hardened Runtime、提交 Apple 公證並 Staple 公證票證。
- [ ] 在乾淨的標準 macOS 使用者帳戶測試實際下載的公證版。
- [ ] 發布 App ZIP／DMG 的 SHA-256，並確認 GitHub Release 中的版本與原始碼 Tag 一致。

## 發布判定

目前專案是**已通過技術檢查的 source-only GitHub 發布候選版**。產品名稱已改為 `Token Monitor`，程式碼與文件採 MIT License，人物與 AppIcon 排除於 MIT License 之外，且 Git 不會包含任何預先編譯的 App。Apple Developer ID 與公證不是本次 source-only 發布的阻擋項目。公開 GitHub 前仍應補齊 AI 素材生成／參考輸入權利記錄、建立儲存庫及安全聯絡方式。除非狀態確實成立且能提供證明，不得把本軟體描述為「官方」、「經 OpenAI 核准」或「已通過 Apple 公證」。
