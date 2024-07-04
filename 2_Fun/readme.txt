//配置链接  不是脚本
http://172.23.158.72:2017/

电脑主机需要先开代理
//从这里开始执行 下面ip换乘虚拟机所在的电脑IP  比如： http://192.168.31.11:7890 

export http_proxy=http://192.168.31.10:7890 
export https_proxy=http://192.168.31.10:7890 

wget -O v2rayA.sh https://raw.githubusercontent.com/TianMenLong/testsh/main//2_Fun/v2rayA.sh && chmod +x v2rayA.sh && ./v2rayA.sh
