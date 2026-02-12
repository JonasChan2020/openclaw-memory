#!/bin/bash
# OpenClaw NAS 自动部署脚本 v2
# 使用 SSH 密钥认证 + 无密码 sudo

set -e

NAS_HOST="192.168.3.6"
NAS_PORT="6022"
NAS_USER="jonas"
SSH_KEY="~/.ssh/id_rsa_nas"

echo "🚀 开始自动部署..."

# 1. 复制构建文件到 NAS
echo "📦 复制文件到 NAS..."
rsync -avz -e "ssh -i $SSH_KEY -p $NAS_PORT -o StrictHostKeyChecking=no" \
    --exclude='node_modules' \
    --exclude='.git' \
    "/Users/hao/Documents/CODES/NEWCODE/ADMIN.NET.PRO/docker/" \
    "$NAS_USER@$NAS_HOST:/volume1/docker/" 2>&1 | tail -20

# 2. 重启 Docker 容器
echo "🚀 重启 Docker 容器..."
ssh -i $SSH_KEY -p $NAS_PORT -o StrictHostKeyChecking=no $NAS_USER@$NAS_HOST << 'EOF'
    cd /volume1/docker
    
    # 停止并启动容器
    docker-compose down 2>/dev/null || true
    docker-compose up -d
    
    # 等待服务启动
    sleep 10
    
    echo "✅ 容器已重启!"
EOF

echo ""
echo "🎉 部署完成!"
echo "🌐 访问地址:"
echo "  - 前端: http://$NAS_HOST:9100"
echo "  - API: http://$NAS_HOST:9102"
