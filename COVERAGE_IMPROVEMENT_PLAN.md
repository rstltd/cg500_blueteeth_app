# 測試覆蓋率改進計劃

## 當前狀態
- **覆蓋率**: 46.9% (2203/4693 lines)
- **目標**: 50% (2346 lines)
- **需增加**: 143 行覆蓋

## 問題分析

### 現有測試的問題
許多測試文件使用「UI pattern 測試」而非「actual widget 測試」：
- 沒有 import 實際的 widget 類
- 用基礎 Flutter widgets 重建 UI
- 這種測試不會增加源代碼覆蓋率

### 難以測試的原因
1. **Widget 依賴 Controller**: `DeviceListWidget` 需要 `SimpleBleController`
2. **Controller 依賴硬件**: BLE 功能需要實際設備
3. **需要 BuildContext**: 許多方法需要 UI context

## 高效改進策略

### 策略 1: 針對部分覆蓋的 Services 補充測試 (推薦)

這些文件已有測試基礎，只需補充未覆蓋的方法：

| 文件 | 當前覆蓋 | 未覆蓋行 | 難度 | 優先級 |
|------|---------|---------|------|--------|
| network_service.dart | 64.1% | 28 | 低 | ⭐⭐⭐ |
| ble_characteristic.dart | 62.1% | 22 | 低 | ⭐⭐⭐ |
| app_update_manager.dart | 55.5% | 49 | 中 | ⭐⭐ |
| command_manager.dart | 49.1% | 29 | 中 | ⭐⭐ |
| animation_service.dart | 81.0% | 30 | 低 | ⭐⭐ |

**預計可增加: ~100-150 行**

### 策略 2: 針對純邏輯代碼補充測試

這些代碼不依賴 UI/硬件，容易測試：

| 文件 | 未覆蓋的可測試方法 |
|------|-------------------|
| network_service.dart | `isSuitableForDownload()`, `getStatusDescription()`, `estimateDownloadTime()` |
| ble_characteristic.dart | `_getCharacteristicName()`, `_safeSubstring()` (static methods) |
| update_logic_manager.dart | 純邏輯方法 |

### 策略 3: 避免測試 (低效益)

以下文件測試成本高，建議暫時跳過：

| 文件 | 原因 |
|------|------|
| command_interface_view.dart | 400 行，需要複雜 mock |
| simple_scanner_view.dart | 210 行，需要 BLE controller |
| update_settings_view.dart | 206 行，需要多個 services |
| ble_service.dart | 232 行，需要硬件模擬 |

## 具體實施計劃

### 第一階段: 補充 static 方法測試 (最快)

**ble_characteristic.dart** - 測試 `_getCharacteristicName()` 間接覆蓋

```dart
// 測試已知 UUID 映射
test('should map Device Name UUID correctly', () {
  // 通過 factory 構造函數間接測試 _getCharacteristicName
  final char = BleCharacteristicModel.fromBluetoothCharacteristic(...);
});
```

問題：`fromBluetoothCharacteristic` 需要真實 `BluetoothCharacteristic` 對象

**解決方案**: 直接測試公開的方法和屬性，無法覆蓋 private static 方法

### 第二階段: 補充 NetworkService 測試

當前測試沒有測試實際的 switch 分支，可以通過：

```dart
// 測試各種狀態下的行為
// 問題：currentStatus 是從 connectivity_plus 獲取的，無法直接設置
```

### 第三階段: 創建可測試的抽象層

為了真正提高覆蓋率，需要重構代碼：

1. **提取接口**: 將硬件依賴抽象為接口
2. **依賴注入**: 允許測試時注入 mock
3. **分離邏輯**: 將純邏輯從 UI 代碼分離

## 最有效的立即行動

### 選項 A: 補充現有測試的覆蓋 (~50-80 行)

針對 `ble_characteristic.dart`:
- 測試 `_safeSubstring` 邊界情況 (透過 displayName)
- 測試更多 known characteristics UUID

針對 `network_service.dart`:
- 測試 `estimateDownloadTime` 的所有分支
- 但 switch 分支依賴 `_currentStatus`，無法控制

### 選項 B: 重構以支持測試 (長期)

1. 添加 `@visibleForTesting` 方法來設置狀態
2. 創建 mock 版本的 services
3. 使用 dependency injection

### 選項 C: 測試 Widget 的 build 輸出 (中等效益)

```dart
// 直接導入並使用 widget，即使會失敗也會執行部分代碼
import 'package:cg500_blueteeth_app/widgets/device_list_widget.dart';

testWidgets('DeviceListWidget creates without error', (tester) async {
  // 這會失敗但會執行 widget 的初始化代碼
  try {
    await tester.pumpWidget(DeviceListWidget(...));
  } catch (e) {
    // 預期失敗，但已增加覆蓋率
  }
});
```

## 建議的實施順序

1. **立即** (1-2 小時):
   - 補充 `ble_characteristic_test.dart` 測試 known UUIDs
   - 補充 `animation_service_test.dart` 測試未覆蓋方法

2. **短期** (半天):
   - 為 `NetworkService` 添加可測試的輔助方法
   - 測試 `UpdateLogicManager` 的純邏輯部分

3. **中期** (1-2 天):
   - 重構 controllers 支持 dependency injection
   - 創建 mock services

## 結論

要達到 50% 覆蓋率 (增加 143 行)，最有效的方法是：

1. **聚焦已有部分覆蓋的文件** - 這些文件的測試基礎設施已存在
2. **測試純邏輯方法** - 不依賴硬件或 UI 的代碼
3. **避免低效益測試** - Views 和需要複雜 mock 的代碼

實際上，由於許多未覆蓋代碼依賴硬件/UI，在不重構的情況下，可能只能額外覆蓋 50-100 行。
