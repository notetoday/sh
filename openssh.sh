#!/bin/bash

# 检查当前用户是否是root
if [ $(id -u) -eq 0 ]; then
    IS_ROOT=true
else
    IS_ROOT=false
fi

# 如果不是root用户，检查是否安装了sudo，如果没有安装则安装sudo
if [ "$IS_ROOT" = false ]; then
    if ! dpkg -l sudo >/dev/null 2>&1; then
        echo "sudo 未安装，正在安装..."
        apt-get -y update
        apt-get -y install sudo
    fi
fi

# 更新系统并安装必要的软件包
if [ "$IS_ROOT" = true ]; then
    apt-get -y update
    apt-get install -y build-essential zlib1g-dev libssl-dev
else
    sudo apt-get -y update
    sudo apt-get install -y build-essential zlib1g-dev libssl-dev
fi

# 下载最新的 OpenSSH 包
wget https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-9.8p1.tar.gz

# 解压并进入目录
tar -xzf openssh-9.8p1.tar.gz
cd openssh-9.8p1

# 编译和安装 OpenSSH
./configure
make
if [ "$IS_ROOT" = true ]; then
    make install
else
    sudo make install
fi

# 重启 SSH 服务
if [ "$IS_ROOT" = true ]; then
    systemctl restart ssh
else
    sudo systemctl restart ssh
fi

# 验证安装的版本
ssh -V

# 如果版本不是 openssh-9.8p1，则添加环境变量
if ! ssh -V 2>&1 | grep -q "openssh-9.8p1"; then
    echo 'export PATH=/usr/local/bin:/usr/local/sbin:$PATH' >> ~/.bashrc
    source ~/.bashrc
    ssh -V
fi

# 修改 ssh.service 文件以使用新的二进制路径
if [ "$IS_ROOT" = true ]; then
    sed -i 's|ExecStartPre=/usr/sbin/sshd|ExecStartPre=/usr/local/sbin/sshd|; s|ExecStart=/usr/sbin/sshd|ExecStart=/usr/local/sbin/sshd|; s|ExecReload=/usr/sbin/sshd|ExecReload=/usr/local/sbin/sshd|' /lib/systemd/system/ssh.service
else
    sudo sed -i 's|ExecStartPre=/usr/sbin/sshd|ExecStartPre=/usr/local/sbin/sshd|; s|ExecStart=/usr/sbin/sshd|ExecStart=/usr/local/sbin/sshd|; s|ExecReload=/usr/sbin/sshd|ExecReload=/usr/local/sbin/sshd|' /lib/systemd/system/ssh.service
fi

# 确认 ssh.service 中的修改
grep -E 'ExecStartPre|ExecStart|ExecReload' /lib/systemd/system/ssh.service

# 重新加载 systemd 并重启 sshd
if [ "$IS_ROOT" = true ]; then
    systemctl daemon-reload
    systemctl restart sshd
else
    sudo systemctl daemon-reload
    sudo systemctl restart sshd
fi

# 验证正在运行的 SSH 进程
ps -ef | grep sshd

# 更新配置文件链接（可选清理）
if [ "$IS_ROOT" = true ]; then
    rm /usr/local/etc/sshd_config
    ln -s /etc/ssh/sshd_config /usr/local/etc/sshd_config
    systemctl daemon-reload
    systemctl restart sshd
else
    sudo rm /usr/local/etc/sshd_config
    sudo ln -s /etc/ssh/sshd_config /usr/local/etc/sshd_config
    sudo systemctl daemon-reload
    sudo systemctl restart sshd
fi

# 清理旧版本（可选）
if [ "$IS_ROOT" = true ]; then
    rm /usr/sbin/sshd
else
    sudo rm /usr/sbin/sshd
fi

echo "OpenSSH 升级至版本 9.8p1 完成。"
ssh -V
