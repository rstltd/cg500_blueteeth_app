/// Centralized string management for the CG500 Bluetooth App.
///
/// This class provides all UI strings used throughout the application.
/// Centralizing strings makes it easier to:
/// - Maintain consistent terminology across the app
/// - Update translations in one place
/// - Add support for multiple languages in the future
/// - Write tests that don't break when text changes
///
/// Usage:
/// ```dart
/// import 'package:cg500_blueteeth_app/l10n/app_strings.dart';
///
/// Text(AppStrings.startScanning)
/// Text(AppStrings.devicesFound(5))
/// ```
abstract class AppStrings {
  // ============================================================
  // BLE Scanning
  // ============================================================

  /// Start scanning button text
  static const String startScanning = '開始掃描';

  /// Stop scanning button text
  static const String stopScanning = '停止掃描';

  /// Scanning in progress indicator
  static const String scanning = '掃描中...';

  /// Scanning for BLE devices message
  static const String scanningForDevices = '正在搜尋 BLE 裝置...';

  /// Clear devices button tooltip
  static const String clearDevices = '清除裝置';

  /// Device count display
  static String devicesFound(int count) => '已發現 $count 個裝置';

  /// No devices found message
  static const String noDevicesFound = '未發現 BLE 裝置';

  /// Start scanning hint
  static const String startScanningHint = '開始掃描以發現附近裝置';

  /// No matching devices message
  static String noMatchingDevices(String query) => '沒有符合「$query」的裝置';

  /// Available devices hint
  static String availableDevicesHint(int count) =>
      '有 $count 個裝置可用，請嘗試其他搜尋條件';

  /// Available devices section title
  static const String availableDevices = '可用設備';

  // ============================================================
  // Connection Status
  // ============================================================

  /// Connected status
  static const String connected = '已連線';

  /// Disconnected status
  static const String disconnected = '已斷線';

  /// Connecting status
  static const String connecting = '連線中...';

  /// Disconnecting status
  static const String disconnecting = '斷線中...';

  /// Device connected title
  static const String deviceConnected = '裝置已連線';

  /// No device connected title
  static const String noDeviceConnected = '未連線裝置';

  /// Please connect device first
  static const String pleaseConnectFirst = '請先連接裝置';

  /// Please connect BLE device hint
  static const String pleaseConnectBleDevice = '請連接 BLE 裝置以發送指令';

  /// Ready to send commands
  static const String readyToSendCommands = '可發送指令';

  /// Connect button text
  static const String connect = '連線';

  /// Disconnect button text
  static const String disconnect = '中斷連線';

  // ============================================================
  // Device Information
  // ============================================================

  /// Device label
  static const String device = '裝置';

  /// Device ID label
  static const String deviceId = '裝置 ID';

  /// Device name label
  static const String name = '名稱';

  /// Unknown device name
  static const String unknownDevice = '未知裝置';

  /// Unknown value
  static const String unknown = '未知';

  /// RSSI/Signal strength label
  static const String rssi = 'RSSI';

  /// Signal strength label
  static const String signalStrength = '訊號強度';

  /// Connection status label
  static const String connectionStatus = '連線狀態';

  /// Services label
  static const String services = '服務';

  /// Services count
  static String servicesCount(int count) => '$count 個可用';

  /// Services list header
  static const String servicesList = '服務列表：';

  /// Last seen label
  static const String lastSeen = '最後發現';

  /// Connected at label
  static const String connectedAt = '連線時間';

  /// Connection duration label
  static const String connectionDuration = '連線時長';

  /// Connected for label
  static const String connectedFor = '已連線時間';

  /// MTU size label
  static const String mtuSize = 'MTU 大小';

  /// Bytes unit
  static String bytes(int count) => '$count 位元組';

  /// Add to favorites tooltip
  static const String addToFavorites = '加入收藏';

  /// Remove from favorites tooltip
  static const String removeFromFavorites = '取消收藏';

  // ============================================================
  // Connection Stats
  // ============================================================

  /// Connection stats title
  static const String connectionStats = '連線統計';

  /// Device name label for stats
  static const String deviceName = '裝置名稱';

  /// Messages sent label
  static const String messagesSent = '已發送訊息';

  // ============================================================
  // Quick Stats
  // ============================================================

  /// Quick stats title
  static const String quickStats = '快速統計';

