#!/bin/bash

# 提示用户输入 RPC 链接
read -p "请输入 RPC 链接: " RPC_URL

# 发送查询请求
response=$(curl -s -X GET "${RPC_URL}/abci_query?path=\"custom/auth/params\"")

# 检查请求是否成功
if [[ $? -ne 0 ]]; then
  echo "无法连接到 RPC 服务器。请检查链接并重试。"
  exit 1
fi

# 打印响应以手动检查
echo "响应内容: $response"

# 提取最小费用信息
min_fee=$(echo $response | jq -r '.result.response.value' | base64 --decode | jq -r '.minimum_gas_prices')

# 检查是否成功提取到最小费用信息
if [[ -z "$min_fee" ]]; then
  echo "无法获取最小交易费用。请检查 RPC 链接是否正确。"
  exit 1
fi

echo "当前链上的最小交易费用为: $min_fee"