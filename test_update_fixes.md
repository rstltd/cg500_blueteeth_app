# APK 更新功能修復測試指南

## 修復內容總結

### 問題1修復：WiFi Only Downloads 設定失效
**修復位置**: `lib/services/update_service.dart:175-195`
- 移除了不當的 `?? true` 預設值回退
- 添加了 `_preferences` null 檢查，確保設定已載入
- 修正了行動數據下載的條件判斷

### 問題2修復：APK 安裝失敗
**修復位置**: 
1. `android/app/src/main/res/xml/file_paths.xml` - 擴展了 FileProvider 路徑支援
2. `android/app/src/main/AndroidManifest.xml` - 移除了無效的 INSTALL_PACKAGES 權限
3. `android/app/src/main/kotlin/.../MainActivity.kt` - 添加了權限檢查和用戶引導
4. `lib/services/update_service.dart` - 增強了安裝流程和錯誤處理

## 測試步驟

### 測試1：WiFi Only 設定功能
1. 進入 Update Settings 
2. 將 "WiFi Only Downloads" 設為 OFF
3. 使用行動數據網路
4. 嘗試下載更新
5. **預期結果**: 應該允許透過行動數據下載

### 測試2：APK 安裝功能
1. 成功下載更新 APK
2. 點擊安裝
3. **預期行為**: 
   - 如果未授權「未知來源安裝」，會顯示權限請求
   - 自動開啟設定頁面供用戶授權
   - 授權後可成功觸發 APK 安裝程序

### 測試3：網路狀態檢測
1. 切換不同網路狀態（WiFi, 行動數據, 無網路）
2. 檢查 Update Settings 中的網路狀態顯示
3. **預期結果**: 狀態顯示正確，下載行為符合設定

## 技術改進詳情

### NetworkService 邏輯改進
- 明確的 `wifiOnly` 參數處理
- 不再依賴可能為 null 的偏好設定

### Android 權限處理
- 正確的 FileProvider 配置，支援多種存儲路徑
- 動態權限檢查（Android 8.0+）
- 用戶友善的權限請求流程

### 錯誤處理增強
- 詳細的日誌記錄
- 用戶友善的錯誤訊息
- 適當的回退機制

## 需要手動測試的場景
1. 不同 Android 版本的相容性
2. 實際的 GitHub Releases APK 下載
3. 從行動數據到 WiFi 的網路切換
4. 權限授權後的安裝流程

修復完成後，這兩個關鍵問題應該都能得到解決。