  /// Found label
  static const String found = '已發現';

  // ============================================================
  // Command Interface
  // ============================================================

  /// Command interface title
  static const String commandInterface = '指令介面';

  /// Open command interface button
  static const String openCommandInterface = '開啟指令介面';

  /// Command input placeholder (connected)
  static const String enterCommand = '輸入您的指令...';

  /// Command input placeholder (disconnected)
  static const String connectToSendCommands = '連接裝置以發送指令';

  /// Command input placeholder (connected but not in developer mode)
  static const String needDeveloperMode = '需開啟開發者模式才能手動輸入指令';

  // ============================================================
  // Developer Mode (Role-based access control)
  // ============================================================

  /// Developer mode section title
  static const String developerMode = '開發者模式';

  /// Developer mode subtitle when enabled
  static const String developerModeEnabled = '已啟用 — 顯示全部指令並開放手動輸入';

  /// Developer mode subtitle when disabled
  static const String developerModeDisabled = '一般模式 — 僅顯示基本設備指令';

  /// Password dialog title
  static const String enterDeveloperPassword = '輸入開發者密碼';

  /// Password field hint
  static const String passwordHint = '密碼';

  /// Incorrect password error
  static const String incorrectPassword = '密碼錯誤';

  /// Forgot password link
  static const String forgotPassword = '忘記密碼？';

  /// Forgot password confirm dialog title
  static const String forgotPasswordTitle = '重設為預設密碼？';

  /// Forgot password confirm dialog body — emphasizes security implication
  static const String forgotPasswordBody =
      '密碼將回到出廠預設值，自訂密碼會被清除，但自訂指令與其他設定不受影響。';

  /// Forgot password warning bullet 1
  static const String forgotPasswordBullet1 = '密碼將回到出廠預設值';

  /// Forgot password warning bullet 2 (security implication)
  static const String forgotPasswordBullet2 =
      '任何知道預設密碼的人都能進入開發者模式，請僅在無法恢復密碼時使用';

  /// Forgot password destructive action button label
  static const String forgotPasswordResetButton = '重設密碼';

  /// Password reset success snackbar
  static const String passwordResetSuccess = '已重設為預設密碼，請以預設密碼登入';

  /// Change password menu item / dialog title
  static const String changePasswordTitle = '修改開發者密碼';

  /// Old password field hint
  static const String oldPasswordHint = '舊密碼';

  /// New password field hint
  static const String newPasswordHint = '新密碼';

  /// Confirm new password field hint
  static const String confirmNewPasswordHint = '再次輸入新密碼';

  /// New password too short error
  static const String passwordTooShort = '密碼長度至少 4 字元';

  /// New password mismatch error
  static const String passwordMismatch = '兩次輸入的新密碼不一致';

  /// Change password success
  static const String changePasswordSuccess = '密碼已更新';

  /// Confirm button text (generic)
  static const String confirm = '確定';

  // ============================================================
  // Custom Commands (Dev Mode)
  // ============================================================

  /// Management view title
  static const String customCommands = '自訂指令';

  /// Settings list tile title
  static const String manageCustomCommands = '管理自訂指令';

  /// FAB / add button label
  static const String addCustomCommand = '新增自訂指令';

  /// Edit dialog title
  static const String editCustomCommand = '編輯自訂指令';

  /// Command string text field hint
  static const String customCommandStringHint = '指令字串（例如 \$MAC,CN001）';

  /// Name text field hint
  static const String customCommandNameHint = '顯示名稱';

  /// Description text field hint
  static const String customCommandDescriptionHint = '說明（可選）';

  /// Empty state title
  static const String customCommandsEmpty = '尚未新增任何自訂指令';

  /// Empty state hint
  static const String customCommandsEmptyHint = '點右下角 + 新增第一個自訂指令';

  /// Empty state — example command formats shown so new users know what to type
  static const String customCommandsEmptyExamples =
      '指令必須以 \$ 開頭，常見格式：\n\n'
      '• \$INFO（無參數）\n'
      '• \$APN,internet（單一參數）\n'
      '• \$ADDR,192.168.1.1:8080（IP+Port）\n'
      '• \$REBOOT,2（時間參數）';

  /// Caption shown under the network status card to clarify scope —
  /// reassures field operators that no network is needed for normal BLE work.
  static const String bleCommandsWorkOffline =
      'BLE 指令發送不需要網路，網路狀態僅影響韌體更新檢查';

