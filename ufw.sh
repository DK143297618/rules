#!/bin/bash
# 安装 UFW + 自动放行 SSH + 开机自启 + 守护服务

# 自动读取 SSH 端口
SSH_PORT=$(grep -E "^Port " /etc/ssh/sshd_config | awk '{print $2}')
SSH_PORT=${SSH_PORT:-22}
echo "检测到 SSH 端口为: $SSH_PORT"

echo "[1/3] 安装 UFW"
sudo apt update
sudo apt install -y ufw

echo "[2/3] 设置 UFW 开机启用并放行 SSH"
sudo sed -i 's/ENABLED=no/ENABLED=yes/' /etc/ufw/ufw.conf
sudo ufw allow $SSH_PORT/tcp
sudo systemctl enable ufw
sudo systemctl start ufw
sudo ufw --force enable
sudo ufw status verbose

echo "[3/3] 创建 systemd 守护服务"
sudo tee /etc/systemd/system/ufw-watchdog.service > /dev/null <<'EOF'
[Unit]
Description=UFW watchdog service - ensure firewall always active
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash -c 'while true; do ufw status | grep -q "inactive" && ufw enable; sleep 60; done'
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now ufw-watchdog
sudo systemctl status ufw-watchdog --no-pager

echo "✅ UFW 安装完成，SSH 端口 $SSH_PORT 已放行，守护服务已启动"
