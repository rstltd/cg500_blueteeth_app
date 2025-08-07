# APK 更新權限問題修復報告

## 🔍 發現的權限問題

### 1. Android 11+ 包可見性限制
**問題**: 缺少 APK 安裝意圖的查詢配置
**修復**: 在 `AndroidManifest.xml` 添加了 `<queries>` 配置

### 2. FileProvider 路徑兼容性問題  
**問題**: `getApplicationDocumentsDirectory()` 返回的路徑可能不在 FileProvider 配置範圍內
**修復**: 
- 添加了路徑回退機制（documents → support directory）
- 擴展了 FileProvider 路徑配置

### 3. 權限診斷不足
**問題**: 缺少詳細的錯誤追蹤和診斷信息
**修復**: 
- 添加了詳細的 Android 日誌記錄
- 實現了完整的權限診斷功能
- 創建了權限測試工具

## 🛠️ 修復內容詳情

### Android 配置修復
1. **AndroidManifest.xml**:
   - 添加了 APK 安裝意圖查詢配置
   - 保持了所有必要的權限設定

2. **MainActivity.kt**:
   - 增強了錯誤處理和日誌記錄
   - 添加了 URI 權限授予邏輯
   - 實現了完整的權限診斷功能

### Flutter 端修復
3. **UpdateService.dart**:
   - 添加了目錄路徑回退機制
   - 實現了權限診斷 API
   - 增強了錯誤處理和用戶提示

## 🧪 診斷工具

### 權限診斷功能
新增的診斷功能可以檢查：
- Android 版本兼容性
- 未知來源安裝權限狀態
- FileProvider 配置有效性
- 實際文件路徑訪問性
- URI 權限授予狀況

### 使用方法
```dart
// 在 UpdateService 中調用
final diagnosis = await updateService.diagnosePermissions();
print('診斷結果: $diagnosis');
```

### 測試工具
創建了 `test_permissions.dart` 作為獨立測試工具：
```bash
# 運行權限診斷測試
flutter run -t test_permissions.dart
```

## 📋 測試指南

### 必要測試步驟
1. **權限狀態檢查**:
   - 運行診斷工具檢查基本配置
   - 確認 `canInstallApks` 返回預期值

2. **文件路徑測試**:
   - 檢查 APK 下載路徑是否可訪問
   - 驗證 FileProvider URI 生成

3. **實際安裝測試**:
   - 下載實際 APK 文件
   - 測試安裝流程和權限引導
   - 檢查 Android 日誌輸出

### 日誌監控
使用 `adb logcat` 監控詳細日誌：
```bash
adb logcat | grep -E "(MainActivity|UpdateService)"
```

## 🎯 預期解決的問題

修復後應該能夠：
1. ✅ 正確識別和請求未知來源安裝權限
2. ✅ 成功生成和使用 FileProvider URI
3. ✅ 在不同 Android 版本上兼容運行
4. ✅ 提供詳細的錯誤診斷信息
5. ✅ 引導用戶完成必要的權限設定

## 🚨 仍需注意的事項

1. **設備特定問題**: 某些廠商可能有額外的安全限制
2. **測試覆蓋**: 需要在不同 Android 版本上測試
3. **用戶體驗**: 權限被拒絕時的回退處理
4. **網路狀況**: 確保下載和權限檢查的順序正確

如果仍然遇到問題，請運行診斷工具並提供完整的診斷結果和 Android 日誌。