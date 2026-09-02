#!/bin/bash

# ============================================
# RECON SCRIPT - MULTIPLE TARGET
# Creator : Ekacsetyawan
# GitHub  : https://github.com/ekacs
# Usage: ./recon.sh target1 [target2 ...]
# ============================================

# CEK ARGUMEN
if [ $# -eq 0 ]; then
    echo "❌ ERROR: Tidak ada target!"
    echo ""
    echo "Cara pakai:"
    echo "  ./recon.sh target1 [target2 target3 ...]"
    echo ""
    echo "Contoh:"
    echo "  ./recon.sh itjen.kemenhub.go.id"
    echo "  ./recon.sh itjen.kemenhub.go.id kemenhub.go.id"
    exit 1
fi

echo "========================================="
echo "  RECON - MULTI TARGET"
echo " Creator : Ekacsetyawan"
echo " GitHub  : https://github.com/ekacs"
echo "  Started: $(date '+%H:%M:%S')"
echo "  Output: $(pwd)"
echo "========================================="
echo ""

# Proses setiap target
for target in "$@"; do
    target_clean=$(echo "$target" | sed 's/\./_/g')
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🎯 TARGET: $target"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 1. Subfinder
    echo "[1/3] Subfinder ..."
    subfinder -d "$target" -silent > "subs-${target_clean}.txt" 2>/dev/null
    count=$(wc -l < "subs-${target_clean}.txt" 2>/dev/null || echo "0")
    echo "  ✅ Found $count subdomains"
    
    # 2. crt.sh
    echo "[2/3] crt.sh ..."
    curl -s "https://crt.sh/?q=%25.$target&output=json" --max-time 120 \
      | jq -r '.[].name_value' 2>/dev/null | sed 's/\*\.//g' | tr 'A-Z' 'a-z' | sort -u >> "subs-${target_clean}.txt"
    echo "  ✅ Data added"
    
    # 3. Merge & Sort
    echo "[3/3] Processing ..."
    sort -u "subs-${target_clean}.txt" | grep -v '^$' > "all-${target_clean}.txt"
    total=$(wc -l < "all-${target_clean}.txt")
    
    echo ""
    echo "  ✅ Total: $total subdomains"
    echo "  📁 File: all-${target_clean}.txt"
    
    # Preview
    if [ "$total" -gt 0 ]; then
        echo ""
        echo "  Preview:"
        head -5 "all-${target_clean}.txt" | sed 's/^/    • /'
        if [ "$total" -gt 5 ]; then
            echo "    ... and $((total - 5)) more"
        fi
    fi
done

echo ""
echo "========================================="
echo "  ✅ COMPLETED!"
echo "  Total target: $#"
echo "  Finished: $(date '+%H:%M:%S')"
echo "========================================="
