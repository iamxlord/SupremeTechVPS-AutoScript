#!/bin/bash
clear
# ... (Standard colors and elevation code) ...
echo -e "    [01] Create Reality Account"
echo -e "    [02] Generate Trial Reality"
echo -e "    [03] Extend Reality Account"
echo -e "    [04] Delete Reality Account"
echo -e "    [05] Check User Login"
# ... 
case $opt in
    1|01) add-reality ;;
    2|02) trial-reality ;;
    3|03) renew-reality ;;
    4|04) del-reality ;;
    5|05) cek-reality ;;
    0|00) menu ;;
esac
