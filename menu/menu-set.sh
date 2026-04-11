#!/bin/bash
# --- Mr. X Premium System Settings & Extensions ---

# Auto-Elevate to Root
if [ "${EUID}" -ne 0 ]; then
    echo -e "\033[0;33mElevating privileges... Please enter your password if prompted.\033[0m"
    exec sudo "$0" "$@"
fi

# --- COLORS & VARIABLES ---
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

MYIP=$(curl -sS ifconfig.me)

# ==========================================
# CUSTOM PROXY RESPONSE CHANGER
# ==========================================
proxy_response_changer() {
    clear
    echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}             CUSTOM PROXY RESPONSE EDITOR             ${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    
    current=$(cat /etc/xray/proxy_resp.txt 2>/dev/null || echo "Switching Protocols")
    echo -e " Current Response: ${GREEN}HTTP/1.1 101 $current${NC}"
    echo -e ""
    echo -e " Example: SupremeTech, Connected"
    read -p " Enter New Text (Leave blank to cancel): " new_resp
    
    if [[ -n "$new_resp" ]]; then
        echo "$new_resp" > /etc/xray/proxy_resp.txt
        systemctl restart ws-proxy
        echo -e "${GREEN}[✔] Response Updated to: HTTP/1.1 101 $new_resp${NC}"
        echo -e "${GREEN}[✔] Python Proxy Restarted!${NC}"
    fi
    sleep 2; menu-set.sh
}

# ==========================================
# 1. DOMAIN MANAGER
# ==========================================
domain_manager() {
    clear
    echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}               DOMAIN & SSL MANAGER                   ${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    echo -e "  ${GREEN}[1]${NC} Change Server Domain (Host)"
    echo -e "  ${GREEN}[2]${NC} Renew Let's Encrypt Certificate (SSL)"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    read -p " Select : " dom_opt
    
    if [ "$dom_opt" == "1" ]; then
        read -p " Input New Domain: " new_domain
        if [[ -n "$new_domain" ]]; then
            echo "$new_domain" > /etc/xray/domain
            echo "$new_domain" > /root/domain
            echo -e "${GREEN}Domain updated to $new_domain. Please Renew Certificate next.${NC}"
        fi
        sleep 2; menu-set.sh
    elif [ "$dom_opt" == "2" ]; then
        domain=$(cat /etc/xray/domain)
        echo -e "${YELLOW}Stopping services for Acme.sh standalone...${NC}"
        systemctl stop nginx
        systemctl stop ws-proxy 2>/dev/null
        
        /root/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256 --force
        /root/.acme.sh/acme.sh --installcert -d "$domain" --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc
        chmod 644 /etc/xray/xray.key
        
        systemctl start nginx
        systemctl start ws-proxy 2>/dev/null
        systemctl restart xray stunnel4
        echo -e "${GREEN}Certificate Renewed & Services Restarted!${NC}"
        read -n 1 -s -r -p "Press any key to back..."
        menu-set.sh
    fi
}

# ==========================================
# 2. PORT INFO & SERVER STATUS
# ==========================================
port_info() {
    clear
    domain=$(cat /etc/xray/domain 2>/dev/null)
    echo -e "${CYAN}====================-[ X TUNNEL ]-===================${NC}"
    echo -e "${YELLOW}>>> Service & Port${NC}"
    echo -e " - OpenSSH            : 22"
    echo -e " - Dropbear           : 109, 143"
    echo -e " - Stunnel4           : 447, 777"
    echo -e " - Universal Proxy    : 8080"
    echo -e " - Xray VMess/VLESS   : 443"
    echo -e " - Xray Trojan/SS     : 443"
    echo -e " - Hysteria2 (UDP)    : 443"
    echo -e " - SlowDNS (DNSTT)    : 53, 5300"
    echo -e " - OpenVPN (DL)       : 81"
    echo -e ""
    echo -e "${YELLOW}>>> Server Status${NC}"
    echo -e " - IP Address         : $MYIP"
    echo -e " - Domain             : $domain"
    echo -e " - Timezone           : $(date +%Z)"
    echo -e "${CYAN}=================================================================${NC}"
    read -n 1 -s -r -p "Press any key to back..."
    menu-set.sh
}

