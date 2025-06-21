# Aztec 节点自动化部署项目

## 项目简介

这是一个用于自动化部署 Aztec 验证者节点的 Ansible 项目。通过简单的配置，可以快速部署和管理多个 Aztec 节点。

## 项目结构

```
ansible/
├── README.md                           # 项目说明文档
├── 部署教程.md                         # 详细部署教程
├── key.txt                            # 节点配置文件（私钥,地址,IP）
├── generate_inventory.sh              # 生成 Ansible 库存文件
├── deploy_validator.yaml              # Ansible 部署剧本
├── check_ansible_connectivity.sh      # 连接测试脚本
├── pre_add_ssh_fingerprints.sh        # SSH 指纹预添加脚本
├── 快速部署.sh                         # 一键快速部署脚本
├── 客户机环境准备.sh                    # 客户机环境准备脚本
└── root用户配置说明.md                  # Root 用户配置说明
```

## 安全说明

⚠️ **重要提醒**：
- 本项目中的 `key.txt` 文件包含示例数据，不包含真实的私钥和地址
- 部署前请将 `key.txt` 中的示例数据替换为您的真实数据
- 请妥善保管您的私钥，不要泄露给他人
- 建议将 `key.txt` 文件权限设置为 600：`chmod 600 key.txt`

## 快速开始

### 1. 宿主机准备

```bash
# 安装 Ansible
sudo apt install ansible  # Ubuntu/Debian
# 或
sudo yum install ansible  # CentOS/RHEL

# 配置 SSH 密钥
ssh-keygen -t rsa -b 4096
```

### 2. 客户机准备

在每台目标服务器上运行：

```bash
# 下载并运行环境准备脚本
curl -O https://raw.githubusercontent.com/your-repo/ansible/客户机环境准备.sh
chmod +x 客户机环境准备.sh
./客户机环境准备.sh
```

**注意：** 本部署使用 root 用户运行 Aztec 节点，所有文件将部署到 `/root` 目录下。请确保 root 用户可以 SSH 登录。

### 3. 配置节点信息

编辑 `key.txt` 文件，添加节点信息：

```
私钥,钱包地址,服务器IP
0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef,0x1234567890abcdef1234567890abcdef1234567890,192.168.1.100
```

### 4. 一键部署

```bash
chmod +x 快速部署.sh
./快速部署.sh
```

## 详细文档

- [部署教程.md](部署教程.md) - 完整的部署指南
- [客户机环境准备.sh](客户机环境准备.sh) - 客户机环境准备脚本
- [root用户配置说明.md](root用户配置说明.md) - Root 用户配置说明

## 功能特性

- ✅ 自动化部署 Aztec 验证者节点
- ✅ 支持多节点批量部署
- ✅ PM2 进程管理
- ✅ 自动开机启动
- ✅ SSH 指纹预添加
- ✅ 连接测试
- ✅ 日志管理
- ✅ 故障排除指南

## 系统要求

### 宿主机
- Linux/macOS/Windows (WSL)
- Python 3.7+
- Ansible 2.9+
- SSH 客户端

### 客户机
- Ubuntu 20.04+ 或 CentOS 7+
- 4GB+ RAM
- 50GB+ 可用存储
- 稳定的网络连接

## 常用命令

### 查看节点状态
```bash
ansible all -i inventory.ini -m shell -a "pm2 status"
```

### 重启所有节点
```bash
ansible all -i inventory.ini -m shell -a "pm2 restart aztec-{{ p2p_ip }}"
```

### 查看日志
```bash
ansible all -i inventory.ini -m shell -a "pm2 logs aztec-{{ p2p_ip }}"
```

### 停止所有节点
```bash
ansible all -i inventory.ini -m shell -a "pm2 stop aztec-{{ p2p_ip }}"
```

## 故障排除

### 常见问题

1. **SSH 连接失败**
   - 检查 SSH 密钥配置
   - 确认防火墙设置
   - 验证用户名和 IP

2. **PM2 进程启动失败**
   - 检查 Node.js 安装
   - 查看错误日志
   - 确认 Aztec CLI 安装

3. **网络连接问题**
   - 检查 RPC 地址可访问性
   - 确认端口开放

### 日志位置
- PM2 日志：`/root/aztec-IP.log`
- 错误日志：`/root/aztec-IP-error.log`
- PM2 日志：`pm2 logs aztec-IP`

## 安全注意事项

- 🔒 保护私钥安全，设置文件权限为 600
- 🔒 使用强 SSH 密钥认证
- 🔒 定期更新系统和软件包
- 🔒 监控系统资源使用情况

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目。

## 许可证

MIT License

## 联系方式

如有问题，请通过以下方式联系：
- 提交 GitHub Issue
- 发送邮件至：your-email@example.com

---

**注意：** 请根据您的具体环境和需求调整配置参数。