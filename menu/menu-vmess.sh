#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

clear
echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}                 XRAY VMESS MANAGER                   ${NC}"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
echo -e "    ${GREEN}[01]${NC} Create Vmess Account"
echo -e "    ${GREEN}[02]${NC} Generate Trial Vmess"
echo -e "    ${GREEN}[03]${NC} Extend Vmess Account"
echo -e "    ${GREEN}[04]${NC} Delete Vmess Account"
echo -e "    ${GREEN}[05]${NC} Check User Login"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
echo -e "    ${GREEN}[00]${NC} Back to Main Menu"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
read -p " Select menu : " opt

case $opt in
    1|01) add-ws ;;
    2|02) trial-ws ;;
    3|03) renew-ws ;;
    4|04) del-ws ;;
    5|05) cek-ws ;;
    0|00) menu ;;
    *) echo "Invalid Option"; sleep 1; menu-vmess.sh ;;
esac
