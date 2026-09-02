#!/bin/bash

# ============================================
# URL HARVESTING + STATUS 200 FILTER
# Creator : Ekacsetyawan
# GitHub  : https://github.com/ekacs
# Usage  : ./urls.sh target1 [target2 ...]
# ============================================

# CEK ARGUMEN
if [ $# -eq 0 ]; then
    echo "❌ ERROR: Tidak ada target!"
    echo ""
    echo "Cara pakai:"
    echo "  ./urls.sh target1 [target2 target3 ...]"
    echo ""
    echo "Contoh:"
    echo "  ./urls.sh itjen.kemenhub.go.id"
    echo "  ./urls.sh itjen.kemenhub.go.id kemenhub.go.id"
    exit 1
fi

echo "========================================="
echo "  URL HARVESTING + STATUS 200 FILTER"
echo "  Creator : Ekacsetyawan"
echo "  GitHub  : https://github.com/ekacs"
echo "  Started: $(date '+%H:%M:%S')"
echo "  Output : $(pwd)"
echo "========================================="
echo ""

# Proses setiap target
for target in "$@"; do
    target_clean=$(echo "$target" | sed 's/\./_/g')
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🎯 TARGET: $target"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 1. WaybackURLs
    echo "[1/4] WaybackURLs ..."
    echo "$target" | waybackurls > "wayback-${target_clean}.txt" 2>/dev/null
    wb_count=$(wc -l < "wayback-${target_clean}.txt" 2>/dev/null || echo "0")
    echo "  ✅ Found $wb_count URLs"
    
    # 2. GAU
    echo "[2/4] GAU ..."
    gau "$target" --subs > "gau-${target_clean}.txt" 2>/dev/null
    gau_count=$(wc -l < "gau-${target_clean}.txt" 2>/dev/null || echo "0")
    echo "  ✅ Found $gau_count URLs"
    
    # 3. Merge & Deduplikasi
    echo "[3/4] Merging & deduplicating ..."
    cat "wayback-${target_clean}.txt" "gau-${target_clean}.txt" 2>/dev/null | sort -u > "all-${target_clean}.txt"
    total=$(wc -l < "all-${target_clean}.txt")
    echo "  ✅ Total unique URLs: $total"
    
    # 4. Filter Status 200 dengan httpx
    echo "[4/4] Filtering status 200 with httpx ..."
    
    if [ -s "all-${target_clean}.txt" ]; then
        # Jalankan httpx untuk cek status
        cat "all-${target_clean}.txt" | httpx -silent -status-code -title -content-length -o "httpx-${target_clean}.txt" 2>/dev/null
        
        # Ambil hanya URL dengan status 200
        grep '\[200\]' "httpx-${target_clean}.txt" | cut -d' ' -f1 > "alive-${target_clean}.txt"
        
        # Hitung jumlah status 200
        alive_count=$(wc -l < "alive-${target_clean}.txt" 2>/dev/null || echo "0")
        echo "  ✅ Found $alive_count URLs with status 200"
    else
        echo "  ⚠️  No URLs to filter"
        touch "alive-${target_clean}.txt"
        alive_count=0
    fi
    
    # ============================================
    # HASIL
    # ============================================
    
    echo ""
    echo "  ✅ Selesai untuk target: $target"
    echo "  📁 File:"
    echo "     • all-${target_clean}.txt     : $total URLs (all)"
    echo "     • alive-${target_clean}.txt   : $alive_count URLs (status 200)"
    
    # Preview URL status 200
    if [ "$alive_count" -gt 0 ]; then
        echo ""
        echo "  Preview (5 URLs with status 200):"
        head -5 "alive-${target_clean}.txt" | sed 's/^/    • /'
        if [ "$alive_count" -gt 5 ]; then
            echo "    ... and $((alive_count - 5)) more"
        fi
    fi
done

echo ""
echo "========================================="
echo "  ✅ COMPLETED!"
echo "  Creator : Ekacsetyawan"
echo "  Total target: $#"
echo "  Finished: $(date '+%H:%M:%S')"
echo "========================================="
