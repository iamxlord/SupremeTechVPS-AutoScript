import telebot
from telebot.types import ReplyKeyboardMarkup, KeyboardButton
import subprocess
import os
import uuid
import json
import base64
import re
from datetime import datetime, timedelta

# --- 1. INITIALIZATION & CREDENTIALS ---
with open('/etc/xray/tg_token', 'r') as f:
    TOKEN = f.read().strip()
with open('/etc/xray/tg_chatid', 'r') as f:
    ADMIN_ID = f.read().strip()

bot = telebot.TeleBot(TOKEN)
user_states = {}

# Security Check
def is_admin(message):
    return str(message.chat.id) == ADMIN_ID

# Helper: Get Server Info for Receipts
def get_server_info():
    try:
        ip = subprocess.check_output(["curl", "-sS", "ifconfig.me"]).decode().strip()
    except:
        ip = "Unknown"
    domain = open('/etc/xray/domain').read().strip() if os.path.exists('/etc/xray/domain') else "IP-Only"
    ns = open('/etc/xray/nsdomain').read().strip() if os.path.exists('/etc/xray/nsdomain') else "Not Set"
    pubkey = open('/etc/slowdns/server.pub').read().strip() if os.path.exists('/etc/slowdns/server.pub') else "Not Set"
    return ip, domain, ns, pubkey

# --- 2. INTERACTIVE KEYBOARD MENU ---
@bot.message_handler(commands=['start', 'menu'], func=is_admin)
def send_menu(message):
    markup = ReplyKeyboardMarkup(resize_keyboard=True, row_width=2)
    markup.add(
        KeyboardButton("🚀 Create SSH"),
        KeyboardButton("⚡ Create VMess"),
        KeyboardButton("🛡️ Create VLESS"),
        KeyboardButton("🐎 Create Trojan"),
        KeyboardButton("👻 Create Shadowsocks"),
        KeyboardButton("🚀 Create Hysteria2"),
        KeyboardButton("📊 Server Status")
    )
    bot.send_message(message.chat.id, "🤖 *Mr. X VPN Control Panel*\nSelect an option below:", parse_mode="Markdown", reply_markup=markup)

# --- 3. CREATION FLOW ---
@bot.message_handler(func=lambda message: message.text in ["🚀 Create SSH", "⚡ Create VMess", "🛡️ Create VLESS", "🐎 Create Trojan", "👻 Create Shadowsocks", "🚀 Create Hysteria2"] and is_admin(message))
def start_creation(message):
    protocol = message.text.split(" ")[2]
    user_states[message.chat.id] = {'protocol': protocol}
    
    msg = bot.reply_to(message, f"👤 Enter new Username for *{protocol}*:", parse_mode="Markdown")
    bot.register_next_step_handler(msg, process_username)

def process_username(message):
    cid = message.chat.id
    user_states[cid]['username'] = message.text
    
    if user_states[cid]['protocol'] == "SSH":
        msg = bot.reply_to(message, "🔑 Enter Password:")
        bot.register_next_step_handler(msg, process_password)
    else:
        msg = bot.reply_to(message, "📆 Enter Active Days (e.g., 30):")
        bot.register_next_step_handler(msg, process_days)

def process_password(message):
    cid = message.chat.id
    user_states[cid]['password'] = message.text
    msg = bot.reply_to(message, "📆 Enter Active Days (e.g., 30):")
    bot.register_next_step_handler(msg, process_days)

def process_days(message):
    cid = message.chat.id
    user_states[cid]['days'] = message.text
    msg = bot.reply_to(message, "📱 Enter Max Login Limit (e.g., 2):")
    bot.register_next_step_handler(msg, process_execute)

