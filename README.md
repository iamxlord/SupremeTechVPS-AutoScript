# ⚡ TheTechSavage Premium VPS Manager (Final Edition)

![Version](https://img.shields.io/badge/Version-3.0_Premium-cyan?style=for-the-badge) 
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge) 
![Platform](https://img.shields.io/badge/Platform-Ubuntu_20%2B-orange?style=for-the-badge)

**The Ultimate All-in-One VPN Autoscript.** Built for high-performance tunneling, low-latency gaming, and maximum server stability. Features a futuristic dashboard, self-healing protocols, and automated management.

---

## 🚀 Key Features

### 💎 Core Protocols
* ✅ **Xray Core (XTLS-Reality):** Vmess, Vless, and Trojan (Multi-Path Support).
* ✅ **SSH & WebSocket:** Python-based generic proxy for stable connections (Port 80).
* ✅ **Secure TLS:** Full SSL/TLS encryption via Nginx & Acme.sh.

### 🛡️ Smart Automation
* 🔄 **Auto-Expiry:** Automatically deletes expired accounts at midnight (00:00).
* 🚫 **Anti-Multilogin:** Kills users exceeding the device limit (Runs every 5 mins).
* 🌐 **Smart Domain Check:** Verifies DNS pointing before installation to prevent errors.
* ⚡ **Auto-Reboot:** Scheduled daily reboots to keep RAM fresh and fast.
* 🧹 **Auto-Cleaner:** Clears system logs and caches automatically.

---

## 📥 Installation

Run this command on a fresh **Ubuntu 20.04 / 22.04 / 24.04 LTS** or **Debian 10 / 11 / 12** VPS.

```bash
apt update && apt install -y wget && wget -q https://raw.githubusercontent.com/thetechsavage26/TheTechSavageVpnManager/main/install/setup.sh && chmod +x setup.sh && ./setup.sh
```

### 🛠️ Setup Steps
1.  **Paste the command** above into your terminal.
2.  **Enter your Domain** when prompted (e.g., `vpn.mysite.com`).
3.  **Wait** for the "INSTALLATION COMPLETE" message.
4.  **The server will reboot** automatically to finalize changes.

---

## 🎮 The Dashboard

Type `menu` to access the futuristic control panel.

```bash
menu
```

### 🖥️ Menu Overview
| Menu Option | Function |
| :--- | :--- |
| **[01] SSH Manager** | Create, Renew, and Manage SSH/WS accounts. |
| **[02] VMess Manager** | Create TLS/Non-TLS Vmess accounts. |
| **[03] VLESS Manager** | Create VLESS (XTLS) accounts. |
| **[04] Trojan Manager** | Create Trojan-WS accounts. |
| **[05] Settings** | Check RAM, Speedtest, Restart Services, Change Domain. |
| **[06] Trial Generator** | Instantly generate 24-hour trial accounts. |
| **[07] Backup/Restore** | Cloud backup for your user data. |

---

## 🔌 Service Ports

| Service | Protocol | Port |
| :--- | :--- | :--- |
| **SSH** | TCP | 22 |
| **SSH-WS (HTTP)** | TCP | 80 |
| **SSH-SSL (TLS)** | TCP | 443 |
| **Dropbear** | TCP | 109, 143 |
| **Xray (All)** | TCP/TLS | 443, 80 |
| **Nginx** | HTTP/S | 81, 443 |

---

## ⚠️ Credits & Disclaimer

**Developed & Maintained by:** [TheTechSavage](https://t.me/thetechsavage)

> *This project is for educational purposes and network management only. The developer is not responsible for misuse.*
