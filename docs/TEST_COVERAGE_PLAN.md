# 測試覆蓋率提升計劃

## 當前狀態分析

### 覆蓋率概覽
| Layer       | Coverage | Lines  | 狀態     |
|-------------|----------|--------|----------|
| Controllers | 35.8%    | 310    | 需改進   |
| Models      | 79.3%    | 227    | 良好     |
| Services    | 37.2%    | 1321   | 需改進   |
| Utils       | 100.0%   | 141    | 完成     |
| Views       | 0.4%     | 839    | 極低     |
| Widgets     | 38.1%    | 1516   | 需改進   |
| **Total**   | **34.8%**| **4415**| 目標 60% |

---

## Views 層測試策略 (839 行, 0.4% → 目標 40%)

### 分析：為何 Views 難以測試

**Views 檔案清單：**
1. `simple_scanner_view.dart` (517 行)
2. `command_interface_view.dart` (949 行)
3. `update_settings_view.dart` (511 行)

**主要挑戰：**
- Views 直接實例化 Singleton Controllers/Services
- 依賴 BLE 硬體功能 (SimpleBleController)
- 依賴平台通道 (Platform Channels)
- 使用 StreamBuilder 監聽多個 Streams
- 包含複雜的 UI 交互邏輯

### 策略 1：提取可測試的 UI 邏輯

**目標：** 將純 UI 邏輯提取為獨立函數，可以在不需要 Mock 的情況下測試

**可提取的函數：**

```dart
// simple_scanner_view.dart
Color _getNotificationColor(NotificationType type)  // 純函數
String _formatDateTime(DateTime dateTime)            // 純函數
String _formatDuration(Duration duration)            // 純函數

// command_interface_view.dart
Color _getNotificationColor(NotificationType type)  // 純函數
String _formatDuration(Duration duration)            // 純函數

// update_settings_view.dart
Color _getNetworkStatusColor()                       // 依賴 _networkStatus
IconData _getNetworkStatusIcon()                     // 依賴 _networkStatus
```

**預估測試數量：** 15-20 個

### 策略 2：測試 Widget 建構邏輯

**目標：** 測試 Views 渲染的基本 Widget 結構

**可測試項目：**
- Loading 狀態顯示
- AppBar 結構和標題
- 基本佈局結構 (Mobile/Tablet/Desktop)
- 錯誤狀態顯示

**挑戰：** 需要 Mock SimpleBleController

**解決方案：** 使用 Widget Wrapper 模式

```dart
// 測試用 Wrapper
class TestableSimpleScannerView extends StatelessWidget {
  final bool isInitialized;
  final Widget? connectedDeviceWidget;

  // 提供測試用的靜態數據，避免依賴真實 Controller
}
```

**預估測試數量：** 20-30 個

### 策略 3：建立 Mock 基礎設施

**需要 Mock 的類別：**

1. **SimpleBleController Mock**
   - `devicesStream` → 返回 Stream<List<BleDeviceModel>>
   - `connectedDeviceStream` → 返回 Stream<BleDeviceModel?>
   - `notificationStream` → 返回 Stream<NotificationModel>
   - `isInitialized` → 返回 bool
   - `connectedDevice` → 返回 BleDeviceModel?

2. **UpdateService Mock**
   - `getCurrentVersionInfo()` → 返回 Map<String, String>
   - `updateStream` → 返回 Stream<UpdateInfo>
   - `checkForUpdates()` → 返回 Future<UpdateInfo?>

3. **NetworkService Mock**
   - `networkStream` → 返回 Stream<NetworkStatus>
   - `currentStatus` → 返回 NetworkStatus
   - `getStatusDescription()` → 返回 String

**Mock 實現方式：**
```dart
// 使用 mockito 或手動 Mock
class MockSimpleBleController extends SimpleBleController {
  final StreamController<List<BleDeviceModel>> _devicesController;

  @override
  Stream<List<BleDeviceModel>> get devicesStream => _devicesController.stream;

  // 提供測試數據注入方法
  void emitDevices(List<BleDeviceModel> devices) {
    _devicesController.add(devices);
  }
}
```

**預估工作量：** 建立 Mock 基礎設施需要 2-3 小時

---

## Services 層測試策略 (1321 行, 37.2% → 目標 55%)

### 未測試的 Services

1. **permission_service.dart** (92 行)
2. **ble_service.dart** (估計 400+ 行)
3. **update_service.dart** (845 行)

### 策略分析

#### 1. PermissionService (92 行)

**挑戰：** 依賴 `permission_handler` 套件的平台功能

**可測試項目：**
- `getPermissionStatusDescription()` - 純函數，可直接測試
- Singleton 模式正確性
- 方法存在性檢查

