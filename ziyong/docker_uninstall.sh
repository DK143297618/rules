#!/bin/bash

# 脚本目的：在 Debian 系统上完全卸载 Docker
# 适用环境：Debian 9（Stretch）及以上版本
# 注意事项：在执行前备份重要数据（如容器、镜像、卷）

set -e  # 遇到错误时退出

echo "开始卸载 Docker..."

# 1. 停止 Docker 服务
echo "停止 Docker 服务..."
sudo systemctl stop docker docker.socket || {
    echo "警告：无法停止 Docker 服务，可能已停止或未安装"
}

# 2. 卸载 Docker 相关软件包
echo "卸载 Docker 软件包..."
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras 2>/dev/null || {
    echo "警告：部分软件包可能未安装，继续执行..."
}

# 3. 删除 Docker 数据和配置文件
echo "删除 Docker 数据和配置文件..."
sudo rm -rf /var/lib/docker /var/lib/containerd /etc/docker /var/run/docker.sock || {
    echo "警告：部分文件或目录可能不存在，继续执行..."
}

# 4. 删除 Docker 用户组（如果存在）
echo "删除 Docker 用户组..."
if getent group docker >/dev/null; then
    sudo groupdel docker || {
        echo "警告：无法删除 Docker 用户组，可能仍在使用"
    }
else
    echo "Docker 用户组不存在，跳过..."
fi

# 5. 移除 Docker 的 APT 源
echo "移除 Docker APT 源..."
sudo rm -f /etc/apt/sources.list.d/docker.list /etc/apt/keyrings/docker.asc || {
    echo "警告：APT 源文件可能不存在，继续执行..."
}
sudo apt-get update || {
    echo "错误：无法更新 APT 索引，请检查网络或 APT 配置"
    exit 1
}

# 6. 清理无用依赖和缓存
echo "清理无用依赖和缓存..."
sudo apt-get autoremove -y
sudo apt-get autoclean

# 7. 验证卸载
echo "验证 Docker 是否已卸载..."
if command -v docker >/dev/null 2>&1; then
    echo "警告：Docker 仍可执行，可能未完全卸载。请检查："
    docker --version
    dpkg -l | grep -i docker
    exit 1
elif dpkg -l | grep -i docker >/dev/null; then
    echo "警告：系统中仍有 Docker 相关软件包："
    dpkg -l | grep -i docker
    exit 1
else
    echo "Docker 已成功卸载！"
fi

exit 0
