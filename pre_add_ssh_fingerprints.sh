#!/bin/bash

# 定义变量
KNOWN_HOSTS_FILE="$HOME/.ssh/known_hosts"
INVENTORY_FILE="inventory.ini"  # 你的Ansible库存文件
SSH_PORT="22"  # 默认SSH端口，如有不同请修改
TEMP_KEYS=$(mktemp)  # 临时存储收集的密钥

# 创建known_hosts文件（如果不存在）
mkdir -p ~/.ssh
touch "$KNOWN_HOSTS_FILE"
chmod 600 "$KNOWN_HOSTS_FILE"

# 检查依赖项
if ! command -v ssh-keyscan &> /dev/null; then
    echo "❌ 错误：ssh-keyscan 工具未安装，请先安装openssh-client"
    exit 1
fi

# 从inventory文件提取IP/主机名
extract_hosts() {
    # 提取所有非注释行的主机名/IP
    grep -Eo '^[^#[:space:]]+' "$INVENTORY_FILE" | \
    grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|[a-zA-Z0-9.-]+' | \
    sort -u
}

# 收集指纹
collect_fingerprints() {
    echo "🔍 开始收集主机SSH指纹..."
    while read -r host; do
        if ! grep -q "^$host" "$KNOWN_HOSTS_FILE"; then
            echo "正在处理: $host"
            ssh-keyscan -p "$SSH_PORT" -H "$host" >> "$TEMP_KEYS" 2>/dev/null
        else
            echo "已存在: $host (跳过)"
        fi
    done < <(extract_hosts)
}

# 验证并合并密钥
merge_keys() {
    if [ -s "$TEMP_KEYS" ]; then
        echo "✅ 发现新主机指纹:"
        cat "$TEMP_KEYS"
        
        # 验证密钥格式
        if ssh-keygen -lf "$TEMP_KEYS" &>/dev/null; then
            cat "$TEMP_KEYS" >> "$KNOWN_HOSTS_FILE"
            echo "指纹已安全添加到 $KNOWN_HOSTS_FILE"
        else
            echo "❌ 错误：收集到无效的SSH密钥"
            exit 1
        fi
    else
        echo "ℹ️ 没有发现新主机需要添加"
    fi
}

# 主流程
collect_fingerprints
merge_keys

# 清理
rm -f "$TEMP_KEYS"

echo "🎉 操作完成！现在运行Ansible将不再提示密钥确认"
