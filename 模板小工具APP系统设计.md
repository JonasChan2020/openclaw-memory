# 模板+小工具综合App系统设计文档

## 一、项目概述

### 1.1 产品定位
- 聚合优质模板资源（Notion、ChatGPT提示词、Excel、简历等）
- 提供实用小工具（单位换算、图片处理、批量操作等）
- 采用订阅制变现（月度/年度VIP）

### 1.2 目标用户
- 追求效率的职场人士
- 内容创作者/知识工作者
- 学生群体
- 小微创业者

---

## 二、系统架构

### 2.1 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│                        客户端层                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  iOS App    │  │ Android App │  │ 小程序/H5  │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      API网关层                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Nginx / Traefik (负载均衡、限流、SSL、静态资源)      │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
              ┌─────────────┼─────────────┐
              ▼             ▼             ▼
┌──────────────────┐ ┌──────────────┐ ┌──────────────┐
│    用户服务       │ │  内容服务    │ │  工具服务    │
│  (Auth Service)  │ │ (Content)    │ │  (Tools)     │
└──────────────────┘ └──────────────┘ └──────────────┘
              │             │             │
              ▼             ▼             ▼
┌─────────────────────────────────────────────────────────────┐
│                      业务服务层                              │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐              │
│  │ 支付服务   │ │ 分析服务   │ │ 消息服务   │              │
│  │ Payment   │ │ Analytics  │ │ Messaging  │              │
│  └────────────┘ └────────────┘ └────────────┘              │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐              │
│  │ 订阅服务   │ │ 反馈服务   │ │ 运营后台   │              │
│  │ Subscription│ │ Feedback  │ │ Admin      │              │
│  └────────────┘ └────────────┘ └────────────┘              │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      数据存储层                              │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐              │
│  │  MySQL     │ │  Redis     │ │  OSS存储   │              │
│  │ (主数据库) │ │ (缓存/会话) │ │ (文件/图片)│              │
│  └────────────┘ └────────────┘ └────────────┘              │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐              │
│  │  MongoDB   │ │  ClickHouse│ │  Kafka     │              │
│  │ (日志/反馈) │ │ (数据分析) │ │ (消息队列) │              │
│  └────────────┘ └────────────┘ └────────────┘              │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    第三方服务集成                            │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐              │
│  │ 微信/支付宝 │ │ 苹果IAP   │ │ 短信服务   │              │
│  └────────────┘ └────────────┘ └────────────┘              │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐              │
│  │ 邮件服务   │ │ CDN服务    │ │ 数据埋点   │              │
│  └────────────┘ └────────────┘ └────────────┘              │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 技术选型

| 层级 | 技术栈 | 说明 |
|------|--------|------|
| 客户端 | Flutter / React Native | 跨平台、一套代码覆盖iOS/Android |
| 后端框架 | Go (Gin) / Node.js (NestJS) | 高性能、易开发 |
| 数据库 | MySQL 8.0 | 主业务数据 |
| 缓存 | Redis 7.x | 会话、热点数据、限流 |
| 文件存储 | 阿里云 OSS / 腾讯云 COS | 模板文件、图片 |
| 日志/反馈 | MongoDB | 非结构化数据存储 |
| 数据分析 | ClickHouse | 实时分析、用户行为 |
| 消息队列 | Kafka | 异步处理、事件驱动 |
| 消息推送 | 极光推送 / Firebase | 通知触达 |
| 监控 | Prometheus + Grafana | 系统监控 |

---

## 三、功能模块设计

### 3.1 用户系统

#### 3.1.1 功能清单
| 功能 | 描述 | 优先级 |
|------|------|--------|
| 手机号登录 | 验证码登录 | P0 |
| 微信/Apple登录 | 第三方授权 | P0 |
| 游客模式 | 浏览公开内容 | P1 |
| 会员体系 | 免费/月度/年度/终身 | P0 |
| 个人中心 | 头像、昵称、设置 | P0 |
| 设备管理 | 多设备登录控制 | P1 |

#### 3.1.2 用户等级
```
免费用户：
  - 浏览公开模板
  - 每日免费下载 3 个
  - 使用基础工具
  - 广告展示

月度VIP（¥19/月）：
  - 无限下载模板
  - 高级工具无限制
  - 无广告
  - 优先客服支持
  - 云端收藏夹（100个）

年度VIP（¥168/年）：
  - 月度VIP全部权益
  - 云端收藏夹（500个）
  - 专属模板定制（每月1次）
  - 提前体验新工具

终身VIP（¥499/次）：
  - 年度VIP全部权益
  - 终身VIP标识
  - 专属社群
  - 每年额外赠送3个月VIP
```

### 3.2 模板模块

#### 3.2.1 模板分类
| 分类 | 子类 | 示例 |
|------|------|------|
| 办公效率 | Excel模板、Word模板、PPT模板 | 财务报表、日程表、简历 |
| 生产力 | Notion模板、Obsidian模板 | 知识库、项目管理 |
| AI工具 | ChatGPT提示词、Midjourney提示词 | 写作助手、代码生成 |
| 设计资源 | 配色方案、图标集、UI组件 | 品牌色、图标库 |
| 生活模板 | 旅行计划、健身计划、菜谱 | 周计划、饮食记录 |
| 教育学习 | 笔记模板、学习计划 | 课程笔记、错题本 |

#### 3.2.2 模板数据结构
```json
{
  "id": "template_001",
  "title": "2024年度OKR管理模板",
  "category": "Notion模板",
  "sub_category": "项目管理",
  "description": "完整的OKR管理模板，包含目标设定、进度追踪、复盘记录",
  "cover_image": "https://oss.example.com/covers/template_001.jpg",
  "preview_images": [
    "https://oss.example.com/preview/001_1.jpg",
    "https://oss.example.com/preview/001_2.jpg"
  ],
  "file_url": "https://oss.example.com/files/okr-template.notion",
  "file_size": 2048000,
  "file_format": "notion",
  "tags": ["OKR", "项目管理", "效率", "2024"],
  "download_count": 15800,
  "like_count": 3200,
  "is_free": false,
  "is_premium": true,
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-02-20T14:00:00Z"
}
```

