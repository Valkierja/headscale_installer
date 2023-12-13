#!/bin/bash
echo "make sure using root user"



apt update && apt upgrade
apt install -y wget git openssl curl nginx vim zip

mkdir TEMP_SCALEINSTALL

# you can safely delete and you should delete this folder if previous install was interupted
cd TEMP_SCALEINSTALL
echo "cd TEMP_SCALEINSTALL"
echo "you should delete ALL this folder if previous install was interupted"
wget --output-document=headscale.deb https://github.com/juanfont/headscale/releases/download/v0.22.3/headscale_0.22.3_linux_amd64.deb
dpkg --install headscale.deb
systemctl enable headscale --now

read -p "make sure change IP and Port manully in this script, press anything to continue" VOID
HEADSCALE_IP=""
HEADSCALE_VPN_Port=""
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
cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak

wget --output-document=tempNginx https://raw.githubusercontent.com/Valkierja/headscale_installer/main/cfg/default
cat "tempNginx" > default
echo "" >> default
cat "/etc/nginx/sites-available/default.bak" >> default
filename="default"
new_server_port="    listen ${HEADSCALE_Nginx_Port};"
new_server_url="    server_name ${HEADSCALE_IP};"
sed -i "7s,.*,${new_server_port}," "$filename"
sed -i "9s,.*,${new_server_url}," "$filename"
cp default

wget https://github.com/gurucomputing/headscale-ui/releases/download/2023.01.30-beta-1/headscale-ui.zip
unzip -d /var/www headscale-ui.zip
systemctl start headscale --now
systemctl restart nginx --now
echo "save next line, it's your SECRET KEY!!"
headscale apikeys create --expiration 9999d
echo "go to http://${HEADSCALE_IP}:${HEADSCALE_Nginx_Port}/web"
echo "check doc for next operation"
cd ..
rm -rf TEMP_SCALEINSTALL