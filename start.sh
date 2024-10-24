#!/bin/bash
export FILE_PATH=${FILE_PATH:-'./webssh'}      # 安装目录
export PORT=${PORT:-'8080'}                    # web端口
export USER=${USER:-''}                        # 登录用户名，可以为空
export PASS=${PASS:-''}                        # 登录密码，可以为空

mkdir -p "${FILE_PATH}"; ARCH=$(uname -m); DOWNLOAD_DIR="${FILE_PATH}"; FILE_INFO=""
if [ "$ARCH" = "arm" ] || [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
    FILE_INFO="https://github.com/acscamo/webssh/raw/main/webssh_linux_arm64 webssh"
elif [ "$ARCH" = "amd64" ] || [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "x86" ]; then
    FILE_INFO="https://github.com/acscamo/webssh/raw/main/webssh_linux_amd64 webssh"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

URL=$(echo "$FILE_INFO" | cut -d ' ' -f 1)
NEW_FILENAME=$(echo "$FILE_INFO" | cut -d ' ' -f 2)
FILENAME="$DOWNLOAD_DIR/$NEW_FILENAME"

if [ -e "$FILENAME" ]; then
    echo -e "\e[1;32m$FILENAME already exists, Skipping download\e[0m"
else
    curl -L -sS -o "$FILENAME" "$URL" || { echo -e "\e[1;31mFailed to download $URL\e[0m"; exit 1; }
    echo -e "\e[1;32mDownloading $FILENAME\e[0m"
fi

# 启动 webssh
if [ -e "${FILE_PATH}/webssh" ]; then
    chmod +x "${FILE_PATH}/webssh"
    
    echo -e "\e[1;34mStarting webssh...\e[0m"
    
    if [ -z "${USER}" ] || [ -z "${PASS}" ]; then
        "${FILE_PATH}/webssh" -p "${PORT}" >/dev/null 2>&1 &
    else
        "${FILE_PATH}/webssh" -p "${PORT}" -a "${USER}:${PASS}" >/dev/null 2>&1 &
    fi
    
    # 检查端口
    sleep 2  # 等待服务启动
    if nc -z localhost "${PORT}"; then
        echo -e "\e[1;32mwebssh is running on port ${PORT}\e[0m"
    else
        echo -e "\e[1;31mwebssh failed to start on port ${PORT}\e[0m"
        exit 1
    fi
else
    echo -e "\e[1;31mwebssh not found in ${FILE_PATH}\e[0m"
fi

    sleep 3
    if pgrep -x "webssh" > /dev/null; then
        echo -e "\e[1;32mwebssh is running\e[0m"
    else 
        echo -e "\e[1;35mwebssh is not running, restarting...\e[0m"
        pkill -x "webssh"
        nohup "${FILE_PATH}/webssh" -p "${PORT}" -a "${USER}:${PASS}" >/dev/null 2>&1 & 
        sleep 2
        echo -e "\e[1;32mwebssh restarted\e[0m"
    fi
else
    echo -e "\e[1;31mwebssh not found in ${FILE_PATH}\e[0m"
fi

# 获取IP地址
IP=$(curl -s --max-time 1 ipv4.ip.sb || curl -s --max-time 1 api.ipify.org || { 
    ipv6=$(curl -s --max-time 1 ipv6.ip.sb); echo "[$ipv6]"; 
} || echo "未能获取到IP")

echo -e "\e[1;32m访问 http://分配的域名:${PORT} 或 http://${IP}:${PORT}\e[0m"
