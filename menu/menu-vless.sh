#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

clear
echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}                 XRAY VLESS MANAGER                   ${NC}"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
echo -e "    ${GREEN}[01]${NC} Create Vless Account"
echo -e "    ${GREEN}[02]${NC} Generate Trial Vless"
echo -e "    ${GREEN}[03]${NC} Extend Vless Account"
echo -e "    ${GREEN}[04]${NC} Delete Vless Account"
echo -e "    ${GREEN}[05]${NC} Check User Login"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
echo -e "    ${GREEN}[00]${NC} Back to Main Menu"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
read -p " Select menu : " opt

case $opt in
    1|01) add-vless ;;
    2|02) trial-vless ;;
    3|03) renew-vless ;;
    4|04) del-vless ;;
    5|05) cek-vless ;;
    0|00) menu ;;
    *) echo "Invalid Option"; sleep 1; menu-vless.sh ;;
esac
