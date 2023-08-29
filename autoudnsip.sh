#!/bin/bash
curl -s https://raw.githubusercontent.com/notetoday/dnsmasq_sniproxy_install/master/dns.txt > temp_dns.txt

# 获取 DNS 列表
dns_list=$(cat temp_dns.txt)

# 替换 IP
custom_config="/etc/dnsmasq.d/custom_netflix.conf"
changes_made=false  # 用于跟踪是否进行了修改

while read line; do
  domain=$(echo "$line" | grep -o '/.*' | sed 's/^\///g')
  new_ip=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+')

  # 检查是否需要替换行
  if ! grep -qF "$domain/$new_ip" "$custom_config"; then
    sed -i "s|$domain/[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+|$domain/$new_ip|" "$custom_config"
    changes_made=true
  fi
done <<< "$dns_list"

# 清理临时文件
rm temp_dns.txt

if [ "$changes_made" = true ]; then
  # 重新启动网络服务
  systemctl restart dnsmasq
  # 提示操作完成
  echo "替换完成！服务已重启。"
else
  echo "内容无变化，无需操作。"
fi
