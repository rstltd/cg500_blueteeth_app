# CG500 BLE App 部署和更新指南

## 📱 部署策略概覽

本應用採用**混合更新策略**，結合以下兩種技術：

### 🚀 方案1：Shorebird 熱更新（推薦）
- **適用場景**：UI 調整、邏輯修改、BLE 功能優化等
- **優勢**：用戶無感知更新，不需重新下載 APK
- **限制**：不能更新原生代碼、Flutter 版本、依賴庫等

### 📦 方案2：APK 完整更新
- **適用場景**：重大版本更新、原生代碼更改、依賴庫升級等
- **優勢**：可以進行完整更新，包含所有變更

---

## 🛠️ 設置更新服務器

### 服務器 API 端點

需要實現以下 API 端點：

#### 1. 版本檢查 API
```
GET /api/version
Headers:
  Current-Version: 1.0.0
  Current-Build: 1
  Platform: android

Response:
{
  "latest_version": "1.1.0",
  "current_version": "1.0.0",
  "download_url": "app_v1.1.0.apk",
  "download_size": 15728640,
  "release_notes": "• 新增設備連接穩定性改進\n• 修復藍牙掃描問題\n• UI 介面優化",
  "is_forced": false,
  "update_type": "recommended",
  "release_date": "2024-01-15T10:00:00Z"
}
```

#### 2. APK 下載端點
```
GET /api/download/{filename}
Response: APK 文件流
```

### 服務器端實現示例（Node.js）

```javascript
const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3000;

// 版本配置
const VERSION_CONFIG = {
  latest_version: "1.1.0",
  download_size: 15728640,
  release_notes: "• 新增設備連接穩定性改進\n• 修復藍牙掃描問題\n• UI 介面優化",
  is_forced: false,
  update_type: "recommended",
  release_date: "2024-01-15T10:00:00Z"
};

// 版本檢查 API
app.get('/api/version', (req, res) => {
  const currentVersion = req.headers['current-version'] || '1.0.0';
  const platform = req.headers['platform'] || 'android';
  
  // 比較版本邏輯
  const hasUpdate = compareVersions(VERSION_CONFIG.latest_version, currentVersion) > 0;
  
  if (!hasUpdate) {
    return res.json({
      latest_version: currentVersion,
      current_version: currentVersion,
      has_update: false
    });
  }
  
  res.json({
    ...VERSION_CONFIG,
    current_version: currentVersion,
    download_url: `app_v${VERSION_CONFIG.latest_version}.apk`,
    has_update: true
  });
});

// APK 下載端點
app.get('/api/download/:filename', (req, res) => {
  const filename = req.params.filename;
  const filePath = path.join(__dirname, 'apks', filename);
  
  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ error: 'File not found' });
  }
  
  res.setHeader('Content-Type', 'application/vnd.android.package-archive');
  res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
  
  const fileStream = fs.createReadStream(filePath);
  fileStream.pipe(res);
});

function compareVersions(v1, v2) {
  const parts1 = v1.split('.').map(Number);
  const parts2 = v2.split('.').map(Number);
  
  for (let i = 0; i < Math.max(parts1.length, parts2.length); i++) {
    const part1 = parts1[i] || 0;
    const part2 = parts2[i] || 0;
    
    if (part1 > part2) return 1;
    if (part1 < part2) return -1;
  }
  
  return 0;
}

app.listen(PORT, () => {
  console.log(`Update server running on port ${PORT}`);
});
```

---

## 🏗️ Shorebird 熱更新設置

### 1. 安裝 Shorebird CLI

```bash
# 安裝 Shorebird CLI
curl --proto '=https' --tlsv1.2 https://shorebird.dev/install.sh -sSf | bash

# 驗證安裝
shorebird --version
```

### 2. 創建 Shorebird 應用

```bash
# 登入 Shorebird
shorebird login

# 創建新應用
shorebird apps create
```

### 3. 配置應用

更新 `shorebird.yaml` 文件：

