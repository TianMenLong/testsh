from web3 import Web3

# 自定义配置
#rpc_url = "http://127.0.0.1:26657"  # 自定义的 RPC URL
#rpc_url ="https://airchains-rpc.kubenode.xyz/"

rpc_url = "http://127.0.0.1:8545"
#rpc_url = "http://172.22.140.128:26657" 

chain_id = 1  # 自定义的链 ID

# 钱包地址和私钥
sender_address = Web3.to_checksum_address("0x6a378a65cddfa4ebfff4bc097866282cf5c78dae") # 发送者钱包地址
sender_private_key = "0xdcb18ea59cd9e19e668d509016319481f932e7fedc7fe20c189257499083c933"  # 发送者钱包的私钥

# 接收者钱包地址和转账金额（以最小单位表示）
receiver_address = "0x6a378a65cddfa4ebfff4bc097866282cf5c78dae"  # 接收者钱包地址
amount = 1000000000000000000  # 转账金额（示例为 1个币）

print("创建 Web3 实例")
# 创建 Web3 实例
web3 = Web3(Web3.HTTPProvider(rpc_url))

print("Using RPC URL:", rpc_url)
print("Sender Address:", sender_address)
#print("Nonce:", transaction["nonce"])

print("构建交易对象")
# 构建交易对象
transaction = {
    "to": receiver_address,
    "value": amount,
    "gas": 21000,  # 设置默认的 gas 数量
    "gasPrice": web3.to_wei(50, "gwei"),  # 设置默认的 gas 价格
    "nonce": web3.eth.get_transaction_count(sender_address),
    "chainId": chain_id,
}
print("签名交易")
# 签名交易
signed_txn = web3.eth.account.sign_transaction(transaction, sender_private_key)

print("发送交易")

# 发送交易
tx_hash = web3.eth.send_raw_transaction(signed_txn.rawTransaction)
print("------------等待交易确认")
# 等待交易确认
tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
print("-------------交易确认完成")

# 输出交易结果
print("Hash:", tx_receipt.transactionHash.hex())
print("Gas Used:", tx_receipt.gasUsed)
print("Status:", tx_receipt.status)