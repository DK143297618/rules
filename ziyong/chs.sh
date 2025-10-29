#!/bin/bash
set -e

echo "=== 修复系统 locale 并启用中文显示支持（保持英文界面） ==="

# 更新软件包索引
apt update -y

# 安装 locale 支持（若已安装则跳过）
apt install -y locales

echo
echo "--- 生成所需语言环境 ---"
locale-gen en_US.UTF-8 zh_CN.UTF-8

# 确保 localedef 完整执行，避免缺失警告
localedef -v -c -i zh_CN -f UTF-8 zh_CN.UTF-8 || true
localedef -v -c -i en_US -f UTF-8 en_US.UTF-8 || true

echo
echo "--- 写入系统配置文件 ---"

# 清理旧配置（防止 update-locale 报 invalid）
sed -i '/^LANG/d' /etc/default/locale 2>/dev/null || true
sed -i '/^LC_CTYPE/d' /etc/default/locale 2>/dev/null || true
sed -i '/^LANGUAGE/d' /etc/default/locale 2>/dev/null || true

# 写入新配置
cat <<EOF | tee /etc/default/locale >/dev/null
LANG=en_US.UTF-8
LC_CTYPE=zh_CN.UTF-8
EOF

# 同步到 /etc/environment （部分桌面或 ssh 登录依赖）
grep -q "LANG=" /etc/environment && sed -i 's/^LANG=.*/LANG=en_US.UTF-8/' /etc/environment || echo "LANG=en_US.UTF-8" >> /etc/environment
grep -q "LC_CTYPE=" /etc/environment && sed -i 's/^LC_CTYPE=.*/LC_CTYPE=zh_CN.UTF-8/' /etc/environment || echo "LC_CTYPE=zh_CN.UTF-8" >> /etc/environment

echo
echo "--- 重新加载环境 ---"
source /etc/default/locale || true

echo
echo "=== 当前语言环境 ==="
locale

echo
echo "✅ 配置完成！"
echo "已为全系统启用英文界面 + 中文显示支持。"
echo "如提示仍有 locale 警告，可重启终端或执行："
echo "  source /etc/default/locale"
echo
