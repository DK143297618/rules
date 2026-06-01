#!/bin/bash

# 遇到错误立即停止执行
set -e

echo -e "\033[33m🚮 正在卸载 zsh 和 tmux，并清理相关配置...\033[0m"
# 加上 || true 防止由于之前没安装导致脚本报错停止
sudo apt remove --purge zsh tmux -y || true 
sudo apt autoremove -y

echo -e "\033[33m🧹 清除旧的配置文件...\033[0m"
rm -rf ~/.oh-my-zsh ~/.zshrc ~/.zprofile ~/.zlogin ~/.zlogout ~/.zshenv ~/.zsh ~/.cache/zsh ~/.local/share/zsh ~/.zcompdump* ~/.tmux.conf ~/.tmux

echo -e "\033[32m✅ 清理完成，开始重新安装 zsh、tmux 和依赖...\033[0m"
sudo apt update
# 加入了 tmux
sudo apt install zsh tmux git curl command-not-found -y

echo -e "\033[36m⚙️ 安装 Oh My Zsh...\033[0m"
# --unattended 参数防止安装后直接进入 zsh 阻塞脚本
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

echo -e "\033[36m🔌 下载 Zsh 插件...\033[0m"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

echo -e "\033[36m🛠 配置 ~/.zshrc 插件...\033[0m"
# 利用 oh-my-zsh 的插件机制加载所需插件
sed -i 's/^plugins=.*/plugins=(git command-not-found zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

echo -e "\033[36m🪟 初始化 Tmux 基础配置...\033[0m"
cat > ~/.tmux.conf << 'EOF'
# 开启鼠标支持 (可通过鼠标调整面板大小、切换窗口等)
set -g mouse on

# 确保 tmux 内部默认使用 zsh
set-option -g default-shell /bin/zsh

# 开启 256 色支持，防止 zsh 主题在 tmux 中颜色显示错乱
set -g default-terminal "screen-256color"
EOF

echo -e "\033[36m🌀 设置 zsh 为当前用户的默认 shell...\033[0m"
sudo chsh -s $(which zsh) $(whoami)

echo -e "\033[32m✅ 安装与配置全部完成！\033[0m"
echo -e "\033[32m🚀 正在为您加载并切换到 Zsh...\033[0m"

# 替换当前进程并以 Login Shell 启动 zsh
exec zsh -l