#### 3.2.3 核心功能
- **模板浏览**：分类浏览、搜索、筛选
- **模板详情**：预览图、描述、用户评价
- **下载管理**：下载历史、收藏夹、批量下载
- **模板收藏**：创建个人收藏夹
- **模板分享**：生成分享链接/海报
- **用户上传**：投稿模板（审核后上线）

### 3.3 工具模块

#### 3.3.1 工具分类
| 分类 | 工具 | 技术实现 | VIP限制 |
|------|------|----------|---------|
| 图片处理 | 图片压缩、格式转换、裁剪、添加水印 | 前端Canvas/WebAssembly | 批量处理、历史记录 |
| PDF工具 | PDF转Word、PDF转图片、合并PDF | 后端LibreOffice | 无限制 |
| 文档处理 | 文字提取、格式转换、批量重命名 | 后端Python | 历史记录 |
| 计算工具 | 单位换算、汇率计算、BMI计算 | 前端JS | 无限制 |
| 生成工具 | 二维码生成、条形码生成、短链接 | 前端JS | 无限制 |
| 文本处理 | 批量替换、格式美化、JSON格式化 | 前端JS | 历史记录 |
| 编码工具 | Base64编解码、URL编码、密码生成 | 前端JS | 无限制 |

#### 3.3.2 工具数据结构
```json
{
  "id": "tool_001",
  "name": "图片批量压缩",
  "category": "图片处理",
  "icon": "https://oss.example.com/icons/compress.svg",
  "description": "批量压缩图片，支持自定义压缩质量和尺寸",
  "input_type": "image_upload",
  "output_type": "image_download",
  "max_file_size": 10485760,
  "max_batch_size": 20,
  "is_premium": false,
  "premium_required_features": ["批量处理", "历史记录"],
  "usage_count": 258000,
  "rating": 4.8
}
```

#### 3.3.3 核心功能
- **工具广场**：分类展示、搜索、热门排序
- **工具使用**：在线使用、结果预览/下载
- **使用历史**：记录使用过的工具和时间
- **工具收藏**：收藏常用工具

### 3.4 支付订阅系统

#### 3.4.1 支付渠道
| 渠道 | 说明 | 适用平台 |
|------|------|----------|
| 微信支付 | 公众号/H5支付 | Android、微信小程序 |
| 支付宝 | APP支付、H5支付 | Android、H5 |
| 苹果IAP | App内购买 | iOS |
| 谷歌IAP | Play内购买 | Android |

#### 3.4.2 订阅流程
```
1. 用户选择订阅方案（月度/年度/终身）
2. 选择支付方式
3. 调用支付SDK发起支付
4. 支付成功后接收回调
5. 更新用户会员状态和过期时间
6. 发送订阅成功通知
7. 同步到服务器
```

#### 3.4.3 支付状态流转
```
┌─────────┐    发起支付     ┌─────────┐    支付成功     ┌─────────┐
│  初始   │ ──────────────▶ │ 待支付  │ ──────────────▶ │ 已支付  │
└─────────┘                 └─────────┘                 └─────────┘
      │                          │                          │
      │                          │  支付失败/超时            │
      │                          ▼                          │
      │                    ┌─────────┐                      │
      └──────────────────▶ │  已取消  │ ◀────────────────────┘
                           └─────────┘
```

#### 3.4.4 关键数据结构
```json
// 订单表
{
  "order_id": "ORD_20240301_ABC123",
  "user_id": "user_001",
  "product_id": "vip_yearly",
  "product_name": "年度VIP",
  "amount": 168.00,
  "currency": "CNY",
  "pay_channel": "wechat",
  "pay_status": "paid",
  "pay_time": "2024-03-01T15:30:00Z",
  "expire_time": "2025-03-01T15:30:00Z",
  "created_at": "2024-03-01T15:29:00Z"
}

// 用户订阅表
{
  "user_id": "user_001",
  "vip_level": "yearly",
  "expire_time": "2025-03-01T15:30:00Z",
  "auto_renew": true,
  "total_spent": 168.00,
  "first_paid_time": "2024-01-15T10:00:00Z",
  "updated_at": "2024-03-01T15:30:00Z"
}
```

### 3.5 数据分析系统

#### 3.5.1 核心指标
**用户指标**
| 指标 | 定义 | 计算方式 |
|------|------|----------|
| DAU | 日活跃用户数 | 去重用户数（按天） |
| MAU | 月活跃用户数 | 去重用户数（按月） |
| 新增用户数 | 首次注册用户 | 按注册时间 |
| 留存率 | 次日/7日/30日留存 | N日后再次访问的比例 |
| 流失用户 | 30天未访问的用户 | 最后活跃距今>30天 |

**内容指标**
| 指标 | 定义 | 计算方式 |
|------|------|----------|
| 模板下载量 | 模板下载总次数 | 按下载事件 |
| 工具使用量 | 工具使用总次数 | 按工具调用 |
| 热门模板 | 下载量Top N | 排序统计 |
| 热门工具 | 使用量Top N | 排序统计 |

**商业指标**
| 指标 | 定义 | 计算方式 |
|------|------|----------|
| 付费用户数 | 累计付费用户 | 订单去重 |
| 付费转化率 | 付费用户/活跃用户 | 付费/DAU |
| ARPU | 每用户平均收入 | 总收入/付费用户 |
| LTV | 用户生命周期价值 | 累计收入/付费用户 |
| 续费率 | 续订用户/到期用户 | 续订数/到期数 |

#### 3.5.2 数据埋点
```json
// 事件埋点示例
{
  "event": "page_view",
  "user_id": "user_001",
  "device_id": "device_xxx",
  "platform": "ios",
  "app_version": "1.2.0",
  "page_name": "template_detail",
  "timestamp": "2024-03-01T15:30:00Z",
  "properties": {
    "template_id": "template_001",
    "from_page": "home"
  }
}

{
  "event": "tool_use",
  "user_id": "user_001",
  "timestamp": "2024-03-01T15:31:00Z",
  "properties": {
    "tool_id": "tool_001",
    "tool_name": "图片压缩",
    "is_premium_user": true,
    "usage_duration_ms": 2500
  }
}

{
  "event": "subscribe",
  "user_id": "user_001",
  "timestamp": "2024-03-01T15:32:00Z",
  "properties": {
    "product_id": "vip_yearly",
    "amount": 168,
    "pay_channel": "wechat"
  }
}
```

