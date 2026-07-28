# GitHub 部署指南

完全基於 GitHub 的零成本部署方案，無需額外伺服器。

> **版本號格式以 [`docs/VERSIONING.md`](docs/VERSIONING.md) 為準。** 本文件僅
> 描述部署流程；所有與版本格式、通道、release script CLI 相關的爭議，皆以
> VERSIONING.md 為唯一裁決來源。

---

## 前置準備

### 1. 安裝 GitHub CLI

```pwsh
# Windows (winget)
winget install GitHub.cli
```

或從 https://cli.github.com/ 下載安裝包。

### 2. 驗證 GitHub 身份

```pwsh
gh auth login
```

選擇 GitHub.com，使用瀏覽器登入。

### 3. 驗證存取權限

```pwsh
gh repo view rstltd/cg500_blueteeth_app
```

---

## 一鍵發布流程

專案採用 **CalVer (`vYY.0M[.MICRO][-beta.N]`)** 與兩個發布通道（`stable` /
`beta`）。Release script 的模式名稱直接反映語意，**不再使用 `patch` /
`minor` / `major`**：

```pwsh
# 月度 stable release  (e.g. 26.05+31 -> 26.06+33)
python3 scripts/simple_release.py release --notes-file release_notes.md --yes

# 同月 hotfix          (e.g. 26.05+31 -> 26.05.1+32)
python3 scripts/simple_release.py hotfix  --notes-file release_notes.md --yes

# Beta pre-release     (e.g. 26.05+31 -> 26.06-beta.1+32)
python3 scripts/simple_release.py beta    --notes-file release_notes.md --yes

# Release candidate    (rarely used, only when feature-freeze step is wanted)
python3 scripts/simple_release.py rc      --notes-file release_notes.md --yes

# 僅 build number 升一級 (no version change)
python3 scripts/simple_release.py build   --yes
```

`--yes` 在非互動 shell（CI、Claude Code 的 Bash tool）必填，否則會卡在
確認提示。詳見 [`docs/VERSIONING.md` §3](docs/VERSIONING.md)。

### 自動化流程包含

1. **版本號更新** — 自動修改 `pubspec.yaml`（**只有 release script 可寫**）
2. **靜態分析 + 測試** — `flutter analyze` + `flutter test` 一旦失敗就中止
3. **APK 建置** — Flutter release build
4. **Git commit + tag** — 提交版本變更並建立本地 tag
5. **Push** — 推送 commit 與 tag 到 GitHub
6. **GitHub Release** — 用 `gh release create --verify-tag` 發布；
   `beta` / `rc` 自動帶 `--prerelease` flag
7. **APK 上傳** — APK 與 SHA256 一併附在 Release 頁面

---

## 用戶更新體驗

### App 自動檢查更新

- 啟動時呼叫 GitHub Releases API
- 發現新版本顯示更新對話框
- 一鍵下載並安裝新版本
- **通道選擇**：`設定 → 更新通道` 可切換 `stable` / `beta`，beta
  使用者會收到 prerelease；stable 使用者只看 latest stable
  （詳見 [`docs/VERSIONING.md` §2](docs/VERSIONING.md)）

### 手動分享 APK

```
https://github.com/rstltd/cg500_blueteeth_app/releases/latest
```

---

## 進階配置

### Private Repository 設定

倉庫為 private 時：

1. **Personal Access Token (推薦)**
   - GitHub Settings → Developer settings → Personal access tokens
   - 建立 token 並賦予 `repo` 權限
   - App 使用公開 GitHub API（不需要 token 即可讀 releases）

2. **或改為 Public Repository**
   - 不介意代碼公開時 API 存取無限制

### 自訂發布類型標記

Release notes 可以用標記控制更新類型：

```
[forced]    強制更新（critical 也接受）
[critical]  同上
[recommended]  顯示為「建議更新」
```

**Release notes 標題不要寫死版本號** — 由 release script 從模式自動算出，
寫死會在 hotfix / beta 流程出錯（詳見記憶 `release_process_notes.md`）。

---

## 故障排除

### GitHub CLI 認證失敗

```pwsh
gh auth status
gh auth refresh
```

### 找不到 APK 檔案

```pwsh
flutter doctor
flutter clean
flutter pub get
```

### Git 推送失敗（uncommitted changes）

Release script 會自動阻擋，需要先處理：

```pwsh
git status
git stash  # 或 git commit
```

### Private Repository 存取問題

GitHub Releases API 對 private 倉庫的匿名存取有限制：

- App 可以讀 releases（匿名）
- 但下載可能需要驗證
- 必要時測試後決定是否改為 public

### Windows cp950 編碼錯誤

`simple_release.py` 已透過 `_run()` helper 統一強制 UTF-8。**不要繞過它**
（詳見 commit `b7bd89c` 與記憶 `release_process_notes.md`）。

---

## 優勢總結

### 對開發者的好處

- **零維護成本**：不必架設或維護伺服器
- **全自動化**：單一指令完成所有發布步驟
- **可審計**：所有檔案、tag、release 都在 GitHub
- **與 VERSIONING.md 一致**：mode 名稱直接對應版本語意

### 對用戶的好處

- **無感更新**：App 內自動檢查和安裝
- **通道控制**：可選 stable / beta，互不干擾
- **快速下載**：GitHub CDN 全球加速
- **透明度**：所有版本歷史與變更可查

### 技術優勢

- **高可用性**：GitHub 的可用性保證
- **全球 CDN**：世界各地快速下載
- **API 穩定**：成熟的 GitHub API
- **無流量限制**：不用擔心頻寬費用
