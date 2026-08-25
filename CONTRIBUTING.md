# 貢獻指南

感謝你考慮為 Token Monitor 提交修改。

## 建置與測試

需求：macOS 13 或以上、Apple Command Line Tools，以及 Swift 6 相容工具鏈。

```bash
chmod +x test.sh build-app.sh verify-public-release.sh
./test.sh
./build-app.sh
```

提交 Pull Request 前，請確保 `./test.sh` 全部通過，並說明修改目的、測試方式及使用者可見的行為變化。

## 憑證安全

不得在 Issue、Pull Request、Commit、截圖、日誌或測試資料中放入真實 OpenAI Admin API Key、Bearer Token、私鑰、密碼或其他秘密。如果懷疑憑證曾經外洩，請立即在相應服務撤銷並輪替。

## 人物與 AppIcon

人物及 AppIcon 不包含在 MIT License 中。請勿在 Pull Request 中加入權利不明的圖片、聲音、字型或其他第三方素材；新增素材時必須同時提供來源與授權依據。

## Pull Request 原則

- 一個 Pull Request 聚焦一個主題。
- 儘量附上自動測試；介面修改請附上實際 macOS 顯示驗證。
- 不得把本專案描述為 OpenAI 官方、獲核准或獲背書的產品。
- 公開安全漏洞請依 `SECURITY.md` 使用私人回報方式，不要在公開 Issue 揭露利用細節或憑證。
