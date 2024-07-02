#!/bin/bash

# 安装 V2RayA
function installv2raya() {
    # 添加公钥
    wget -qO - https://apt.v2raya.org/key/public-key.asc | sudo tee /etc/apt/keyrings/v2raya.asc

    # 添加 V2RayA 软件源
    echo "deb [signed-by=/etc/apt/keyrings/v2raya.asc] https://apt.v2raya.org/ v2raya main" | sudo tee /etc/apt/sources.list.d/v2raya.list

    # 更新软件包列表
    sudo apt update

    # 安装 V2RayA 和 V2Ray
    sudo apt install v2raya v2ray
}

# 启动 V2RayA 服务
function startv2raya() {
    sudo systemctl start v2raya.service
}

# 设置 V2RayA 服务开机自启
function setsysenable() {
    sudo systemctl enable v2raya.service
}

# 移除 V2RayA 和 V2Ray
function rmv2rary() {
    sudo apt remove --purge v2raya v2ray
    sudo apt autoremove
    sudo rm /etc/apt/sources.list.d/v2raya.list
    sudo rm /etc/apt/keyrings/v2raya.asc
}

# 主菜单
function main_menu() {
    while true; do
        clear
        echo "默认端口2017:"
        echo "菜单选项:"
        echo "1. 安装v2ray"
        echo "2. 启动v2ray"
        echo "3. 设置开机自动启动v2ray"
        echo "4. 移除v2ray"
       
        read -p "请输入选项（1-4）: " OPTION

        case $OPTION in
        1) installv2raya ;;
        2) startv2raya ;;
        3) setsysenable ;;
        4) rmv2rary ;;
        *) echo "无效选项。" ;;
        esac
        echo "按任意键返回主菜单..."
        read -n 1
    done
}

# 显示主菜单
main_menu
