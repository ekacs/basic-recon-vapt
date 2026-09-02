#!/bin/bash

# ============================================
# SENSITIVE FILE CHECKER
# Creator : Ekacsetyawan
# GitHub  : https://github.com/ekacsetyawan
# Usage  : ./check-sensitive.sh target.com
# ============================================

# CEK ARGUMEN
if [ $# -eq 0 ]; then
    echo "❌ ERROR: Tidak ada target!"
    echo ""
    echo "Cara pakai:"
    echo "  ./check-sensitive.sh target.com"
    echo ""
    echo "Contoh:"
    echo "  ./check-sensitive.sh itjen.kemenhub.go.id"
    exit 1
fi

TARGET=$1

# Daftar path sensitif
paths=(
    "robots.txt"
    "readme.html"
    "license.txt"
    "wp-json/"
    "wp-json/wp/v2/users"
    "xmlrpc.php"
    "wp-login.php"
    ".env"
    ".git/config"
    "wp-content/debug.log"
    "wp-config.php.bak"
    ".htaccess"
    ".htpasswd"
    "sitemap.xml"
    "phpinfo.php"
    "backup.zip"
    "admin/"
    "login/"
)

echo "========================================="
echo "  SENSITIVE FILE CHECKER"
echo "  Creator : Ekacsetyawan"
echo "  Target  : $TARGET"
echo "  Started : $(date '+%H:%M:%S')"
echo "========================================="
echo ""

for path in "${paths[@]}"; do
    url="https://$TARGET/$path"
    
    # Cek status dengan curl
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 "$url")
    size=$(curl -s -o /dev/null -w "%{size_download}" --max-time 15 "$url")
    
    # Tampilkan dengan warna berdasarkan status
    if [ "$response" = "200" ]; then
        echo -e "  ✅ /$path -> HTTP $response (Size: $size bytes) [FOUND]"
    elif [ "$response" = "301" ] || [ "$response" = "302" ]; then
        echo -e "  🔄 /$path -> HTTP $response (Redirect)"
    elif [ "$response" = "403" ]; then
        echo -e "  🔒 /$path -> HTTP $response (Forbidden)"
    elif [ "$response" = "404" ]; then
        echo -e "  ❌ /$path -> HTTP $response (Not Found)"
    else
        echo -e "  ⚠️  /$path -> HTTP $response"
    fi
done

echo ""
echo "========================================="
echo "  ✅ COMPLETED!"
echo "  Creator : Ekacsetyawan"
echo "	github	: github.com/ekacs"
echo "  Finished: $(date '+%H:%M:%S')"
echo "========================================="
