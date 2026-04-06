#!/bin/bash

@gitafauzun
# --- 1. YAPILANDIRMA ---
NETWORK_BLOCK="192.168.1.0/24"
REAL_USER=${SUDO_USER:-$USER}
REPORT_DIR="../reports"
REPORT_MD="$REPORT_DIR/audit_$(date +%F).md"
REPORT_HTML="$REPORT_DIR/audit_$(date +%F).html"
SCAN_DATA="/tmp/nmap_raw.txt"
START_TIME=$(date +%s)

# ---  RENK PALETİ (High Contrast) ---
CYAN='\033[1;36m' ; GREEN='\033[1;32m' ; YELLOW='\033[1;33m' 
PURPLE='\033[1;35m' ; WHITE='\033[1;37m' ; RED='\033[1;31m' ; NC='\033[0m'

# --- 3. YETKİ VE TEMİZLİK ---
cleanup() {
    sudo chown -R $REAL_USER:$REAL_USER $REPORT_DIR
    sudo chmod -R 755 $REPORT_DIR
    rm -f $SCAN_DATA
}
trap cleanup EXIT

clear
echo -e "${CYAN}======================================================"
echo -e "System-Network Checker"
echo -e "======================================================${NC}"

# Nmap taraması 
sudo nmap -sn $NETWORK_BLOCK -oG $SCAN_DATA > /dev/null

echo -e "# Sistem Envanter Raporu - $(date +%F)\n" > $REPORT_MD
echo "| IP Adresi | Hostname | Durum | Donanım / Üretici | Servis Rolü |" >> $REPORT_MD
echo "|-----------|----------|--------|-------------------|-------------|" >> $REPORT_MD

UP_COUNT=0 ; DOWN_COUNT=0
PREFIX=$(echo $NETWORK_BLOCK | cut -d. -f1-3)

for i in {1..254}; do
    ip="$PREFIX.$i"
    echo -ne "${WHITE}Analyzing Infrastructure: $ip${NC}\r"

    if grep -q "$ip.*Up" $SCAN_DATA; then
        ((UP_COUNT++))
        
        # 1. Hostname Çözümleme (DNS Check)
        HNAME=$(dig +short -x $ip | sed 's/\.$//')
        [[ -z "$HNAME" ]] && HNAME="No-DNS-Record"

        # 2. Üretici ve Gecikme
        LATENCY=$(grep "$ip" $SCAN_DATA | awk '{print $NF}' | tr -d '()')
        VENDOR=$(sudo nmap -sn $ip | grep "MAC Address" | cut -d'(' -f2 | tr -d ')' || echo "System/Virtual")

        # 3. Sistem Rolü Belirleme
        ROLE="Generic Host"
        PORTS=$(nmap -Pn -F $ip | grep "open" | awk '{print $1}' | paste -sd "," -)
        
        if [[ "$ip" == *".1" ]]; then ROLE="🛡️ Gateway/Router";
        elif [[ $PORTS == *"53/"* ]]; then ROLE="🔍 Domain Controller (DNS)";
        elif [[ $PORTS == *"445/"* ]]; then ROLE="📁 File Server (SMB)";
        elif [[ $PORTS == *"80/"* || $PORTS == *"443/"* ]]; then ROLE="🌐 Web Infrastructure";
        elif [[ $PORTS == *"22/"* ]]; then ROLE="🐧 Linux Management (SSH)";
        elif [[ $PORTS == *"3389/"* ]]; then ROLE="🖥️ Remote Desktop (RDP)";
        fi

        echo -e "${GREEN}[UP]${NC} ${WHITE}$ip${NC} | ${YELLOW}$ROLE${NC} | ${PURPLE}$LATENCY${NC}"
        echo "| $ip | $HNAME | ONLINE | $VENDOR | $ROLE |" >> $REPORT_MD
    else
        ((DOWN_COUNT++))
        echo "| $ip | - | OFFLINE | - | - |" >> $REPORT_MD
    fi
done

# --- 4. HTML (SYSTEM ADMIN DASHBOARD) ---
cat <<EOF > $REPORT_HTML
<!DOCTYPE html>
<html>
<head>
    <title>System Admin Inventory</title>
    <style>
        body { font-family: 'Inter', system-ui; background: #0d1117; color: #c9d1d9; padding: 25px; }
        .dashboard { max-width: 1200px; margin: auto; }
        .header { border-bottom: 2px solid #30363d; padding-bottom: 15px; margin-bottom: 25px; display: flex; justify-content: space-between; align-items: center; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .card { background: #161b22; padding: 20px; border-radius: 12px; border: 1px solid #30363d; text-align: center; }
        .card h2 { margin: 0; color: #58a6ff; font-size: 2.5rem; }
        .card p { margin: 10px 0 0; color: #8b949e; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; background: #161b22; border-radius: 12px; overflow: hidden; }
        th { background: #21262d; color: #58a6ff; padding: 15px; text-align: left; }
        td { padding: 12px 15px; border-bottom: 1px solid #30363d; }
        .status-up { color: #3fb950; background: rgba(63,185,80,0.1); padding: 4px 12px; border-radius: 6px; font-weight: bold; }
        .status-down { color: #f85149; opacity: 0.6; }
        .role-badge { color: #d2a8ff; font-family: monospace; }
        tr:hover { background: #1c2128; }
    </style>
</head>
<body>
    <div class="dashboard">
        <div class="header">
            <h1>📊 System Asset Management</h1>
            <span>$(date)</span>
        </div>
        <div class="stats">
            <div class="card" style="border-bottom: 4px solid #3fb950;"><h2>$UP_COUNT</h2><p>Aktif Node</p></div>
            <div class="card" style="border-bottom: 4px solid #f85149;"><h2>$DOWN_COUNT</h2><p>Pasif / Rezerve</p></div>
            <div class="card" style="border-bottom: 4px solid #58a6ff;"><h2>$NETWORK_BLOCK</h2><p>Subnet</p></div>
        </div>
        <table>
            <thead><tr><th>IP Adresi</th><th>Hostname</th><th>Durum</th><th>Üretici / HW</th><th>Sistem Rolü</th></tr></thead>
            <tbody>
                $(cat $REPORT_MD | grep "|" | grep -v "IP Adresi" | grep -v "\-\-\-" | \
                sed 's/ONLINE/<span class="status-up">ONLINE<\/span>/g' | \
                sed 's/OFFLINE/<span class="status-down">OFFLINE<\/span>/g' | \
                sed 's/^|/<tr><td>/' | sed 's/|/<\/td><td>/g' | sed 's/$/<\/td><\/tr>/')
            </tbody>
        </table>
    </div>
</body>
</html>
EOF

DURATION=$(( $(date +%s) - START_TIME ))
echo -e "\n${CYAN}======================================================"
echo -e " ${WHITE}KONTROL TAMAMLANDI | SÜRE: $DURATION SN"
echo -e " RAPOR: ${YELLOW}$REPORT_HTML${NC}"
echo -e "======================================================"
