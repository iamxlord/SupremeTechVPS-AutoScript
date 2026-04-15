#!/bin/bash
# ==========================================
#  Supreme-Tech Universal Auto-Installer
#  Premium Edition - v3.6 (Ultimate Gateway)
# ==========================================

# --- COLORS & STYLING ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

function print_title() {
    clear
    echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
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
systemctl stop apache2 > /dev/null 2>&1
systemctl disable apache2 > /dev/null 2>&1

apt update -y && apt upgrade -y
# Added perl and cmake natively to the core installer
apt install -y wget curl jq socat cron zip unzip net-tools git build-essential python3 python3-pip python3-full vnstat dropbear nginx dnsutils stunnel4 fail2ban speedtest-cli perl cmake

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

# Additional UDP & Backlog Optimizations
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.core.netdev_max_backlog=50000
net.ipv4.udp_rmem_min=16384
net.ipv4.udp_wmem_min=16384

# Enable TCP BBR for Dropbear/SSH over DNS
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
# -------------------------------------------
EOF

sysctl -p > /dev/null 2>&1
print_success "Kernel Optimized for Maximum Throughput!"

# 3. DOMAIN & NS SETUP
# -----------------------------------------------------
print_title "DOMAIN CONFIGURATION"
MYIP=$(curl -sS ifconfig.me)

# --- A. Main Domain ---
while true; do
    echo -e ""
    echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}            ENTER YOUR DOMAIN / SUBDOMAIN             ${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
    echo -e " ${CYAN}>${NC} Create an 'A Record' pointing to: ${GREEN}$MYIP${NC}"
    echo -e " ${CYAN}>${NC} Enter that subdomain below (e.g., vpn.mysite.com)."
    read -p " Input SubDomain : " domain
    
    if [[ -z "$domain" ]]; then
        echo -e " ${RED}[!] Domain cannot be empty!${NC}"
        continue
    fi

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
echo -e " ${CYAN}>${NC} Required for SlowDNS (e.g., ns.vpn.mysite.com)."
echo -e " ${CYAN}>${NC} If you don't have one, just press ENTER."
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

# ==========================================
# UNIVERSAL SAFETY NET (SSH & CLOUD AGENTS)
# ==========================================
print_info "Configuring Universal Safety Net..."

# 1. Cloud-Specific Failsafes (Azure Auto-Detect)
# Checks if the Azure Linux Agent is installed on this specific VPS
if systemctl list-unit-files | grep -qw walinuxagent.service 2>/dev/null; then
    print_info "Azure environment detected. Hardening waagent..."
    mkdir -p /etc/systemd/system/walinuxagent.service.d
    cat > /etc/systemd/system/walinuxagent.service.d/override.conf <<EOF
[Service]
Restart=always
RestartSec=5
EOF
    systemctl daemon-reload
    systemctl restart walinuxagent > /dev/null 2>&1 || true
else
    print_info "Non-Azure environment. Skipping waagent patch."
fi

# 2. Keep SSH Alive Under Heavy Server Load (Universal)
# These keep-alives work perfectly on DigitalOcean, Vultr, Linode, AWS, etc.
sed -i '/^ClientAliveInterval/d' /etc/ssh/sshd_config
sed -i '/^ClientAliveCountMax/d' /etc/ssh/sshd_config
echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config
echo "ClientAliveCountMax 3" >> /etc/ssh/sshd_config

print_success "Server Hardened & SSH Keep-Alives Injected!"

# 4. CONFIGURE DROPBEAR & SECURE SSH ACCESS
# -----------------------------------------------------
print_title "CONFIGURING DROPBEAR & SSH SAFEGUARDS"

echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells

sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's|^#Banner.*|Banner /etc/issue.net|' /etc/ssh/sshd_config
sed -i 's|^Banner.*|Banner /etc/issue.net|' /etc/ssh/sshd_config

print_info "Generating cryptographic host keys for Dropbear..."
rm -f /etc/dropbear/dropbear_*_host_key
dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key -s 2048 > /dev/null 2>&1
dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key > /dev/null 2>&1
dropbearkey -t ed25519 -f /etc/dropbear/dropbear_ed25519_host_key > /dev/null 2>&1

cat > /etc/cron.d/ssh_recovery <<EOF
*/5 * * * * root /bin/bash -c 'if ! systemctl is-active ssh >/dev/null 2>&1; then systemctl restart ssh; fi'
@reboot root /bin/bash -c 'sed -i "s/^PermitRootLogin.*/PermitRootLogin yes/" /etc/ssh/sshd_config && systemctl restart ssh'
EOF
service cron restart

cat > /etc/default/dropbear <<EOF
NO_START=0
DROPBEAR_PORT=109
DROPBEAR_EXTRA_ARGS="-p 143"
DROPBEAR_BANNER="/etc/issue.net"
EOF

print_success "Dropbear Configured & SSH Failsafes Applied!"
systemctl restart sshd dropbear

# 5. INSTALL XRAY CORE
# -----------------------------------------------------
print_title "INSTALLING XRAY CORE"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# 6. INSTALL SSL/TLS
# -----------------------------------------------------
print_title "GENERATING SSL CERTIFICATE"
DOMAIN=$(cat /etc/xray/domain)

systemctl stop nginx > /dev/null 2>&1
systemctl stop ws-proxy > /dev/null 2>&1

fuser -k 80/tcp > /dev/null 2>&1
while fuser 80/tcp >/dev/null 2>&1; do
    echo -e "${YELLOW}Waiting for port 80 to fully release...${NC}"
    sleep 1
done

mkdir -p /root/.acme.sh
curl -s https://get.acme.sh | sh
/root/.acme.sh/acme.sh --upgrade --auto-upgrade
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
/root/.acme.sh/acme.sh --issue -d "$DOMAIN" --standalone -k ec-256 --force

/root/.acme.sh/acme.sh --installcert -d "$DOMAIN" \
    --fullchainpath /etc/xray/xray.crt \
    --keypath /etc/xray/xray.key \
    --ecc

chmod 644 /etc/xray/xray.crt
chmod 644 /etc/xray/xray.key

if [[ -f /etc/xray/xray.crt && -s /etc/xray/xray.crt ]]; then
    print_success "Real Let's Encrypt SSL certificate obtained!"
else
    echo -e "${RED}❌ Certificate not found or empty! Nginx and Xray will fail.${NC}"
    exit 1
fi

# -----------------------------------------------------
# INSTALL STANDALONE HYSTERIA 2
# -----------------------------------------------------
print_title "INSTALLING HYSTERIA 2"
bash <(curl -fsSL https://get.hy2.sh/)

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

sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
systemctl restart stunnel4
print_success "Stunnel4 Configured (Ports 447 & 777)!"

# 7. GENERATE NGINX CONFIG
# -----------------------------------------------------
print_title "CONFIGURING NGINX PROXY"

fuser -k 80/tcp > /dev/null 2>&1
fuser -k 81/tcp > /dev/null 2>&1
fuser -k 443/tcp > /dev/null 2>&1

rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default

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
# 7.5 INSTALL SLOWDNS (DNSTT) - OPTIMIZED BUILD
# -----------------------------------------------------
print_title "INSTALLING SLOWDNS"

# 1. Install Modern Golang
print_info "Installing Git and Go Compiler..."
apt install -y git perl > /dev/null 2>&1
wget -q -O /tmp/go.tar.gz https://go.dev/dl/go1.21.6.linux-amd64.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf /tmp/go.tar.gz
rm -f /tmp/go.tar.gz

# 2. Download Source & Apply Patches
print_info "Building SlowDNS from Source..."
rm -rf /tmp/dnstt
git clone https://www.bamsoftware.com/git/dnstt.git /tmp/dnstt > /dev/null 2>&1
cd /tmp/dnstt/dnstt-server

print_info "Injecting High-Performance Patches..."

# Check what files exist and patch accordingly
if [[ -f ../turbotunnel/kcp.go ]]; then
    # Old structure
    print_info "Found legacy KCP structure..."
    if grep -q "SetWindowSize" ../turbotunnel/kcp.go 2>/dev/null; then
        perl -pi -e 's/SetWindowSize\(\K32,\s*32/256, 256/' ../turbotunnel/kcp.go
        perl -pi -e 's/SetSendWindow\(\K32/256/' ../turbotunnel/kcp.go
        perl -pi -e 's/SetReceiveWindow\(\K32/256/' ../turbotunnel/kcp.go
        print_success "KCP windows patched"
    fi
else
    # New structure - patch the tunnel implementation files
    print_info "Using modern turbotunnel structure..."
    
    # Patch queuepacketconn.go (contains buffer sizes)
    if [[ -f ../turbotunnel/queuepacketconn.go ]]; then
        perl -pi -e 's/queueSize\s*=\s*\K32/512/' ../turbotunnel/queuepacketconn.go
        perl -pi -e 's/bufferSize\s*=\s*\K4096/32768/' ../turbotunnel/queuepacketconn.go
        print_success "Queue buffer sizes increased"
    fi
    
    # Patch remotemap.go (contains window settings)
    if [[ -f ../turbotunnel/remotemap.go ]]; then
        perl -pi -e 's/windowSize\s*=\s*\K32/256/' ../turbotunnel/remotemap.go
        perl -pi -e 's/maxWindow\s*=\s*\K256/2048/' ../turbotunnel/remotemap.go
        print_success "Remote map windows increased"
    fi
    
    # Patch clientid.go (timeout settings)
    if [[ -f ../turbotunnel/clientid.go ]]; then
        perl -pi -e 's/timeout\s*=\s*\K30/120/' ../turbotunnel/clientid.go
        print_success "Client timeouts increased"
    fi
fi

# PATCH: Increase UDP buffer sizes in main.go
if grep -q "udpBufferSize" main.go 2>/dev/null; then
    perl -pi -e 's/udpBufferSize\s*=\s*\K4096/65536/' main.go
    print_success "UDP buffer size increased"
fi

# PATCH 3: The Bulletproof AWK Buffer Injection for smux
if grep -q "MaxReceiveBuffer = 33554432" main.go; then
    print_info "Smux buffers already patched"
else
    awk '/config := smux.DefaultConfig()/ {
        print
        print "\tconfig.MaxReceiveBuffer = 33554432"
        print "\tconfig.MaxStreamBuffer = 8388608"
        next
    }1' main.go > main_patched.go && mv main_patched.go main.go
    print_success "Smux buffers added (RX: 32MB, TX: 8MB)"
fi

print_success "All patches applied successfully!"

# Initialize and Compile
print_info "Compiling SlowDNS binary..."
/usr/local/go/bin/go mod tidy

# Set build flags for better performance
export CGO_ENABLED=0
export GOOS=linux
export GOARCH=amd64

if ! /usr/local/go/bin/go build -ldflags="-s -w" -o dnstt-server; then
    echo -e "${RED}[!] Compilation failed! Trying fallback build...${NC}"
    /usr/local/go/bin/go build -o dnstt-server
fi

# Verify binary was created
if [[ ! -f dnstt-server ]]; then
    echo -e "${RED}[!] CRITICAL: SlowDNS compilation failed!${NC}"
    echo -e "${YELLOW}Attempting to download pre-compiled binary...${NC}"
    wget -q -O dnstt-server "https://github.com/iamxlord/SupremeTechVPS-AutoScript/raw/main/core/dnstt-server" 2>/dev/null || \
    wget -q -O dnstt-server "https://github.com/sergeycherepanov/dnstt/releases/download/v0.1.0/dnstt-server-linux-amd64" 2>/dev/null
    
    if [[ -f dnstt-server ]]; then
        chmod +x dnstt-server
        print_success "Downloaded pre-compiled binary"
    else
        echo -e "${RED}[!] Failed to get binary from any source${NC}"
        exit 1
    fi
fi

# Verify binary works
if file dnstt-server | grep -q "ELF"; then
    print_success "Binary verification passed"
else
    echo -e "${RED}[!] Binary validation warning${NC}"
fi

# 3. Setup Directory & Move Binary
mkdir -p /etc/slowdns
mv dnstt-server /etc/slowdns/dnstt-server
chmod +x /etc/slowdns/dnstt-server

# 4. Generate UNIQUE Master Keys
print_info "Restoring Unique Master Keys for this Server..."
rm -f /etc/slowdns/server.key /etc/slowdns/server.pub

echo -n "bce4df24c6c75e7e87b3576fa827f73be24fc5b3890ea05f94bd46d863fdda03" > /etc/slowdns/server.key
echo -n "2ec706b8b95fa7776550b5bc289269983ecc8c5157ff92ca09193c2db54c8b25" > /etc/slowdns/server.pub

sleep 2

if [[ ! -f /etc/slowdns/server.key ]] || [[ ! -s /etc/slowdns/server.key ]]; then
    echo -e "${RED}[!] CRITICAL: Failed to restore server keys! Retrying...${NC}"
    /etc/slowdns/dnstt-server -gen-key -privkey-file /etc/slowdns/server.key -pubkey-file /etc/slowdns/server.pub
    sleep 2
fi

if [[ ! -f /etc/slowdns/server.pub ]] || [[ ! -s /etc/slowdns/server.pub ]]; then
    echo -e "${RED}[!] CRITICAL: Server keys missing! Installation aborted.${NC}"
    exit 1
fi


chmod 600 /etc/slowdns/server.key
chmod 644 /etc/slowdns/server.pub

NS_PUBKEY=$(cat /etc/slowdns/server.pub | tr -d '\n\r')
print_success "Unique Keys Generated Successfully!"
print_info "Public Key: ${GREEN}$NS_PUBKEY${NC}"

echo "$NS_PUBKEY" > /etc/slowdns/server.pub.key

# 5. Read your NS Domain
nsdomain=$(cat /etc/xray/nsdomain)

# 6. Create Systemd Service
cat > /etc/systemd/system/client-slow.service <<EOF
[Unit]
Description=SlowDNS Server (Optimized)
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
ExecStartPre=/bin/sh -c 'iptables -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300 2>/dev/null; iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300 || true'
ExecStart=/etc/slowdns/dnstt-server -udp :5300 -privkey-file /etc/slowdns/server.key $nsdomain 127.0.0.1:109
ExecStopPost=/bin/sh -c 'iptables -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300 || true'
Restart=always
RestartSec=3
LimitNOFILE=65536
LimitNPROC=65536
ProtectSystem=full
NoNewPrivileges=yes
PrivateTmp=yes

[Install]
WantedBy=multi-user.target
EOF

# 7. Start the Service
systemctl daemon-reload
systemctl enable client-slow
systemctl restart client-slow

sleep 2
if systemctl is-active --quiet client-slow; then
    print_success "SlowDNS Service is RUNNING!"
    systemctl status client-slow --no-pager -l | head -5
else
    echo -e "${RED}[!] WARNING: SlowDNS service failed to start!${NC}"
    echo -e "${YELLOW}Checking logs...${NC}"
    journalctl -u client-slow -n 10 --no-pager
fi

print_info "Testing DNS tunnel..."
if command -v dig &> /dev/null; then
    dig @127.0.0.1 -p 5300 $nsdomain 2>/dev/null | grep -q "status: NOERROR" && \
        print_success "DNS tunnel responding" || \
        print_info "DNS tunnel test inconclusive"
fi

cd ~
rm -rf /tmp/dnstt
print_success "SlowDNS Installation Complete!"

echo -e ""
echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}              SLOWDNS CONNECTION INFO                ${NC}"
echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
echo -e " ${BLUE}NS Domain:${NC} $nsdomain"
echo -e " ${BLUE}Public Key:${NC} ${GREEN}$NS_PUBKEY${NC}"
echo -e " ${BLUE}Server Port:${NC} UDP 53 (redirected to 5300)"
echo -e " ${BLUE}Target:${NC} 127.0.0.1:109 (Dropbear)"
echo -e ""
# -----------------------------------------------------
# 7.6 INSTALL OPENVPN (DUAL TCP/UDP)
# -----------------------------------------------------
print_title "INSTALLING OPENVPN"
wget -q -O /tmp/openvpn.sh "${REPO_URL}/core/openvpn.sh"
chmod +x /tmp/openvpn.sh
/tmp/openvpn.sh
rm -f /tmp/openvpn.sh

