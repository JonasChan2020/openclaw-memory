#!/bin/bash
# OpenClaw NAS 自动部署脚本 v3
# 使用 SSHFS 挂载 NAS 文件系统

set -e

NAS_HOST="192.168.3.6"
NAS_PORT="6022"
NAS_USER="jonas"
NAS_PASSWORD="1988Chen0219"
MOUNT_POINT="/tmp/nas_docker"
DOCKER_DIR="/Users/hao/Documents/CODES/NEWCODE/ADMIN.NET.PRO/docker"

echo "🚀 开始自动部署..."

# 1. 创建挂载点
echo "📡 挂载 NAS..."
mkdir -p $MOUNT_POINT

# 2. 挂载 SMB 共享
sshfs -o volname=Docker $NAS_USER@$NAS_HOST:/docker $MOUNT_POINT \
    -o ssh_command="ssh -p $NAS_PORT" \
    -o password_stdin \
    <<< "$NAS_PASSWORD" 2>&1 || echo "Mount attempt..."

# 检查是否挂载成功
if mount | grep -q "$MOUNT_POINT"; then
    echo "✅ 挂载成功!"
    
    # 3. 复制文件
    echo "📦 复制文件..."
    cp -r "$DOCKER_DIR/app/" "$MOUNT_POINT/"
    cp -r "$DOCKER_DIR/nginx/dist/" "$MOUNT_POINT/"
    
    echo "✅ 文件已复制!"
    
    # 4. 卸载
    umount $MOUNT_POINT || true
else
    echo "❌ 挂载失败，请手动复制文件"
    echo ""
    echo "📋 手动操作步骤:"
    echo "1. 在 Finder 中连接: smb://$NAS_HOST"
    echo "2. 用户: $NAS_USER, 密码: $NAS_PASSWORD"
    echo "3. 复制以下目录到 NAS:"
    echo "   - $DOCKER_DIR/app/"
    echo "   - $DOCKER_DIR/nginx/dist/"
fi

echo ""
echo "🎉 完成!"
echo "🌐 请在 Container Manager 中重启容器"