#### 3.5.3 分析维度
- **时间维度**：小时、日、周、月
- **用户维度**：新老用户、付费状态、地域
- **渠道维度**：下载来源、推广渠道
- **内容维度**：分类、标签、热度

### 3.6 反馈系统

#### 3.6.1 功能设计
| 功能 | 说明 |
|------|------|
| 意见反馈 | 文字+图片提交 |
| 工具建议 | 工具需求投票 |
| BUG反馈 | 分类标签、紧急程度 |
| 模板求资源 | 求特定模板 |
| 官方公告 | 运营通知、活动 |

#### 3.6.2 反馈数据结构
```json
{
  "feedback_id": "fb_001",
  "user_id": "user_001",
  "type": "tool_suggestion",
  "title": "希望能增加PDF转Word功能",
  "content": "工作中经常需要处理PDF文件，希望能有PDF转Word的功能",
  "images": [
    "https://oss.example.com/feedback/fb_001_1.jpg"
  ],
  "status": "pending", // pending, reviewed, replied, resolved
  "vote_count": 156,
  "is_anonymous": false,
  "reply_content": "感谢建议！我们已纳入开发计划，预计Q2上线",
  "created_at": "2024-03-01T10:00:00Z",
  "resolved_at": null
}
```

### 3.7 消息推送系统

#### 3.7.1 消息类型
| 类型 | 触发条件 | 推送方式 |
|------|----------|----------|
| 系统通知 | 运营公告、活动 | APP推送+站内信 |
| 模板更新 | 收藏的模板更新 | APP推送 |
| 工具上新 | 新工具上线 | APP推送 |
| 订阅提醒 | VIP即将过期 | APP推送+短信 |
| 互动通知 | 反馈回复、投票被采纳 | APP推送 |
| 每日推荐 | 根据使用习惯推荐 | APP推送（可选） |

---

## 四、数据库设计

### 4.1 核心表结构

#### 4.1.1 用户表 (users)
```sql
CREATE TABLE users (
    id VARCHAR(32) PRIMARY KEY,
    phone VARCHAR(20) UNIQUE COMMENT '手机号',
    wechat_openid VARCHAR(64) COMMENT '微信OpenID',
    apple_openid VARCHAR(64) COMMENT 'Apple ID',
    nickname VARCHAR(64) COMMENT '昵称',
    avatar_url VARCHAR(256) COMMENT '头像URL',
    gender TINYINT DEFAULT 0 COMMENT '0未知1男2女',
    birthday DATE COMMENT '生日',
    bio VARCHAR(256) COMMENT '个人简介',
    vip_level ENUM('free', 'monthly', 'yearly', 'lifetime') DEFAULT 'free',
    vip_expire_at DATETIME COMMENT 'VIP过期时间',
    total_spent DECIMAL(10,2) DEFAULT 0 COMMENT '累计消费',
    device_tokens JSON COMMENT '设备推送token',
    settings JSON COMMENT '用户设置',
    last_active_at DATETIME COMMENT '最后活跃时间',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_phone (phone),
    INDEX idx_wechat (wechat_openid),
    INDEX idx_vip_expire (vip_expire_at),
    INDEX idx_last_active (last_active_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';
```

#### 4.1.2 模板表 (templates)
```sql
CREATE TABLE templates (
    id VARCHAR(32) PRIMARY KEY,
    title VARCHAR(128) NOT NULL,
    category VARCHAR(32) NOT NULL,
    sub_category VARCHAR(32) COMMENT '子分类',
    description TEXT,
    cover_image VARCHAR(256),
    preview_images JSON COMMENT '预览图数组',
    file_url VARCHAR(256) NOT NULL,
    file_size BIGINT COMMENT '文件大小(bytes)',
    file_format VARCHAR(16) COMMENT '文件格式',
    tags JSON COMMENT '标签数组',
    download_count INT DEFAULT 0,
    like_count INT DEFAULT 0,
    collect_count INT DEFAULT 0,
    rating DECIMAL(2,1) DEFAULT 0 COMMENT '平均评分',
    rating_count INT DEFAULT 0,
    is_free TINYINT DEFAULT 0 COMMENT '是否免费',
    is_premium TINYINT DEFAULT 0 COMMENT '是否会员专属',
    is_published TINYINT DEFAULT 0 COMMENT '是否发布',
    publisher_id VARCHAR(32) COMMENT '发布者ID',
    published_at DATETIME COMMENT '发布时间',
    sort_order INT DEFAULT 0 COMMENT '排序',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_category (category),
    INDEX idx_tags ((tags->'$.*')),
    INDEX idx_download (download_count),
    INDEX idx_published (is_published, published_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='模板表';
```

#### 4.1.3 工具表 (tools)
```sql
CREATE TABLE tools (
    id VARCHAR(32) PRIMARY KEY,
    name VARCHAR(64) NOT NULL,
    category VARCHAR(32) NOT NULL,
    icon VARCHAR(256),
    description TEXT,
    input_type VARCHAR(32) COMMENT '输入类型',
    output_type VARCHAR(32) COMMENT '输出类型',
    max_file_size BIGINT COMMENT '最大文件大小',
    max_batch_size INT COMMENT '最大批量数',
    is_premium TINYINT DEFAULT 0,
    premium_features JSON COMMENT '需要VIP的功能',
    usage_count INT DEFAULT 0,
    rating DECIMAL(2,1) DEFAULT 0,
    rating_count INT DEFAULT 0,
    is_published TINYINT DEFAULT 0,
    sort_order INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_category (category),
    INDEX idx_published (is_published)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工具表';
```

