#!/bin/bash
# Debian Trixie (13) 升级到 7.x 内核（stable源）
# trixie main 的 linux-image-cloud-amd64 meta-package 默认拉 6.12.x
# 但 7.1.10 的具体包在 trixie main 里是有的，直接装即可
# 用法: bash debian-trixie-kernel7-upgrade.sh [--dry-run]

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*"; exit 1; }

# ── 前置检查 ──────────────────────────────────────────────
[[ $EUID -ne 0 ]] && err "需要 root 权限"
[[ -f /etc/os-release ]] || err "找不到 /etc/os-release"
grep -q "trixie" /etc/os-release || err "不是 Debian trixie"
[[ -f /boot/grub/grub.cfg ]] || err "非 GRUB 引导"

# 当前内核
CURRENT=$(uname -r)
echo "当前内核: $CURRENT"

# ── 查找 trixie main 里最新的 7.x cloud 内核 ──────────────
log "搜索 trixie main 7.x cloud 内核..."
apt-get update -qq 2>/dev/null

# 找 trixie main 里 linux-image-7.x+deb14-cloud-amd64 的最新版本
CANDIDATE=$(apt-cache madison linux-image-cloud-amd64 2>/dev/null \
  | grep "trixie/main" \
  | grep -oP '[\d.]+-[\d]+(?=\s)' \
  | sort -V \
  | tail -1)

# 也找所有 7.x cloud 内核包
LATEST_7=$(apt-cache search linux-image-7 2>/dev/null \
  | grep -oP 'linux-image-\K[\d.]+-[\d]+\+deb14-cloud-amd64' \
  | sort -V \
  | tail -1)

if [[ -z "$LATEST_7" ]]; then
  err "trixie main 里没有 7.x cloud 内核包\n可能需要先加 trixie-backports 源:\n  echo 'deb http://deb.debian.org/debian trixie-backports main' > /etc/apt/sources.list.d/backports.list\n  apt-get update"
fi

log "找到 7.x cloud 内核: $LATEST_7"

# 精确版本号
VER=$(apt-cache show "linux-image-${LATEST_7}" 2>/dev/null \
  | grep "^Version:" | head -1 | awk '{print $2}')
[[ -z "$VER" ]] && err "无法获取版本号"
log "完整版本: $LATEST_7 ($VER)"

# ── 检查是否已安装 ────────────────────────────────────────
if dpkg -l "linux-image-${LATEST_7}" 2>/dev/null | grep -q "^ii"; then
  warn "已安装 $LATEST_7，跳过安装"
  SKIP_INSTALL=true
else
  SKIP_INSTALL=false
fi

# ── 安装内核 ──────────────────────────────────────────────
if [[ "$SKIP_INSTALL" == "false" ]]; then
  log "安装 linux-image-${LATEST_7} ..."
  if $DRY_RUN; then
    warn "[dry-run] apt-get install -y linux-image-${LATEST_7}"
  else
    apt-get install -y "linux-image-${LATEST_7}" 2>&1 | tail -5
  fi
fi

# ── 更新 GRUB ─────────────────────────────────────────────
log "更新 GRUB..."
if ! $DRY_RUN; then
  update-grub 2>&1 | tail -3
fi

# ── 设置下次启动到新内核 ──────────────────────────────────
SUBMENU_PATH="Advanced options for Debian GNU/Linux>Debian GNU/Linux, with Linux ${LATEST_7}"
log "设置 GRUB 下次启动: $LATEST_7"
if ! $DRY_RUN; then
  grub-reboot "$SUBMENU_PATH"
  echo "GRUB next_entry: $(grub-editenv list | grep next_entry)"
fi

# ── 确认 ──────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "  安装完成，待重启生效"
echo "  新内核: $LATEST_7"
echo "  当前:   $CURRENT"
echo ""
echo "  重启:   systemctl reboot"
echo "  验证:   uname -r"
echo "=========================================="

if $DRY_RUN; then
  echo ""
  warn "dry-run 模式，未实际执行。去掉 --dry-run 参数运行。"
fi