# --- 4. EXECUTION & RECEIPTS ---
def process_execute(message):
    cid = message.chat.id
    data = user_states.get(cid, {})
    
    user = data.get('username', '')
    days = data.get('days', '')
    limit = message.text
    protocol = data.get('protocol', '')
    
    # 🚨 SECURITY: Strict Regex Validation
    if not re.match("^[a-zA-Z0-9_-]+$", user):
        bot.send_message(cid, "❌ *Security Error:* Username contains invalid characters. Use only letters, numbers, hyphens, or underscores.", parse_mode="Markdown")
        return
    if not days.isdigit() or not limit.isdigit():
        bot.send_message(cid, "❌ *Error:* Days and Limits must be numbers.", parse_mode="Markdown")
        return
    
    ip, domain, ns, pubkey = get_server_info()
    
    # Native Python Date Math (Safe)
    exp_date = (datetime.now() + timedelta(days=int(days))).strftime('%Y-%m-%d')
    config_path = "/usr/local/etc/xray/config.json"
    
    bot.send_message(cid, f"⏳ Creating {protocol} account `{user}`...", parse_mode="Markdown")
    
    try:
        if protocol == "SSH":
            pwd = data['password']
            # Safe subprocess execution (No shell=True)
            subprocess.run(["useradd", "-e", exp_date, "-s", "/bin/false", "-M", user], check=True)
            subprocess.run(["chpasswd"], input=f"{user}:{pwd}\n", text=True, check=True)
            
            os.makedirs('/etc/xray/limit', exist_ok=True)
            with open(f'/etc/xray/limit/{user}', 'w') as f: f.write(limit)
            
            receipt = f"""✅ *PREMIUM SSH ACCOUNT* ✅
            
👤 *Username:* `{user}`
🔑 *Password:* `{pwd}`
📱 *Limit:* `{limit}` Device(s)
📆 *Expiry:* `{exp_date}`

🌐 *IP:* `{ip}`
🏠 *Host:* `{domain}`
📡 *NS:* `{ns}`
🔑 *PubKey:* `{pubkey}`

*--- PORTS ---*
SSH/Dropbear : `22, 109, 143`
SSH-WS       : `80`
SSH-WSS      : `443`
Univ. Proxy  : `8080`
SSL/TLS      : `447, 777`
OVPN         : `http://{domain}:85/client-tcp.ovpn`

*--- PAYLOAD EXAMPLES ---*
*WebSocket (WS/WSS):*
`GET / HTTP/1.1[crlf]Host: {domain}[crlf]Upgrade: websocket[crlf][crlf]`

*Custom HTTP Proxy (e.g. Bug Fronting):*
`GET http://{domain} HTTP/1.1[crlf]Host: bug.com[crlf][crlf]`"""

        else:
            # 🚨 THE FIX: PURE PYTHON JSON INJECTION (Zero Command Injection Risk)
            with open(config_path, 'r') as f:
                config_data = f.read()

            if protocol == "VMess":
                uid = str(uuid.uuid4())
                new_block = f"// #vmess\n          // ### {user} {exp_date}\n          }},{{\"id\": \"{uid}\",\"alterId\": 0,\"email\": \"{user}\""
                config_data = config_data.replace("// #vmess", new_block)
                
                os.makedirs('/etc/xray/limit/vmess', exist_ok=True)
                with open(f'/etc/xray/limit/vmess/{user}', 'w') as f: f.write(limit)
                
                v_dict = {"add": domain, "aid": "0", "host": domain, "id": uid, "net": "ws", "path": "/vmess", "port": "443", "ps": user, "scy": "auto", "sni": domain, "tls": "tls", "type": "", "v": "2"}
                link_tls = "vmess://" + base64.b64encode(json.dumps(v_dict).encode()).decode()
                
                receipt = f"""✅ *PREMIUM VMESS ACCOUNT* ✅\n\n👤 *Username:* `{user}`\n🔑 *UUID:* `{uid}`\n📱 *Limit:* `{limit}` Device(s)\n📆 *Expiry:* `{exp_date}`\n🏠 *Host:* `{domain}`\n\n🔗 *TLS Link:*\n`{link_tls}`"""

            elif protocol == "VLESS":
                uid = str(uuid.uuid4())
                new_block = f"// #vless\n          // #vl {user} {exp_date}\n          }},{{\"id\": \"{uid}\",\"email\": \"{user}\""
                config_data = config_data.replace("// #vless", new_block)
                
                os.makedirs('/etc/xray/limit/vless', exist_ok=True)
                with open(f'/etc/xray/limit/vless/{user}', 'w') as f: f.write(limit)
                
                link_tls = f"vless://{uid}@{domain}:443?path=/vless&security=tls&encryption=none&type=ws#{user}"
                receipt = f"""✅ *PREMIUM VLESS ACCOUNT* ✅\n\n👤 *Username:* `{user}`\n🔑 *UUID:* `{uid}`\n📱 *Limit:* `{limit}` Device(s)\n📆 *Expiry:* `{exp_date}`\n🏠 *Host:* `{domain}`\n\n🔗 *TLS Link:*\n`{link_tls}`"""

            elif protocol == "Trojan":
                uid = str(uuid.uuid4())
                new_block = f",\n          {{ \"password\": \"{uid}\", \"email\": \"{user}\" }}\n          // #trojan-ws\n          // #tr {user} {exp_date}"
                config_data = config_data.replace("// #trojan-ws", new_block)
                
                os.makedirs('/etc/xray/limit/trojan', exist_ok=True)
                with open(f'/etc/xray/limit/trojan/{user}', 'w') as f: f.write(limit)
                
                link_tls = f"trojan://{uid}@{domain}:443?path=%2Ftrojan-ws&security=tls&host={domain}&type=ws&sni={domain}#{user}"
                receipt = f"""✅ *PREMIUM TROJAN ACCOUNT* ✅\n\n👤 *Username:* `{user}`\n🔑 *Password:* `{uid}`\n📱 *Limit:* `{limit}` Device(s)\n📆 *Expiry:* `{exp_date}`\n🏠 *Host:* `{domain}`\n\n🔗 *TLS Link:*\n`{link_tls}`"""

            elif protocol == "Shadowsocks":
                uid = str(uuid.uuid4())
                new_block = f",\n          {{ \"password\": \"{uid}\", \"method\": \"aes-256-gcm\", \"email\": \"{user}\" }}\n          // #ss-ws\n          // #ss {user} {exp_date}"
                config_data = config_data.replace("// #ss-ws", new_block)
                
                os.makedirs('/etc/xray/limit/shadowsocks', exist_ok=True)
                with open(f'/etc/xray/limit/shadowsocks/{user}', 'w') as f: f.write(limit)
                
                ss_creds = base64.b64encode(f"aes-256-gcm:{uid}".encode()).decode()
                link_tls = f"ss://{ss_creds}@{domain}:443?plugin=v2ray-plugin%3Btls%3Bhost%3D{domain}%3Bpath%3D%2Fss-ws#{user}"
                link_http = f"ss://{ss_creds}@{domain}:80?plugin=v2ray-plugin%3Bhost%3D{domain}%3Bpath%3D%2Fss-ws#{user}"
                
                receipt = f"""✅ *PREMIUM SHADOWSOCKS* ✅\n\n👤 *Username:* `{user}`\n🔑 *Password:* `{uid}`\n📱 *Limit:* `{limit}` Device(s)\n📆 *Expiry:* `{exp_date}`\n🏠 *Host:* `{domain}`\n\n🔗 *TLS/SSL (WSS) Link:*\n`{link_tls}`\n\n🔗 *HTTP Obfs (WS) Link:*\n`{link_http}`"""

            elif protocol == "Hysteria2":
                uid = str(uuid.uuid4())
                new_block = f",\n          {{ \"password\": \"{uid}\", \"email\": \"{user}\" }}\n          // #hy2\n          // #hy {user} {exp_date}"
                config_data = config_data.replace("// #hy2", new_block)
                
                os.makedirs('/etc/xray/limit/hysteria', exist_ok=True)
                with open(f'/etc/xray/limit/hysteria/{user}', 'w') as f: f.write(limit)
                
                link = f"hysteria2://{uid}@{domain}:443/?sni={domain}&insecure=0#{user}"
                receipt = f"""✅ *PREMIUM HYSTERIA v2* ✅\n\n👤 *Username:* `{user}`\n🔑 *Password:* `{uid}`\n📱 *Limit:* `{limit}` Device(s)\n📆 *Expiry:* `{exp_date}`\n🏠 *Host:* `{domain}`\n🔌 *Protocol:* `UDP`\n\n🔗 *Hysteria2 Link:*\n`{link}`"""

            # Save the updated JSON back to the file
            with open(config_path, 'w') as f:
                f.write(config_data)

            # Restart Xray using safe subprocess execution
            subprocess.run(["systemctl", "restart", "xray"], check=True)

        bot.send_message(cid, receipt, parse_mode="Markdown")
        
    except subprocess.CalledProcessError as e:
        bot.send_message(cid, f"❌ *System Error:* Command execution failed.", parse_mode="Markdown")
    except Exception as e:
        bot.send_message(cid, f"❌ *Error:* Failed to create account.\n`{str(e)}`", parse_mode="Markdown")

