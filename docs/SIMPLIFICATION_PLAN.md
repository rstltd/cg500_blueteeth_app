# 專案複雜度降低計畫

> **STATUS：Phases 1–3 已完成（2024-12 至 2026-05 期間多次 commit）。** 介面
> 已從 10 縮減為 3、`BleNotificationDelegate` 已重構為單類別配置式、
> `UpdateService` 已分解為 4 個窄服務（`update_checker` / `download_manager` /
> `install_manager` / `update_preferences_store`）並由 `UpdateController` 協
> 調。Phase 4 (Widget 整理) 未明確結論——`animated_widgets.dart` 等大檔仍存
> 在於 `lib/widgets/common/`。本文保留作為歷史決策脈絡；現況請參考實際程式
> 碼與 CLAUDE.md。

> 建立日期：2024-12-09
> 基於：[OVER_ENGINEERING_ANALYSIS.md](./OVER_ENGINEERING_ANALYSIS.md)
> 目標：降低架構複雜度，提升可維護性

---

## 執行摘要

本計畫分三個階段執行，預計可減少 600-800 行代碼，將檔案數從 117 個降至 95-100 個。

---

## Phase 1：移除不必要的介面抽象

### 1.1 目標
移除 8 個只有單一實作的介面，保留 2 個有實際價值的介面。

### 1.2 保留的介面

| 介面 | 原因 |
|------|------|
| BleNotificationDelegate | 有 4 個實作，策略模式有意義 |
| CommandRepositoryInterface | 測試需要 mock，已建立測試 |

### 1.3 移除的介面

| 介面 | 檔案 | 對應實作 |
|------|------|----------|
| PermissionServiceInterface | permission_service_interface.dart | PermissionService |
| NetworkServiceInterface | network_service_interface.dart | NetworkService |
| NotificationServiceInterface | notification_service_interface.dart | SmartNotificationService |
| BleServiceInterface | ble_service_interface.dart | BleService |
| UpdateServiceInterface | update_service_interface.dart | UpdateService |
| ErrorHandlingServiceInterface | error_handling_service_interface.dart | ErrorHandlingService |
| CommandParameterStorageInterface | command_parameter_storage_interface.dart | CommandParameterStorageService |
| UpdateUiDelegate | update_ui_delegate.dart | (單一使用) |

### 1.4 執行步驟

#### Step 1.4.1: 移除 PermissionServiceInterface
```
1. 更新 service_locator.dart
   - 將 registerLazySingleton<PermissionServiceInterface> 改為 registerLazySingleton<PermissionService>
2. 更新所有引用處
   - lib/services/ble_service.dart
   - test/mocks/mock_services.dart
3. 刪除 permission_service_interface.dart
4. 執行測試驗證
```

#### Step 1.4.2: 移除 NetworkServiceInterface
```
1. 更新 service_locator.dart
2. 更新所有引用處
   - lib/services/update_service.dart
   - lib/controllers/app_update_manager.dart
   - test/mocks/mock_services.dart
3. 刪除 network_service_interface.dart
4. 執行測試驗證
```

#### Step 1.4.3: 移除 NotificationServiceInterface
```
1. 更新 service_locator.dart
2. 更新所有引用處
   - lib/services/ble_service.dart
   - lib/services/error_handling_service.dart
   - lib/services/update_service.dart
   - lib/controllers/simple_ble_controller.dart
   - lib/core/interfaces/ble_notification_delegate.dart
   - test/mocks/mock_services.dart
3. 刪除 notification_service_interface.dart
4. 執行測試驗證
```

#### Step 1.4.4: 移除 BleServiceInterface
```
1. 更新 service_locator.dart
2. 更新所有引用處
   - lib/controllers/simple_ble_controller.dart
   - test/mocks/mock_services.dart
3. 刪除 ble_service_interface.dart
4. 執行測試驗證
```

#### Step 1.4.5: 移除 UpdateServiceInterface
```
1. 更新 service_locator.dart
2. 更新所有引用處
   - lib/controllers/app_update_manager.dart
   - test/mocks/mock_services.dart
3. 刪除 update_service_interface.dart
4. 執行測試驗證
```

#### Step 1.4.6: 移除 ErrorHandlingServiceInterface
```
1. 更新 service_locator.dart
2. 更新所有引用處
   - (檢查實際引用)
   - test/mocks/mock_services.dart
3. 刪除 error_handling_service_interface.dart
4. 執行測試驗證
```

