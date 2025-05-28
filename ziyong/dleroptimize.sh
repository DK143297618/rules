#!/bin/bash
set -e

# ===== Time Synchronization =====
if ! command -v chronyd >/dev/null 2>&1; then
    apt-get update && apt-get install -y chrony
fi
if ! systemctl is-active --quiet chronyd; then
    systemctl enable --now chronyd
fi
timedatectl set-timezone Asia/Shanghai 2>/dev/null || true

# ===== File Descriptor Limit =====
echo "1048576" > /proc/sys/fs/file-max
ulimit -n 1048576

# ===== Kernel Parameter Optimization =====
chattr -i /etc/sysctl.conf
cat > /etc/sysctl.conf << EOF
# ====== Memory Management ======
vm.swappiness = 5
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5

# ====== File Descriptor & Connection Limits ======
fs.file-max = 1048576
net.core.somaxconn = 32768
net.ipv4.tcp_max_syn_backlog = 65536

# ====== Network Buffer Tuning ======
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.optmem_max = 8388608
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 16384 67108864
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384
net.core.netdev_max_backlog = 65536

# ====== TCP Low-Latency Optimizations ======
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_adv_win_scale = 1

# ====== TCP Connection Management ======
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_synack_retries = 2

# ====== Protocol Stack Features ======
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_rfc1337 = 1

# ====== Routing & Forwarding ======
net.ipv4.ip_forward = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv6.conf.all.forwarding = 1

# ====== Security Hardening ======
net.ipv4.icmp_echo_ignore_all = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.send_redirects = 0
EOF

# Apply kernel parameters
sysctl -p

# ===== Security Limits Configuration =====
# Set user/process resource limits
cat > /etc/security/limits.conf << EOF
# File descriptor limits
* soft nofile 1048576
* hard nofile 1048576

# Process limits
* soft nproc 65535
* hard nproc 65535

# Memory locking
* soft memlock unlimited
* hard memlock unlimited

# Core dump size
* soft core unlimited
* hard core unlimited

# Root-specific limits
root soft nofile 1048576
root hard nofile 1048576
root soft nproc 65535
root hard nproc 65535
root soft memlock unlimited
root hard memlock unlimited
root soft core unlimited
root hard core unlimited
EOF

# Apply security limits
ulimit -n 1048576      # Open files
ulimit -u 65535        # User processes
ulimit -l unlimited    # Locked memory
ulimit -c unlimited    # Core dumps
