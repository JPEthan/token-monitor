# 隱私說明 / Privacy Notice

最後更新：2026-08-25

## 摘要

本 App 沒有廣告、分析工具、遙測、追蹤器、第三方 SDK、帳戶系統或發布者控制的伺服器。它只會在啟動時（如已儲存金鑰）、排程自動同步或使用者手動刷新時，把 OpenAI Admin API Key 透過 HTTPS 傳送到 OpenAI 官方 Usage API，並在本機顯示回傳的彙總用量。

## 本機儲存

- **OpenAI Admin API Key**：儲存在 macOS Keychain，不寫入 UserDefaults、專案、一般設定檔或發布包。
- **偏好設定**：月度 Token 額度、自動同步頻率、顯示語言、音效開關、桌寵位置與左右方向儲存在 macOS UserDefaults。
- **用量快照**：輸入 Token、輸出 Token、快取輸入、請求次數與最近更新時間只保存在執行中 App 的記憶體；本版本不建立永久用量歷史資料庫。
- **橡皮鴨音效**：在本機即時生成，不會錄音或上傳音訊。

## 網路連線

App 的自動或手動同步只會向以下端點發出讀取請求：

```text
https://api.openai.com/v1/organization/usage/completions
```

Admin API Key 會放在 HTTPS Authorization 標頭中傳送給 OpenAI。App 使用不落地快取、不接受 Cookie 的暫時性網路 Session。點擊「官方用量頁」會由 macOS 開啟 `https://platform.openai.com/usage`；其後的瀏覽活動由瀏覽器和 OpenAI 的政策管理。

本 App 不會把資料傳送給專案發布者，也不會連線到發布者控制的伺服器。OpenAI 對 API 資料的處理受 OpenAI 條款與資料控制說明約束；請參閱 [OpenAI Data Controls](https://developers.openai.com/api/docs/guides/your-data#default-usage-policies-by-endpoint)。

## 可見的組織資料

Usage API 回傳的是彙總用量，但組織用量仍可能是敏感的營運資訊。App 只在本機介面顯示總量；使用者應避免把包含用量或組織資訊的截圖公開分享。

## 刪除資料

- 在 App 設定中選擇「移除已儲存的金鑰」可刪除本機 Keychain 項目。這不會撤銷 OpenAI 端的金鑰；如需停止憑證效力，還必須在 OpenAI 管理介面撤銷或輪替。
- 偏好設定可透過移除 App 的偏好設定網域清除。
- 用量快照會在 App 結束時從記憶體消失。
- 單純把 App 丟進垃圾桶不一定會刪除 macOS Keychain 項目；建議先在 App 內移除金鑰。

## 儿童隱私與敏感資料

本 App 不是為兒童設計，也不要求姓名、地址、付款資料、醫療資料或政府識別資料。請勿在任何公開回報中附上 API Key 或組織敏感資訊。

## English summary

The app contains no ads, analytics, telemetry, trackers, third-party SDKs, publisher accounts, or publisher-operated servers. The OpenAI Admin API Key is stored in macOS Keychain and sent only over HTTPS to the official OpenAI Organization Usage endpoint at launch when a key is already stored, during scheduled refreshes, or after a manual refresh. Aggregate usage is held in memory; ordinary preferences are stored in UserDefaults. The app uses an ephemeral, no-cookie, no-disk-cache network session. Remove the local Keychain item from Settings before uninstalling; local removal does not revoke the credential at OpenAI, so revoke or rotate it through OpenAI when needed. OpenAI's own processing is governed by its terms and data controls.