# ==========================================
# 3. SERVICE RESTART MANAGER
# ==========================================
restart_services() {
    clear
    echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}                 SERVICE MANAGER                      ${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    echo -e "  ${GREEN}[1]${NC} Restart All Services"
    echo -e "  ${GREEN}[2]${NC} Restart Xray Core"
    echo -e "  ${GREEN}[3]${NC} Restart Nginx"
    echo -e "  ${GREEN}[4]${NC} Restart SSH & Dropbear"
    echo -e "  ${GREEN}[5]${NC} Restart SlowDNS"
    echo -e "  ${GREEN}[6]${NC} Restart Telegram Bot"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    read -p " Select : " res_opt
    
    case $res_opt in
        1) systemctl restart dropbear stunnel4 xray client-slow ws-proxy ohp cron nginx tg-bot; echo -e "${GREEN}All Services Restarted!${NC}" ;;
        2) systemctl restart xray; echo -e "${GREEN}Xray Restarted!${NC}" ;;
        3) systemctl restart nginx; echo -e "${GREEN}Nginx Restarted!${NC}" ;;
        4) systemctl restart ssh dropbear; echo -e "${GREEN}SSH/Dropbear Restarted!${NC}" ;;
        5) systemctl restart client-slow; echo -e "${GREEN}SlowDNS Restarted!${NC}" ;;
        6) systemctl restart tg-bot; echo -e "${GREEN}Telegram Bot Restarted!${NC}" ;;
    esac
    sleep 2; menu-set.sh
}

# ==========================================
# 4. SAFE XRAY CONFIG EDITOR
# ==========================================
xray_editor() {
    clear
    CONFIG="/usr/local/etc/xray/config.json"
    BACKUP="/tmp/config.json.editor.bak"
    
    echo -e "${YELLOW}Opening Xray Config in Nano...${NC}"
    sleep 1
    cp "$CONFIG" "$BACKUP"
    nano "$CONFIG"
    
    echo -e "${BLUE}[*] Validating JSON syntax...${NC}"
    if jq . "$CONFIG" >/dev/null 2>&1; then
        echo -e "${GREEN}[✔] Syntax perfectly valid! Restarting Xray...${NC}"
        systemctl restart xray
    else
        echo -e "${RED}[✘] CRITICAL: JSON syntax is broken!${NC}"
        echo -e "${YELLOW}[!] Reverting to backup to prevent server crash...${NC}"
        cp "$BACKUP" "$CONFIG"
        systemctl restart xray
    fi
    sleep 3; menu-set.sh
}

# ==========================================
# 5. FIREWALL MANAGER (UFW)
# ==========================================
firewall_manager() {
    clear
    if ! command -v ufw &> /dev/null; then apt install ufw -y >/dev/null 2>&1; fi
    echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}                 FIREWALL (UFW) MANAGER               ${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    echo -e "  ${GREEN}[1]${NC} Enable & Apply Default VPN Rules"
    echo -e "  ${GREEN}[2]${NC} Disable Firewall"
    echo -e "  ${GREEN}[3]${NC} View Active Status"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    read -p " Select : " fw_opt

    case $fw_opt in
        1)
            echo -e "${YELLOW}Applying VPN Port Whitelists...${NC}"
            ufw --force reset; ufw default deny incoming; ufw default allow outgoing
            ufw allow 22/tcp; ufw allow 109/tcp; ufw allow 85/tcp; ufw allow 143/tcp
            ufw allow 80/tcp; ufw allow 81/tcp; ufw allow 443/tcp; ufw allow 447/tcp; ufw allow 777/tcp
            ufw allow 8080/tcp; ufw allow 53/udp; ufw allow 5300/udp
            ufw --force enable
            echo -e "${GREEN}Default VPN Rules Applied!${NC}" ;;
        2) ufw disable; echo -e "${RED}Firewall Disabled!${NC}" ;;
        3) ufw status numbered; echo ""; read -n 1 -s -r -p "Press any key..." ;;
    esac
    sleep 2; menu-set.sh
}

