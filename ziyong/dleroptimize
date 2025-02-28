
#!/bin/bash

# Time Synchronization
# Ensure system time is accurate for logs and synchronization
for pkg in ntpdate htpdate; do
    if ! which $pkg >/dev/null 2>&1; then
        apt install $pkg -y
    fi
done

# Set timezone and sync system time
timedatectl set-timezone Asia/Shanghai
timeout 5 ntpdate time1.google.com || timeout 5 htpdate -s www.baidu.com
hwclock -w

# Entropy Pool Management
# Ensure sufficient entropy for cryptographic operations
entropy=$(< /proc/sys/kernel/random/entropy_avail)
if [ $entropy -lt "1000" ] && ! systemctl is-active --quiet haveged; then
    apt install haveged -y
    systemctl enable haveged
    systemctl restart haveged
fi

# File Descriptor Limit
# Increase the maximum number of file handles
echo "1048576" > /proc/sys/fs/file-max
ulimit -n 1048576

# Kernel parameter optimization
chattr -i /etc/sysctl.conf
cat > /etc/sysctl.conf << EOF
# Memory usage
# Optimize memory usage for high throughput on public networks
vm.swappiness = 10
vm.dirty_ratio = 20
vm.dirty_background_ratio = 5
vm.overcommit_memory = 1

# File descriptor limits
fs.file-max = 1048576

# TCP/UDP buffer settings for large traffic
net.core.netdev_max_backlog = 65536
net.core.somaxconn = 32768
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.optmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384

# TCP connection management
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_keepalive_time = 120
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2

# TCP advanced settings
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_rfc1337 = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_congestion_control = bbr

# ICMP Settings
# Disable ICMP for security and to prevent unnecessary overhead
net.ipv4.icmp_echo_ignore_all = 1
# net.ipv6.icmp.echo_ignore_all = 1

# IPv4 routing
net.ipv4.ip_forward = 1
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.send_redirects = 0

# IPv6 settings
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.forwarding = 1
net.ipv6.conf.all.forwarding = 1

# Path MTU Discovery
net.ipv4.ip_no_pmtu_disc = 0
net.ipv4.tcp_mtu_probing = 1

# Port Range
net.ipv4.ip_local_port_range = 1024 65535

# Connection Backlog
net.core.somaxconn = 32768

# TCP auxiliary settings
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_fastopen = 3
EOF

# Apply kernel parameters
sysctl -p

# Security limits configuration
cat > /etc/security/limits.conf << EOF
# File descriptor limits
* soft nofile 2097152
* hard nofile 2097152

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
root soft nofile 2097152
root hard nofile 2097152
root soft nproc 65535
root hard nproc 65535
root soft memlock unlimited
root hard memlock unlimited
root soft core unlimited
root hard core unlimited
EOF

# Apply security limits
ulimit -n 1048576
ulimit -u 65535
ulimit -l unlimited
ulimit -c unlimited

echo "Script finished at $(date)"
