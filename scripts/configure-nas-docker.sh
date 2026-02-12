#!/bin/bash
# NAS Docker API 配置脚本
# 自动在 NAS 上配置 Docker API

NAS_HOST="192.168.3.6"
NAS_PORT="6022"
NAS_USER="jonas"
NAS_PASSWORD="1988Chen0219"

# 创建配置脚本
cat > /tmp/configure_docker_api.sh << 'SCRIPT'
#!/bin/bash

# 获取 root 权限
echo "$1" | sudo -S vi /var/packages/Docker/etc/dockerd.json << 'EOF'
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
EOF

# 重启 Docker 服务
synoservice --restart pkgctl-Docker

# 等待服务启动
sleep 5

# 验证
curl -s http://localhost:2375/version && echo "Docker API is running!"
SCRIPT

# 上传并执行脚本
echo "$NAS_PASSWORD" | ssh -o StrictHostKeyChecking=no -p $NAS_PORT $NAS_USER@$NAS_HOST "cat > /tmp/configure_docker_api.sh" < /tmp/configure_docker_api.sh

# 执行配置
echo "$NAS_PASSWORD" | ssh -o StrictHostKeyChecking=no -p $NAS_PORT $NAS_USER@$NAS_HOST "chmod +x /tmp/configure_docker_api.sh && bash /tmp/configure_docker_api.sh $NAS_PASSWORD"
