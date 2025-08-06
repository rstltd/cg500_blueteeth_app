# 🚀 GitHub 部署指南

這是一個完全基於 GitHub 的零成本部署方案，無需額外伺服器。

## 📋 前置準備

### 1. 安裝 GitHub CLI
```bash
# Windows (使用 winget)
winget install GitHub.cli

# 或下載安裝包
# https://cli.github.com/
```

### 2. 驗證 GitHub 身份
```bash
gh auth login
```
選擇 GitHub.com，使用瀏覽器登入您的 GitHub 帳戶。

### 3. 驗證存取權限
```bash
gh repo view rstltd/cg500_blueteeth_app
```

## 🎯 一鍵發布流程

### 發布新版本 (推薦)
```bash
# 補丁版本 (1.0.0 → 1.0.1)
python scripts/simple_release.py patch

# 小版本 (1.0.1 → 1.1.0)  
python scripts/simple_release.py minor

# 大版本 (1.1.0 → 2.0.0)
python scripts/simple_release.py major
```

### 自動化流程包含：
1. ✅ **版本號更新** - 自動修改 `pubspec.yaml`
2. ✅ **APK 建置** - Flutter release build
3. ✅ **Git 提交** - 提交版本變更
4. ✅ **GitHub Release** - 創建發布頁面
5. ✅ **檔案上傳** - 自動上傳 APK
6. ✅ **推送代碼** - 同步到 GitHub

## 📱 用戶更新體驗

### APP 自動檢查更新
- 啟動時自動檢查 GitHub Releases
- 發現新版本顯示更新對話框
- 一鍵下載並安裝新版本

### 手動分享 APK
用戶也可以直接到 GitHub 下載：
```
https://github.com/rstltd/cg500_blueteeth_app/releases/latest
```

## 🔧 進階配置

### Private Repository 設定
由於您的倉庫是 private，需要：

1. **Personal Access Token (推薦)**
   - 到 GitHub Settings > Developer settings > Personal access tokens
   - 創建 token 具備 `repo` 權限
   - APP 將使用公開的 GitHub API（不需要 token 用於讀取 releases）

2. **或者改為 Public Repository**
   - 如果不介意代碼公開，可以將倉庫設為 public
   - 這樣 API 存取完全沒有限制

### 自訂發布說明
在 Git commit 訊息中使用特殊標記：
```bash
git commit -m "Add new feature [recommended]"
# 這會讓更新類型變為 "recommended"

git commit -m "Critical security fix [forced]"  
# 這會強制用戶更新
```

## 📊 版本管理策略

### 語義化版本控制
- `patch`: 錯誤修復 (1.0.0 → 1.0.1)
- `minor`: 新功能 (1.0.1 → 1.1.0)  
- `major`: 重大變更 (1.1.0 → 2.0.0)

### 版本號格式
```
major.minor.patch+build
例如: 1.2.3+15
```

### 更新類型自動判定
- **Patch 更新**: 顯示為「可選更新」
- **Minor 更新**: 顯示為「建議更新」
- **Major 更新**: 顯示為「建議更新」
- **包含 [forced] 標籤**: 強制更新

## 🚨 故障排除

### 常見問題

#### 1. GitHub CLI 認證失敗
```bash
gh auth status
gh auth refresh
```

#### 2. 找不到 APK 檔案
確保 Flutter 已正確安裝並可以建置：
```bash
flutter doctor
flutter clean
flutter pub get
```

#### 3. Git 推送失敗
檢查是否有未提交的變更：
```bash
git status
git stash  # 暫存變更
```

#### 4. Private Repository 存取問題
GitHub Releases API 對 private 倉庫有限制：
- APP 可以讀取 releases（匿名存取）
- 但下載可能需要驗證
- 建議測試後決定是否改為 public

### 測試發布流程
建議先測試整個流程：
```bash
# 建立測試版本
python scripts/simple_release.py patch

# 檢查 GitHub Releases 頁面
# 測試 APP 的更新檢查功能
```

## 📈 優勢總結

### ✅ 對開發者的好處
- **零維護成本**: 無需架設或維護伺服器
- **全自動化**: 一個命令完成所有發布步驟
- **版本管理**: 自動化的語義化版本控制
- **備份安全**: 所有檔案都在 GitHub 安全存儲

### ✅ 對用戶的好處
- **無感更新**: APP 內自動檢查和安裝
- **快速下載**: GitHub CDN 全球加速
- **透明度**: 可查看所有版本歷史和變更
- **可信度**: 官方 GitHub 平台，值得信賴

### ✅ 技術優勢
- **高可用性**: GitHub 99.9% 正常運行時間
- **全球 CDN**: 世界各地快速下載
- **API 穩定**: 成熟的 GitHub API
- **無流量限制**: 不用擔心頻寬費用

## 🎉 開始使用

1. 確認前置準備完成
2. 執行第一次發布：`python scripts/simple_release.py patch`
3. 測試 APP 的更新檢查功能
4. 享受零維護成本的自動更新系統！

---

> 💡 **小提示**: 這個方案讓您完全專注於 APP 開發，而不用操心部署和更新的複雜性。GitHub 處理所有基礎設施，您只需要專注於寫程式碼！