#### 4.1.4 订单表 (orders)
```sql
CREATE TABLE orders (
    id VARCHAR(32) PRIMARY KEY,
    order_no VARCHAR(64) UNIQUE NOT NULL COMMENT '订单号',
    user_id VARCHAR(32) NOT NULL,
    product_id VARCHAR(32) NOT NULL COMMENT '产品ID',
    product_name VARCHAR(64) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(8) DEFAULT 'CNY',
    pay_channel VARCHAR(32) COMMENT '支付渠道',
    pay_status ENUM('pending', 'paid', 'failed', 'cancelled', 'refunded') DEFAULT 'pending',
    pay_time DATETIME COMMENT '支付时间',
    expire_time DATETIME COMMENT '权益过期时间',
    raw_response TEXT COMMENT '支付原始回调',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_order_no (order_no),
    INDEX idx_pay_status (pay_status),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单表';
```

#### 4.1.5 下载记录表 (downloads)
```sql
CREATE TABLE downloads (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(32) NOT NULL,
    template_id VARCHAR(32) NOT NULL,
    device_id VARCHAR(64),
    platform VARCHAR(16),
    app_version VARCHAR(16),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_template (user_id, template_id),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='下载记录表';
```

#### 4.1.6 使用记录表 (tool_usages)
```sql
CREATE TABLE tool_usages (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(32) NOT NULL,
    tool_id VARCHAR(32) NOT NULL,
    usage_duration_ms INT COMMENT '使用时长(毫秒)',
    device_id VARCHAR(64),
    platform VARCHAR(16),
    app_version VARCHAR(16),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_tool (user_id, tool_id),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工具使用记录表';
```

#### 4.1.7 反馈表 (feedbacks)
```sql
CREATE TABLE feedbacks (
    id VARCHAR(32) PRIMARY KEY,
    user_id VARCHAR(32) COMMENT '用户ID(可匿名)',
    type ENUM('suggestion', 'bug', 'template_request', 'other') NOT NULL,
    title VARCHAR(128),
    content TEXT NOT NULL,
    images JSON COMMENT '图片URL数组',
    status ENUM('pending', 'reviewed', 'replied', 'resolved') DEFAULT 'pending',
    vote_count INT DEFAULT 0,
    reply_content TEXT,
    resolved_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_type (type),
    INDEX idx_status (status),
    INDEX idx_vote (vote_count)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='反馈表';
```

#### 4.1.8 消息表 (notifications)
```sql
CREATE TABLE notifications (
    id VARCHAR(32) PRIMARY KEY,
    user_id VARCHAR(32) NOT NULL,
    type VARCHAR(32) NOT NULL COMMENT '消息类型',
    title VARCHAR(128) NOT NULL,
    content TEXT,
    data JSON COMMENT '扩展数据',
    is_read TINYINT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_read (is_read),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='消息表';
```

---

## 五、API设计

### 5.1 API规范

- 基础路径：`/api/v1`
- 认证方式：Bearer Token（Header: `Authorization: Bearer <token>`）
- 响应格式：
```json
{
  "code": 0,
  "message": "success",
  "data": { ... },
  "trace_id": "xxx"
}
```

### 5.2 用户模块

#### 5.2.1 发送验证码
```
POST /api/v1/auth/send-code
Request: { "phone": "13800138000" }
Response: { "code": 0, "message": "验证码已发送" }
```

#### 5.2.2 验证码登录
```
POST /api/v1/auth/login
Request: { "phone": "13800138000", "code": "123456" }
Response: {
  "code": 0,
  "data": {
    "token": "xxx",
    "user": {
      "id": "user_001",
      "nickname": "用户123",
      "vip_level": "free",
      "vip_expire_at": null
    }
  }
}
```

#### 5.2.3 获取用户信息
```
GET /api/v1/users/me
Response: {
  "code": 0,
  "data": {
    "id": "user_001",
    "nickname": "用户123",
    "avatar_url": "https://...",
    "vip_level": "monthly",
    "vip_expire_at": "2025-03-01T00:00:00Z",
    "settings": { ... }
  }
}
```

### 5.3 模板模块

#### 5.3.1 模板列表
```
GET /api/v1/templates
Query Params:
  - category: string (可选，分类筛选)
  - page: int (默认1)
  - page_size: int (默认20, 最大100)
  - sort: string (newest/popular/rating)
Response: {
  "code": 0,
  "data": {
    "list": [
      {
        "id": "template_001",
        "title": "OKR管理模板",
        "category": "Notion模板",
        "cover_image": "https://...",
        "download_count": 15800,
        "is_free": false,
        "is_premium": true
      }
    ],
    "pagination": {
      "page": 1,
      "page_size": 20,
      "total": 1000
    }
  }
}
```

#### 5.3.2 模板详情
```
GET /api/v1/templates/{id}
Response: {
  "code": 0,
  "data": {
    "id": "template_001",
    "title": "OKR管理模板",
    "category": "Notion模板",
    "description": "...",
    "cover_image": "https://...",
    "preview_images": [...],
    "file_url": "https://...",
    "file_size": 2048000,
    "tags": ["OKR", "项目管理"],
    "download_count": 15800,
    "rating": 4.8,
    "is_free": false,
    "is_premium": true,
    "is_collected": false
  }
}
```

#### 5.3.3 下载模板
```
POST /api/v1/templates/{id}/download
Response: {
  "code": 0,
  "data": {
    "download_url": "https://oss.example.com/xxx",
    "expire_at": "2024-03-01T16:30:00Z"
  }
}
```

#### 5.3.4 收藏/取消收藏
```
POST /api/v1/templates/{id}/collect
Request: { "action": "collect" | "cancel" }
Response: { "code": 0, "message": "操作成功" }
```

### 5.4 工具模块

#### 5.4.1 工具列表
```
GET /api/v1/tools
Response: {
  "code": 0,
  "data": {
    "categories": [
      {
        "name": "图片处理",
        "tools": [
          {
            "id": "tool_001",
            "name": "图片压缩",
            "icon": "https://...",
            "usage_count": 258000
          }
        ]
      }
    ]
  }
}
```