  /// Network row label in the update settings card
  static const String networkLabel = '網路：';

  /// Hint shown while update preferences are still loading
  static const String loadingPreferences = '正在載入偏好設定...';

  /// Warning shown when the current connection isn't WiFi but WiFi is required
  static const String wifiRecommended = '建議使用 WiFi';

  /// Estimated download time prefix
  static String estimatedDownloadTime(String time) => '預估時間：$time';

  /// Command history panel title
  static const String commandHistory = '指令歷史';

  /// Empty state for command history
  static const String noCommandsYet = '尚無指令紀錄';

  /// Tooltip on the "fill input" history button
  static const String historyFillInputTooltip = '填入輸入框';

  /// Tooltip on the "send now" history button
  static const String historySendNowTooltip = '直接送出';

  /// Tooltip on the mobile history opener icon
  static const String commandHistoryTooltip = '指令歷史';

  /// Bottom sheet title shown when picking a history command on mobile
  static const String tapHistoryToSend = '點擊指令立即送出';

  /// Application title shown on the splash screen and main scanner AppBar
  static const String appTitle = 'CG500 藍牙掃描器';

  /// First line of the splash screen
  static const String initializingApp = '正在初始化 CG500 藍牙應用...';

  /// Second line of the splash screen, explains what is being loaded
  static const String loadingUpdateSystem = '載入更新系統中';

  /// Error: empty command string
  static const String customCommandEmptyError = '指令不可為空';

  /// Error: missing $ prefix
  static const String customCommandMustStartWithDollar = '指令必須以 \$ 開頭';

  /// Error: empty name
  static const String customCommandNameEmptyError = '請輸入顯示名稱';

  /// Error: duplicate among custom commands
  static const String customCommandDuplicateInCustom =
      '此指令已存在於自訂指令中';

  /// Error: collision with built-in
  static const String customCommandDuplicateInBuiltIn =
      '此指令與內建指令相同';

  /// Delete confirmation title
  static const String customCommandDeleteTitle = '刪除自訂指令';

  /// Delete confirmation body
  static String customCommandDeleteBody(String command) =>
      '確定要刪除「$command」嗎？此動作無法復原。';

  /// Delete button
  static const String delete = '刪除';

  /// Save button
  static const String save = '儲存';

  /// Conflict banner title
  static const String customCommandConflictsTitle = '偵測到指令衝突';

  /// Conflict banner body
  static const String customCommandConflictsBody =
      '以下自訂指令與 app 更新後的內建指令重複，目前已自動隱藏。請重新命名或刪除。';

  /// Previous command tooltip
  static const String previousCommand = '上一個指令';

  /// Next command tooltip
  static const String nextCommand = '下一個指令';

  /// Ready status
  static const String ready = '就緒';

  /// Commands count
  static String commandsCount(int count) => '$count 個指令';

  /// Command label (for message bubbles)
  static const String command = '指令';

  /// Response label
  static const String response = '回應';

  /// Clear messages tooltip
  static const String clearMessages = '清除訊息';

  /// Communication log title
  static const String communicationLog = '通訊紀錄';

  /// Device communication title
  static const String deviceCommunication = '設備通訊';

  /// No messages yet
  static const String noMessagesYet = '尚無訊息';

  /// Send command to start
  static const String sendCommandToStart = '發送指令以開始對話';

  /// Initializing command interface
  static const String initializingCommandInterface = '正在初始化指令介面...';

  /// New messages indicator
  static String newMessages(int count) => '$count 則新訊息';

  /// Scroll to bottom tooltip
  static const String scrollToBottom = '捲動到底部';

  // ============================================================
  // Command Feedback
  // ============================================================

  /// Command sent successfully
  static const String commandSentSuccess = '指令發送成功';

  /// Command send failed
  static const String commandSendFailed = '指令發送失敗';

  /// Sending command
  static const String sendingCommand = '發送中...';

  /// Send command button
  static const String sendCommand = '發送指令';

  /// Device not connected
  static const String deviceNotConnected = '設備未連線';

  // ============================================================
  // Command Form
  // ============================================================

  /// Set parameters title
  static const String setParameters = '設定參數';

  /// Last used parameters loaded
  static const String lastParametersLoaded = '已載入上次使用的參數';

