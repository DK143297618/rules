#!/bin/bash

# 检查是否以 root 权限运行
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以 root 权限运行，请使用 sudo 或切换到 root 用户"
    exit 1
fi

echo "开始卸载 Tailscale..."

# 停止 Tailscale 服务
if systemctl is-active --quiet tailscale; then
    echo "正在停止 Tailscale 服务..."
    systemctl stop tailscale
fi

# 禁用 Tailscale 服务
if systemctl is-enabled --quiet tailscale; then
    echo "正在禁用 Tailscale 服务..."
    systemctl disable tailscale
fi

# 卸载 Tailscale 软件包
if dpkg -l | grep -q tailscale; then
    echo "正在卸载 Tailscale 软件包..."
    apt-get purge -y tailscale
    apt-get autoremove -y
    apt-get autoclean
else
    echo "未找到 Tailscale 软件包，可能已卸载"
fi

# 删除 Tailscale 配置文件和数据
if [ -d "/var/lib/tailscale" ]; then
    echo "正在删除 Tailscale 数据目录..."
    rm -rf /var/lib/tailscale
fi

if [ -d "/etc/tailscale" ]; then
    echo "正在删除 Tailscale 配置文件..."
    rm -rf /etc/tailscale
fi

# 检查是否卸载成功
if ! command -v tailscale >/dev/null 2>&1; then
    echo "Tailscale 已成功卸载"
else
    echo "卸载过程中可能出现问题，请手动检查"
fi

exit 0