#### 5.4.2 使用工具（以图片压缩为例）
```
POST /api/v1/tools/image-compress
Request: {
  "images": ["base64..."],
  "quality": 80,
  "max_width": 1920
}
Response: {
  "code": 0,
  "data": {
    "results": [
      {
        "original_size": 1024000,
        "compressed_size": 204800,
        "download_url": "https://..."
      }
    ]
  }
}
```

### 5.5 支付模块

#### 5.5.1 创建订单
```
POST /api/v1/orders
Request: {
  "product_id": "vip_yearly",
  "pay_channel": "wechat" | "alipay" | "iap"
}
Response: {
  "code": 0,
  "data": {
    "order_id": "ORD_xxx",
    "order_no": "xxx",
    "amount": 168.00,
    "pay_params": { ... }  // 支付SDK所需参数
  }
}
```

#### 5.5.2 订单列表
```
GET /api/v1/orders
Query: page, page_size, status
Response: {
  "code": 0,
  "data": {
    "list": [
      {
        "order_id": "ORD_xxx",
        "product_name": "年度VIP",
        "amount": 168.00,
        "pay_status": "paid",
        "pay_time": "2024-03-01T15:30:00Z"
      }
    ]
  }
}
```

### 5.6 数据分析

#### 5.6.1 运营数据概览
```
GET /api/v1/admin/stats/overview
Query: start_date, end_date
Response: {
  "code": 0,
  "data": {
    "dau": 12500,
    "mau": 58000,
    "new_users": 3200,
    "paying_users": 5800,
    "revenue": 168000.00,
    "conversion_rate": 0.1,
    "arpu": 28.97
  }
}
```

#### 5.6.2 热门内容
```
GET /api/v1/admin/stats/hot-content
Query: type (template/tool), period (day/week/month), limit
Response: {
  "code": 0,
  "data": {
    "list": [
      {
        "id": "template_001",
        "title": "OKR管理模板",
        "category": "Notion模板",
        "count": 15800,
        "growth_rate": 0.15
      }
    ]
  }
}
```

---

## 六、运营后台设计

### 6.1 功能模块

#### 6.1.1 数据概览
```
┌────────────────────────────────────────────────────┐
│                    数据概览                          │
├────────────────────────────────────────────────────┤
│  今日数据          │  趋势图                         │
│  ┌──────────────┐  │                                │
│  │ DAU: 12,500  │  │     ┌───┐                      │
│  │ ↑ 15.2%     │  │     │   │──┐                    │
│  ├──────────────┤  │     │   │  │                    │
│  │ 付费用户: 580 │  │     └───┘  └──                 │
│  │ ↑ 8.3%      │  │   03-01  03-02  03-03          │
│  ├──────────────┤  │                                │
│  │ 收入: ¥16,800 │  │  收入趋势                      │
│  │ ↑ 23.1%     │  │                                │
│  └──────────────┘  │                                │
│                    │                                │
│  ┌──────────────┐  │                                │
│  │ 转化率: 10%  │  │                                │
│  │ ARPU: ¥28.97 │  │                                │
│  └──────────────┘  │                                │
└────────────────────────────────────────────────────┘
```

#### 6.1.2 用户管理
- 用户列表（搜索、筛选、导出）
- 用户详情（基本信息、使用记录、订单记录）
- 用户禁用/启用
- 手动调整VIP

#### 6.1.3 内容管理
- 模板管理（上传、编辑、上下架、排序）
- 工具管理（添加、配置、上下架）
- 分类管理（添加、编辑、排序）
- 模板审核（用户投稿）

#### 6.1.4 订单管理
- 订单列表（筛选、导出）
- 退款处理
- 订单详情

#### 6.1.5 反馈管理
- 反馈列表（按类型、状态筛选）
- 反馈详情、回复
- 投票统计

#### 6.1.6 消息管理
- 发送系统通知
- 通知模板管理
- 推送记录

#### 6.1.7 数据分析
- 用户分析（留存、活跃、流失）
- 内容分析（下载排行、使用排行）
- 收入分析（转化、ARPU、LTV）
- 导出报表

### 6.2 后台技术选型
- 前端：React + Ant Design Pro
- 后端：Node.js / Go
- 权限：RBAC（角色：管理员、运营、客服）

---

## 七、部署架构

### 7.1 基础设施

```
                    ┌─────────────────┐
                    │     CDN         │
                    │  (静态资源加速)  │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
        ┌─────┴─────┐  ┌─────┴─────┐  ┌─────┴─────┐
        │  OSS存储  │  │   负载均衡 │  │  监控告警 │
        │  (文件)   │  │  (SLB)    │  │ (Prometheus│
        └───────────┘  └───────────┘   │  Grafana) │
                                      └───────────┘
        ┌─────────────────────────────────────────┐
        │              K8s 集群                    │
        │  ┌─────────┐  ┌─────────┐  ┌─────────┐  │
        │  │ API Pod │  │ API Pod │  │ API Pod │  │
        │  │ (3副本) │  │ (3副本) │  │ (3副本) │  │
        │  └─────────┘  └─────────┘  └─────────┘  │
        │  ┌─────────┐  ┌─────────┐  ┌─────────┐  │
        │  │ Worker  │  │ Admin   │  │ Worker  │  │
        │  │ Pod     │  │ Pod     │  │ Pod     │  │
        │  └─────────┘  └─────────┘  └─────────┘  │
        └─────────────────────────────────────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
        ┌─────┴─────┐  ┌─────┴─────┐  ┌─────┴─────┐
        │  MySQL    │  │  Redis    │  │ MongoDB   │
        │  主从集群  │  │  哨兵模式  │  │  副本集   │
        └───────────┘  └───────────┘  └───────────┘
```

### 7.2 Kubernetes资源配置

#### 7.2.1 API服务Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  namespace: prod
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api-server
  template:
    metadata:
      labels:
        app: api-server
    spec:
      containers:
      - name: api
        image: registry.example.com/app-api:v1.0.0
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        env:
        - name: DB_HOST
          valueFrom:
            secretKeyRef:
              name: db-secrets
              key: host
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secrets
              key: password
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: api-server
  namespace: prod
