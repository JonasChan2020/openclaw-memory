#!/bin/bash
# GitHub Token 配置脚本

read -sp "输入 GitHub Personal Access Token: " GH_TOKEN
echo ""

# 设置 token
gh auth login --with-token "$GH_TOKEN" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✓ GitHub 登录成功!"
else
    echo "✗ 登录失败，请手动运行: gh auth login"
fi