  /// Hint shown in command form when device is offline — user can prefill before connecting
  static const String offlineEditHint = '目前未連線，可預先填寫參數，連線後再送出';

  /// Section title shown above warningMessage in DangerConfirmDialog
  static const String dangerConsequencesTitle = '執行後會發生：';

  /// SnackBar shown right after a device connects — guides user to command interface
  static String justConnectedSnackBar(String deviceName) =>
      '已連線到 $deviceName，可開啟指令介面開始操作';

  /// SnackBar action label that opens the command interface
  static const String justConnectedSnackBarAction = '開啟';

  /// Reset button
  static const String reset = '重設';

  /// All commands label
  static const String allCommands = '全部指令';

  /// All category label
  static const String all = '全部';

  /// More button (opens command menu)
  static const String more = '更多';

  // ============================================================
  // Command Categories
  // ============================================================

  /// Query category label
  static const String categoryQuery = '查詢';

  /// Config category label
  static const String categoryConfig = '設定';

  /// Control category label
  static const String categoryControl = '控制';

  /// Debug category label
  static const String categoryDebug = '除錯';

  /// Custom category label
  static const String categoryCustom = '自訂';

  /// Query category description
  static const String categoryQueryDesc = '查詢設備資訊和狀態';

  /// Config category description
  static const String categoryConfigDesc = '修改設備設定';

  /// Control category description
  static const String categoryControlDesc = '控制設備行為';

  /// Debug category description
  static const String categoryDebugDesc = '開發和除錯用途';

  /// Custom category description
  static const String categoryCustomDesc = '使用者自行新增的指令';

  // ============================================================
  // Validation
  // ============================================================

  /// Required field validation error
  static String requiredField(String label) => '$label 為必填項目';

  // ============================================================
  // Search
  // ============================================================

  /// Search devices placeholder
  static const String searchDevices = '搜尋裝置...';

  /// Search by name or ID placeholder
  static const String searchByNameOrId = '依名稱或 ID 搜尋...';

  /// Close search tooltip
  static const String closeSearch = '關閉搜尋';

  /// Search device tooltip
  static const String searchDevice = '搜尋裝置';

  // ============================================================
  // Common Actions
  // ============================================================

  /// Close button
  static const String close = '關閉';

  /// Cancel button
  static const String cancel = '取消';

  /// Apply button
  static const String apply = '套用';

  /// Apply settings button
  static const String applySettings = '套用設定';

  /// Retry button
  static const String retry = '重試';

  /// Error prefix
  static String error(String message) => '錯誤: $message';

  // ============================================================
  // Update System
  // ============================================================

  /// Update button
  static const String update = '更新';

  /// Update now button
  static const String updateNow = '立即更新';

  /// Skip button
  static const String skip = '跳過';

  /// Later button
  static const String later = '稍後';

  /// Browser download button
  static const String browserDownload = '瀏覽器下載';

  /// Download failed warning
  static const String downloadFailedWarning = '若下載失敗，請點擊下方「瀏覽器下載」';

  /// Download guide title
  static const String downloadGuide = '下載指南';

  /// Got it button
  static const String gotIt = '了解';

  /// Cannot open browser message
  static String cannotOpenBrowser(String url) => '無法開啟瀏覽器。請前往:\n$url';

  /// Open browser failed message
  static String openBrowserFailed(String error) => '開啟瀏覽器失敗: $error';

  /// Check for updates menu item
  static const String checkForUpdates = '檢查更新';

  /// Update settings menu item
  static const String updateSettings = '更新設定';

  /// Check update tooltip
  static const String checkUpdateTooltip = '檢查更新';

  /// Cannot load update settings
  static const String cannotLoadUpdateSettings = '無法載入更新設定';

  /// Network status section
  static const String networkStatus = '網路狀態';

  // ============================================================
  // Update Settings
  // ============================================================

  /// Update check section
  static const String updateCheck = '更新檢查';

  /// Auto check updates option
  static const String autoCheckUpdates = '自動檢查更新';

  /// Auto check updates description
  static const String autoCheckUpdatesDesc = '啟動 App 時自動檢查更新';

  /// Check frequency option
  static const String checkFrequency = '檢查頻率';

  /// Check frequency description
  static const String checkFrequencyDesc = '多久檢查一次更新';

