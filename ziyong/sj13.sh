#!/bin/bash
set -e

Font_Red="\033[31m"
Font_Blue="\033[34m"
Font_Green="\033[32m"
Font_Suffix="\033[0m"

MIN_TOTAL_MB=1024

clear

# 检查 root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${Font_Red}必须以 root 用户运行${Font_Suffix}"
    exit 1
fi

# 检查内存+swap
total_mem=$(free -m | awk '/^Mem:/ {print $2}')
total_swap=$(free -m | awk '/^Swap:/ {print $2}')
total_all=$((total_mem + total_swap))
echo "检测到物理内存: ${total_mem}MB, swap: ${total_swap}MB, 总和: ${total_all}MB"
if [ "$total_all" -lt "$MIN_TOTAL_MB" ]; then
    echo -e "${Font_Red}内存+swap 不足 ${MIN_TOTAL_MB}MB，升级可能失败！${Font_Suffix}"
    exit 1
fi

# 升级前确认
echo -e "${Font_Red}!!! 警告：即将从 Debian 12 (bookworm) 升级到 Debian 13 (trixie)"
echo -e "!!! 升级有风险，请先备份重要数据或制作 VPS 快照${Font_Suffix}"
read -p "确认继续吗？(y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "已取消升级"
    exit 0
fi

# 备份重要配置
echo -e "${Font_Blue}正在备份系统配置...${Font_Suffix}"
cp /etc/sysctl.conf /etc/sysctl.conf.bak
cp /etc/apt/sources.list /etc/apt/sources.list.bak
mkdir -p /root/apt-list-backup
cp /etc/apt/sources.list.d/* /root/apt-list-backup/ 2>/dev/null || true

# 升级 Debian 12 到最新
echo -e "${Font_Blue}升级 Debian 12 到最新版本...${Font_Suffix}"
apt update
apt upgrade -y
apt full-upgrade -y
apt --purge autoremove -y

# 替换源为 Debian 13 trixie
echo -e "${Font_Blue}替换软件源为 Debian 13 (trixie)...${Font_Suffix}"
sed -i 's/bookworm/trixie/g' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null
apt update

# 第一阶段升级（不引入新包）
echo -e "${Font_Blue}第一阶段升级（不安装新包）...${Font_Suffix}"
apt upgrade --without-new-pkgs -y

# 第二阶段升级（完全升级）
echo -e "${Font_Blue}第二阶段升级（full-upgrade）...${Font_Suffix}"
apt full-upgrade -y

# 修复依赖
echo -e "${Font_Blue}修复可能的依赖问题...${Font_Suffix}"
apt-get -f install -y

# 安装最新内核
echo -e "${Font_Blue}安装最新内核...${Font_Suffix}"
apt install --install-recommends linux-image-amd64 linux-headers-amd64 -y

# 清理无用包
echo -e "${Font_Blue}清理无用包...${Font_Suffix}"
apt --purge autoremove -y
apt autoclean

# 升级完成
echo -e "${Font_Green}升级完成！${Font_Suffix}"
echo "当前版本: $(cat /etc/debian_version)"
echo "当前内核: $(uname -r)"
echo -e "${Font_Blue}建议执行 reboot 重启以应用新内核${Font_Suffix}"