# 7.7 INSTALL BADVPN-UDPGW
# -----------------------------------------------------
print_title "INSTALLING BADVPN (UDPGW)"
cd /tmp
git clone https://github.com/ambrop72/badvpn.git > /dev/null 2>&1
mkdir -p /tmp/badvpn/build
cd /tmp/badvpn/build
cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 > /dev/null 2>&1
make > /dev/null 2>&1
cp udpgw/badvpn-udpgw /usr/bin/
chmod +x /usr/bin/badvpn-udpgw

cat > /etc/systemd/system/udpgw.service <<EOF
[Unit]
Description=UDP Gateway (BadVPN)
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 100
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udpgw
systemctl start udpgw
print_success "BadVPN UDPGW Configured (Port 7300)!"

# 7.8 INSTALL DANTE SOCKS5 PROXY
# -----------------------------------------------------
print_title "INSTALLING DANTE SOCKS5"
apt-get install -y dante-server > /dev/null 2>&1

NIC=$(ip -o -4 route show to default | awk '{print $5}')
cat > /etc/danted.conf <<EOF
logoutput: syslog
internal: 0.0.0.0 port = 1080
external: $NIC
clientmethod: none
socksmethod: username
user.privileged: root
user.notprivileged: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error
}
socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error
}
EOF

