# Root 用户配置说明

## 概述

本 Aztec 节点部署项目使用 root 用户运行所有服务，所有文件都部署在 `/root` 目录下。本文档说明如何正确配置 root 用户 SSH 访问。

## 为什么使用 Root 用户？

1. **简化权限管理** - 避免文件权限问题
2. **统一部署路径** - 所有文件都在 `/root` 目录
3. **PM2 进程管理** - 以 root 用户运行 PM2 进程
4. **日志文件管理** - 日志文件保存在 `/root` 目录
5. **系统服务管理** - 直接管理系统级服务
6. **端口绑定** - 避免端口权限问题

## 完整配置流程

### 第一步：在宿主机上生成 SSH 密钥

```bash
# 生成 SSH 密钥对（推荐使用 ed25519）
ssh-keygen -t ed25519 -C "aztec-deploy"

# 或者使用 RSA（如果需要兼容旧系统）
ssh-keygen -t rsa -b 4096 -C "aztec-deploy"

# 查看生成的公钥
cat ~/.ssh/id_ed25519.pub
# 或者
cat ~/.ssh/id_rsa.pub
```

### 第二步：在客户机上配置 Root 用户 SSH

```bash
# 1. 设置 root 用户密码（如果需要）
sudo passwd root

# 2. 创建 root 用户的 SSH 目录
sudo mkdir -p /root/.ssh
sudo chmod 700 /root/.ssh

# 3. 创建 authorized_keys 文件
sudo touch /root/.ssh/authorized_keys
sudo chmod 600 /root/.ssh/authorized_keys

# 4. 添加控制机的公钥（替换为您的实际公钥）
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICCuLgJ401AVRHC9Ejp6flDgg5W5aI5vxxiXmE5VIqC example@host" | sudo tee -a /root/.ssh/authorized_keys

# 5. 验证权限设置
ls -la /root/.ssh/
```

### 第三步：配置 SSH 服务

```bash
# 1. 编辑 SSH 配置文件
sudo nano /etc/ssh/sshd_config

# 2. 确保以下设置（取消注释或添加）
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication no
AuthorizedKeysFile .ssh/authorized_keys

# 3. 重启 SSH 服务
sudo systemctl restart ssh

# 4. 检查 SSH 服务状态
sudo systemctl status ssh
```

### 第四步：在宿主机上测试连接

```bash
# 测试 root 用户 SSH 连接
ssh root@目标服务器IP

# 如果连接成功，说明配置正确
# 可以退出测试连接
exit
```

## 安全配置

### SSH 安全设置

```bash
# 1. 禁用密码认证
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# 2. 禁用 root 密码登录（只允许密钥）
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

# 3. 限制 SSH 用户
sudo sed -i 's/#AllowUsers/AllowUsers root/' /etc/ssh/sshd_config

# 4. 更改默认 SSH 端口（可选，提高安全性）
sudo sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config

# 5. 重启 SSH 服务
sudo systemctl restart ssh
```

### 防火墙配置

```bash
# Ubuntu/Debian (UFW)
sudo ufw allow ssh
sudo ufw allow 8545/tcp  # L1 RPC
sudo ufw allow 5052/tcp  # Beacon RPC
sudo ufw --force enable

# CentOS/RHEL (firewalld)
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-port=8545/tcp
sudo firewall-cmd --permanent --add-port=5052/tcp
sudo firewall-cmd --reload
```

### 系统安全设置

```bash
# 1. 更新系统
sudo apt update && sudo apt upgrade -y

# 2. 安装安全工具
sudo apt install fail2ban -y

# 3. 配置 fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# 4. 设置自动更新
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure -plow unattended-upgrades
```

## 故障排除

### SSH 连接问题

1. **权限问题**
   ```bash
   # 检查 SSH 目录权限
   ls -la /root/.ssh/
   
   # 修复权限
   sudo chmod 700 /root/.ssh
   sudo chmod 600 /root/.ssh/authorized_keys
   sudo chown root:root /root/.ssh
   sudo chown root:root /root/.ssh/authorized_keys
   ```

2. **SSH 服务问题**
   ```bash
   # 检查 SSH 服务状态
   sudo systemctl status ssh
   
   # 查看 SSH 日志
   sudo journalctl -u ssh
   
   # 重启 SSH 服务
   sudo systemctl restart ssh
   ```

3. **防火墙问题**
   ```bash
   # 检查防火墙状态
   sudo ufw status
   
   # 临时禁用防火墙测试
   sudo ufw disable
   
   # 重新启用防火墙
   sudo ufw enable
   ```

