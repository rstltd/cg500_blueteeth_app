# CG500 設備指令參考

> **這份是設備韌體側的指令快速參考。** App 內可見的指令清單、參數型別、危險
> 等級、UI 提示等以 `lib/repositories/command_repository.dart` 為準（該檔包含
> 12 個指令完整定義並對應 UI 表單）。修改本檔時，請同步檢視 repository。

| 指令 | 說明 |
|------|------|
| `$CMD` | 顯示所有指令 |
| `$INFO` | 顯示設定和訊息（MAC、電壓值、IP、Port、時間、韌體版本等） |
| `$DEBUG` | 顯示 GPS 資料（下此指令後須手動重啟才能恢復傳輸） |
| `$MAC` | 設定此設備的設備代號。範例：`$MAC,CN001` |
| `$APN` | 修改連線 4G 用的 APN。範例：`$APN,internet`；IoT SIM 卡用 `$APN,internet.iot` |
| `$ADDR` | 設定 TCP 傳輸路徑的 IP 和 Port，格式為 `$ADDR,<IP>:<Port>`。範例：`$ADDR,211.20.56.183:8180` 或 `$ADDR,rmdgnss.com:8180` |
| `$REBOOT` | 設定每到了 X 小時整點重啟設備，格式為 `$REBOOT,<0~23>`。範例：`$REBOOT,2` |
| `$ALARM` | 顯示執行訊息：SD(1)、GPS(2)、TCP(4)、ADC(8)。只顯示 TCP 給 4，全部顯示 1+2+4+8=15。範例：`$ALARM,15` |
| `$FTPADDR` | 設定韌體更新位址（原本用 FTP 下載，後改由 HTTP 下載，但命令名稱沒變）。範例：`$FTPADDR,211.72.53.102:80` |
| `$STARTX` | 重新啟動 MCU（危險指令，所有連線將中斷，設備需要約 30 秒重新啟動） |
| `$SHOWP` | 顯示內部參數（給 RD debug 用） |
| `$TCPX` | 重新啟動 TCP 流程（短暫離線約 5–10 秒，BLE 連線不受影響） |
