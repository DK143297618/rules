#!/bin/bash

# 遇到错误立即停止执行
set -e

echo -e "\033[33m🚮 正在卸载 zsh 并清理相关配置...\033[0m"
# 加上 || true 防止由于之前没安装 zsh 导致脚本在这里报错停止
sudo apt remove --purge zsh -y || true 
sudo apt autoremove -y

echo -e "\033[33m🧹 清除旧的配置文件...\033[0m"
rm -rf ~/.oh-my-zsh ~/.zshrc ~/.zprofile ~/.zlogin ~/.zlogout ~/.zshenv ~/.zsh ~/.cache/zsh ~/.local/share/zsh ~/.zcompdump*

echo -e "\033[32m✅ 清理完成，开始重新安装 zsh 和依赖...\033[0m"
sudo apt update
sudo apt install zsh git curl command-not-found -y

echo -e "\033[36m⚙️ 安装 Oh My Zsh...\033[0m"
# ⚠️ 关键修改：加入 --unattended 参数，防止安装后直接进入 zsh 阻塞脚本
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

echo -e "\033[36m🔌 下载插件 zsh-autosuggestions 和 zsh-syntax-highlighting...\033[0m"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

echo -e "\033[36m🛠 配置 ~/.zshrc 插件...\033[0m"
# ⚠️ 关键修改：直接利用 oh-my-zsh 的插件机制，加入 command-not-found
sed -i 's/^plugins=.*/plugins=(git command-not-found zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

echo -e "\033[36m🌀 设置 zsh 为当前用户的默认 shell...\033[0m"
# 显式指定当前用户，提升兼容性
sudo chsh -s $(which zsh) $(whoami)

echo -e "\033[32m✅ 安装与配置全部完成！\033[0m"
echo -e "\033[32m🚀 正在为您加载并切换到 Zsh...\033[0m"

# 替换当前进程并以 Login Shell 启动 zsh
exec zsh -l
