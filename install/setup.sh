#!/bin/bash
# ==========================================
#  TheTechSavage Universal Auto-Installer
#  Premium Edition - v3.5 (Verified Stable)
# ==========================================

# --- COLORS & STYLING ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Helper for "Futuristic" Headers (FIXED WIDTH = 54 Chars)
function print_title() {
    clear
    echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
    # Center text manually for perfect alignment
    local text="$1"
    local width=54
    local padding=$(( (width - ${#text}) / 2 ))
    printf "${CYAN}│${YELLOW}%*s%s%*s${CYAN}│${NC}\n" $padding "" "$text" $padding ""
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
    sleep 1
}

function print_success() {
    echo -e "${GREEN} [OK] $1${NC}"
}

function print_info() {
    echo -e "${BLUE} [INFO] $1${NC}"
}

# 1. DEFINE GITHUB REPO
# -----------------------------------------------------
REPO_USER="iamxlord"
REPO_NAME="SupremeTechVPS-AutoScript"
BRANCH="main"
REPO_URL="https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/${BRANCH}"

# 2. SYSTEM PREPARATION
# -----------------------------------------------------
print_title "SYSTEM PREPARATION"
print_info "Creating System Directories..."
mkdir -p /etc/xray
mkdir -p /etc/xray/limit/vmess
mkdir -p /etc/xray/limit/vless
mkdir -p /etc/xray/limit/trojan
mkdir -p /usr/local/etc/xray
mkdir -p /etc/openvpn

print_info "Installing Essentials..."
# Stop Apache if present (Fix for Nginx OFF issue)
systemctl stop apache2 > /dev/null 2>&1
systemctl disable apache2 > /dev/null 2>&1

apt update -y && apt upgrade -y
apt install -y wget curl jq socat cron zip unzip net-tools git build-essential python3 python3-pip python3-full vnstat dropbear nginx dnsutils stunnel4 fail2ban speedtest-cli

# 2.5 OPTIMIZE KERNEL (BBR & UDP MAXING FOR SLOWDNS)
# -----------------------------------------------------
print_title "OPTIMIZING KERNEL (BBR & UDP)"
print_info "Applying High-Latency Tunneling Patches..."

cat >> /etc/sysctl.conf <<EOF

# --- NETWORK OPTIMIZATIONS ---
# Maximize UDP Buffers for DNSTT (SlowDNS)
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 1048576
net.core.wmem_default = 1048576
net.ipv4.udp_mem = 1048576 8388608 16777216

# Enable TCP BBR for Dropbear/SSH over DNS
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
# -------------------------------------------
EOF

# Apply the patches to the live kernel immediately
sysctl -p > /dev/null 2>&1
print_success "Kernel Optimized for Maximum Throughput!"

# 3. DOMAIN & NS SETUP (YOUR EXACT DESIGN)
# -----------------------------------------------------
print_title "DOMAIN CONFIGURATION"
MYIP=$(curl -sS ifconfig.me)

# --- A. Main Domain ---
while true; do
    echo -e ""
    echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}            ENTER YOUR DOMAIN / SUBDOMAIN             ${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
    # Instructions print FIRST
    echo -e " ${CYAN}>${NC} Create an 'A Record' pointing to: ${GREEN}$MYIP${NC}"
    echo -e " ${CYAN}>${NC} Enter that subdomain below (e.g., vpn.mysite.com)."
    # Input prompt prints LAST
    read -p " Input SubDomain : " domain
    
    if [[ -z "$domain" ]]; then
        echo -e " ${RED}[!] Domain cannot be empty!${NC}"
        continue
    fi

    # Quick IP Check
    echo -e " ${BLUE}[...] Verifying IP pointing for $domain...${NC}"
    DOMAIN_IP=$(dig +short "$domain" | head -n 1)
    
    if [[ "$DOMAIN_IP" == "$MYIP" ]]; then
        echo -e " ${GREEN}[✔] Verified! Domain points to this VPS.${NC}"
        echo "$domain" > /etc/xray/domain
        break
    else
        echo -e " ${RED}[✘] Domain points to $DOMAIN_IP (Expected $MYIP)${NC}"
        echo -e "     Continuing anyway... (Please ensure DNS is correct)"
        echo "$domain" > /etc/xray/domain
        break
    fi
done

# --- B. NameServer (NS) ---
echo -e ""
echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}              ENTER YOUR NAMESERVER (NS)              ${NC}"
echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
# Instructions print FIRST
echo -e " ${CYAN}>${NC} Required for SlowDNS (e.g., ns.vpn.mysite.com)."
echo -e " ${CYAN}>${NC} If you don't have one, just press ENTER."
# Input prompt prints LAST
read -p " Input NS Domain : " nsdomain

if [[ -z "$nsdomain" ]]; then
    echo "ns.$domain" > /etc/xray/nsdomain
    print_info "Using default: ns.$domain"
else
    echo "$nsdomain" > /etc/xray/nsdomain
    print_success "NS Domain Saved!"
fi

# 3.5 TELEGRAM BACKUP SETUP
# -----------------------------------------------------
echo -e ""
echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}               TELEGRAM BOT SETUP (BACKUPS)           ${NC}"
echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
echo -e " ${CYAN}>${NC} Get a Bot Token from @BotFather."
echo -e " ${CYAN}>${NC} Send /start to your new bot in Telegram."
echo -e " ${CYAN}>${NC} Get your Chat ID from @userinfobot."
echo -e " ${CYAN}>${NC} Press ENTER to skip if you don't want Telegram backups."
read -p " Input Bot Token : " tg_token

if [[ -n "$tg_token" ]]; then
    read -p " Input Chat ID   : " tg_chatid
    echo "$tg_token" > /etc/xray/tg_token
    echo "$tg_chatid" > /etc/xray/tg_chatid
    print_success "Telegram Backup Configured!"
else
    print_info "Telegram setup skipped. Cloud fallback will be used."
fi

# 4. CONFIGURE DROPBEAR (FORCE WRITE)
# -----------------------------------------------------
print_title "CONFIGURING DROPBEAR SSH"

# Allow restricted shells so Dropbear accepts VPN users
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells

cat > /etc/default/dropbear <<EOF
NO_START=0
DROPBEAR_PORT=109
DROPBEAR_EXTRA_ARGS="-p 143"
DROPBEAR_BANNER="/etc/issue.net"
EOF

print_success "Dropbear Configured (Ports 109 & 143)"
systemctl restart dropbear

# 5. INSTALL XRAY CORE
# -----------------------------------------------------
print_title "INSTALLING XRAY CORE"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# # 6. INSTALL SSL/TLS & ROBUST VERIFICATION
# -----------------------------------------------------
print_title "GENERATING SSL CERTIFICATE"

DOMAIN=$(cat /etc/xray/domain)
echo -e "${BLUE}[INFO] Getting certificate for: $DOMAIN${NC}"

# Stop anything using port 80 (Let's Encrypt needs it)
systemctl stop nginx > /dev/null 2>&1
systemctl stop ws-proxy > /dev/null 2>&1
fuser -k 80/tcp > /dev/null 2>&1
sleep 2

# Request the certificate
mkdir -p /root/.acme.sh
curl -s https://get.acme.sh | sh
/root/.acme.sh/acme.sh --upgrade --auto-upgrade
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
/root/.acme.sh/acme.sh --issue -d "$DOMAIN" --standalone -k ec-256 --force

# Install the certificate where Nginx and Xray expect it
/root/.acme.sh/acme.sh --installcert -d "$DOMAIN" \
    --fullchainpath /etc/xray/xray.crt \
    --keypath /etc/xray/xray.key \
    --ecc

# Set proper permissions
chmod 644 /etc/xray/xray.crt
chmod 644 /etc/xray/xray.key

# 🚨 THE FIX: Verify SSL Success before proceeding
if [[ -f /etc/xray/xray.crt && -s /etc/xray/xray.crt ]]; then
    print_success "Real Let's Encrypt SSL certificate obtained!"
else
    echo -e "${RED}❌ Certificate not found or empty! Nginx and Xray will fail.${NC}"
    echo -e "${YELLOW}Please check if your domain ($DOMAIN) correctly points to $(curl -s ifconfig.me).${NC}"
    echo -e "${RED}Installation Aborted. Please fix DNS and run again.${NC}"
    exit 1
fi

# -----------------------------------------------------
# INSTALL STANDALONE HYSTERIA 2 (UDP 443)
# -----------------------------------------------------
print_title "INSTALLING HYSTERIA 2"

# 1. Install Official Hysteria 2
bash <(curl -fsSL https://get.hy2.sh/)

# 2. Write JSON-formatted config (Valid YAML) mapped to Let's Encrypt
cat > /etc/hysteria/config.yaml <<EOF
{
  "listen": ":443",
  "tls": {
    "cert": "/etc/xray/xray.crt",
    "key": "/etc/xray/xray.key"
  },
  "auth": {
    "type": "userpass",
    "userpass": {}
  },
  "masquerade": {
    "type": "proxy",
    "proxy": {
      "url": "https://bing.com",
      "rewriteHost": true
    }
  }
}
EOF

systemctl enable hysteria-server.service
systemctl restart hysteria-server.service
print_success "Hysteria 2 Standalone Configured on UDP 443!"

# 6.5 CONFIGURE STUNNEL4
# -----------------------------------------------------
print_title "CONFIGURING STUNNEL4"

cat > /etc/stunnel/stunnel.conf <<EOF
pid = /var/run/stunnel4.pid
cert = /etc/xray/xray.crt
key = /etc/xray/xray.key
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear]
accept = 447
connect = 127.0.0.1:109

[openssh]
accept = 777
connect = 127.0.0.1:22
EOF

# Enable Stunnel to start on boot
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
systemctl restart stunnel4
print_success "Stunnel4 Configured (Ports 447 & 777)!"

# 7. GENERATE NGINX CONFIG (PATH-BASED ROUTING FOR XRAY)
# -----------------------------------------------------
print_title "CONFIGURING NGINX PROXY"

# 1. Kill any conflicts on Port 80/81/443
fuser -k 80/tcp > /dev/null 2>&1
fuser -k 81/tcp > /dev/null 2>&1
fuser -k 443/tcp > /dev/null 2>&1

# 2. REMOVE DEFAULT CONFIG
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default

# 3. Create Custom Config (Port 443 SSL + Path Routing)
cat > /etc/nginx/conf.d/vps.conf <<EOF
server {
    listen 81 default_server;
    listen 443 ssl http2 default_server;
    server_name _;
    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    access_log /var/log/nginx/vps-access.log;
    error_log /var/log/nginx/vps-error.log;

    # Route VLESS Traffic
    location /vless {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # Route VMess Traffic
    location /vmess {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # Route Trojan Traffic
    location /trojan-ws {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10003;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # Route Shadowsocks Traffic
    location /ss-ws {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10004;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # Route WSS (Secure WebSocket) & General SSH Payloads to Python Proxy

    location / {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:80;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }
}
EOF
print_success "Nginx Config Created (SSL & Xray Routing Enabled)!"

# -----------------------------------------------------
# 7.5 INSTALL SLOWDNS (DNSTT) - DYNAMIC BUILD
# -----------------------------------------------------
print_title "INSTALLING SLOWDNS"

# 1. Install Modern Golang
print_info "Installing Git and Go Compiler..."
apt install -y git > /dev/null 2>&1
wget -q -O /tmp/go.tar.gz https://go.dev/dl/go1.21.6.linux-amd64.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf /tmp/go.tar.gz
rm -f /tmp/go.tar.gz

# 2. Download Source, Patch, & Compile
print_info "Building SlowDNS from Source..."
rm -rf /tmp/dnstt
git clone https://www.bamsoftware.com/git/dnstt.git /tmp/dnstt > /dev/null 2>&1
cd /tmp/dnstt/dnstt-server

print_info "Injecting High-Performance Buffer Patches into Go Source..."
# 🚨 SURGICAL GO PATCH: Find where smux.DefaultConfig() is called and inject massive buffer overrides
sed -i 's/config := smux.DefaultConfig()/config := smux.DefaultConfig()\n\tconfig.MaxReceiveBuffer = 16777216\n\tconfig.MaxStreamBuffer = 4194304/g' main.go

# Initialize and Compile
/usr/local/go/bin/go mod tidy
/usr/local/go/bin/go build


# 3. Setup Directory & Move Binary
mkdir -p /etc/slowdns
mv dnstt-server /etc/slowdns/dnstt-server
chmod +x /etc/slowdns/dnstt-server

# 4. Generate UNIQUE Master Keys
print_info "Generating Unique Master Keys for this Server..."
# Generate a fresh pair of Curve25519 keys
/etc/slowdns/dnstt-server -gen-key -privkey-file /etc/slowdns/server.key -pubkey-file /etc/slowdns/server.pub
sync
sleep 1

# Secure the private key so only root can read it
chmod 600 /etc/slowdns/server.key
chmod 644 /etc/slowdns/server.pub

# Save the Public Key to a variable so we can show it at the end of the install
NS_PUBKEY=$(cat /etc/slowdns/server.pub)
print_success "Unique Keys Generated!"

# 5. Read your NS Domain
nsdomain=$(cat /etc/xray/nsdomain)

# 6. Create Systemd Service
cat > /etc/systemd/system/client-slow.service <<EOF
[Unit]
Description=SlowDNS Server
After=network.target

[Service]
Type=simple
User=root
ExecStartPre=/bin/sh -c 'iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300 || true'
ExecStart=/etc/slowdns/dnstt-server -udp :5300 -privkey-file /etc/slowdns/server.key $nsdomain 127.0.0.1:109
ExecStopPost=/bin/sh -c 'iptables -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300 || true'
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# 7. Start the Service
systemctl daemon-reload
systemctl enable client-slow
systemctl restart client-slow

# Cleanup
cd ~
rm -rf /tmp/dnstt
print_success "SlowDNS Configured (Static Mode)!"
# -----------------------------------------------------

# 7.6 INSTALL OPENVPN
# -----------------------------------------------------
print_title "INSTALLING OPENVPN"
wget -q -O /tmp/openvpn.sh "${REPO_URL}/core/openvpn.sh"
chmod +x /tmp/openvpn.sh
/tmp/openvpn.sh
rm -f /tmp/openvpn.sh

# 8. DOWNLOAD FILES
# -----------------------------------------------------
print_title "DOWNLOADING SCRIPTS"

download_bin() {
    local folder=$1
    local file=$2
    wget -q -O /usr/bin/$file "${REPO_URL}/$folder/$file"
    chmod +x /usr/bin/$file
    echo -e " [OK] Installed: $file"
}

wget -q -O /usr/local/etc/xray/config.json "${REPO_URL}/core/config.json.template"
wget -q -O /etc/systemd/system/xray.service "${REPO_URL}/core/xray.service"
wget -q -O /etc/xray/ohp.py "${REPO_URL}/core/ohp.py"
wget -q -O /etc/xray/proxy.py "${REPO_URL}/core/proxy.py"

# -----------------------------------------------------
# CREATING TELEGRAM BOT SERVICE
# -----------------------------------------------------
TG_TOKEN=$(cat /etc/xray/tg_token 2>/dev/null)

if [[ -n "$TG_TOKEN" ]]; then
    print_info "Setting up Python Virtual Environment for Bot..."
    # 🚨 THE FIX: Use venv instead of breaking system packages!
    apt install -y python3-venv > /dev/null 2>&1
    python3 -m venv /etc/xray/venv
    /etc/xray/venv/bin/pip install pyTelegramBotAPI > /dev/null 2>&1

    print_info "Downloading Telegram Bot Script..."
    wget -q -O /etc/xray/tgbot.py "${REPO_URL}/core/tgbot.py"

    print_info "Creating Telegram Bot Service..."
    cat > /etc/systemd/system/tg-bot.service <<EOF
[Unit]
Description=Telegram VPN Manager Bot
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/xray
# 🚨 THE FIX: Run the bot securely inside the isolated venv
ExecStart=/etc/xray/venv/bin/python /etc/xray/tgbot.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable tg-bot
    systemctl restart tg-bot
    print_success "Telegram Bot Service Configured securely!"
else
    print_info "Skipping Telegram Bot Service (No Token Provided)."
fi

# -----------------------------------------------------

# -----------------------------------------------------
# CREATING SSH-WS PROXY SERVICE (PORT 80)
# -----------------------------------------------------
print_info "Creating SSH-WS Proxy Service..."
cat > /etc/systemd/system/ws-proxy.service <<EOF
[Unit]
Description=Python Proxy SSH-WS
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/xray
ExecStart=/usr/bin/python3 /etc/xray/proxy.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ws-proxy
systemctl restart ws-proxy
print_success "SSH-WS Proxy Service Configured!"

# -----------------------------------------------------
# CREATING OHP PROXY SERVICE (PORT 2095)
# -----------------------------------------------------
print_info "Creating OHP Proxy Service..."
cat > /etc/systemd/system/ohp.service <<EOF
[Unit]
Description=Python OHP Proxy
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/xray
ExecStart=/usr/bin/python3 /etc/xray/ohp.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ohp
systemctl restart ohp
print_success "OHP Proxy Service Configured!"
# -----------------------------------------------------

download_bin "menu" "menu"
download_bin "menu" "menu-set.sh"
download_bin "menu" "menu-ssh.sh"
download_bin "menu" "menu-trojan.sh"
download_bin "menu" "menu-vless.sh"
download_bin "menu" "menu-vmess.sh"
download_bin "menu" "menu-ss.sh"
download_bin "menu" "menu-hy.sh"

files_ssh=(usernew trial renew hapus member delete autokill cek tendang xp backup restore cleaner health-check show-conf ceklim)
for file in "${files_ssh[@]}"; do
    download_bin "ssh" "$file"
done

# ADDED ALL SS AND HY2 SCRIPTS HERE:
files_xray=(add-ws del-ws renew-ws cek-ws trial-ws add-vless del-vless xray-limit renew-vless cek-vless trial-vless add-tr del-tr renew-tr cek-tr trial-tr add-ss del-ss renew-ss cek-ss trial-ss add-hy2 del-hy2 renew-hy2 cek-hy2 trial-hy2)
for file in "${files_xray[@]}"; do
    download_bin "xray" "$file"
done

# 9. FINAL CONFIGURATION
# -----------------------------------------------------
print_title "FINALIZING SERVICES"

# -----------------------------------------------------
# CONFIGURE FAIL2BAN (BRUTE-FORCE PROTECTION)
# -----------------------------------------------------
print_info "Configuring Fail2Ban Protection..."

cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1
bantime  = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port    = 22
logpath = %(sshd_log)s
backend = %(sshd_backend)s

[dropbear]
enabled  = true
port     = 109,143
logpath  = /var/log/auth.log
maxretry = 3
EOF

systemctl restart fail2ban
systemctl enable fail2ban
print_success "Fail2Ban Active (Protecting SSH & Dropbear)!"

# Configure Vnstat
systemctl enable vnstat
systemctl restart vnstat

# Enable Services
systemctl daemon-reload
systemctl enable xray
systemctl restart xray
systemctl enable nginx
systemctl restart nginx
systemctl enable dropbear
systemctl restart dropbear
systemctl enable stunnel4
systemctl restart stunnel4

# Cronjobs
echo "0 0 * * * root /usr/bin/xp" > /etc/cron.d/xp
echo "*/5 * * * * root /usr/bin/tendang" > /etc/cron.d/tendang
echo "0 0 1 * * root systemctl restart stunnel4 nginx xray" > /etc/cron.d/cert_reload

service cron restart
print_success "Services Started."

# 10. FINISH & REBOOT (10s)
# -----------------------------------------------------
clear
echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}               INSTALLATION COMPLETED!                ${NC}"
echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
echo -e " ${BLUE}Domain      :${NC} $domain"
echo -e " ${BLUE}NS Domain   :${NC} $nsdomain"
echo -e " ${BLUE}SlowDNS Pub :${NC} $NS_PUBKEY"
echo -e " ${BLUE}IP Address  :${NC} $MYIP"
echo -e ""
echo -e "${YELLOW} IMPORTANT: Server will reboot in 10 seconds... ${NC}"
echo -e "${CYAN}────────────────────────────────────────────────────────${NC}"

for i in {10..1}; do
    echo -e " Rebooting in $i..."
    sleep 1
done

reboot
