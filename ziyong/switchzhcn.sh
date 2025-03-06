#!/bin/bash

# 设置脚本在出现错误时退出
set -e

# 定义颜色变量用于输出
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}开始配置 Debian 中文环境...${NC}"

# 更新软件包列表
echo -e "${GREEN}更新软件包列表...${NC}"
sudo apt update

# 安装必要的语言包和工具
echo -e "${GREEN}安装必要的语言包和工具...${NC}"
sudo apt install -y locales fonts-noto-cjk curl wget

# 生成 zh_CN.UTF-8 语言环境
echo -e "${GREEN}生成 zh_CN.UTF-8 语言环境...${NC}"
sudo locale-gen zh_CN.UTF-8

# 检查是否成功生成语言环境
if ! locale -a | grep -q "zh_CN.UTF-8"; then
    echo -e "${RED}生成 zh_CN.UTF-8 语言环境失败，请检查系统配置！${NC}"
    exit 1
fi

# 设置默认语言环境
echo -e "${GREEN}设置默认语言环境为 zh_CN.UTF-8...${NC}"
echo 'LANG="zh_CN.UTF-8"' | sudo tee /etc/default/locale > /dev/null
echo 'LANGUAGE="zh_CN.UTF-8"' | sudo tee -a /etc/default/locale > /dev/null
echo 'LC_ALL="zh_CN.UTF-8"' | sudo tee -a /etc/default/locale > /dev/null

# 配置用户的语言环境变量
echo -e "${GREEN}配置用户的语言环境变量...${NC}"
echo 'export LANG="zh_CN.UTF-8"' >> ~/.bashrc
echo 'export LANGUAGE="zh_CN.UTF-8"' >> ~/.bashrc
echo 'export LC_ALL="zh_CN.UTF-8"' >> ~/.bashrc

# 提示用户重新登录
echo -e "${GREEN}配置完成！请重新登录或重启系统以使更改生效。${NC}"
