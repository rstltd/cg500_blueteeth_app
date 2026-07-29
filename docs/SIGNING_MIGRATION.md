# 簽章與 applicationId 遷移評估

日期：2026-07-29　狀態：**評估，尚未執行**

## 現況

`android/app/build.gradle.kts`：

```kotlin
namespace = "com.example.cg500_blueteeth_app"
applicationId = "com.example.cg500_blueteeth_app"   // 還帶著 Flutter 範本的 TODO

buildTypes {
    release {
        // TODO: Add your own signing config for the release build.
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

兩處都是 Flutter `create` 產生的範本預設值，從未改過。

好消息：`android/.gitignore` 已正確排除 `key.properties`、`**/*.keystore`、`**/*.jks`，`git ls-files` 確認沒有任何 keystore 被追蹤過。所以這是「還沒做」，不是「做錯了要清歷史」。

## 風險有多實際

debug keystore 不是「比較弱的金鑰」，而是**每一台裝了 Android SDK 的電腦上都有同一把、密碼公開是 `android`** 的固定金鑰。

對一般 app 這只是不能上架 Play Store 的問題。但這個 app 有**自建的 in-app OTA 更新機制**，情況不同：

- Android 允許用**相同簽章**的 APK 覆蓋安裝
- 任何人都能用 debug keystore 簽出一個 `com.example.cg500_blueteeth_app`
- 誘導現場人員安裝一次（或取得手機幾分鐘），就能替換掉整個 app，而系統不會有任何簽章不符的警告

實際被利用的門檻是「要能把 APK 送到現場人員手上」，不算低。但這是這個 app 目前唯一一道形同虛設的防線 —— 其餘 Android 設定（權限宣告、`exported`、FileProvider、明文流量）審查後都是乾淨的。

## 兩種遷移路徑，代價差很多

### 路徑 A：只換簽章，保留 `com.example.*`

**這是最糟的選項，不要走。**

新版 APK 與已安裝版本的 `applicationId` 相同但簽章不同 → Android 拒絕覆蓋安裝，回 `INSTALL_FAILED_UPDATE_INCOMPATIBLE`。

而現場人員是透過 app 內的更新按鈕觸發安裝的，他們會看到的是系統跳出一句籠統的「應用程式未安裝」，**沒有任何線索說明原因，也沒有任何提示告訴他們該先解除安裝**。等於每一台現場手機都會卡在這裡，然後打電話回來問。

### 路徑 B：簽章與 `applicationId` 一起換（建議）

因為 `applicationId` 變了，Android 把新 APK 視為**另一個 app**，不是升級 —— 於是：

- 從舊 app 按更新 → 下載 → 安裝，**會成功**（安裝為新 app）
- 舊 app 保留在手機上，新舊並存兩個 icon
- 現場人員確認新 app 能連上設備後，自行移除舊 app

**反直覺但關鍵**：同時換兩樣東西反而比只換簽章平順，因為 `applicationId` 改變把「覆蓋安裝失敗」變成了「安裝新 app 成功」，避開了那個沒有錯誤訊息的死路。

代價是要處理「兩個 icon」的短暫混淆，以及舊 app 會繼續提示更新（它仍指向同一個 GitHub repo）。這兩點都可以用 release notes 講清楚。

## 換 applicationId 會清空的資料

新的 `applicationId` = 新的資料沙箱，SharedPreferences 全部歸零：

| key | 內容 | 現場影響 |
|---|---|---|
| `custom_commands_v1` | **使用者自建的命令** | **最痛的一項**。現場人員自己建的命令全數消失，且 app 沒有匯出功能 |
| `role_dev_password_hash` | 開發者模式密碼 | 回到預設密碼，需重新設定 |
| `command_history` | 命令歷史 | 影響輕微 |
| `update_skip_versions` / `update_wifi_only` / `update_channel` | 更新偏好 | 回預設值，影響輕微 |
| `role_dev_session_active` | 開發者模式 session 旗標 | 無影響（本來就不跨啟動保留，見 ADR-0005） |

**執行前必須先確認的事**：現場實際有多少人建過自訂命令？如果有，遷移前要請他們抄錄，或由 IT 統一收集後在新版預載進 `command_repository.dart`。這是唯一無法自動搬移的資料（Android 沙箱隔離，新 app 讀不到舊 app 的 SharedPreferences）。

## 建議的執行順序

1. **先確認自訂命令的使用狀況**（上一節）。這決定要不要多做一步收集作業。
2. **發一版舊 ID 的過渡版本**，release notes 明講：下一版會安裝成新的 app，裝好確認可用後請移除舊版，並提醒先抄下自訂命令。
3. **建立正式 keystore**（`android/key.properties` 已在 `.gitignore` 內），密碼進團隊密碼保管機制，keystore 檔案做**離站備份**。
4. **同一個 commit 改掉** `namespace`、`applicationId`、release `signingConfig`，並移除那兩行範本 TODO 註解。
5. **發布新版**，release notes 開頭就寫遷移說明。
6. 現場確認新 app 正常後，通知移除舊 app。

## 關於 keystore 遺失

因為這個 app 走自建 OTA、不經 Play Store，keystore 遺失的後果比一般 app 輕 —— 可以再換一次簽章配合一次現場重裝，不是永久失去發布能力。

但「一次現場重裝」對散布在各工地的設備來說是實質成本。離站備份還是要做。

## 時機建議

這件事**沒有時間壓力，但越晚做越貴** —— 現場裝機數量只會增加，而遷移成本與裝機數成正比。

最合理的做法是**綁進一次已經排定的現場巡檢**，讓遷移不需要為它自己多跑一趟。ADR-0006 提到現場有「每月維護巡檢」的既有節奏，那就是天然的時機。