#### Step 1.4.7: 移除 CommandParameterStorageInterface
```
注意：此介面剛在設計審查中被加入，需評估是否確實需要

1. 評估測試需求
2. 如不需要，更新相關引用
3. 刪除介面檔案
4. 執行測試驗證
```

#### Step 1.4.8: 移除 UpdateUiDelegate
```
1. 評估使用情況
2. 如只有單一使用，內聯到使用處
3. 刪除介面檔案
4. 執行測試驗證
```

### 1.5 預期成果
- 刪除 8 個介面檔案 (~750 行)
- 簡化 service_locator.dart
- 減少間接層

### 1.6 風險緩解
- 每個步驟後執行 `flutter test`
- 每個步驟後執行 `flutter analyze`
- 小步提交，方便回滾

---

## Phase 2：重構 BleNotificationDelegate

### 2.1 目標
將 4 個實作類別合併為 1 個可配置類別。

### 2.2 現狀分析

```dart
// 現有結構 (571 行)
abstract class BleNotificationDelegate {
  // 37 個方法
  void onInitializeSuccess();
  void onInitializeFailure(String reason);
  void onScanStarted();
  // ... 34 個更多
}

class DefaultBleNotificationDelegate implements BleNotificationDelegate { }
class MinimalBleNotificationDelegate implements BleNotificationDelegate { }
class ConfigurableBleNotificationDelegate implements BleNotificationDelegate { }
class SilentBleNotificationDelegate implements BleNotificationDelegate { }
```

### 2.3 目標結構

```dart
// 目標結構 (~150 行)
enum BleNotificationVerbosity {
  silent,   // 不顯示任何通知
  minimal,  // 只顯示錯誤
  normal,   // 顯示錯誤和重要事件
  verbose,  // 顯示所有事件
}

class BleNotificationDelegate {
  final NotificationService _notificationService;
  BleNotificationVerbosity verbosity;

  BleNotificationDelegate({
    required NotificationService notificationService,
    this.verbosity = BleNotificationVerbosity.normal,
  }) : _notificationService = notificationService;

  // 統一的通知方法
  void notify(BleEvent event, {String? customMessage}) {
    if (!_shouldNotify(event)) return;

    final message = customMessage ?? _getDefaultMessage(event);
    final type = _getNotificationType(event);
    _notificationService.show(message, type: type);
  }

  bool _shouldNotify(BleEvent event) {
    switch (verbosity) {
      case BleNotificationVerbosity.silent:
        return false;
      case BleNotificationVerbosity.minimal:
        return event.isError;
      case BleNotificationVerbosity.normal:
        return event.isError || event.isImportant;
      case BleNotificationVerbosity.verbose:
        return true;
    }
  }

  // 事件特定的便捷方法
  void onInitializeSuccess() => notify(BleEvent.initializeSuccess);
  void onInitializeFailure(String reason) =>
      notify(BleEvent.initializeFailure, customMessage: reason);
  // ... 其他方法
}

enum BleEvent {
  initializeSuccess(isError: false, isImportant: true),
  initializeFailure(isError: true, isImportant: true),
  scanStarted(isError: false, isImportant: false),
  // ... 其他事件
  ;

  final bool isError;
  final bool isImportant;
  const BleEvent({required this.isError, required this.isImportant});
}
```

### 2.4 執行步驟

```
1. 建立 BleEvent 枚舉
2. 建立新的 BleNotificationDelegate 類別
3. 更新 BleService 使用新類別
4. 更新 SimpleBleController 使用新類別
5. 更新測試
6. 刪除舊的 4 個實作類別
7. 執行完整測試
```

### 2.5 預期成果
- 代碼從 571 行減少到 ~150 行 (節省 ~420 行)
- 配置更直觀（使用枚舉而非類別選擇）
- 新增通知類型只需修改枚舉

---

## Phase 3：分解 UpdateService

### 3.1 目標
將 UpdateService (830 行) 分解為職責單一的服務。

### 3.2 分解方案

```
UpdateService (830 行)
    ↓ 分解為
UpdateChecker (~200 行)
├── checkForUpdates()
├── checkForUpdatesFromGitHub()
├── compareVersions()
└── getCurrentVersionInfo()

DownloadManager (~250 行)
├── downloadUpdate()
├── downloadWithRetry()
├── downloadProgressStream
├── cancelDownload()
└── cleanupTempFiles()

InstallManager (~150 行)
├── installUpdate()
├── canRequestPackageInstalls()
├── requestInstallPermission()
└── openInstallSettings()

UpdatePreferenceService (~100 行)
├── autoCheckEnabled
├── autoDownloadEnabled
├── wifiOnlyDownload
├── updatePreferences()
└── loadPreferences()

UpdateCoordinator (~130 行) [可選]
├── 協調各服務
└── 提供統一 API
```

