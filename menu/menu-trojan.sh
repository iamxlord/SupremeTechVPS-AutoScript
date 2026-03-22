#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

clear
echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}                 XRAY TROJAN MANAGER                  ${NC}"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
echo -e "    ${GREEN}[01]${NC} Create Trojan Account"
echo -e "    ${GREEN}[02]${NC} Generate Trial Trojan"
echo -e "    ${GREEN}[03]${NC} Extend Trojan Account"
echo -e "    ${GREEN}[04]${NC} Delete Trojan Account"
echo -e "    ${GREEN}[05]${NC} Check User Login"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
echo -e "    ${GREEN}[00]${NC} Back to Main Menu"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
read -p " Select menu : " opt

case $opt in
    1|01) add-tr ;;
    2|02) trial-tr ;;
    3|03) renew-tr ;;
    4|04) del-tr ;;
    5|05) cek-tr ;;
    0|00) menu ;;
    *) echo "Invalid Option"; sleep 1; menu-trojan.sh ;;
esac
