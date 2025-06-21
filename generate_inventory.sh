#!/bin/bash

INPUT_FILE="key.txt"
INVENTORY_FILE="inventory.ini"
VARS_DIR="host_vars"
GROUP_NAME="validators"

# 检查输入文件是否存在
if [ ! -f "$INPUT_FILE" ]; then
    echo "❌ 错误：找不到输入文件 $INPUT_FILE"
    exit 1
fi

# 检查输入文件是否为空
if [ ! -s "$INPUT_FILE" ]; then
    echo "❌ 错误：$INPUT_FILE 文件为空"
    exit 1
fi

echo "📖 读取输入文件: $INPUT_FILE"
echo "📄 文件内容:"
cat "$INPUT_FILE"
echo "📏 文件大小: $(wc -c < "$INPUT_FILE") 字节"
echo "📏 文件行数: $(wc -l < "$INPUT_FILE") 行"

mkdir -p "$VARS_DIR"
echo "[$GROUP_NAME]" > "$INVENTORY_FILE"

line_count=0

# 使用更可靠的方法读取文件
while IFS=',' read -r pk address ip || [ -n "$pk" ]; do
  line_count=$((line_count + 1))
  echo "🔍 处理第 $line_count 行:"
  echo "  私钥: '$pk'"
  echo "  地址: '$address'" 
  echo "  IP: '$ip'"
  
  # 清理数据，移除前后空格和换行符
  ip_clean=$(echo "$ip" | tr -d '\r\n' | xargs)
  pk_clean=$(echo "$pk" | tr -d '\r\n' | xargs)
  address_clean=$(echo "$address" | tr -d '\r\n' | xargs)

  # 检查是否所有字段都不为空
  if [ -z "$ip_clean" ] || [ -z "$pk_clean" ] || [ -z "$address_clean" ]; then
    echo "⚠️ 警告：跳过无效行（缺少字段）"
    echo "  清理后 - 私钥: '$pk_clean'"
    echo "  清理后 - 地址: '$address_clean'"
    echo "  清理后 - IP: '$ip_clean'"
    continue
  fi

  echo "✅ 清理后的数据:"
  echo "  私钥: '$pk_clean'"
  echo "  地址: '$address_clean'"
  echo "  IP: '$ip_clean'"

  # 写入 inventory.ini
  echo "$ip_clean" >> "$INVENTORY_FILE"
  echo "📝 已添加到 inventory.ini: $ip_clean"

  # 写入每个 host 的变量文件（host_vars/IP.yml）
  cat > "${VARS_DIR}/${ip_clean}.yml" <<EOF
validator_private_key: "$pk_clean"
coinbase_address: "$address_clean"
p2p_ip: "$ip_clean"
EOF
  echo "📁 已创建变量文件: ${VARS_DIR}/${ip_clean}.yml"

done < "$INPUT_FILE"

echo "✅ 生成完成：$INVENTORY_FILE 和每个主机的 host_vars/"
echo "📊 处理了 $line_count 行数据"