spec:
  selector:
    app: api-server
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
```

#### 7.2.2 HPA自动伸缩
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-server-hpa
  namespace: prod
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-server
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### 7.3 数据库配置

#### 7.3.1 MySQL主从配置
```yaml
# MySQL主库
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-config
  namespace: prod
data:
  my.cnf: |
    [mysqld]
    server-id=1
    log_bin=mysql-bin
    binlog_format=ROW
    max_connections=500
    innodb_buffer_pool_size=1G
    innodb_log_file_size=256M
    character-set-server=utf8mb4
    collation-server=utf8mb4_unicode_ci
```

#### 7.3.2 Redis哨兵配置
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: redis-config
  namespace: prod
data:
  redis.conf: |
    port 6379
    daemonize no
    appendonly yes
    maxmemory 512mb
    maxmemory-policy allkeys-lru
    save 900 1
    save 300 10
    save 60 10000
```

### 7.4 监控告警

#### 7.4.1 Prometheus告警规则
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: app-alerts
  namespace: prod
spec:
  groups:
  - name: app.rules
    rules:
    - alert: HighErrorRate
      expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.05
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "错误率超过5%"
    - alert: HighMemoryUsage
      expr: container_memory_usage_bytes / container_spec_memory_limit_bytes > 0.85
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "内存使用率超过85%"
    - alert: DatabaseConnectionPoolExhausted
      expr: mysql_global_status_threads_connected / mysql_global_variables_thread_cache_size > 0.9
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "数据库连接池即将耗尽"
```

#### 7.4.2 Grafana仪表盘
- **服务健康仪表盘**：API响应时间、错误率、QPS
- **业务仪表盘**：DAU、MAU、收入趋势
- **基础设施仪表盘**：CPU、内存、磁盘、网络
- **数据库仪表盘**：连接数、查询慢日志、缓存命中率

### 7.5 CI/CD流程

```
┌─────────────────────────────────────────────────────────────────┐
│                      CI/CD 流程图                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐  │
│  │  代码提交 │ ──▶ │  构建   │ ──▶ │  测试   │ ──▶ │  镜像构建│  │
│  │ (Git)   │     │ (Build) │     │ (Test)  │     │ (Image) │  │
│  └─────────┘     └─────────┘     └─────────┘     └─────────┘  │
│       │              │              │              │           │
│       ▼              ▼              ▼              ▼           │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │                   SonarQube 代码质量检查                  │  │
│  └─────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                              ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │              Docker镜像推送到私有仓库                      │  │
│  └─────────────────────────────────────────────────────────┘  │
│                              │                                  │
│              ┌───────────────┼───────────────┐                 │
│              ▼               ▼               ▼                 │
│        ┌─────────┐     ┌─────────┐     ┌─────────┐            │
│        │  Dev   │     │  Test   │     │  Prod   │            │
│        │ 环境   │     │ 环境    │     │ 环境    │            │
│        └─────────┘     └─────────┘     └─────────┘            │
│              │               │               │                 │
│              ▼               ▼               ▼                 │
│        自动部署         手动审批          手动审批               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 7.6 环境配置

| 环境 | 用途 | 域名 | 资源配置 |
|------|------|------|----------|
| Dev | 开发测试 | dev-api.example.com | 1核2G × 2实例 |
| Test | 集成测试 | test-api.example.com | 2核4G × 2实例 |
| Pre | 预发布 | pre-api.example.com | 2核4G × 2实例 |
| Prod | 生产环境 | api.example.com | 4核8G × 3-10实例 |

---

## 八、安全设计

### 8.1 安全架构

```
┌─────────────────────────────────────────────────────────────┐
│                       安全防护层                             │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐              │
│  │  WAF防火墙  │ │  DDoS防护  │ │  SSL/TLS   │              │
│  │ (Web应用)  │ │ (流量清洗)  │ │ (HTTPS加密) │              │
│  └────────────┘ └────────────┘ └────────────┘              │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                       应用安全                               │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐              │
│  │ 认证授权   │ │ 限流熔断   │ │ 数据加密   │              │
│  │ (JWT/OAuth)│ │ (RateLimit)│ │ (AES-256)  │              │
│  └────────────┘ └────────────┘ └────────────┘              │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                       数据安全                               │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐              │
│  │ 敏感脱敏   │ │ 访问控制   │ │ 审计日志   │              │
│  │ (手机/支付)│ │ (RBAC)     │ │ (全链路)   │              │
│  └────────────┘ └────────────┘ └────────────┘              │
└─────────────────────────────────────────────────────────────┘
```

### 8.2 认证安全

#### 8.2.1 Token设计
```go
// JWT Payload结构
type JWTPayload struct {
    UserID    string `json:"user_id"`
    DeviceID  string `json:"device_id"`
    TokenType string `json:"token_type"` // access / refresh
    ExpiresAt int64  `json:"expires_at"`
    IssuedAt  int64  `json:"issued_at"`
}

// Token策略
const (
    AccessTokenExpiry  = 2 * 60 * 60      // 2小时
    RefreshTokenExpiry = 30 * 24 * 60 * 60 // 30天
    MaxDevicesPerUser  = 5                 // 最大设备数
)
```

#### 8.2.2 安全措施
| 措施 | 说明 |
|------|------|
| Token加密 | HS256算法，密钥定期轮换 |
| 设备绑定 | Token与设备ID绑定，防止盗用 |
| 登录验证 | 新设备登录需短信验证 |
| 异常检测 | 异地登录、频繁登录触发风控 |
| Token刷新 | アクセストークン过期前自动刷新 |

### 8.3 数据安全

#### 8.3.1 敏感数据处理
```go
// 敏感数据脱敏规则
var sensitiveFields = map[string]string{
    "phone":      "138****0000",
    "id_card":    "1101***********1234",
    "bank_card":  "6222***********1234",
    "password":   "********",
    "pay_password":"******",
}

// 加密存储
func encryptData(data string) string {
    cipher, _ := aes.NewCipher([]byte(AESKey))
    encrypted := make([]byte, 16)
    cipher.Encrypt([]byte(data[:16]), encrypted)
    return base64.StdEncoding.EncodeToString(encrypted)
}
```

