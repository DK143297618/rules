#!/bin/bash

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 步骤 1: 删除旧的 Bintray 安装源
echo -e "${BLUE}步骤 1: 删除旧的 Bintray 安装源...${NC}"
if sudo rm /etc/apt/sources.list.d/speedtest.list 2>/dev/null; then
    echo -e "${GREEN}成功删除旧的 speedtest.list 文件！${NC}"
else
    echo -e "${YELLOW}未找到 speedtest.list 文件，跳过此步骤。${NC}"
fi

# 步骤 2: 更新 apt-get
echo -e "${BLUE}步骤 2: 更新 apt-get 软件源列表...${NC}"
if sudo apt-get update; then
    echo -e "${GREEN}apt-get 更新成功！${NC}"
else
    echo -e "${RED}apt-get 更新失败，请检查网络连接。${NC}"
    exit 1
fi

# 步骤 3: 删除旧版 Speedtest
echo -e "${BLUE}步骤 3: 删除旧版本的 Speedtest...${NC}"
if sudo apt-get remove -y speedtest 2>/dev/null; then
    echo -e "${GREEN}旧版 speedtest 删除成功！${NC}"
else
    echo -e "${YELLOW}未找到已安装的旧版 speedtest，跳过此步骤。${NC}"
fi

# 步骤 4: 删除非官方的 speedtest-cli
echo -e "${BLUE}步骤 4: 删除非官方的 speedtest-cli...${NC}"
if sudo apt-get remove -y speedtest-cli 2>/dev/null; then
    echo -e "${GREEN}非官方的 speedtest-cli 删除成功！${NC}"
else
    echo -e "${YELLOW}未找到已安装的 speedtest-cli，跳过此步骤。${NC}"
fi

# 步骤 5: 安装 curl（如果尚未安装）
echo -e "${BLUE}步骤 5: 检查并安装 curl...${NC}"
if sudo apt-get install -y curl; then
    echo -e "${GREEN}curl 已成功安装或已经是最新版本！${NC}"
else
    echo -e "${RED}curl 安装失败，请检查网络连接。${NC}"
    exit 1
fi

# 步骤 6: 添加 Ookla Speedtest 仓库
echo -e "${BLUE}步骤 6: 添加 Ookla Speedtest 仓库...${NC}"
if curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash; then
    echo -e "${GREEN}成功添加 Ookla Speedtest 仓库！${NC}"
else
    echo -e "${RED}添加 Ookla Speedtest 仓库失败，请检查网络连接。${NC}"
    exit 1
fi

# 步骤 7: 安装 Speedtest
echo -e "${BLUE}步骤 7: 安装 Speedtest...${NC}"
if sudo apt-get install -y speedtest; then
    echo -e "${GREEN}Speedtest 安装成功！${NC}"
else
    echo -e "${RED}Speedtest 安装失败，请检查错误信息。${NC}"
    exit 1
fi

# 结束
echo -e "${GREEN}所有步骤已成功完成！你现在可以运行 'speedtest' 进行测试。${NC}"
