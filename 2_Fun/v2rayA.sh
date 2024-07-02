#!/bin/bash

# ��װ V2RayA
function installv2raya() {
    # ��ӹ�Կ
    wget -qO - https://apt.v2raya.org/key/public-key.asc | sudo tee /etc/apt/keyrings/v2raya.asc

    # ��� V2RayA ���Դ
    echo "deb [signed-by=/etc/apt/keyrings/v2raya.asc] https://apt.v2raya.org/ v2raya main" | sudo tee /etc/apt/sources.list.d/v2raya.list

    # ����������б�
    sudo apt update

    # ��װ V2RayA �� V2Ray
    sudo apt install v2raya v2ray
}

# ���� V2RayA ����
function startv2raya() {
    sudo systemctl start v2raya.service
}

# ���� V2RayA ���񿪻�����
function setsysenable() {
    sudo systemctl enable v2raya.service
}

# �Ƴ� V2RayA �� V2Ray
function rmv2rary() {
    sudo apt remove --purge v2raya v2ray
    sudo apt autoremove
    sudo rm /etc/apt/sources.list.d/v2raya.list
    sudo rm /etc/apt/keyrings/v2raya.asc
}

# ���˵�
function main_menu() {
    while true; do
        clear
        echo "Ĭ�϶˿�2017:"
        echo "�˵�ѡ��:"
        echo "1. ��װv2ray"
        echo "2. ����v2ray"
        echo "3. ���ÿ����Զ�����v2ray"
        echo "4. �Ƴ�v2ray"
       
        read -p "������ѡ�1-4��: " OPTION

        case $OPTION in
        1) installv2raya ;;
        2) startv2raya ;;
        3) setsysenable ;;
        4) rmv2rary ;;
        *) echo "��Чѡ�" ;;
        esac
        echo "��������������˵�..."
        read -n 1
    done
}

# ��ʾ���˵�
main_menu
