#!/bin/bash

# 客户机环境准备脚本
# 在目标服务器上运行此脚本来安装必要的软件

set -e

echo "🔧 开始准备客户机环境..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检测操作系统
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [[ -f /etc/lsb-release ]]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [[ -f /etc/debian_version ]]; then
        OS=Debian
        VER=$(cat /etc/debian_version)
    elif [[ -f /etc/SuSe-release ]]; then
        OS=SuSE
    elif [[ -f /etc/redhat-release ]]; then
        OS=RedHat
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    
    log_info "检测到操作系统: $OS $VER"
}

# 系统更新
update_system() {
    log_info "更新系统包..."
    
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        sudo apt update && sudo apt upgrade -y
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        sudo yum update -y
    else
        log_warning "未知操作系统，跳过系统更新"
    fi
    
    log_success "系统更新完成"
}

# 安装基础工具
install_basic_tools() {
    log_info "安装基础工具..."
    
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        sudo apt install -y curl wget git build-essential
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        sudo yum install -y curl wget git gcc gcc-c++ make
    fi
    
    log_success "基础工具安装完成"
}

# 安装 Node.js
install_nodejs() {
    log_info "安装 Node.js..."
    
    # 检查是否已安装
    if command -v node &> /dev/null; then
        local node_version=$(node --version)
        log_info "Node.js 已安装: $node_version"
        
        # 检查版本是否满足要求
        if [[ "$node_version" =~ v([0-9]+) ]]; then
            local major_version=${BASH_REMATCH[1]}
            if [[ $major_version -ge 18 ]]; then
                log_success "Node.js 版本满足要求"
                return 0
            fi
        fi
    fi
    
    # 安装 Node.js 18.x
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
        sudo yum install -y nodejs
    fi
    
    # 验证安装
    if command -v node &> /dev/null; then
        log_success "Node.js 安装完成: $(node --version)"
        log_success "npm 安装完成: $(npm --version)"
    else
        log_error "Node.js 安装失败"
        exit 1
    fi
}

# 安装 PM2
install_pm2() {
    log_info "安装 PM2..."
    
    if command -v pm2 &> /dev/null; then
        log_info "PM2 已安装: $(pm2 --version)"
    else
        sudo npm install -g pm2
        log_success "PM2 安装完成"
    fi
}

# 安装 Aztec CLI
install_aztec_cli() {
    log_info "安装 Aztec CLI..."
    
    if command -v aztec &> /dev/null; then
        log_info "Aztec CLI 已安装"
    else
        npm install -g @aztec/cli
        log_success "Aztec CLI 安装完成"
    fi
}

# 配置 SSH
configure_ssh() {
    log_info "配置 SSH..."
    
    # 配置 root 用户 SSH
    sudo mkdir -p /root/.ssh
    sudo chmod 700 /root/.ssh
    
    if [[ ! -f /root/.ssh/authorized_keys ]]; then
        sudo touch /root/.ssh/authorized_keys
        sudo chmod 600 /root/.ssh/authorized_keys
        log_info "创建了 /root/.ssh/authorized_keys 文件"
    fi
    
    log_success "Root 用户 SSH 配置完成"
    log_warning "请确保将控制机的公钥添加到 /root/.ssh/authorized_keys"
    log_warning "注意：本部署将使用 root 用户运行 Aztec 节点"
}

# 配置防火墙
configure_firewall() {
    log_info "配置防火墙..."
    
    if command -v ufw &> /dev/null; then
        # Ubuntu 防火墙
        sudo ufw allow ssh
        sudo ufw allow 8545/tcp  # L1 RPC
        sudo ufw allow 5052/tcp  # Beacon RPC
        sudo ufw --force enable
        log_success "UFW 防火墙配置完成"
    elif command -v firewall-cmd &> /dev/null; then
        # CentOS 防火墙
        sudo firewall-cmd --permanent --add-service=ssh
        sudo firewall-cmd --permanent --add-port=8545/tcp
        sudo firewall-cmd --permanent --add-port=5052/tcp
        sudo firewall-cmd --reload
        log_success "firewalld 防火墙配置完成"
    else
        log_warning "未检测到防火墙，请手动配置端口开放"
    fi
}

# 创建必要的目录
create_directories() {
    log_info "创建必要的目录..."
    
    sudo mkdir -p /root
    sudo chown root:root /root
    sudo chmod 755 /root
    
    log_success "目录创建完成"
}

# 显示系统信息
show_system_info() {
    log_info "系统信息："
    echo "  操作系统: $OS $VER"
    echo "  内核版本: $(uname -r)"
    echo "  架构: $(uname -m)"
    echo "  内存: $(free -h | awk 'NR==2{printf "%.1f GB", $2/1024}')"
    echo "  磁盘空间: $(df -h / | awk 'NR==2{print $4}') 可用"
    echo "  Node.js: $(node --version)"
    echo "  npm: $(npm --version)"
    echo "  PM2: $(pm2 --version)"
    echo "  Aztec CLI: $(aztec --version 2>/dev/null || echo '未安装')"
}

# 显示后续步骤
show_next_steps() {
    log_info "环境准备完成！"
    echo ""
    echo "📋 后续步骤："
    echo "  1. 确保控制机的 SSH 公钥已添加到 ~/.ssh/authorized_keys"
    echo "  2. 在控制机上运行部署脚本"
    echo "  3. 监控节点运行状态"
    echo ""
    echo "🔧 常用命令："
    echo "  查看 PM2 进程: pm2 status"
    echo "  查看 PM2 日志: pm2 logs"
    echo "  重启进程: pm2 restart <进程名>"
    echo "  停止进程: pm2 stop <进程名>"
    echo ""
    echo "📁 日志文件位置："
    echo "  /root/aztec-*.log"
    echo "  /root/aztec-*-error.log"
}

# 主函数
main() {
    echo "=========================================="
    echo "    客户机环境准备脚本"
    echo "=========================================="
    echo ""
    
    detect_os
    update_system
    install_basic_tools
    install_nodejs
    install_pm2
    install_aztec_cli
    configure_ssh
    configure_firewall
    create_directories
    show_system_info
    show_next_steps
    
    echo ""
    log_success "🎉 客户机环境准备完成！"
}

# 执行主函数
main "$@" 