4. **网络连接问题**
   ```bash
   # 测试网络连接
   ping 目标服务器IP
   
   # 测试端口连接
   telnet 目标服务器IP 22
   
   # 检查 SSH 端口
   sudo netstat -tlnp | grep :22
   ```

### 部署问题

1. **权限错误**
   ```bash
   # 检查 /root 目录权限
   ls -la /root/
   
   # 修复权限
   sudo chown root:root /root
   sudo chmod 755 /root
   ```

2. **PM2 进程问题**
   ```bash
   # 检查 PM2 进程
   pm2 status
   
   # 查看 PM2 日志
   pm2 logs
   
   # 重启 PM2 进程
   pm2 restart all
   
   # 删除 PM2 进程
   pm2 delete all
   ```

3. **Node.js 问题**
   ```bash
   # 检查 Node.js 版本
   node --version
   
   # 检查 npm 版本
   npm --version
   
   # 重新安装 Node.js
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt-get install -y nodejs
   ```

## 监控和维护

### 系统监控

```bash
# 1. 查看系统资源
htop
df -h
free -h

# 2. 查看进程状态
ps aux | grep aztec
ps aux | grep pm2

# 3. 查看网络连接
netstat -tlnp
ss -tlnp

# 4. 查看系统日志
sudo journalctl -f
sudo tail -f /var/log/syslog
```

### 日志管理

```bash
# 1. 查看 Aztec 节点日志
tail -f /root/aztec-*.log
tail -f /root/aztec-*-error.log

# 2. 查看 PM2 日志
pm2 logs
pm2 logs --lines 100

# 3. 查看 SSH 访问日志
sudo tail -f /var/log/auth.log

# 4. 查看系统日志
sudo tail -f /var/log/syslog
```

### 备份策略

```bash
# 1. 备份 SSH 密钥
cp -r ~/.ssh ~/.ssh_backup

# 2. 备份配置文件
sudo cp /root/aztec-start.sh /root/aztec-start.sh.backup

# 3. 备份 PM2 配置
pm2 save
cp ~/.pm2 ~/.pm2_backup

# 4. 备份系统配置
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
```

## 最佳实践

### 安全最佳实践

1. **使用专用服务器**
   - 为 Aztec 节点使用专用服务器
   - 避免与其他服务冲突
   - 定期备份重要数据

2. **定期维护**
   - 定期检查节点状态
   - 更新软件版本
   - 清理日志文件

3. **监控和告警**
   - 设置系统监控
   - 配置告警通知
   - 监控磁盘空间

4. **访问控制**
   - 限制 SSH 访问来源 IP
   - 使用强 SSH 密钥
   - 定期轮换密钥

### 性能优化

```bash
# 1. 系统优化
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
echo 'net.core.rmem_max=134217728' | sudo tee -a /etc/sysctl.conf
echo 'net.core.wmem_max=134217728' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# 2. 文件描述符限制
echo 'root soft nofile 65536' | sudo tee -a /etc/security/limits.conf
echo 'root hard nofile 65536' | sudo tee -a /etc/security/limits.conf

# 3. 日志轮转
sudo logrotate -f /etc/logrotate.conf
```

## 常见问题解答

### Q: 为什么使用 root 用户而不是普通用户？
A: 使用 root 用户可以避免文件权限问题，简化部署流程，所有文件统一在 `/root` 目录下管理。

### Q: 如何确保 SSH 连接安全？
A: 使用强 SSH 密钥认证，禁用密码登录，配置防火墙，限制访问来源 IP。

### Q: 如果 SSH 连接失败怎么办？
A: 检查 SSH 服务状态、防火墙设置、密钥权限、网络连接等，参考故障排除部分。

### Q: 如何监控节点运行状态？
A: 使用 `pm2 status` 查看进程状态，`pm2 logs` 查看日志，`htop` 查看系统资源。

### Q: 如何备份重要数据？
A: 定期备份 SSH 密钥、配置文件、PM2 配置等，参考备份策略部分。

## 总结

使用 root 用户部署 Aztec 节点可以简化配置和管理，但需要注意安全性。建议：

1. **安全配置**
   - 使用强 SSH 密钥认证
   - 禁用密码登录
   - 配置防火墙规则
   - 限制访问来源

2. **系统维护**
   - 定期更新系统和软件
   - 监控系统资源使用
   - 备份重要配置文件
   - 清理日志文件

3. **监控管理**
   - 设置系统监控
   - 配置告警通知
   - 定期检查节点状态
   - 及时处理异常

4. **性能优化**
   - 优化系统参数
   - 配置日志轮转
   - 监控磁盘空间
   - 定期维护

通过以上配置和管理，可以确保 Aztec 节点安全、稳定、高效地运行。 