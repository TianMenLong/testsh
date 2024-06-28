#!/bin/bash

# 安装 jq 工具
if ! command -v jq &> /dev/null
then
    echo "jq 未安装，正在安装 jq..."
    sudo apt-get update
    sudo apt-get install -y jq
fi

# 下载二进制文件
wget https://github.com/airchains-network/junction/releases/download/v0.1.0/junctiond

# 使二进制文件可执行
chmod +x junctiond

# 将二进制文件移动到系统范围的目录
sudo mv junctiond /usr/local/bin

# 使用名字对象初始化节点
junctiond init mynode

# 更新创世配置
# 下载测试网创世纪文件
wget https://github.com/airchains-network/junction/releases/download/v0.1.0/genesis.json

# 替换现有的创世文件
cp genesis.json ~/.junction/config/genesis.json

# 更新配置
# 编辑 persistent_peers
sed -i 's|persistent_peers = ""|persistent_peers = "de2e7251667dee5de5eed98e54a58749fadd23d8@34.22.237.85:26656"|' ~/.junction/config/config.toml

# 设置最低 gas 价格
sed -i 's|minimum-gas-prices = ""|minimum-gas-prices = "0.00025amf"|' ~/.junction/config/app.toml

# 启动节点
junctiond start &

# 等待节点同步
while true; do
    STATUS=$(junctiond status | jq .SyncInfo.catching_up)
    if [ "$STATUS" == "false" ]; then
        echo "节点已完成同步"
        break
    else
        echo "节点正在同步中..."
        sleep 10
    fi
done

# 为验证者创建新帐户
VALIDATOR_NAME="myvalidator"
junctiond keys add $VALIDATOR_NAME

echo "请确保为您的账户注资至少 58 tokens"

# 提示用户在继续之前确保账户已注资
read -p "按回车键继续，确保账户已注资..."

# 获取公钥
PUBKEY=$(junctiond comet show-validator | jq -r .key)

# 创建 validator.json 文件
cat <<EOF > validator.json
{
	"pubkey": "$PUBKEY",
	"amount": "1000000amf",
	"moniker": "$VALIDATOR_NAME",
	"identity": "",
	"website": "",
	"security": "",
	"details": "",
	"commission-rate": "0.1",
	"commission-max-rate": "0.2",
	"commission-max-change-rate": "0.01",
	"min-self-delegation": "1"
}
EOF

# 质押代币成为验证者
junctiond tx staking create-validator validator.json --from $VALIDATOR_NAME --chain-id junction --fees 500amf

# 查询验证器集
junctiond query tendermint-validator-set

echo "验证者节点设置完成。"
