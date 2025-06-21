#!/bin/bash

# Aztec 节点快速部署脚本
# 使用方法: ./快速部署.sh

set -e  # 遇到错误立即退出

echo "🚀 开始 Aztec 节点快速部署..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检查必要文件
check_files() {
    log_info "检查必要文件..."
    
    local required_files=("key.txt" "generate_inventory.sh" "deploy_validator.yaml" "check_ansible_connectivity.sh" "pre_add_ssh_fingerprints.sh")
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "缺少必要文件: $file"
            exit 1
        fi
    done
    
    log_success "所有必要文件检查通过"
}

# 检查 Ansible 是否安装
check_ansible() {
    log_info "检查 Ansible 安装..."
    
    if ! command -v ansible &> /dev/null; then
        log_error "Ansible 未安装，请先安装 Ansible"
        echo "安装命令："
        echo "  Ubuntu/Debian: sudo apt install ansible"
        echo "  CentOS/RHEL: sudo yum install ansible"
        echo "  macOS: brew install ansible"
        exit 1
    fi
    
    log_success "Ansible 已安装: $(ansible --version | head -n1)"
}

# 检查 SSH 密钥
check_ssh_key() {
    log_info "检查 SSH 密钥..."
    
    if [[ ! -f "$HOME/.ssh/id_rsa" ]]; then
        log_warning "未找到 SSH 私钥，请确保已配置 SSH 密钥"
        echo "生成 SSH 密钥命令："
        echo "  ssh-keygen -t rsa -b 4096 -C 'your_email@example.com'"
        echo "请确保已将公钥添加到目标服务器的 ~/.ssh/authorized_keys"
        read -p "是否继续？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        log_success "SSH 私钥已找到"
    fi
}

# 生成库存文件
generate_inventory() {
    log_info "生成 Ansible 库存文件..."
    
    if [[ ! -x "generate_inventory.sh" ]]; then
        chmod +x generate_inventory.sh
    fi
    
    ./generate_inventory.sh
    
    if [[ ! -f "inventory.ini" ]]; then
        log_error "生成库存文件失败"
        exit 1
    fi
    
    log_success "库存文件生成完成"
}

# 预添加 SSH 指纹
add_ssh_fingerprints() {
    log_info "预添加 SSH 指纹..."
    
    if [[ ! -x "pre_add_ssh_fingerprints.sh" ]]; then
        chmod +x pre_add_ssh_fingerprints.sh
    fi
    
    ./pre_add_ssh_fingerprints.sh
    log_success "SSH 指纹添加完成"
}

# 测试连接
test_connectivity() {
    log_info "测试 Ansible 连接..."
    
    if [[ ! -x "check_ansible_connectivity.sh" ]]; then
        chmod +x check_ansible_connectivity.sh
    fi
    
    ./check_ansible_connectivity.sh
    
    if [[ $? -ne 0 ]]; then
        log_error "连接测试失败，请检查网络和 SSH 配置"
        exit 1
    fi
    
    log_success "连接测试通过"
}

# 执行部署
deploy_nodes() {
    log_info "开始部署 Aztec 节点..."
    
    ansible-playbook -i inventory.ini deploy_validator.yaml
    
    if [[ $? -ne 0 ]]; then
        log_error "部署失败"
        exit 1
    fi
    
    log_success "部署完成"
}

# 验证部署
verify_deployment() {
    log_info "验证部署结果..."
    
    echo "检查 PM2 进程状态..."
    ansible all -i inventory.ini -m shell -a "pm2 status" || true
    
    echo "检查最近日志..."
    ansible all -i inventory.ini -m shell -a "tail -n 20 /root/aztec-*.log" || true
    
    log_success "验证完成"
}

# 显示使用说明
show_usage() {
    log_info "部署完成！"
    echo ""
    echo "📋 常用管理命令："
    echo "  查看所有节点状态: ansible all -i inventory.ini -m shell -a 'pm2 status'"
    echo "  重启所有节点: ansible all -i inventory.ini -m shell -a 'pm2 restart aztec-{{ p2p_ip }}'"
    echo "  查看日志: ansible all -i inventory.ini -m shell -a 'pm2 logs aztec-{{ p2p_ip }}'"
    echo "  停止所有节点: ansible all -i inventory.ini -m shell -a 'pm2 stop aztec-{{ p2p_ip }}'"
    echo ""
    echo "📁 日志文件位置："
    echo "  PM2 日志: /root/aztec-IP.log"
    echo "  错误日志: /root/aztec-IP-error.log"
    echo ""
    echo "🔧 如需添加新节点，请："
    echo "  1. 在 key.txt 中添加新行"
    echo "  2. 重新运行 ./generate_inventory.sh"
    echo "  3. 执行 ansible-playbook -i inventory.ini deploy_validator.yaml"
}

# 主函数
main() {
    echo "=========================================="
    echo "    Aztec 节点快速部署脚本"
    echo "=========================================="
    echo ""
    
    check_files
    check_ansible
    check_ssh_key
    generate_inventory
    add_ssh_fingerprints
    test_connectivity
    deploy_nodes
    verify_deployment
    show_usage
    
    echo ""
    log_success "🎉 部署流程完成！"
}

# 执行主函数
main "$@" 