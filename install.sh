#!/bin/bash
echo "make sure using root user"



apt update && apt upgrade
apt install -y wget git openssl curl nginx vim 

mkdir TEMP_SCALEINSTALL
cd TEMP_SCALEINSTALL
wget --output-document=headscale.deb https://github.com/juanfont/headscale/releases/download/v0.22.3/headscale_0.22.3_linux_amd64.deb
dpkg --install headscale.deb
systemctl enable headscale --now

read -p "make sure change IP and Port manully in this script, press anything to continue" VOID
HEADSCALE_IP="148.135.81.235"
HEADSCALE_VPN_Port="1234"
HEADSCALE_Nginx_Port=""

#DO NOT CHANGE UNDER LINES
server_url="server_url: http://$HEADSCALE_IP:$HEADSCALE_VPN_Port"
# nginx_url="server_url: http://$HEADSCALE_IP:$HEADSCALE_VPN_Port"

# 提示用户输入文件名

filename="/etc/headscale/config.yaml"
# 检查文件是否存在
if [ ! -f "$filename" ]; then
    echo "headscale config dont exist! check install mannualy"
    exit 1
fi

# 查找包含ip_prefixed字符串的行号
line_number=$(grep -n 'ip_prefixes:' "$filename" | head -n 1 | cut -d: -f1)

# 如果找到了匹配的行
if [ -n "$line_number" ]; then
    # 获取下一行的行号
    next_line=$((line_number + 1))

    # 在下一行添加注释符号
    sed -i "${next_line}s/^/#/" "$filename"
else
    echo "headscale config didnt have ip_prefixes. check manually!"
    exit 1
fi

line_number=$(grep -n 'server_url:' "$filename" | head -n 1 | cut -d: -f1)
# 如果找到了匹配的行
if [ -n "$line_number" ]; then
    # 构建新的 server_url 字符串
    new_server_url="server_url: http://$HEADSCALE_IP:$HEADSCALE_VPN_Port"

    # 使用sed替换整行
    sed -i "${line_number}s,.*,${new_server_url}," "$filename"

else
    echo "server_url cant found"
    exit 1
fi

read -p "WARNNING! going to change Nginx config file */etc/nginx/sites-available/default*, backup is /etc/nginx/sites-available/default.bak, press anything to continue" VOID


 