  /// Download settings section
  static const String downloadSettings = '下載設定';

  /// Auto download updates option
  static const String autoDownloadUpdates = '自動下載更新';

  /// Auto download updates description
  static const String autoDownloadUpdatesDesc = '發現更新時自動下載';

  /// WiFi only download option
  static const String wifiOnlyDownload = '僅 WiFi 下載';

  /// WiFi only download description
  static const String wifiOnlyDownloadDesc = '僅在連接 WiFi 時下載更新';

  /// Skipped versions section
  static const String skippedVersions = '已略過版本';

  /// No skipped versions
  static const String noSkippedVersions = '沒有略過的版本';

  /// Version prefix
  static String version(String v) => '版本 $v';

  /// Clear all button
  static const String clearAll = '全部清除';

  /// Current version section
  static const String currentVersion = '目前版本';

  /// Version label
  static const String versionLabel = '版本';

  /// Build number label
  static const String buildNumber = '建置編號';

  // Version Info Widget labels (English for compatibility)
  /// Current version label (English)
  static const String currentVersionLabel = 'Current Version';

  /// New version label (English)
  static const String newVersionLabel = 'New Version';

  /// Download size label (English)
  static const String downloadSizeLabel = 'Download Size';

  /// Release date label (English)
  static const String releaseDateLabel = 'Release Date';

  /// What's new label (English)
  static const String whatsNew = 'What\'s New';

  /// Default release notes
  static const String defaultReleaseNotes = 'Bug fixes and performance improvements';

  /// Reset section
  static const String resetSection = '重設';

  /// Restore defaults option
  static const String restoreDefaults = '還原預設值';

  /// Restore defaults description
  static const String restoreDefaultsDesc = '將所有更新設定還原為預設值';

  /// Reset settings dialog title
  static const String resetSettingsTitle = '重設設定';

  /// Reset settings confirmation
  static const String resetSettingsConfirmation =
      '確定要將所有更新設定還原為預設值嗎？此操作無法復原。';

  /// Settings restored message
  static const String settingsRestored = '設定已還原為預設值';

  // ============================================================
  // Update Banner
  // ============================================================

  /// New version available message
  static String newVersionAvailable(String version) => '新版本可用: $version';

  /// Click to download manually
  static const String clickToDownloadManually = '點擊從 GitHub 手動下載';

  /// Download button
  static const String download = '下載';

  /// Download APK manually hint
  static const String downloadApkManually = '下載 APK 檔案後手動安裝';

  /// Please go to URL message
  static String pleaseGoTo(String url) => '請前往: $url';

  /// Important update available
  static const String importantUpdateAvailable = '重要更新可用';

  /// Required update
  static const String requiredUpdate = '必要更新';

  /// Update available
  static const String updateAvailable = '有可用更新';

  /// Optional update
  static const String optionalUpdate = '可選更新';

  /// Update description
  static String updateDescription(String version) =>
      '版本 $version 已可更新，包含增強功能';

  // ============================================================
  // Installation Guide
  // ============================================================

  /// Installation guide title
  static const String installationGuide = '安裝指南';

  /// Step progress
  static String stepProgress(int current, int total) => '步驟 $current / $total';

  /// Instructions label
  static const String instructions = '操作說明:';

  /// Previous button
  static const String previous = '上一步';

  /// Next button
  static const String next = '下一步';

  /// Install now button
  static const String installNow = '立即安裝';

  /// Skip guide button
  static const String skipGuide = '跳過指南';

  // Installation steps
  /// Start installation step title
  static const String startInstallation = '開始安裝';

  /// Start installation description
  static const String startInstallationDesc = '正在準備更新安裝。';

  /// Start installation instruction
  static const String startInstallationInstruction = '若沒有動作，請點擊下方「立即安裝」';

  /// Enable unknown sources step title
  static const String enableUnknownSources = '啟用未知來源';

  /// Enable unknown sources description
  static const String enableUnknownSourcesDesc = '允許安裝來自未知來源的應用程式。';

  /// Enable unknown sources instructions
  static const List<String> enableUnknownSourcesInstructions = [
    '如有提示，請在安全性對話框中點擊「設定」',
    '開啟「允許此來源」或「未知來源」',
    '返回安裝畫面',
  ];

  /// Install update step title
  static const String installUpdate = '安裝更新';

