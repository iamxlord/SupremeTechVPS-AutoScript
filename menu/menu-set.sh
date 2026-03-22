#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'
MYIP=$(wget -qO- icanhazip.com)
domain=$(cat /etc/xray/domain)
clear
echo -e "\033[0;34m┌─────────────────────────────────────────────────────┐\033[0m"
echo -e "     \E[44;1;39m          SYSTEM SETTINGS MANAGER            \E[0m"
echo -e "\033[0;34m└─────────────────────────────────────────────────────┘\033[0m"
echo -e " [\033[0;32m01\033[0m]  Panel Domain (Change / Renew)"
echo -e " [\033[0;32m02\033[0m]  Speedtest VPS"
echo -e " [\033[0;32m03\033[0m]  Info Port"
echo -e " [\033[0;32m04\033[0m]  Set Auto Reboot (Interval)"
echo -e " [\033[0;32m05\033[0m]  Set Auto Reboot (Specific Time)"
echo -e " [\033[0;32m06\033[0m]  Restart All Services"
echo -e " [\033[0;32m07\033[0m]  Change Banner"
echo -e " [\033[0;32m08\033[0m]  Check Bandwidth"
echo -e " [\033[0;32m09\033[0m]  Server Health Check"
echo -e "\033[0;34m└─────────────────────────────────────────────────────┘\033[0m"
echo -e " [\033[0;31m00\033[0m]  Back to Main Menu"
echo -e ""
read -p " Select menu : " opt
case $opt in
1|01)
    clear
    echo -e "\033[0;34m┌─────────────────────────────────────────────────────┐\033[0m"
    echo -e "              DOMAIN MANAGER"
    echo -e "\033[0;34m└─────────────────────────────────────────────────────┘\033[0m"
    echo -e " [1] Change Domain (Host)"
    echo -e " [2] Renew Certificate (SSL)"
    echo ""
    read -p " Select: " domopt
    if [[ $domopt == "1" ]]; then
        read -p "Input New Domain: " newdom
        echo "$newdom" > /etc/xray/domain
        echo "$newdom" > /root/domain
        echo -e "\033[0;32mDomain updated to $newdom. Please Renew Certificate now.\033[0m"
        read -n 1 -s -r -p "Press any key..."
        menu-set.sh
    elif [[ $domopt == "2" ]]; then
        echo -e "\033[0;32mStopping services...\033[0m"
        systemctl stop xray
        systemctl stop ws-proxy  
        /root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256 --force
        /root/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc
        chmod 644 /etc/xray/xray.key
        systemctl start xray
        systemctl start ws-proxy
        echo -e "\033[0;32mCertificate Renewed!\033[0m"
        read -n 1 -s -r -p "Press any key..."
        menu-set.sh
    fi
    ;;
2|02)
    clear
    echo -e "\033[0;32mRunning Speedtest...\033[0m"
    speedtest-cli --simple
    echo ""
    read -n 1 -s -r -p "Press any key to back..."
    menu-set.sh
    ;;
3|03)
    clear
    echo -e "\033[0;34m====================-[ THETECHSAVAGE TUNNEL ]-===================\033[0m"
    echo -e ">>> Service & Port"
    echo -e " - OpenSSH            : 22"
    echo -e " - Dropbear           : 109, 143"
    echo -e " - Stunnel4           : 447, 777"
    echo -e " - Xray Vless TLS     : 443"
    echo -e " - Xray Vmess TLS     : 443"
    echo -e " - Xray Trojan TLS    : 443"
    echo -e " - SlowDNS            : 53, 5300"
    echo -e ""
    echo -e ">>> Server Status"
    echo -e " - IP Address         : $MYIP"
    echo -e " - Domain             : $domain"
    echo -e " - Timezone           : $(date +%Z)"
    echo -e " - Auto-Reboot        : [ON]"
    echo -e "\033[0;34m=================================================================\033[0m"
    read -n 1 -s -r -p "Press any key to back..."
    menu-set.sh
    ;;