**不可測試項目（需要 Mock）：**
- `requestBluetoothPermissions()` - 依賴原生權限 API
- `hasBluetoothPermissions()` - 依賴原生權限 API
- `getBluetoothStatus()` - 依賴原生權限 API

**預估測試數量：** 10-15 個

#### 2. UpdateService (845 行)

**可測試項目：**

```dart
// 純函數測試
_cleanVersionTag(String tag)           // "v1.0.0" → "1.0.0"
_isForceUpdate(String releaseNotes)    // 檢測 [forced], [critical] 等
_determineUpdateType(current, latest)  // 比較版本決定更新類型
_formatBytes(int bytes)                // 格式化檔案大小

// 類別測試
UpdateInfo                             // 模型類別，包含 hasUpdate 邏輯
DownloadProgress                       // 模型類別，包含格式化方法
UpdateType enum                        // 枚舉值測試
```

**不可測試項目（需要 Mock/平台功能）：**
- `initialize()` - 依賴 PackageInfo
- `checkForUpdates()` - 依賴 HTTP 請求
- `downloadUpdate()` - 依賴 HTTP 下載和檔案系統
- `installUpdate()` - 依賴平台通道

**策略：**
1. 將純函數提取為 static 方法或獨立 utils
2. 為 UpdateInfo 和 DownloadProgress 類別建立完整測試

**預估測試數量：** 40-50 個

#### 3. BleService (估計 400+ 行)

**挑戰：** 完全依賴 flutter_blue_plus 套件和藍牙硬體

**可測試項目：**
- Service UUID 常量
- 資料格式化函數
- 狀態枚舉

**預估測試數量：** 10-15 個

---

## 實施計劃

### Phase 1：快速提升覆蓋率（低風險）

**優先順序 1：純函數測試**
| 項目 | 預估測試數 | 難度 |
|------|-----------|------|
| UpdateInfo 類別完整測試 | 20 | 低 |
| DownloadProgress 類別測試 | 15 | 低 |
| UpdateType 枚舉測試 | 5 | 低 |
| PermissionService 描述函數 | 10 | 低 |
| Views 純函數提取測試 | 15 | 低 |

**預估總測試數：** 65 個
**預估覆蓋率提升：** +5-8%

### Phase 2：Mock 基礎設施建立

**需要建立的 Mock：**
1. MockSimpleBleController
2. MockUpdateService
3. MockNetworkService
4. MockThemeService

**預估工作量：** 建立完整 Mock 系統

### Phase 3：Views 層測試

**使用 Mock 測試：**
- simple_scanner_view.dart 基本渲染
- command_interface_view.dart 基本渲染
- update_settings_view.dart 基本渲染

**預估測試數：** 30-40 個
**預估覆蓋率提升：** +8-12%

---

## 建議執行順序

### 立即可執行（無需 Mock）

1. **UpdateInfo 完整測試** ⭐ 高優先
   - hasUpdate 邏輯
   - 版本比較邏輯
   - JSON 序列化/反序列化
   - 邊界案例（空版本、特殊字符等）

2. **DownloadProgress 完整測試** ⭐ 高優先
   - 進度計算
   - 格式化方法
   - 時間估算顯示

3. **PermissionService 部分測試**
   - getPermissionStatusDescription()
   - Singleton 模式

4. **Views 純函數提取**
   - 將 _formatDateTime, _formatDuration 等提取到 utils
   - 為這些函數建立測試

### 需要 Mock 基礎設施

5. **建立 Mock 類別**
   - 從最簡單的開始：MockNetworkService
   - 逐步擴展到 MockSimpleBleController

6. **Views 基本渲染測試**
   - Loading 狀態
   - 錯誤狀態
   - 空資料狀態

---

## 預期成果

| 階段 | 新增測試數 | 預估覆蓋率 |
|------|-----------|-----------|
| 當前 | 1196 | 34.8% |
| Phase 1 完成 | +65 | ~40% |
| Phase 2 完成 | +0 (基礎設施) | ~40% |
| Phase 3 完成 | +40 | ~50% |
| **總計** | **+105** | **~50%** |

---

## 風險評估

### 低風險項目
- 純函數測試
- 模型類別測試
- 枚舉測試

### 中風險項目
- Mock 基礎設施建立（可能遇到 Singleton 問題）
- Views StreamBuilder 測試

### 高風險項目
- BLE 相關測試（需要實際設備或複雜 Mock）
- Platform Channel 測試

---

## 結論

**建議立即開始 Phase 1**，因為：
1. 不需要 Mock，可以直接開始
2. 風險最低
3. 可以快速看到覆蓋率提升
4. 為後續 Mock 工作建立基礎

**預估 Phase 1 完成時間：** 1-2 小時
**預估 Phase 1 後覆蓋率：** 40%+