  /// Install update description
  static const String installUpdateDesc = '進行安裝程序。';

  /// Install update instructions
  static const List<String> installUpdateInstructions = [
    '如有顯示，請檢視應用程式權限',
    '點擊「安裝」繼續',
    '等待安裝完成',
  ];

  /// Installation complete step title
  static const String installationComplete = '安裝完成';

  /// Installation complete description
  static const String installationCompleteDesc = '更新已成功安裝。';

  /// Installation complete instructions
  static const List<String> installationCompleteInstructions = [
    '應用程式將自動重新啟動',
    '您將在應用程式中看到新版本',
    '所有資料和設定都已保留',
  ];

  /// Cannot start installation error
  static const String cannotStartInstallation = '無法啟動安裝。請手動安裝。';

  /// Installation error message
  static String installationError(String error) => '安裝錯誤: $error';

  // ============================================================
  // Scanner View
  // ============================================================

  /// Initializing Bluetooth controller
  static const String initializingBluetooth = '正在初始化藍牙控制器...';

  /// More settings tooltip
  static const String moreSettings = '更多設定';

  /// Device info tooltip
  static const String deviceInfo = '設備資訊';

  // ============================================================
  // Device Status Panel
  // ============================================================

  /// Please connect BLE device first
  static const String pleaseConnectBleDeviceFirst = '請先連接 BLE 裝置';

  // ============================================================
  // Danger Levels
  // ============================================================

  /// Safe danger level
  static const String dangerLevelSafe = '安全';

  /// Warning danger level
  static const String dangerLevelWarning = '警告';

  /// Dangerous danger level
  static const String dangerLevelDangerous = '危險';

  /// Confirm execution title
  static const String confirmExecution = '確認執行';

  /// Attention title
  static const String attention = '注意';

  /// Warning dangerous operation title
  static const String warningDangerousOperation = '警告：危險操作';

  /// Execute button
  static const String execute = '執行';

  /// Understand and continue button
  static const String understandAndContinue = '我了解，繼續執行';

  /// Confirm dangerous operation button
  static const String confirmDangerousOperation = '確認執行危險操作';

  // ============================================================
  // Error Handling — titles, messages, and recovery action labels.
  // The codes referenced here mirror those in ErrorHandlingService.
  // ============================================================

  /// Title shown for ErrorCategory.bluetooth
  static const String bluetoothErrorTitle = '藍牙錯誤';

  /// Title shown for ErrorCategory.permission
  static const String permissionErrorTitle = '需要權限';

  /// Title shown for ErrorCategory.network
  static const String networkErrorTitle = '網路錯誤';

  /// Title shown for ErrorCategory.validation
  static const String validationErrorTitle = '輸入錯誤';

  /// Title shown for ErrorCategory.system
  static const String systemErrorTitle = '系統錯誤';

  /// Title shown for ErrorCategory.unknown
  static const String unknownErrorTitle = '未預期的錯誤';

  /// Bluetooth: BLE_DISABLED — adapter is off
  static const String bleDisabledMessage =
      '此裝置的藍牙目前未開啟，請開啟藍牙後再試。';

  /// Bluetooth: BLE_UNAVAILABLE — hardware doesn't support BLE
  static const String bleUnavailableMessage = '此裝置不支援 Bluetooth Low Energy。';

  /// Bluetooth: DEVICE_NOT_FOUND
  static const String deviceNotFoundMessage =
      '找不到所選的裝置，可能已超出範圍或已關機。';

  /// Bluetooth: CONNECTION_FAILED
  static const String connectionFailedMessage =
      '無法連線到裝置，請確認裝置在附近並重試。';

  /// Bluetooth: CONNECTION_LOST
  static const String connectionLostMessage = '與裝置的連線已中斷，可能已超出訊號範圍。';

  /// Bluetooth: SERVICE_DISCOVERY_FAILED
  static const String serviceDiscoveryFailedMessage = '無法探索裝置服務，裝置可能不相容。';

  /// Bluetooth: CHARACTERISTIC_NOT_FOUND
  static const String characteristicNotFoundMessage = '找不到裝置上必要的特徵值。';

  /// Bluetooth: WRITE_FAILED
  static const String writeFailedMessage = '無法將資料送到裝置，請檢查連線後再試。';

