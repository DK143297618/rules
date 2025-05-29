#!/bin/bash

set -e

echo "🚮 正在卸载 zsh 并清理相关配置..."

sudo apt remove --purge zsh -y
rm -rf ~/.oh-my-zsh ~/.zshrc ~/.zprofile ~/.zlogin ~/.zlogout ~/.zshenv ~/.zsh ~/.cache/zsh ~/.local/share/zsh ~/.zcompdump*

echo "✅ 清理完成，开始重新安装 zsh 和配置..."

sudo apt update
sudo apt install zsh git curl command-not-found -y

echo "⚙️ 安装 Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "🔌 安装插件 zsh-autosuggestions 和 zsh-syntax-highlighting..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

echo "🛠 配置 ~/.zshrc 插件..."
sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

cat >> ~/.zshrc << 'EOF'

# 手动加载插件
source ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# command-not-found 支持
if [ -x /usr/lib/command-not-found ]; then
    function command_not_found_handler() {
        /usr/lib/command-not-found -- "$1"
        return $?
    }
fi
EOF

echo "🌀 设置 zsh 为默认 shell..."
chsh -s $(which zsh)

echo "✅ 安装完成，立即切换到 zsh！"
exec zsh