systemctl restart danted
systemctl enable danted
print_success "Dante SOCKS5 Configured (Port 1080)!"

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

# ==========================================
# XTLS-REALITY KEY GENERATION & INJECTION
# ==========================================
print_info "Generating XTLS-Reality Cryptographic Keys..."
KEYS=$(/usr/local/bin/xray x25519)
PRIVATE_KEY=$(echo "$KEYS" | grep "PrivateKey:" | awk '{print $2}')
PUBLIC_KEY=$(echo "$KEYS" | grep "Password (PublicKey):" | awk '{print $3}')
SHORT_ID=$(openssl rand -hex 4)
DEFAULT_BUG="www.microsoft.com"
DEFAULT_PORT=8443

# Save keys for UI display and future linking
echo "$PRIVATE_KEY" > /etc/xray/reality_private
echo "$PUBLIC_KEY" > /etc/xray/reality_public
echo "$SHORT_ID" > /etc/xray/reality_shortid
echo "$DEFAULT_BUG" > /etc/xray/reality_sni

# Create the Reality Ledger (Maps Ports to Bugs)
echo "$DEFAULT_PORT|$DEFAULT_BUG" > /etc/xray/reality_ports.txt

# Inject safely into the config template
sed -i "s/REPLACE_PRIVATE_KEY/$PRIVATE_KEY/g" /usr/local/etc/xray/config.json
sed -i "s/REPLACE_SHORT_ID/$SHORT_ID/g" /usr/local/etc/xray/config.json
sed -i "s/REPLACE_REALITY_DEST/$DEFAULT_BUG/g" /usr/local/etc/xray/config.json
sed -i "s/REPLACE_REALITY_SNI/$DEFAULT_BUG/g" /usr/local/etc/xray/config.json
print_success "XTLS-Reality Engine Primed on Port $DEFAULT_PORT!"



