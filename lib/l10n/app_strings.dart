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

  /// Query category description
  static const String categoryQueryDesc = '查詢設備資訊和狀態';

  /// Config category description
  static const String categoryConfigDesc = '修改設備設定';

  /// Control category description
  static const String categoryControlDesc = '控制設備行為';

  /// Debug category description
  static const String categoryDebugDesc = '開發和除錯用途';

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
  // Notification Settings
  // ============================================================

  /// Notification settings title
  static const String notificationSettings = '通知設定';

  /// Notification settings subtitle
  static const String notificationSettingsSubtitle = '設定通知的顯示時機和方式';

  /// Loading settings
  static const String loadingSettings = '正在載入設定...';

  /// Notification level section
  static const String notificationLevel = '通知等級';

  /// Smart filtering section
  static const String smartFiltering = '智慧過濾';

  /// Notification categories section
  static const String notificationCategories = '通知類別';

  /// Statistics section
  static const String statistics = '統計資料';

  /// Control BLE notifications description
  static const String controlBleNotifications = '控制產生多少 BLE 操作通知';

  /// Errors only option
  static const String errorsOnly = '僅錯誤';

  /// Errors only description
  static const String errorsOnlyDesc = '僅顯示錯誤通知（建議）';

  /// Errors and warnings option
  static const String errorsAndWarnings = '錯誤與警告';

  /// Errors and warnings description
  static const String errorsAndWarningsDesc = '顯示錯誤和警告';

  /// All details option
  static const String allDetails = '所有詳情';

  /// All details description
  static const String allDetailsDesc = '顯示所有通知，包括訊息和成功';

  /// Silent option
  static const String silent = '靜音';

  /// Silent description
  static const String silentDesc = '不產生任何 BLE 通知';

  /// Enable smart filtering
  static const String enableSmartFiltering = '啟用智慧過濾';

  /// Smart filtering description
  static const String smartFilteringDesc = '自動減少重複和騷擾通知';

  /// Smart filtering explanation
  static const String smartFilteringExplanation =
      '智慧過濾可防止重複通知、減少連線狀態騷擾，並靜音內部操作。';

  /// Connection events option
  static const String connectionEvents = '連線事件';

  /// Connection events description
  static const String connectionEventsDesc = '裝置連線/斷線時顯示通知';

  /// Scanning events option
  static const String scanningEvents = '掃描事件';

  /// Scanning events description
  static const String scanningEventsDesc = '掃描裝置時顯示通知';

  /// MTU configuration category
  static const String mtuConfigurationCategory = 'MTU 配置';

  /// MTU configuration option
  static const String mtuConfiguration = '顯示 MTU 設定通知';

  /// Command feedback option
  static const String commandFeedback = '指令回饋';

  /// Command feedback description
  static const String commandFeedbackDesc = '顯示已發送指令的通知';

  /// Total notifications stat
  static const String totalNotifications = '總通知數';

  /// Filtered notifications stat
  static const String filteredNotifications = '已過濾通知';

  /// Pending notifications stat
  static const String pendingNotifications = '待處理通知';

  /// Clear filters button
  static const String clearFilters = '清除過濾器';

  /// Notification filters cleared message
  static const String notificationFiltersCleared = '通知過濾器已清除';

  /// Notification settings saved message
  static const String notificationSettingsSaved = '通知設定已儲存';

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

  /// Notification settings tooltip
  static const String notificationSettingsTooltip = '通知設定';

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
}
