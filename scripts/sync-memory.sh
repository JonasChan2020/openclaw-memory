#!/bin/bash
# OpenClaw 记忆同步脚本
# 自动同步到 NAS 和 GitHub

DATE=$(date +%Y-%m-%d_%H:%M)
SOURCE="/Users/hao/clawd"
BACKUP_DIR="$HOME/memory_backup"
NAS_PATH="/Volumes/memory"  # 待挂载
NAS_IP="192.168.3.6"

echo "[$DATE] 同步记忆文件..."

# 1. Git 提交并推送
cd "$SOURCE"
git add memory/ MEMORY.md
git commit -m "memory: $DATE" || echo "Nothing to commit"
git push origin main 2>/dev/null && echo "✓ GitHub synced" || echo "✗ GitHub sync failed"

# 2. 同步到本地备份
cp -r "$SOURCE/memory" "$BACKUP_DIR/"
cp "$SOURCE/MEMORY.md" "$BACKUP_DIR/"
echo "✓ Local backup updated"

# 3. 同步到 NAS (如果已挂载)
if mount | grep -q "$NAS_PATH"; then
    cp -r "$SOURCE/memory" "$NAS_PATH/"
    cp "$SOURCE/MEMORY.md" "$NAS_PATH/"
    echo "✓ NAS synced"
else
    echo "! NAS not mounted, skipped"
    echo "  To mount: mount_smbfs //jonas:1988Chen0219@$NAS_IP/JonasWorkSpace/memory $NAS_PATH"
fi

echo "[$DATE] Sync complete!"
