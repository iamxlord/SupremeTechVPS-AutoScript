#!/bin/bash
# --- Auto-Elevate to Root ---
if [ "${EUID}" -ne 0 ]; then
    echo -e "\033[0;33mElevating privileges... Please enter your password if prompted.\033[0m"
    exec sudo "$0" "$@"
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

clear
echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}               SHADOWSOCKS MANAGER                    ${NC}"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
echo -e "    ${GREEN}[01]${NC} Create Shadowsocks Account"
echo -e "    ${GREEN}[02]${NC} Generate Trial Shadowsocks"
echo -e "    ${GREEN}[03]${NC} Extend Shadowsocks Account"
echo -e "    ${GREEN}[04]${NC} Delete Shadowsocks Account"
echo -e "    ${GREEN}[05]${NC} Check User Login"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
echo -e "    ${GREEN}[00]${NC} Back to Main Menu"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
read -p " Select menu : " opt

case $opt in
    1|01) add-ss ;;
    2|02) trial-ss ;;
    3|03) renew-ss ;;
    4|04) del-ss ;;
    5|05) cek-ss ;;
    0|00) menu ;;
    *) echo -e "${RED}Invalid Option${NC}"; sleep 1; menu-ss.sh ;;
esac
