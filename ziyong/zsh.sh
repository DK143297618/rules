#!/bin/bash

# 遇到错误立即停止执行
set -e

echo -e "\033[33m🚮 正在清理旧的配置与相关软件...\033[0m"
# 加上 || true 防止由于之前没安装导致报错停止
sudo apt remove --purge zsh tmux -y || true 
sudo apt autoremove -y

echo -e "\033[33m🧹 清除旧的配置文件...\033[0m"
rm -rf ~/.oh-my-zsh ~/.zshrc ~/.zprofile ~/.zlogin ~/.zlogout ~/.zshenv ~/.zsh ~/.cache/zsh ~/.local/share/zsh ~/.zcompdump* ~/.tmux.conf ~/.tmux

echo -e "\033[32m✅ 清理完成，开始安装基础依赖...\033[0m"
sudo apt update
# 加入了 wget 用于后续下载，tmux 用于终端复用
sudo apt install zsh tmux git curl wget command-not-found -y

echo -e "\033[36m🚀 安装 Fastfetch (系统信息面板)...\033[0m"
# 下载最新版并静默覆盖
wget -qO fastfetch-linux-amd64.deb https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb
sudo apt install ./fastfetch-linux-amd64.deb -y
# 安装完清理安装包
rm fastfetch-linux-amd64.deb

echo -e "\033[36m⚙️ 安装 Oh My Zsh...\033[0m"
# --unattended 参数防止安装后直接进入 zsh 阻塞脚本
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

echo -e "\033[36m🔌 下载 Zsh 插件...\033[0m"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

echo -e "\033[36m🛠 配置 ~/.zshrc...\033[0m"
# 加载必要的插件
sed -i 's/^plugins=.*/plugins=(git command-not-found zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

# 写入色彩修正与启动项
cat >> ~/.zshrc << 'EOF'

# 强制开启基础命令的色彩输出
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# 每次启动终端时展示极其炫酷的系统状态面板
fastfetch
EOF

echo -e "\033[36m🪟 初始化 Tmux 基础配置...\033[0m"
cat > ~/.tmux.conf << 'EOF'
# 开启鼠标支持
set -g mouse on
# 确保 tmux 内部默认使用 zsh
set-option -g default-shell /bin/zsh
# 开启 256 色支持，防止 zsh 在 tmux 中颜色显示错乱
set -g default-terminal "screen-256color"
EOF

echo -e "\033[36m🌀 设置 zsh 为当前用户的默认 shell...\033[0m"
sudo chsh -s $(which zsh) $(whoami)

echo -e "\033[32m✅ 终极版环境部署完成！\033[0m"
echo -e "\033[32m🚀 正在为您加载并切换到 Zsh...\033[0m"

# 替换当前进程并以 Login Shell 启动 zsh
exec zsh -l