  /// Bluetooth: READ_FAILED
  static const String readFailedMessage = '無法從裝置讀取資料，請檢查連線。';

  /// Permission: BLUETOOTH_PERMISSION_DENIED
  static const String bluetoothPermissionDeniedMessage =
      '需要藍牙權限才能搜尋與連線裝置，請至設定授予權限。';

  /// Permission: LOCATION_PERMISSION_DENIED
  static const String locationPermissionDeniedMessage =
      'Android 上的藍牙搜尋需要位置權限，請至設定授予權限。';

  /// Permission: LOCATION_SERVICE_DISABLED — OS-level location toggle off
  static const String locationServiceDisabledMessage =
      '系統位置服務未啟用，請在系統設定中開啟位置功能。';

  /// Permission: NOTIFICATION_PERMISSION_DENIED
  static const String notificationPermissionDeniedMessage =
      '需要通知權限才能顯示連線狀態更新。';

  /// Network: SocketException
  static const String noInternetMessage = '無法連線到網路，請檢查網路設定後再試。';

  /// Network: TimeoutException
  static const String requestTimedOutMessage = '請求逾時，請檢查連線後再試。';

  /// Validation: INVALID_COMMAND
  static const String invalidCommandMessage = '指令格式不正確，請檢查輸入後再試。';

  /// Validation: EMPTY_COMMAND
  static const String emptyCommandMessage = '指令不可為空，請輸入有效的指令。';

  /// Validation: COMMAND_TOO_LONG
  static const String commandTooLongMessage = '指令過長，請使用較短的指令。';

  /// System: INSUFFICIENT_MEMORY
  static const String insufficientMemoryMessage =
      '記憶體不足，無法完成操作，請關閉其他應用後再試。';

  /// System: FILE_NOT_FOUND
  static const String fileNotFoundMessage = '找不到必要的檔案，若問題持續請重新安裝應用。';

  /// System: STORAGE_FULL
  static const String storageFullMessage = '裝置儲存空間已滿，請清出空間後再試。';

  /// Generic unexpected error fallback
  static const String unexpectedErrorMessage = '發生未預期的錯誤，請再試一次。';

  /// Recovery action: open Bluetooth settings / try to enable
  static const String enableBluetoothAction = '開啟藍牙';

  /// Recovery action: open OS app settings to grant permission
  static const String openSettingsAction = '前往設定';

  /// Recovery action: open OS location settings
  static const String enableLocationServiceAction = '開啟位置服務';

  /// Recovery action: retry the failed operation
  static const String retryAction = '重試';

  /// Caption shown above recovery actions on the blocking error screen
  static const String howToFixCaption = '如何修復：';

  /// Title shown above the error icon on the scanner blocking screen
  static const String bluetoothNotReadyTitle = '藍牙尚未就緒';

  /// Notification title when BLE service finishes initializing successfully
  static const String bluetoothReadyTitle = '藍牙就緒';

  /// Notification message when BLE service finishes initializing successfully
  static const String bluetoothReadyMessage = 'BLE 服務初始化成功';

  /// Notification title shown when the system Bluetooth adapter is off
  /// before scan can start
  static const String bluetoothDisabledScanTitle = '藍牙未開啟';

  /// Notification message paired with [bluetoothDisabledScanTitle]
  static const String bluetoothDisabledScanMessage = '請開啟藍牙後再進行搜尋';

  /// Notification title for a connection success state
  static const String connectedNotificationTitle = '已連線';

  /// Notification message paired with [connectedNotificationTitle]
  static String connectedNotificationMessage(String name) => '已成功連線到 $name';

  /// Notification title for a disconnection state
  static const String disconnectedNotificationTitle = '已斷線';

  /// Notification message paired with [disconnectedNotificationTitle]
  static const String disconnectedNotificationMessage = '已與裝置斷線';

  /// Notification title shown when MTU negotiation falls short
  static const String mtuWarningTitle = 'MTU 警告';

  /// Notification message body for [mtuWarningTitle]
  static String mtuWarningMessage(int mtu) => '無法將 MTU 設定為 $mtu';

  /// Notification title for "Communication Ready" once UART characteristics are wired up
  static const String communicationReadyTitle = '通訊就緒';

  /// Notification message for [communicationReadyTitle]
  static const String communicationReadyMessage = 'Nordic UART 服務設定成功';
}