### 3.3 執行步驟

```
1. 建立 UpdateChecker 類別
   - 提取版本檢查相關方法
   - 建立單元測試

2. 建立 DownloadManager 類別
   - 提取下載相關方法
   - 建立單元測試

3. 建立 InstallManager 類別
   - 提取安裝相關方法
   - 建立單元測試

4. 建立 UpdatePreferenceService 類別
   - 提取偏好設定相關方法
   - 建立單元測試

5. 更新 AppUpdateManager 使用新服務
   - AppUpdateManager 作為協調器

6. 更新 Service Locator 註冊

7. 刪除舊的 UpdateService

8. 執行完整測試
```

### 3.4 依賴關係

```
UpdateChecker
└── 無依賴

DownloadManager
├── NetworkService (網絡狀態)
└── NotificationService (進度通知)

InstallManager
├── PermissionService (權限檢查)
└── NotificationService (安裝通知)

UpdatePreferenceService
└── SharedPreferences (持久化)

AppUpdateManager (協調器)
├── UpdateChecker
├── DownloadManager
├── InstallManager
├── UpdatePreferenceService
└── NetworkService
```

### 3.5 預期成果
- 代碼總量可能略增 (~50 行)
- 每個類別職責單一，易於理解
- 可獨立測試每個功能
- 修改一個功能不影響其他功能

---

## Phase 4：Widget 整理 (可選)

### 4.1 目標
合併過度分散的小型 Widget，整理大型 Widget 檔案。

### 4.2 待評估項目

```
小型 Widget 合併候選：
- quick_command_button.dart + quick_access_bar_widget.dart
- command_preview_widget.dart + command_form_sheet.dart
- command_feedback_widget.dart + (相關組件)

大型 Widget 拆分候選：
- animated_widgets.dart (1,668 行) → 按動畫類型拆分
- semantic_widgets.dart (761 行) → 按功能拆分
```

### 4.3 執行原則
- 優先保持現狀，除非有明確痛點
- 只合併邏輯緊密相關的 Widget
- 不為了減少檔案數而強行合併

---

## 執行時程

### 建議順序

| 階段 | 內容 | 預估工作量 | 優先級 |
|------|------|------------|--------|
| Phase 1 | 移除不必要介面 | 2-3 小時 | 高 |
| Phase 2 | 重構 BleNotificationDelegate | 3-4 小時 | 高 |
| Phase 3 | 分解 UpdateService | 4-6 小時 | 中 |
| Phase 4 | Widget 整理 | 2-3 小時 | 低 |

### 檢查點

每個 Phase 完成後：
1. [ ] 執行 `flutter analyze` 無錯誤
2. [ ] 執行 `flutter test` 全部通過
3. [ ] 手動測試關鍵功能
4. [ ] Git commit 並記錄變更

---

## 回滾策略

如果重構導致問題：

1. **小範圍問題**：使用 `git checkout -- <file>` 還原單一檔案
2. **Phase 失敗**：使用 `git reset --hard <commit>` 還原到 Phase 開始前
3. **嚴重問題**：建立分支進行重構，問題解決前不合併

---

## 成功指標

### 量化指標

| 指標 | 目前 | Phase 1 後 | Phase 2 後 | Phase 3 後 |
|------|------|------------|------------|------------|
| 介面檔案數 | 10 | 2 | 2 | 2 |
| 介面代碼行數 | 1,323 | ~600 | ~200 | ~200 |
| UpdateService 行數 | 830 | 830 | 830 | ~200 (協調器) |
| 總檔案數 | 117 | 109 | 108 | 111 |

### 質化指標

- [ ] 新開發者可在 30 分鐘內理解服務架構
- [ ] 修改通知行為只需修改一個檔案
- [ ] 新增更新功能只需修改相關子服務

---

## 附錄：受影響的測試檔案

執行重構時需要更新的測試：

```
test/mocks/mock_services.dart
test/services/ble_service_test.dart
test/services/update_service_test.dart
test/controllers/simple_ble_controller_test.dart
test/controllers/app_update_manager_test.dart
test/view_models/command_interface_view_model_test.dart
```