# --- 5. SERVER STATUS ---
@bot.message_handler(func=lambda message: message.text == "📊 Server Status" and is_admin(message))
def server_status(message):
    try:
        ram = subprocess.check_output(["sh", "-c", "free -m | grep Mem | awk '{print $3\"/\"$2\" MB\"}'"]).decode().strip()
        cpu = subprocess.check_output(["sh", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print 100 - $8\"%\"}'"]).decode().strip()
        
        ssh_cmd = "awk -F: '$3 >= 1000 && $1 != \"nobody\" && ($7 == \"/bin/false\" || $7 == \"/usr/sbin/nologin\") {print $1}' /etc/passwd | wc -l"
        ssh_count = subprocess.check_output(["sh", "-c", ssh_cmd]).decode().strip()
        
        # 🚨 THE FIX: Safe counting that doesn't crash Python when 0 users exist
        def get_count(tag):
            try:
                res = subprocess.run(["grep", "-c", tag, "/usr/local/etc/xray/config.json"], capture_output=True, text=True)
                return res.stdout.strip() if res.returncode == 0 else "0"
            except:
                return "0"

        vmess_count = get_count("// ###")
        vless_count = get_count("// #vl")
        trojan_count = get_count("// #tr")
        ss_count = get_count("// #ss ")
        hy2_count = get_count("// #hy ")

        status_msg = f"""🖥 *MR. X SERVER STATUS* 🖥

💾 *RAM Used:* `{ram}`
⚙️ *CPU Used:* `{cpu}`

*--- ACTIVE USERS ---*
🚀 *SSH:* `{ssh_count}`
⚡ *VMess:* `{vmess_count}`
🛡️ *VLESS:* `{vless_count}`
🐎 *Trojan:* `{trojan_count}`
👻 *Shadowsocks:* `{ss_count}`
☄️ *Hysteria2:* `{hy2_count}`
"""
        bot.send_message(message.chat.id, status_msg, parse_mode="Markdown")
    except Exception as e:
        bot.send_message(message.chat.id, f"❌ *Error fetching status:* `{str(e)}`", parse_mode="Markdown")

print("Mr. X Telegram Bot is online and listening...")
bot.infinity_polling()
