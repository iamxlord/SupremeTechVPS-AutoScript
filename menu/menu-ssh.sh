#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

clear
echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}             SSH & OPENVPN CONNECTION MANAGER         ${NC}"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
echo -e "    ${GREEN}[01]${NC} Create SSH Account"
echo -e "    ${GREEN}[02]${NC} Generate Trial SSH"
echo -e "    ${GREEN}[03]${NC} Renew SSH Account"
echo -e "    ${GREEN}[04]${NC} Delete SSH Account"
echo -e "    ${GREEN}[05]${NC} Check User Login"
echo -e "    ${GREEN}[06]${NC} List Member SSH"
echo -e "    ${GREEN}[07]${NC} Delete Expired Users"
echo -e "    ${GREEN}[08]${NC} Setup Autokill"
echo -e "    ${GREEN}[09]${NC} Check Multi-Login"
echo -e "    ${GREEN}[10]${NC} Show OpenVPN Config"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
echo -e "    ${GREEN}[00]${NC} Back to Main Menu"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
read -p " Select menu : " opt

case $opt in
    1|01) usernew ;;
    2|02) trial ;;
    3|03) renew ;;
    4|04) hapus ;;
    5|05) cek ;;
    6|06) member ;;
    7|07) delete ;;
    8|08) autokill ;;
    9|09) ceklim ;;
    10) show-conf ;;
    0|00) menu ;;
    *) echo "Invalid Option"; sleep 1; menu-ssh.sh ;;
esac