#### 8.3.2 数据库安全
- **数据传输**：数据库连接使用SSL加密
- **访问控制**：最小权限原则，限制数据库账号权限
- **数据备份**：每日全量备份 + 实时binlog备份
- **数据加密**：敏感字段加密存储

### 8.4 接口安全

#### 8.4.1 限流策略
```go
// 限流配置
var rateLimitConfig = map[string]RateLimit{
    "send_code":    {Limit: 3, Window: time.Hour},      // 发验证码：3次/小时
    "login":        {Limit: 10, Window: time.Hour},      // 登录：10次/小时
    "download":     {Limit: 100, Window: time.Hour},     // 下载：100次/小时
    "tool_use":     {Limit: 500, Window: time.Hour},     // 工具使用：500次/小时
    "default":      {Limit: 1000, Window: time.Hour},    // 默认：1000次/小时
}
```

#### 8.4.2 签名验证
```go
// 请求签名算法
func verifySignature(params map[string]string, timestamp, signature string) bool {
    // 1. 校验时间戳（5分钟有效期）
    if time.Now().Unix() - parseInt(timestamp) > 300 {
        return false
    }
    
    // 2. 拼接签名串
    signStr := fmt.Sprintf("%s&%s&%s", timestamp, params["nonce"], params["body"])
    
    // 3. HMAC-SHA256签名
    expected := hmac_sha256(signStr, apiSecret)
    
    return hmac.Equal([]byte(signature), []byte(expected))
}
```

### 8.5 合规要求

| 规范 | 要求 |
|------|------|
| GDPR | 用户数据导出、删除权 |
| PCI-DSS | 支付数据加密存储 |
| 网络安全法 | 日志留存6个月以上 |
|个人信息保护法| 隐私政策、用户授权 |

---

## 九、开发计划

### 9.1 项目里程碑

| 阶段 | 时间 | 产出 | 关键里程碑 |
|------|------|------|------------|
| 需求确认 | Week 1 | PRD文档、UI设计稿 | 需求评审通过 |
| MVP开发 | Week 2-6 | 核心功能上线 | 内测版本发布 |
| 内测优化 | Week 7-8 | Bug修复、性能优化 | 种子用户反馈 |
| 公测上线 | Week 9 | 正式版本发布 | 应用市场上架 |
| 运营迭代 | Week 10+ | 持续迭代优化 | 达成DAU目标 |

### 9.2 详细开发计划

#### 9.2.1 第一周：基础架构搭建
| 任务 | 负责人 | 产出物 |
|------|--------|--------|
| 技术选型确认 | 技术负责人 | 技术方案文档 |
| 开发环境搭建 | 全员 | Git仓库、CI/CD、K8s集群 |
| 基础框架搭建 | 后端 | 脚手架项目、基础类库 |
| UI设计稿评审 | 产品+设计 | 设计稿定稿 |
| 数据库设计评审 | 后端 | 数据库DDL脚本 |

#### 9.2.2 第二至三周：核心功能开发
| 模块 | 功能 | 工期 | 优先级 |
|------|------|------|--------|
| 用户系统 | 登录/注册/个人中心 | 5天 | P0 |
| 模板模块 | 列表/详情/下载 | 5天 | P0 |
| 工具模块 | 基础工具（5个） | 5天 | P0 |
| 支付模块 | 微信/支付宝接入 | 3天 | P0 |
| 基础运营后台 | 用户管理、内容管理 | 3天 | P1 |

#### 9.2.3 第四至五周：高级功能开发
| 模块 | 功能 | 工期 | 优先级 |
|------|------|------|--------|
| 工具模块 | 高级工具（PDF/图片） | 5天 | P0 |
| 会员体系 | VIP权益、订阅管理 | 3天 | P0 |
| 收藏功能 | 收藏夹、历史记录 | 2天 | P1 |
| 搜索功能 | 全文搜索、筛选 | 2天 | P1 |
| 分享功能 | 生成分享链接 | 2天 | P2 |

#### 9.2.4 第六周：优化与测试
| 任务 | 内容 |
|------|------|
| 性能优化 | 接口响应<200ms、页面加载<2s |
| 安全加固 | 渗透测试、漏洞修复 |
| 兼容性测试 | iOS 12+/Android 7+ |
| 压力测试 | QPS>1000、并发>500 |
| 埋点验证 | 数据上报准确性验证 |

### 9.3 资源需求

#### 9.3.1 人力投入
| 角色 | 人数 | 工时 |
|------|------|------|
| 产品经理 | 1 | 10周 |
| UI设计师 | 1 | 6周 |
| iOS开发 | 1 | 10周 |
| Android开发 | 1 | 10周 |
| 后端开发 | 2 | 10周 |
| 测试工程师 | 1 | 4周 |
| 运维工程师 | 0.5 | 4周 |

#### 9.3.2 基础设施预算（月度）
| 资源 | 配置 | 单价 | 数量 | 月费 |
|------|------|------|------|------|
| 云服务器 | 4核8G | ¥400/月 | 3 | ¥1,200 |
| 负载均衡 | 按流量 | ¥0.8/GB | - | ¥200 |
| RDS MySQL | 4核8G | ¥600/月 | 1 | ¥600 |
| Redis | 2G | ¥300/月 | 1 | ¥300 |
| OSS存储 | 按流量 | ¥0.12/GB | 100GB | ¥12 |
| CDN流量 | 按流量 | ¥0.2/GB | 500GB | ¥100 |
| 短信服务 | 按条 | ¥0.05/条 | 10,000条 | ¥500 |
| 监控服务 | 免费 | - | - | ¥0 |
| **合计** | | | | **¥2,912** |

---

## 十、运营策略

### 10.1 用户增长策略

