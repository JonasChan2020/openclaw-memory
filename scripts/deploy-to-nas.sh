#!/bin/bash
# OpenClaw NAS 自动部署脚本
# 作者: OpenClaw AI
# 用途: 一键配置 Docker API 并部署应用到 NAS

set -e

# 配置
NAS_HOST="192.168.3.6"
NAS_PORT="6022"
NAS_USER="jonas"
NAS_PASSWORD="1988Chen0219"  # 密码只在这里使用一次

echo "🚀 开始自动部署..."

# 1. SSH 连接并配置 Docker API
echo "📡 配置 NAS Docker API..."
sshpass -p "$NAS_PASSWORD" ssh -o StrictHostKeyChecking=no -p $NAS_PORT $NAS_USER@$NAS_HOST << 'EOF'
    # 获取 root 权限
    echo "$NAS_PASSWORD" | sudo -S vi /var/packages/Docker/etc/dockerd.json << 'JSON'
{
    "storage-opts": [],
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "hosts": [
        "unix:///var/run/docker.sock",
        "tcp://0.0.0.0:2375"
    ]
}
JSON

    # 重启 Docker 服务
    echo "$NAS_PASSWORD" | sudo -S synoservice --restart pkgctl-Docker
    sleep 5
    
    # 验证 Docker API
    if curl -s http://localhost:2375/version > /dev/null; then
        echo "✅ Docker API 已开启!"
    else
        echo "❌ Docker API 开启失败"
    fi
EOF

# 2. 复制构建文件到 NAS
echo "📦 复制文件到 NAS..."
sshpass -p "$NAS_PASSWORD" scp -o StrictHostKeyChecking=no -P $NAS_PORT -r docker/app docker/nginx/dist $NAS_USER@$NAS_HOST:/volume1/docker/

# 3. 部署 Docker 容器
echo "🚀 部署 Docker 容器..."
sshpass -p "$NAS_PASSWORD" ssh -o StrictHostKeyChecking=no -p $NAS_PORT $NAS_USER@$NAS_HOST << 'EOF'
    cd /volume1/docker
    
    # 停止旧容器
    docker-compose down || true
    
    # 启动新容器
    docker-compose up -d
    
    echo "✅ 部署完成!"
    echo "🌐 访问地址:"
    echo "  - 前端: http://$NAS_HOST:9100"
    echo "  - API: http://$NAS_HOST:9102"
EOF

echo "🎉 全部完成!"