```yaml
# 使用從控制台獲得的實際 app_id
app_id: your_actual_shorebird_app_id

auto_update:
  check_on_start: true
  check_on_resume: true
  install_automatically: false
  show_progress: true
```

### 4. 建構和發布

```bash
# 建構 release 版本
shorebird release android

# 發布代碼更新（熱更新）
shorebird patch android
```

---

## 📦 APK 發布流程

### 1. 建構 Production APK

```bash
# 清理專案
flutter clean
flutter pub get

# 建構 release APK
flutter build apk --release

# APK 位置：build/app/outputs/flutter-apk/app-release.apk
```

### 2. 簽名 APK（生產環境必需）

#### 創建 Keystore

```bash
keytool -genkey -v -keystore cg500-release-key.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias cg500-key
```

#### 配置簽名

創建 `android/key.properties`：

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=cg500-key
storeFile=../cg500-release-key.keystore
```

更新 `android/app/build.gradle`：

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### 3. 版本管理

更新 `pubspec.yaml` 中的版本號：

```yaml
version: 1.1.0+2  # 格式：主.次.修訂+build號
```

---

## 🔧 更新服務配置

### 1. 修改更新服務器 URL

在 `lib/services/update_service.dart` 中：

```dart
// 替換為您的實際服務器地址
static const String _updateServerUrl = 'https://your-update-server.com/api';
```

### 2. 測試更新功能

```bash
# 建構測試版本
flutter build apk --debug

# 安裝到設備
flutter install
```

---

## 🚀 部署檢查清單

### APK 發布前檢查

- [ ] 更新版本號在 `pubspec.yaml`
- [ ] 測試所有核心功能（BLE 掃描、連接、命令發送）
- [ ] 驗證 UI 在不同螢幕尺寸下的表現
- [ ] 檢查權限請求是否正常
- [ ] 測試更新機制（可選）

### 服務器設置檢查

- [ ] 部署更新服務器
- [ ] 配置 APK 文件存儲
- [ ] 測試版本檢查 API
- [ ] 測試 APK 下載功能
- [ ] 設置 HTTPS（生產環境推薦）

### Shorebird 設置檢查

- [ ] 創建 Shorebird 應用
- [ ] 配置 `shorebird.yaml`
- [ ] 測試熱更新發布

---

## 📱 用戶安裝指導

### 1. 啟用未知來源安裝

用戶需要在 Android 設置中允許安裝未知來源的應用：

```
設定 → 安全性 → 未知的應用程式 → 允許此來源
```

### 2. APK 分發方式

- **直接下載**：提供 APK 下載連結
- **二維碼分享**：生成包含下載連結的二維碼
- **雲端存儲**：使用 Google Drive、Dropbox 等分享

### 3. 更新流程

1. 應用自動檢查更新
2. 顯示更新通知
3. 用戶確認下載
4. 自動引導安裝新版本

---

## 🔍 故障排除

### 常見問題

1. **APK 安裝失敗**
   - 檢查是否允許未知來源安裝
   - 確認 APK 文件完整性

2. **更新檢查失敗**
   - 檢查網絡連接
   - 驗證服務器 URL 配置

3. **熱更新不生效**
   - 確認 Shorebird 配置正確
   - 檢查應用版本是否匹配

### 日誌調試

使用內建的日誌系統查看詳細信息：

```dart
Logger.setLogLevel(Logger.debugLevel);  // 啟用調試日誌
```

---

## 📊 更新統計和監控

建議實現以下監控功能：

- 版本分佈統計
- 更新成功/失敗率
- 用戶更新行為分析
- 錯誤報告收集

---

## 🔐 安全建議

1. **HTTPS**：生產環境務必使用 HTTPS
2. **APK 簽名驗證**：確保 APK 完整性
3. **服務器訪問控制**：限制非授權訪問
4. **版本回滾機制**：準備快速回滾方案

---

這個指南涵蓋了完整的部署和更新流程。根據您的具體需求，可以選擇實施其中的部分或全部功能。