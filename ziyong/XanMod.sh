#!/bin/bash

# 此脚本用于添加 XanMod 内核仓库，从密钥服务器获取额外密钥，
# 并根据 CPU 指令集安装相应版本的 XanMod 内核。

# 确保以 root 身份运行
if [ "$(id -u)" != "0" ]; then
   echo "此脚本必须以 root 身份运行" 
   exit 1
fi

# 检测 CPU 指令集并设置内核版本
level=$(awk 'BEGIN {
    while (!/flags/) if (getline < "/proc/cpuinfo" != 1) exit 1
    if (/lm/&&/cmov/&&/cx8/&&/fpu/&&/fxsr/&&/mmx/&&/syscall/&&/sse2/) level = 1
    if (level == 1 && /cx16/&&/lahf/&&/popcnt/&&/sse4_1/&&/sse4_2/&&/ssse3/) level = 2
    if (level == 2 && /avx/&&/avx2/&&/bmi1/&&/bmi2/&&/f16c/&&/fma/&&/abm/&&/movbe/&&/xsave/) level = 3
    if (level == 3 && /avx512f/&&/avx512bw/&&/avx512cd/&&/avx512dq/&&/avx512vl/) level = 4
    if (level > 0) { print level; exit level + 1 }
    exit 1
}')

case "$level" in
  1)
    kernel_package="linux-xanmod-lts-x64v1"
    ;;
  2)
    kernel_package="linux-xanmod-lts-x64v2"
    ;;
  3)
    kernel_package="linux-xanmod-lts-x64v3"
    ;;
  4)
    # kernel_package="linux-xanmod-lts-x64v4"
    kernel_package="linux-xanmod-lts-x64v3"
    ;;
  *)
    echo "无法确定合适的 Xanmod 内核版本。"
    exit 1
    ;;
esac

# 定义加速后的下载 URL
# 注意：已将加速器更改为 gh.mmzs.xyz
DOWNLOAD_URL="https://gh.mmzs.xyz/https://github.com/dler-io/script/raw/main/kernel/${kernel_package}.deb"

# 下载 XanMod 内核
echo "正在从加速源（gh.mmzs.xyz）下载 $kernel_package"
# 使用加速后的 URL
curl -L -o ${kernel_package}.deb "$DOWNLOAD_URL"

if [ $? -ne 0 ]; then
    echo "下载 $kernel_package 失败"
    exit 1
fi

# 安装 XanMod 内核
echo "正在安装 $kernel_package"
dpkg -i ${kernel_package}.deb

if [ $? -ne 0 ]; then
    echo "安装 $kernel_package 失败"
    exit 1
fi

update-grub

echo "系统将在 10 秒后重启。按 Ctrl+C 取消。"
for i in {10..1}
do
    echo "$i..."
    sleep 1
done
echo "现在重启！"
reboot
