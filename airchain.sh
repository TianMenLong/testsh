#!/bin/bash

# 检查并安装所需的工具
install_if_needed() {
    local package=$1
    if dpkg-query -W "$package" >/dev/null 2>&1; then
        echo "$package 已安装，跳过安装步骤。"
    else
        echo "安装 $package..."
        sudo apt update
        sudo apt install -y "$package"
    fi
}

install_if_needed build-essential
install_if_needed git
install_if_needed make
install_if_needed jq
install_if_needed curl
install_if_needed clang
install_if_needed pkg-config
install_if_needed libssl-dev
install_if_needed wget

# 检查并安装 Go
if command -v go >/dev/null 2>&1; then
    echo "go 已安装，跳过安装步骤。"
else
    echo "下载并安装 Go..."
    wget -c https://golang.org/dl/go1.22.4.linux-amd64.tar.gz -O - | sudo tar -xz -C /usr/local
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    source ~/.bashrc
fi

# 验证安装后的 Go 版本
echo "当前 Go 版本："
go version

# 安装节点
function install_node() {
    sudo apt-get update && sudo apt-get install jq build-essential -y
    cd $HOME
    git clone https://github.com/airchains-network/wasm-station.git
    git clone https://github.com/airchains-network/tracks.git
    cd wasm-station
    go mod tidy
    /bin/bash ./scripts/local-setup.sh

    sudo tee /etc/systemd/system/wasmstationd.service > /dev/null << EOF
[Unit]
Description=wasmstationd
After=network.target

[Service]
User=$USER
ExecStart=$HOME/wasm-station/build/wasmstationd start --api.enable
Restart=always
RestartSec=3
LimitNOFILE=10000

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload && \
    sudo systemctl enable wasmstationd && \
    sudo systemctl start wasmstationd
    
    cd
    wget https://github.com/airchains-network/tracks/releases/download/v0.0.2/eigenlayer
    sudo chmod +x eigenlayer
    sudo mv eigenlayer /usr/local/bin/eigenlayer

    # 定义文件路径
    KEY_FILE="$HOME/.eigenlayer/operator_keys/wallet.ecdsa.key.json"
    # 检查文件是否存在
    if [ -f "$KEY_FILE" ]; then
        echo "文件 $KEY_FILE 已经存在，删除文件"
        rm -f "$KEY_FILE"
    fi

    # 执行创建密钥命令
    echo "123" | eigenlayer operator keys create --key-type ecdsa --insecure wallet

    sudo rm -rf ~/.tracks
    cd $HOME/tracks
    go mod tidy

    # 提示用户输入公钥和节点名
    read -p "请输入Public Key hex: " dakey
    read -p "请输入节点名: " moniker

    # 执行 Go 命令，替换用户输入的值
    go run cmd/main.go init \
        --daRpc "disperser-holesky.eigenda.xyz" \
        --daKey "$dakey" \
        --daType "eigen" \
        --moniker "$moniker" \
        --stationRpc "http://127.0.0.1:26657" \
        --stationAPI "http://127.0.0.1:1317" \
        --stationType "wasm"

    go run cmd/main.go keys junction --accountName wallet --accountPath $HOME/.tracks/junction-accounts/keys

    go run cmd/main.go prover v1WASM

    # 询问用户是否要继续执行
    read -p "是否已经领水完毕要继续执行？(yes/no): " choice

    if [[ "$choice" != "yes" ]]; then
        echo "脚本已终止。"
        exit 0
    fi

    # 如果用户选择继续，则执行以下操作
    echo "继续执行脚本..."

    CONFIG_PATH="$HOME/.tracks/config/sequencer.toml"
    WALLET_PATH="$HOME/.tracks/junction-accounts/keys/wallet.wallet.json"

    # 从配置文件中提取 nodeid
    NODE_ID=$(grep 'node_id =' $CONFIG_PATH | awk -F'"' '{print $2}')

    # 从钱包文件中提取 air 开头的钱包地址
    AIR_ADDRESS=$(jq -r '.address' $WALLET_PATH)

    # 获取本机 IP 地址
    LOCAL_IP=$(hostname -I | awk '{print $1}')

    #取消网络代理
    unset http_proxy
    unset https_proxy

    # 定义 JSON RPC URL 和其他参数
    JSON_RPC="https://rpc1.airchains.t.cosmostaking.com/"
    INFO="EVM Track"
    TRACKS="$AIR_ADDRESS"
    BOOTSTRAP_NODE="/ip4/$LOCAL_IP/tcp/2300/p2p/$NODE_ID"

    # 运行 tracks create-station 命令
    create_station_cmd="go run cmd/main.go create-station \
        --accountName wallet \
        --accountPath $HOME/.tracks/junction-accounts/keys \
        --jsonRPC \"$JSON_RPC\" \
        --info \"$INFO\" \
        --tracks \"$AIR_ADDRESS\" \
        --bootstrapNode \"$BOOTSTRAP_NODE\""

    echo "Running command:"
    echo "$create_station_cmd"

    # 执行命令
    eval "$create_station_cmd"

    sudo tee /etc/systemd/system/stationd.service > /dev/null << EOF
[Unit]
Description=station track service
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/tracks/
Environment="PATH=$PATH:/usr/local/go/bin"
ExecStart=$(which go) run cmd/main.go start
Restart=always
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable stationd
    sudo systemctl restart stationd
}

# 日志功能
function evmos_log() {
    journalctl -u evmosd -f
}

function avail_log() {
    journalctl -u availd -f
}

function tracks_log() {
    journalctl -u tracksd -f
}

function private_key() {
    cd /data/airchains/evm-station/ && /bin/bash ./scripts/local-keys.sh
    cat /root/.avail/identity/identity.toml
    cat $HOME/.tracks/junction-accounts/keys/node.wallet.json
}

function check_avail_address() {
    journalctl -u availd | head
}

function restart() {
    sudo systemctl restart evmosd
    sudo systemctl restart availd
    sudo systemctl restart tracksd
}

function delete_node() {
    sudo rm -rf data .evmosd .avail .tracks
    sudo systemctl stop availd.service evmosd.service tracksd.service
    sudo systemctl disable availd.service evmosd.service tracksd.service
    sudo pkill -9 availd evmosd tracksd
    sudo journalctl --vacuum-time=1s
}

# 主菜单
function main_menu() {
    while true; do
        clear
        echo "请选择要执行的操作:"
        echo "1. 安装节点"
        echo "2. 查看 evmos 状态"
        echo "3. 查看 avail 状态"
        echo "4. 查看 tracks 状态"
        echo "5. 导出所有私钥"
        echo "6. 查看 avail 地址"
        echo "7. 删除节点"
        read -p "请输入选项（1-7）: " OPTION

        case $OPTION in
        1) install_node ;;
        2) evmos_log ;;
        3) avail_log ;;
        4) tracks_log ;;
        5) private_key ;;
        6) check_avail_address ;;
        7) delete_node ;;
        *) echo "无效选项。" ;;
        esac
        echo "按任意键返回主菜单..."
        read -n 1
    done
}

# 显示主菜单
main_menu
