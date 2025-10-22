#!/bin/bash
# ------------------------------------------------------------
# Block China IPs (geoip:cn) from accessing one or more ports
# For Debian 12/13, Ubuntu 22+, with nftables
# ------------------------------------------------------------

set -e

echo "=== [1] Enter ports to block for China IPs (comma separated) ==="
read -p "Ports (e.g. 8388,8443): " PORTS

if [[ -z "$PORTS" ]]; then
    echo "❌ Ports cannot be empty."
    exit 1
fi

# Normalize port list (remove spaces)
PORTS=$(echo "$PORTS" | tr -d ' ')

echo "=== [2] Installing nftables if missing ==="
apt update -y >/dev/null 2>&1
apt install -y nftables wget >/dev/null 2>&1
systemctl enable nftables --now >/dev/null 2>&1

echo "=== [3] Downloading China IP list ==="
CN_LIST="/etc/nftables_china_ip_list.txt"
wget -O "$CN_LIST" https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt

echo "=== [4] Creating nftables config ==="
CONFIG="/etc/nftables.conf"

cat > "$CONFIG" <<EOF
#!/usr/sbin/nft -f
flush ruleset

table inet filter {
    set cnip {
        type ipv4_addr
        flags interval
    }

    chain input {
        type filter hook input priority 0;

        # Allow existing and localhost
        ct state established,related accept
        iif lo accept
EOF

# Add blocking rules for each port
IFS=',' read -ra PORT_ARRAY <<< "$PORTS"
for port in "${PORT_ARRAY[@]}"; do
cat >> "$CONFIG" <<EOF
        ip saddr @cnip tcp dport $port drop
        ip saddr @cnip udp dport $port drop
EOF
done

cat >> "$CONFIG" <<EOF
        accept
    }
}
EOF

echo "=== [5] Applying nftables rules ==="
nft -f "$CONFIG"

echo "=== [6] Importing China IP list (fast mode) ==="
{
    echo "flush set inet filter cnip"
    echo "add element inet filter cnip {"
    sed 's/$/,/' "$CN_LIST"
    echo "}"
} | nft -f -

echo "=== [7] Saving rules persistently ==="
nft list ruleset > "$CONFIG"

echo "=== [8] Creating update script ==="
UPDATE_SCRIPT="/usr/local/bin/update-cnip.sh"
cat > "$UPDATE_SCRIPT" <<'EOF'
#!/bin/bash
CN_LIST="/etc/nftables_china_ip_list.txt"
wget -O "$CN_LIST" https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt
{
    echo "flush set inet filter cnip"
    echo "add element inet filter cnip {"
    sed 's/$/,/' "$CN_LIST"
    echo "}"
} | nft -f -
echo "China IP list updated at $(date)"
EOF
chmod +x "$UPDATE_SCRIPT"

echo "=== [9] Adding weekly cron job ==="
(crontab -l 2>/dev/null; echo "@weekly /usr/local/bin/update-cnip.sh >/dev/null 2>&1") | crontab -

echo ""
echo "✅ Done!"
echo "China IPs are now blocked from accessing port(s): $PORTS"
echo "💾 Rules saved in: /etc/nftables.conf"
echo "🔁 Auto-update script: /usr/local/bin/update-cnip.sh"
echo "🕒 Weekly update scheduled via cron"
echo ""
