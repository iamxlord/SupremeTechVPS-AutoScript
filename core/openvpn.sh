#!/bin/bash
# ==========================================
#  OpenVPN Auto-Installer Module
# ==========================================
domain=$(cat /etc/xray/domain)
MYIP=$(curl -sS ifconfig.me)

echo -e " [INFO] Installing OpenVPN and Easy-RSA..."
export DEBIAN_FRONTEND=noninteractive
apt-get install -y openvpn easy-rsa iptables-persistent libpam0g-dev openvpn-auth-pam > /dev/null 2>&1


echo -e " [INFO] Generating Cryptographic Keys (Takes ~1 minute)..."
make-cadir /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa

# Generate Keys without interactive prompts
export EASYRSA_BATCH=1
./easyrsa init-pki > /dev/null 2>&1
./easyrsa build-ca nopass > /dev/null 2>&1
./easyrsa build-server-full server nopass > /dev/null 2>&1
./easyrsa gen-dh > /dev/null 2>&1
openvpn --genkey --secret ta.key

# Move certificates to OpenVPN main folder
cp pki/ca.crt /etc/openvpn/
cp pki/issued/server.crt /etc/openvpn/
cp pki/private/server.key /etc/openvpn/
cp pki/dh.pem /etc/openvpn/dh2048.pem
cp ta.key /etc/openvpn/

echo -e " [INFO] Configuring OpenVPN Server (TCP 1194)..."
PLUGIN=$(find /usr -type f -name "openvpn-plugin-auth-pam.so" | head -n 1)

cat > /etc/openvpn/server.conf <<EOF
port 1194
proto tcp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem
tls-auth ta.key 0
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 1.1.1.1"
keepalive 10 120
cipher AES-256-CBC
user nobody
group nogroup
persist-key
persist-tun
status openvpn-status.log
verb 3
plugin $PLUGIN login
client-cert-not-required
username-as-common-name
EOF

echo -e " [INFO] Configuring Network Routing..."
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl -p > /dev/null 2>&1

NIC=$(ip -o -4 route show to default | awk '{print $5}')
iptables -t nat -I POSTROUTING -s 10.8.0.0/24 -o $NIC -j MASQUERADE
iptables -t nat -I POSTROUTING -s 10.8.0.0/24 -j SNAT --to-source $MYIP
iptables-save > /etc/iptables/rules.v4

systemctl daemon-reload
systemctl enable openvpn@server
systemctl restart openvpn@server

echo -e " [INFO] Generating Client Profile..."
cat > /etc/openvpn/client.ovpn <<EOF
client
dev tun
proto tcp
remote $domain 1194
resolv-retry infinite
nobind
persist-key
persist-tun
auth-user-pass
cipher AES-256-CBC
verb 3
<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
<tls-auth>
$(cat /etc/openvpn/ta.key)
</tls-auth>
key-direction 1
EOF

# --- NGINX DOWNLOAD LINK SETUP ---
echo -e " [INFO] Setting up Nginx Download Directory..."
mkdir -p /var/www/html/ovpn
cp /etc/openvpn/client.ovpn /var/www/html/ovpn/client-tcp.ovpn
chmod 644 /var/www/html/ovpn/client-tcp.ovpn

cat > /etc/nginx/conf.d/ovpn-download.conf <<EOF
server {
    listen 85;
    server_name _;
    root /var/www/html/ovpn;
    autoindex on;
}
EOF
systemctl restart nginx

echo -e " [OK] OpenVPN Setup Complete!"