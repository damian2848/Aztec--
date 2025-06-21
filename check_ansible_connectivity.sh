#!/bin/bash

INVENTORY_FILE="inventory.ini"
REMOTE_USER="root"  # 使用 root 用户，因为部署剧本使用 root
PRIVATE_KEY_PATH="$HOME/.ssh/id_rsa"  # 你用来连接目标主机的私钥路径

echo "🔍 开始检测 Ansible 是否可以连接主机..."

# 检查 inventory 文件是否存在
if [[ ! -f "$INVENTORY_FILE" ]]; then
  echo "❌ 错误：未找到 $INVENTORY_FILE"
  exit 1
fi

# 执行 Ansible ping 模块测试连接
ansible all -i "$INVENTORY_FILE" -u "$REMOTE_USER" --private-key "$PRIVATE_KEY_PATH" -m ping

# 检测返回码
if [[ $? -eq 0 ]]; then
  echo "✅ 所有主机连接成功！"
else
  echo "⚠️ 某些主机连接失败，请检查上面的输出"
fi

