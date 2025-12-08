$CMD   顯示所有指令          
$INFO   顯示設定和訊息(MAC、電壓值、IP、Port、時間、韌體版本等)      
$DEBUG   顯示GPS資料 (下此指令後須手動重啟才能恢復傳輸)       
$MAC   設定此設備的設備代號  ex :  $MAC,CN001        
$APN   修改連線4G用的APN ex : $APN,internet        
$ADDR   設定TCP傳輸路徑的IP和Port, 格式為$ADDR,<IP>:<Port>   ex : $4G,211.20.56.183:8180   
$REBOOT   設定每到了X小時整點重啟設備, 格式為$REBOOT,<0 ~ 23>  ex : $REBOOT,2     
$ALARM   顯示執行訊息 SD(1) GPS(2) TCP(4) ADC(8)  ; 只顯示 TCP 給 4 , 全部顯示 1 + 2 + 4 + 8 = 15 , ex : $ALARM,15 
$FTPADDR   設定韌體更新位址, 原本用FTP下載, 後來改由HTTP下載, 但命令沒變,  ex : $FTPADDR,211.72.53.102:80  
$STARTX   重新啟動 MCU          
$SHOWP   顯示內部參數, 給 RD debug 用         
$TCPX   重新啟動 TCP 流程