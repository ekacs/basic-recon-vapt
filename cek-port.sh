#!/bin/bash

# ============================================
# NAABU SCANNER + SERVICE INFO (MINIMAL + WAF)
# Creator : Ekacsetyawan
# GitHub  : https://github.com/ekacs
# Version : 1.1
# Usage  : ./naabu-scan.sh target1 [target2 ...]
# ============================================

# CEK ARGUMEN
if [ $# -eq 0 ]; then
    echo "❌ ERROR: Tidak ada target!"
    echo ""
    echo "Cara pakai:"
    echo "  ./naabu-scan.sh target1 [target2 target3 ...]"
    echo ""
    echo "Contoh:"
    echo "  ./naabu-scan.sh 202.61.105.59"
    echo "  ./naabu-scan.sh 202.61.105.59 192.168.1.1"
    exit 1
fi

# Daftar port spesifik
PORTS="22,25,53,80,110,143,389,443,465,587,993,995,3306,5432,6379,8080,8443,9000,9090"

echo "========================================="
echo "  NAABU SCANNER + SERVICE INFO + WAF"
echo "  Creator : Ekacsetyawan"
echo "  GitHub  : https://github.com/ekacs"
echo "  Started : $(date '+%H:%M:%S')"
echo "  Output  : $(pwd)"
echo "========================================="
echo ""

for TARGET in "$@"; do
    target_clean=$(echo "$TARGET" | sed 's/\./_/g')
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🎯 TARGET: $TARGET"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 1. Port Scan
    echo "[1/4] Scanning ports..."
    sudo naabu -host "$TARGET" -p "$PORTS" -silent -o "naabu-ports-${target_clean}.txt" 2>/dev/null
    
    if [ -s "naabu-ports-${target_clean}.txt" ]; then
        count=$(wc -l < "naabu-ports-${target_clean}.txt")
        echo "  ✅ Found $count ports"
    else
        echo "  ❌ No open ports"
        touch "naabu-ports-${target_clean}.txt"
    fi
    
    # 2. Version Scan
    echo "[2/4] Version detection..."
    if [ -s "naabu-ports-${target_clean}.txt" ]; then
        open_ports=$(cat "naabu-ports-${target_clean}.txt" | awk -F':' '{print $2}' | tr '\n' ',' | sed 's/,$//')
        sudo nmap -Pn -sV -T4 -p "$open_ports" "$TARGET" 2>&1 > "nmap-version-${target_clean}.txt"
        echo "  ✅ Version scan selesai"
    else
        touch "nmap-version-${target_clean}.txt"
    fi
    
    # 3. Service Info (Load Balancer, WAF, Server)
    echo "[3/4] Service info & load balancer detection..."
    if [ -s "naabu-ports-${target_clean}.txt" ]; then
        # HTTP ports
        http_ports=$(cat "naabu-ports-${target_clean}.txt" | awk -F':' '$2 ~ /^(80|443|8080|8443|9000|9090)$/ {print $2}' | tr '\n' ',' | sed 's/,$//')
        
        if [ ! -z "$http_ports" ]; then
            echo "  🌐 HTTP ports: $http_ports"
            sudo nmap -Pn -T4 -p "$http_ports" --script=http-headers,http-title,http-server-header,http-waf-detect "$TARGET" 2>&1 > "nmap-serviceinfo-${target_clean}.txt"
            echo "  ✅ Service info selesai"
            
            # Tampilkan hasil
            echo ""
            echo "  📋 Service Info Summary:"
            grep -i "Server:" "nmap-serviceinfo-${target_clean}.txt" | head -1 | sed 's/.*Server: //' | sed 's/|.*//' | xargs | sed 's/^/    • Server: /'
            grep -i "Title:" "nmap-serviceinfo-${target_clean}.txt" | head -1 | sed 's/.*Title: //' | sed 's/|.*//' | xargs | sed 's/^/    • Title: /'
            grep -i "load balancer\|LB\|haproxy\|nginx\|varnish\|cloudflare\|akamai" "nmap-serviceinfo-${target_clean}.txt" | head -1 | xargs | sed 's/^/    • Detected: /'
            grep -i "WAF" "nmap-serviceinfo-${target_clean}.txt" | head -1 | xargs | sed 's/^/    • WAF: /'
        else
            echo "  ⚠️  No HTTP ports, skip service info"
            touch "nmap-serviceinfo-${target_clean}.txt"
        fi
    else
        touch "nmap-serviceinfo-${target_clean}.txt"
    fi
    
    # ============================================
    # 4. WAF DETECTION dengan wafw00f (TAMBAHAN)
    # ============================================
    
    echo "[4/4] WAF Detection with wafw00f..."
    
    # Cek apakah wafw00f terinstall
    if command -v wafw00f &> /dev/null; then
        echo "  🔍 Running wafw00f..."
        
        # Cek apakah ada HTTP/HTTPS port
        if [ -s "naabu-ports-${target_clean}.txt" ]; then
            http_ports=$(cat "naabu-ports-${target_clean}.txt" | awk -F':' '$2 ~ /^(80|443|8080|8443|9000|9090)$/ {print $2}' | tr '\n' ',' | sed 's/,$//')
            
            if [ ! -z "$http_ports" ]; then
                # Deteksi WAF dengan wafw00f
                echo ""
                echo "  🛡️  WAF Detection Result:"
                
                # Tentukan protocol (http/https)
                if [[ "$http_ports" == *"443"* ]] || [[ "$http_ports" == *"8443"* ]]; then
                    PROTOCOL="https"
                else
                    PROTOCOL="http"
                fi
                
                # Jalankan wafw00f
                wafw00f "$PROTOCOL://$TARGET" 2>&1 | tee -a "nmap-serviceinfo-${target_clean}.txt" | grep -E "\[+\]|WAF|Cloudflare|Akamai|AWS|ModSecurity|Sucuri|Wordfence|Barracuda|F5|Imperva|Incapsula"
                
                echo ""
                echo "  ✅ WAF detection selesai"
                echo "  📁 Hasil ditambahkan ke: nmap-serviceinfo-${target_clean}.txt"
            else
                echo "  ⚠️  No HTTP/HTTPS ports, skipping wafw00f"
            fi
        fi
    else
        echo "  ⚠️  wafw00f tidak terinstall"
        echo "  💡 Install dengan: pip3 install wafw00f"
        echo "  💡 Atau: sudo apt install wafw00f -y"
    fi
    
    echo ""
    echo "  ✅ Selesai untuk: $TARGET"
    echo "  📁 Files:"
    echo "     • naabu-ports-${target_clean}.txt"
    echo "     • nmap-version-${target_clean}.txt"
    echo "     • nmap-serviceinfo-${target_clean}.txt"
    echo ""
done

echo "========================================="
echo "  ✅ COMPLETED!"
echo "  Creator : Ekacsetyawan"
echo "  GitHub  : https://github.com/ekacs"
echo "  Total target: $#"
echo "  Finished: $(date '+%H:%M:%S')"
echo "========================================="