# ==========================================
# 6. DNS CHANGER
# ==========================================
dns_changer() {
    clear
    echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}                 SYSTEM DNS CHANGER                   ${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    echo -e "  ${GREEN}[1]${NC} Cloudflare (1.1.1.1 / 1.0.0.1) ${YELLOW}[Fastest]${NC}"
    echo -e "  ${GREEN}[2]${NC} Google DNS (8.8.8.8 / 8.8.4.4)"
    echo -e "  ${GREEN}[3]${NC} Quad9 Security (9.9.9.9)"
    echo -e "  ${GREEN}[4]${NC} Restore System Default"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    read -p " Select : " dns_opt
    
    CONF="/etc/systemd/resolved.conf"
    case $dns_opt in
        1) sed -i 's/^#*DNS=.*/DNS=1.1.1.1 1.0.0.1/' $CONF ;;
        2) sed -i 's/^#*DNS=.*/DNS=8.8.8.8 8.8.4.4/' $CONF ;;
        3) sed -i 's/^#*DNS=.*/DNS=9.9.9.9 149.112.112.112/' $CONF ;;
        4) sed -i 's/^#*DNS=.*/#DNS=/' $CONF ;;
    esac
    systemctl restart systemd-resolved
    echo -e "${GREEN}[✔] DNS Updated Successfully!${NC}"
    sleep 2; menu-set.sh
}

# ==========================================
# 7. SAFE BANNER CHANGER (Dropbear Crash Prevention)
# ==========================================
change_banner() {
    clear
    echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}                 SSH BANNER EDITOR                    ${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    echo -e " ${RED}WARNING:${NC} Do not use massive ASCII art!"
    echo -e " Dropbear will crash if the text is too large."
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    read -n 1 -s -r -p " Press any key to open editor..."

    # 1. Backup existing banner just in case
    cp /etc/issue.net /tmp/issue.net.bak

    # 2. Open nano for editing
    nano /etc/issue.net

    # 3. Check the file size in bytes
    FILE_SIZE=$(wc -c < /etc/issue.net)

    # 4. Strict Enforcement (Max 1000 bytes)
    if [[ $FILE_SIZE -gt 1000 ]]; then
        echo -e "\n${RED}[✘] ERROR: Banner is too large! ($FILE_SIZE bytes)${NC}"
        echo -e "${YELLOW}Dropbear requires banners to be strictly under 1000 bytes.${NC}"
        echo -e "Reverting to previous banner to prevent a server crash..."
        cp /tmp/issue.net.bak /etc/issue.net
        sleep 4
    else
        echo -e "\n${GREEN}[✔] Banner saved safely ($FILE_SIZE bytes).${NC}"
        systemctl restart dropbear ssh
        echo -e "${GREEN}[✔] SSH & Dropbear Restarted Successfully!${NC}"
        sleep 2
    fi
    menu-set.sh
}

