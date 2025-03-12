#!/bin/bash

# 更新系统包列表并安装必要的软件
sudo apt update
sudo apt install zsh git vim curl -y

# 安装 Oh My Zsh，并自动应答“yes”更改默认 shell
echo "安装 Oh My Zsh，并自动设置 zsh 为默认 shell..."
zsh -c "CHSH=yes sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""

# 安装 Oh My Zsh 插件：zsh-autosuggestions 和 zsh-syntax-highlighting
echo "安装 zsh-autosuggestions 和 zsh-syntax-highlighting 插件..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# 安装 command-not-found 插件
echo "安装 command-not-found 插件..."
sudo apt install command-not-found -y

# 定义新的插件列表
new_plugins="git command-not-found zsh-autosuggestions zsh-syntax-highlighting"

# 更新 .zshrc 文件中的 plugins 配置
echo "更新 .zshrc 文件中的 plugins 配置..."
sed -i "s/^plugins=(.*)/plugins=(${new_plugins})/" ~/.zshrc

# 重新加载 zsh 配置
echo "重新加载 zsh 配置..."
source ~/.zshrc

echo "配置完成！"