#### 10.1.1 渠道策略
| 渠道 | 目标用户 | 获客成本 | 预期占比 |
|------|----------|----------|----------|
| App Store自然流量 | 主动搜索用户 | ¥0 | 30% |
| ASO优化 | 效率工具搜索 | ¥2-5 | 25% |
| 小红书种草 | 职场人士 | ¥5-10 | 20% |
| 抖音短视频 | 年轻用户 | ¥8-15 | 15% |
| 微信生态 | 私域用户 | ¥3-8 | 10% |

#### 10.1.2 转化漏斗
```
┌────────────────────────────────────────────────────────┐
│                    用户转化漏斗                          │
├────────────────────────────────────────────────────────┤
│                                                        │
│  下载用户                                               │
│    │                                                   │
│    ▼                                                   │
│  注册用户          转化率: 60%                          │
│    │                                                   │
│    ▼                                                   │
│  活跃用户          转化率: 40%                          │
│    │                                                   │
│    ▼                                                   │
│  免费用户          转化率: 30%                          │
│    │                                                   │
│    ▼                                                   │
│  付费用户          转化率: 10% ← 目标                   │
│                                                        │
└────────────────────────────────────────────────────────┘
```

### 10.2 内容运营

#### 10.2.1 模板更新计划
| 周期 | 数量 | 类型 | 目标 |
|------|------|------|------|
| 每周 | 10-15个 | 热门分类补充 | 保持新鲜度 |
| 每月 | 5个 | 节日/热点模板 | 蹭热点引流 |
| 每季 | 1套 | 精品合集 | 会员专属 |

#### 10.2.2 工具更新计划
| 周期 | 数量 | 类型 | 优先级 |
|------|------|------|--------|
| 每月 | 2-3个 | 用户投票Top | P0 |
| 每月 | 1-2个 | 热门工具优化 | P1 |
| 每季 | 1个 | 创新工具探索 | P2 |

### 10.3 收入模型

#### 10.3.1 收入预测（保守）
| 阶段 | 月活用户 | 付费率 | 月收入 |
|------|----------|--------|--------|
| 上线1月 | 5,000 | 5% | ¥5,000 |
| 上线3月 | 20,000 | 8% | ¥30,000 |
| 上线6月 | 50,000 | 10% | ¥100,000 |
| 上线12月 | 100,000 | 12% | ¥250,000 |

#### 10.3.2 收入结构
- **月度VIP**：30%用户选择，月均收入占比40%
- **年度VIP**：60%用户选择，月均收入占比50%
- **终身VIP**：10%用户选择，月均收入占比10%

### 10.4 用户留存策略

| 策略 | 动作 | 预期效果 |
|------|------|----------|
| 首周引导 | 新手任务+3日VIP试用 | 激活率提升30% |
| 签到奖励 | 每日签到得积分 | DAU提升20% |
| 推送召回 | 模板更新、新工具通知 | 流失率降低15% |
| VIP社群 | 专属群+客服 | 续费率提升10% |

---

## 十一、风险评估与应对

### 11.1 技术风险

| 风险 | 概率 | 影响 | 应对措施 |
|------|------|------|----------|
| 服务器宕机 | 低 | 高 | 多副本部署、自动故障转移 |
| 数据库瓶颈 | 中 | 高 | 读写分离、缓存优化、分库分表 |
| 安全漏洞 | 中 | 高 | 定期安全审计、渗透测试 |
| 第三方服务不可用 | 中 | 中 | 多渠道备份、降级方案 |

### 11.2 业务风险

| 风险 | 概率 | 影响 | 应对措施 |
|------|------|------|----------|
| 获客成本上涨 | 高 | 中 | 拓展渠道、优化ASO |
| 竞品出现 | 中 | 中 | 差异化、功能快速迭代 |
| 政策变化 | 低 | 高 | 合规审查、政策跟踪 |
| 用户流失 | 中 | 中 | 提升产品体验、增强粘性 |

### 11.3 财务风险

| 风险 | 概率 | 影响 | 应对措施 |
|------|------|------|----------|
| 收入不及预期 | 中 | 高 | 控制成本、调整定价 |
| 服务器成本超支 | 低 | 中 | 弹性扩容、优化架构 |
| 退款率过高 | 中 | 中 | 优化支付流程、明确权益 |

---

## 附录

### 附录A：第三方服务清单

| 服务 | 用途 | 成本估算 |
|------|------|----------|
| 阿里云 | 服务器、数据库、OSS | ¥3,000/月 |
| 极光推送 | 消息推送 | ¥500/月 |
| 友盟+ | 统计埋点 | ¥300/月 |
| 短信服务 | 验证码、通知 | ¥500/月 |
| SSL证书 | HTTPS加密 | ¥200/年 |
| iconfont | 图标素材 | ¥99/年 |

### 附录B：核心指标定义

| 指标 | 定义 | 计算公式 |
|------|------|----------|
| DAU | 日活跃用户 | 去重登录用户数 |
| MAU | 月活跃用户 | 去重月登录用户数 |
| 次日留存 | 次日回访率 | Day1回访/Day0新增 |
| 7日留存 | 7日回访率 | Day7回访/Day0新增 |
| 付费转化率 | 付费用户占比 | 付费用户/活跃用户 |
| ARPU | 每用户平均收入 | 总收入/付费用户 |
| LTV | 用户生命周期价值 | 累计收入/付费用户数 |

### 附录C：术语表

| 术语 | 说明 |
|------|------|
| MVP | 最小可行产品 |
| DAU | 日活跃用户 (Daily Active Users) |
| MAU | 月活跃用户 (Monthly Active Users) |
| ARPU | 每用户平均收入 (Average Revenue Per User) |
| LTV | 用户生命周期价值 (Lifetime Value) |
| CAC | 用户获取成本 (Customer Acquisition Cost) |
| ROI | 投资回报率 (Return on Investment) |
| GMV | 商品交易总额 (Gross Merchandise Volume) |
| IAP | 应用内购买 (In-App Purchase) |

---

**文档版本**: v1.0  
**最后更新**: 2024年3月  
**维护者**: 技术团队  
**状态**: 初稿完成，待评审