# ==========================================
# 7. AUTO-REBOOT MENU
# ==========================================
auto_reboot() {
    clear
    echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}                  AUTO-REBOOT MANAGER                 ${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    echo -e "  ${GREEN}[1]${NC} Set Interval (e.g. Every 6 Hours)"
    echo -e "  ${GREEN}[2]${NC} Set Specific Time (e.g. Midnight)"
    echo -e "  ${GREEN}[3]${NC} Turn OFF Auto-Reboot"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    read -p " Select : " reb_opt
    
    if [[ "$reb_opt" == "1" ]]; then
        echo -e " [1] 1 Hour  [2] 6 Hours  [3] 12 Hours  [4] 24 Hours"
        read -p " Select: " x
        if [[ "$x" == "1" ]]; then echo "0 * * * * root /sbin/reboot" > /etc/cron.d/auto_reboot; fi
        if [[ "$x" == "2" ]]; then echo "0 */6 * * * root /sbin/reboot" > /etc/cron.d/auto_reboot; fi
        if [[ "$x" == "3" ]]; then echo "0 */12 * * * root /sbin/reboot" > /etc/cron.d/auto_reboot; fi
        if [[ "$x" == "4" ]]; then echo "0 0 * * * root /sbin/reboot" > /etc/cron.d/auto_reboot; fi
        echo -e "${GREEN}Interval updated!${NC}"; sleep 2; menu-set.sh
    elif [[ "$reb_opt" == "2" ]]; then
        read -p " Input hour (0-23): " hour
        if [[ "$hour" =~ ^[0-9]+$ ]] && [ "$hour" -ge 0 ] && [ "$hour" -le 23 ]; then
            echo "0 $hour * * * root /sbin/reboot" > /etc/cron.d/auto_reboot
            echo -e "${GREEN}Server will reboot daily at $hour:00${NC}"
        else echo -e "${RED}Invalid Number!${NC}"; fi
        sleep 2; menu-set.sh
    elif [[ "$reb_opt" == "3" ]]; then
        rm -f /etc/cron.d/auto_reboot
        echo -e "${RED}Auto-Reboot Disabled!${NC}"; sleep 2; menu-set.sh
    fi
    service cron restart
}

# ==========================================
# 8. BANDWIDTH MONITOR (VNSTAT)
# ==========================================
bandwidth_monitor() {
    clear
    echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}                  BANDWIDTH MONITOR                   ${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    echo -e "  ${GREEN}[1]${NC} Live Traffic"
    echo -e "  ${GREEN}[2]${NC} Daily Usage"
    echo -e "  ${GREEN}[3]${NC} Monthly Usage"
    echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    read -p " Select : " bw
    if [[ $bw == "1" ]]; then vnstat -l; elif [[ $bw == "2" ]]; then vnstat -d; elif [[ $bw == "3" ]]; then vnstat -m; fi
    echo ""; read -n 1 -s -r -p "Press any key to back..."
    menu-set.sh
}

# ==========================================
# MAIN SETTINGS UI (DUAL COLUMN)
# ==========================================
clear
echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}                 SYSTEM SETTINGS MENU                 ${NC}"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
echo -e "  ${GREEN}[01]${NC} Domain & SSL       ${GREEN}[07]${NC} Change SSH Banner"
echo -e "  ${GREEN}[02]${NC} Port Info List     ${GREEN}[08]${NC} Check Bandwidth"
echo -e "  ${GREEN}[03]${NC} Service Restarts   ${GREEN}[09]${NC} Speedtest VPS"
echo -e "  ${GREEN}[04]${NC} Xray Editor        ${GREEN}[10]${NC} System Cache Cleaner"
echo -e "  ${GREEN}[05]${NC} Firewall (UFW)     ${GREEN}[11]${NC} Auto-Reboot Settings"
echo -e "  ${GREEN}[06]${NC} DNS Changer        ${GREEN}[12]${NC} Proxy Response"
echo -e "  ${GREEN}[13]${NC} Health Checker" 
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
echo -e "  ${GREEN}[00]${NC} Back to Main Menu"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
read -p " Select menu : " opt

case $opt in
    1|01) domain_manager ;;
    2|02) port_info ;;
    3|03) restart_services ;;
    4|04) xray_editor ;;
    5|05) firewall_manager ;;
    6|06) dns_changer ;;
    7|07) change_banner ;;
    8|08) bandwidth_monitor ;;
    9|09) clear; speedtest-cli --simple; read -n 1 -s -r -p "Press any key..."; menu-set.sh ;;
    10) cleaner ;;
    11) auto_reboot ;;
    12) proxy_response_changer ;;
    13) health-check; echo ""; read -n 1 -s -r -p "Press any key..."; menu-set.sh ;;
    0|00) menu ;;
    *) echo -e "${RED}Invalid Option${NC}"; sleep 1; menu-set.sh ;;
esac
