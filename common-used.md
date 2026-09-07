
# Subdomain enumeration

- subfinder -d target.com -o subdomains.txt

- assetfinder --subs-only target.com >> subdomains.txt

- /usr/lib/amass/amass enum -passive -d target.com > subdomains.txt

- sort -u subdomains.txt -o subdomains.txt

# Technology detection

wappalyzer https://target.com > ./folder/target.com/wappalyzer.txt
whatweb https://target.com -v > ./folder/target.com/whatweb.txt

# Live host discovery and port scanning

cat ./folder/target.com/subdomains.txt | httpx -silent -title -status-code > ./folder/target.com/live-hosts.txt
nmap -sV -sC -O -p- $(cat ./folder/target.com/live-hosts.txt | cut -d' ' -f1 | sort -u) -o ./folder/target.com/nmap-scan.txt

# Directory discovery

gobuster dir -u https://target.com -w /usr/share/wordlists/dirb/common.txt -t 50 -q > ./folder/target.com/gobuster.txt

# API discovery

katana -u https://target.com -d 3 -jc -kf all -silent > ./folder/target.com/katana.txt

# Secret scanning

trufflehog filesystem --directory ./folder/target.com --no-update --json > ./folder/target.com/trufflehog-secrets.txt

# Vulnerability scanning

nuclei -l ./folder/target.com/live-hosts.txt -t /root/nuclei-templates/ -severity critical,high,medium > ./folder/target.com/nuclei-results.txt

This template provides a comprehensive reconnaissance plan for target.com. The commands will generate detailed output files in the ./folder/target.com/ directory.