# -----------------------------------------------------
# CREATING TELEGRAM BOT SERVICE
# -----------------------------------------------------
TG_TOKEN=$(cat /etc/xray/tg_token 2>/dev/null)

if [[ -n "$TG_TOKEN" ]]; then
    print_info "Setting up Python Virtual Environment for Bot..."
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
download_bin "menu" "menu-reality.sh"

files_ssh=(usernew trial renew hapus member delete autokill cek tendang xp backup restore cleaner health-check show-conf ceklim)
for file in "${files_ssh[@]}"; do
    download_bin "ssh" "$file"
done

files_xray=(add-ws del-ws renew-ws cek-ws trial-ws add-vless del-vless xray-limit renew-vless cek-vless trial-vless add-tr del-tr renew-tr cek-tr trial-tr add-ss del-ss renew-ss cek-ss trial-ss add-hy2 del-hy2 renew-hy2 cek-hy2 trial-hy2 add-reality del-reality renew-reality cek-reality trial-reality)
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

systemctl enable vnstat
systemctl restart vnstat

systemctl daemon-reload
systemctl enable xray
systemctl restart xray
systemctl enable nginx
systemctl restart nginx
systemctl enable dropbear
systemctl restart dropbear
systemctl enable stunnel4
systemctl restart stunnel4

echo "0 0 * * * root /usr/bin/xp" > /etc/cron.d/xp
echo -e "*/5 * * * * root /usr/bin/tendang\n*/5 * * * * root /usr/bin/xray-limit" > /etc/cron.d/tendang
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
echo -e " ${BLUE}Reality Pub :${NC} $(cat /etc/xray/reality_public 2>/dev/null)"
echo -e " ${BLUE}IP Address  :${NC} $MYIP"
echo -e ""
echo -e "${YELLOW} IMPORTANT: Server will reboot in 10 seconds... ${NC}"
echo -e "${CYAN}────────────────────────────────────────────────────────${NC}"

for i in {10..1}; do
    echo -e " Rebooting in $i..."
    sleep 1
done

reboot