4|04)
    clear
    echo -e "\033[0;34m┌─────────────────────────────────────────────────────┐\033[0m"
    echo -e "           AUTO-REBOOT SETTINGS (INTERVAL)"
    echo -e "\033[0;34m└─────────────────────────────────────────────────────┘\033[0m"
    echo -e " [1] Every 1 Hour"
    echo -e " [2] Every 6 Hours"
    echo -e " [3] Every 12 Hours"
    echo -e " [4] Every 24 Hours (Daily)"
    echo -e " [5] Turn OFF Auto-Reboot"
    echo ""
    read -p " Select: " x
    if [[ "$x" == "1" ]]; then
        echo "0 * * * * root /sbin/reboot" > /etc/cron.d/auto_reboot
    elif [[ "$x" == "2" ]]; then
        echo "0 */6 * * * root /sbin/reboot" > /etc/cron.d/auto_reboot
    elif [[ "$x" == "3" ]]; then
        echo "0 */12 * * * root /sbin/reboot" > /etc/cron.d/auto_reboot
    elif [[ "$x" == "4" ]]; then
        echo "0 0 * * * root /sbin/reboot" > /etc/cron.d/auto_reboot
    elif [[ "$x" == "5" ]]; then
        rm -f /etc/cron.d/auto_reboot
    fi
    service cron restart
    echo -e "\033[0;32mAuto-Reboot updated!\033[0m"
    sleep 2
    menu-set.sh
    ;;
5|05)
    clear
    echo -e "\033[0;34m┌─────────────────────────────────────────────────────┐\033[0m"
    echo -e "           AUTO-REBOOT SETTINGS (SPECIFIC TIME)"
    echo -e "\033[0;34m└─────────────────────────────────────────────────────┘\033[0m"
    echo -e " Example: 0 = Midnight, 13 = 1 PM, 23 = 11 PM"
    echo ""
    read -p " Input hour (0-23): " hour
    if [[ "$hour" =~ ^[0-9]+$ ]] && [ "$hour" -ge 0 ] && [ "$hour" -le 23 ]; then
        echo "0 $hour * * * root /sbin/reboot" > /etc/cron.d/auto_reboot
        service cron restart
        echo -e "\033[0;32mServer will reboot daily at $hour:00\033[0m"
    else
        echo -e "\033[0;31mInvalid Number!\033[0m"
    fi
    sleep 2
    menu-set.sh
    ;;
6|06)
    clear
    echo -e "\033[0;32mRestarting All Services...\033[0m"
    systemctl restart dropbear
    systemctl restart stunnel4
    systemctl restart xray
    systemctl restart client-slow
    systemctl restart ws-proxy   
    systemctl restart ohp
    systemctl restart cron
    echo -e "\033[0;32mAll Services Restarted Successfully!\033[0m"
    read -n 1 -s -r -p "Press any key to back..."
    menu-set.sh
    ;;
7|07)
    nano /etc/issue.net
    service dropbear restart
    echo -e "\033[0;32mBanner Saved and Applied!\033[0m"
    read -n 1 -s -r -p "Press any key to back..."
    menu-set.sh
    ;;
8|08)
    clear
    echo -e "\033[0;34m┌─────────────────────────────────────────────────────┐\033[0m"
    echo -e "                  BANDWIDTH MONITOR"
    echo -e "\033[0;34m└─────────────────────────────────────────────────────┘\033[0m"
    echo -e " [1] Live Traffic"
    echo -e " [2] Daily Usage"
    echo -e " [3] Monthly Usage"
    echo ""
    read -p " Select: " bw
    if [[ $bw == "1" ]]; then
        vnstat -l
    elif [[ $bw == "2" ]]; then
        vnstat -d
    elif [[ $bw == "3" ]]; then
        vnstat -m
    fi
    echo ""
    read -n 1 -s -r -p "Press any key to back..."
    menu-set.sh
    ;;
9|09)
    health-check
    echo ""
    read -n 1 -s -r -p "Press any key to back..."
    menu-set.sh
    ;;
0|00)
    menu
    ;;
*)
    menu-set.sh
    ;;
esac
