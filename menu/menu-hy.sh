#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'
# --- Auto-Elevate to Root ---
if [ "${EUID}" -ne 0 ]; then
    echo -e "\033[0;33mElevating privileges... Please enter your password if prompted.\033[0m"
    exec sudo "$0" "$@"
fi

clear
echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}                 HYSTERIA2 MANAGER                    ${NC}"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
echo -e "    ${GREEN}[01]${NC} Create Hysteria2 Account"
echo -e "    ${GREEN}[02]${NC} Generate Trial Hysteria2"
echo -e "    ${GREEN}[03]${NC} Extend Hysteria2 Account"
echo -e "    ${GREEN}[04]${NC} Delete Hysteria2 Account"
echo -e "    ${GREEN}[05]${NC} Check User Login"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
echo -e "    ${GREEN}[00]${NC} Back to Main Menu"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
read -p " Select menu : " opt

case $opt in
    1|01) add-hy2 ;;
    2|02) trial-hy2 ;;
    3|03) renew-hy2 ;;
    4|04) del-hy2 ;;
    5|05) cek-hy2 ;;
    0|00) menu ;;
    *) echo -e "${RED}Invalid Option${NC}"; sleep 1; menu-hy.sh ;;
esac
