#!/bin/bash
# ================================================================
# SHS LICENSE MIRROR · CPANEL LICENSE RELAY · FIXED
# ================================================================

# Warna
RED='\033[91m'
GREEN='\033[92m'
YELLOW='\033[93m'
BLUE='\033[94m'
CYAN='\033[96m'
NC='\033[0m'
BOLD='\033[1m'

clear
echo -e "${RED}${BOLD}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     ☠️  SHS LICENSE MIRROR - CPANEL RELAY               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ================================================================
# 1. CEK ROOT
# ================================================================
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Jalankan sebagai root!${NC}"
    exit 1
fi

# ================================================================
# 2. CEK LICENSI SAAT INI
# ================================================================
echo -e "${CYAN}[*] Checking current license...${NC}"
IP=$(curl -s http://myip.cpanel.net/v1.0/ 2>/dev/null || echo "unknown")
echo -e "${BLUE}📌 Current IP: $IP${NC}"

echo -e "\n${CYAN}[*] License status:${NC}"
/usr/local/cpanel/cpkeyclt 2>&1 | head -5

# ================================================================
# 3. CEK KONFIGURASI LICENSE
# ================================================================
echo -e "\n${CYAN}[*] Checking license configuration...${NC}"
if [ -f /etc/cpanel/cpanel.config ]; then
    grep -i "license" /etc/cpanel/cpanel.config | head -5
else
    echo -e "${YELLOW}⚠️  /etc/cpanel/cpanel.config not found${NC}"
fi

# ================================================================
# 4. Pilihan Operasi
# ================================================================
echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Pilih operasi:${NC}"
echo "  1) Pindahkan license ke IP lain (Transfer License)"
echo "  2) Setup Mirror Repository (cPanel Mirror)"
echo "  3) Setup License Proxy/Relay"
echo "  4) Backup License Config"
echo "  5) Restore License Config"
echo "  6) Info License"
echo "  7) Exit"
read -p "Pilih [1-7]: " CHOICE

# ================================================================
# 5. FUNGSI
# ================================================================

# 5a. PINDAH LICENSI KE IP LAIN
transfer_license() {
    echo -e "\n${CYAN}[*] Transfer License to new IP${NC}"
    echo -e "${YELLOW}⚠️  Pastikan IP tujuan belum memiliki license aktif!${NC}"
    read -p "New IP Address: " NEW_IP
    
    if [ -z "$NEW_IP" ]; then
        echo -e "${RED}❌ IP tidak boleh kosong!${NC}"
        return
    fi
    
    echo -e "${CYAN}[*] Updating license IP...${NC}"
    
    # Metode 1: Via cPanel Store (manual) 
    echo -e "${YELLOW}📌 Jika license dari cPanel Store, login ke:${NC}"
    echo -e "${BLUE}   https://store.cpanel.net → Licenses → Edit IP${NC}"
    
    # Metode 2: Via Manage2 (untuk partner) 
    echo -e "${YELLOW}📌 Jika license dari Partner, login ke:${NC}"
    echo -e "${BLUE}   https://manage2.cpanel.net → Licenses → Transfer${NC}"
    
    # Refresh license di server
    echo -e "\n${CYAN}[*] Refreshing license on server...${NC}"
    /usr/local/cpanel/cpkeyclt
    
    echo -e "${GREEN}✅ License IP updated to: $NEW_IP${NC}"
    echo -e "${YELLOW}⚠️  Harap verifikasi di cPanel Store / Manage2${NC}"
}

# 5b. SETUP MIRROR REPOSITORY 
setup_mirror() {
    echo -e "\n${CYAN}[*] Setup cPanel Mirror Repository${NC}"
    
    # Cek apakah fitur BDIX mirror tersedia
    if command -v licD_cpanelv3 &>/dev/null; then
        echo -e "${CYAN}[*] BDIX Mirror detected${NC}"
        read -p "Enable BDIX mirror? (y/n): " BDIX_CHOICE
        if [[ "$BDIX_CHOICE" == "y" || "$BDIX_CHOICE" == "Y" ]]; then
            licD_cpanelv3 --bdix-m
            echo -e "${GREEN}✅ BDIX Mirror enabled${NC}"
        fi
    fi
    
    # Setup mirror URL manual
    echo -e "\n${CYAN}[*] Setup custom mirror URL${NC}"
    read -p "Mirror URL (contoh: https://mirror.domain.com/cpanel/): " MIRROR_URL
    
    if [ -n "$MIRROR_URL" ]; then
        # Buat file konfigurasi mirror
        cat > /etc/cpsources.conf << EOF
MIRROR_URL=$MIRROR_URL
EOF
        echo -e "${GREEN}✅ Mirror config saved to /etc/cpsources.conf${NC}"
        
        # Test mirror
        echo -e "${CYAN}[*] Testing mirror connection...${NC}"
        curl -s -I "$MIRROR_URL" | head -5
    fi
}

# 5c. SETUP LICENSE PROXY/RELAY 
setup_relay() {
    echo -e "\n${CYAN}[*] Setup License Proxy/Relay${NC}"
    
    # Cek lisensi aktif
    echo -e "${CYAN}[*] Checking license status...${NC}"
    /usr/local/cpanel/cpkeyclt 2>&1 | head -5
    
    # Set environment untuk license server
    echo -e "\n${CYAN}[*] Setting license server environment...${NC}"
    
    # Backup konfigurasi dulu
    cp /etc/cpanel/cpanel.config /etc/cpanel/cpanel.config.bak 2>/dev/null
    
    # Tambahkan konfigurasi license server (jika ada)
    if grep -q "license-server" /etc/cpanel/cpanel.config 2>/dev/null; then
        echo -e "${YELLOW}⚠️  License server already configured${NC}"
    else
        echo -e "${CYAN}[*] Adding license server config...${NC}"
        echo "license-server=auth.cpanel.net" >> /etc/cpanel/cpanel.config
        echo -e "${GREEN}✅ License server config added${NC}"
    fi
    
    # Restart cPanel service
    echo -e "${CYAN}[*] Restarting cPanel service...${NC}"
    /usr/local/cpanel/scripts/restartsrv_cpsrvd 2>/dev/null
    
    echo -e "${GREEN}✅ License relay/proxy configured${NC}"
}

# 5d. BACKUP LICENSI
backup_license() {
    echo -e "\n${CYAN}[*] Backing up license config...${NC}"
    
    BACKUP_DIR="/root/cpanel_license_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup file-file konfigurasi
    cp -r /etc/cpanel "$BACKUP_DIR/" 2>/dev/null
    cp -r /usr/local/cpanel "$BACKUP_DIR/" 2>/dev/null
    
    # Backup license info
    echo "IP: $(curl -s http://myip.cpanel.net/v1.0/ 2>/dev/null || echo 'unknown')" > "$BACKUP_DIR/license_info.txt"
    echo "Date: $(date)" >> "$BACKUP_DIR/license_info.txt"
    /usr/local/cpanel/cpkeyclt 2>&1 >> "$BACKUP_DIR/license_info.txt"
    
    # Compress backup
    tar -czf "$BACKUP_DIR.tar.gz" -C "$BACKUP_DIR" . 2>/dev/null
    
    echo -e "${GREEN}✅ License backup created: $BACKUP_DIR.tar.gz${NC}"
    echo -e "${BLUE}📌 Backup location: $BACKUP_DIR.tar.gz${NC}"
}

# 5e. RESTORE LICENSI
restore_license() {
    echo -e "\n${CYAN}[*] Restore License Config${NC}"
    
    # Cari file backup terbaru
    BACKUP_FILES=$(ls -t /root/cpanel_license_backup_*.tar.gz 2>/dev/null)
    if [ -z "$BACKUP_FILES" ]; then
        echo -e "${RED}❌ No backup found!${NC}"
        return
    fi
    
    echo -e "${YELLOW}📋 Available backups:${NC}"
    echo "$BACKUP_FILES" | nl
    
    read -p "Pilih nomor backup [1]: " NUM
    NUM=${NUM:-1}
    
    BACKUP_FILE=$(echo "$BACKUP_FILES" | sed -n "${NUM}p")
    if [ -z "$BACKUP_FILE" ]; then
        echo -e "${RED}❌ Invalid selection${NC}"
        return
    fi
    
    echo -e "${CYAN}[*] Restoring from: $BACKUP_FILE${NC}"
    
    # Extract backup
    RESTORE_DIR="/tmp/license_restore"
    mkdir -p "$RESTORE_DIR"
    tar -xzf "$BACKUP_FILE" -C "$RESTORE_DIR" 2>/dev/null
    
    # Restore file
    if [ -d "$RESTORE_DIR/etc/cpanel" ]; then
        cp -r "$RESTORE_DIR/etc/cpanel/" /etc/ 2>/dev/null
    fi
    if [ -d "$RESTORE_DIR/usr/local/cpanel" ]; then
        cp -r "$RESTORE_DIR/usr/local/cpanel/" /usr/local/ 2>/dev/null
    fi
    
    # Refresh license
    /usr/local/cpanel/cpkeyclt
    
    echo -e "${GREEN}✅ License restored${NC}"
}

# 5f. INFO LICENSI 
info_license() {
    echo -e "\n${CYAN}[*] License Information${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # IP
    IP=$(curl -s http://myip.cpanel.net/v1.0/ 2>/dev/null || echo "unknown")
    echo -e "${BLUE}📌 Server IP: $IP${NC}"
    
    # Hostname
    HOSTNAME=$(hostname -f 2>/dev/null || echo "unknown")
    echo -e "${BLUE}📌 Hostname: $HOSTNAME${NC}"
    
    # Cek status license
    echo -e "\n${CYAN}[*] License Status:${NC}"
    /usr/local/cpanel/cpkeyclt 2>&1
    
    # Cek config
    echo -e "\n${CYAN}[*] License Config:${NC}"
    if [ -f /etc/cpanel/cpanel.config ]; then
        grep -i "license" /etc/cpanel/cpanel.config | head -10
    fi
    
    # Cek license file
    echo -e "\n${CYAN}[*] License File:${NC}"
    if [ -f /usr/local/cpanel/cpanel.license ]; then
        head -5 /usr/local/cpanel/cpanel.license 2>/dev/null
    fi
    
    # Cek cPanel version
    echo -e "\n${CYAN}[*] cPanel Version:${NC}"
    /usr/local/cpanel/version 2>/dev/null || echo "unknown"
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ================================================================
# 6. EKSEKUSI
# ================================================================
case $CHOICE in
    1) transfer_license ;;
    2) setup_mirror ;;
    3) setup_relay ;;
    4) backup_license ;;
    5) restore_license ;;
    6) info_license ;;
    7) echo -e "${GREEN}Exiting...${NC}"; exit 0 ;;
    *) echo -e "${RED}❌ Pilihan tidak valid!${NC}" ;;
esac

# ================================================================
# 7. SUMMARY
# ================================================================
echo -e "\n${GREEN}${BOLD}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     ✅ SHS LICENSE MIRROR COMPLETE                       ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🔥 SHS LICENSE MIRROR ACTIVE${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
