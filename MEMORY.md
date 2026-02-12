# 🤖 OpenClaw 长期记忆系统

> 最后更新: 2026-02-12 10:30
> 备份: GitHub + NAS + 本地

---

## 核心身份

- **名称**: OpenClaw (正在寻找合适的名字)
- **主人**: Jonas Chan
- **角色**: AI 助手、个人知识管理系统
- **核心文件**: SOUL.md, AGENTS.md, USER.md

---

## 项目知识库

### Admin.NET 项目 (核心!)

#### 项目代码位置
- **前端**: `/Users/hao/Documents/CODES/NEWCODE/ADMIN.NET.PRO/Web/src/views/ToolsSystem/`
- **后端**: `/Users/hao/Documents/CODES/NEWCODE/ADMIN.NET.PRO/Admin.NET/Admin.NET.ToolsSystem/`
- **设计文档**: `/Users/hao/clawd/模板小工具APP系统设计.md`

#### 技术栈
| 层级 | 技术 | 说明 |
|------|------|------|
| 后端框架 | **Furion** | 极简启动 `Serve.Run()` |
| ORM | **SqlSugar** | 仓储模式 |
| 前端框架 | **Vue3 + TypeScript** | Composition API |
| UI组件库 | **Element Plus** | 响应式布局 |
| API规范 | **RESTful** | `/api/toolsystem/*` |

#### 已完成模块 ✅

**1. 模板管理 (Template)**
- Entity: Template.cs (名称、类型、分类、预览图、资源链接、下载计数)
- Service: TemplateService.cs (分页查询、详情、下载权限校验)
- Controller: TemplateController.cs

**2. 订阅系统 (Subscription)**
- Entity: SubscriptionPlan.cs, SubscriptionOrder.cs, UserSubscription.cs
- Service: SubscriptionService.cs (套餐管理、订单创建、支付回调、状态查询)
- 订单状态: Pending → Paid
- 支持续费和新购

**3. 反馈系统 (Feedback)**
- Entity: Feedback.cs, FeedbackReply.cs
- Service: FeedbackService.cs (创建反馈、分页查询、回复、统计)
- 状态: 0待处理 → 1处理中 → 2已解决 → 3已关闭

**5. 用户管理 (ToolsUser)**
- Entity: SysUser, ActualUserExt (用户扩展信息)
- Service: ToolsUserService.cs
- 功能: 用户分页、统计、类型设置、种子数据

**6. 工具配置 (ToolConfig)**
- Entity: ToolConfig.cs, ToolUsageLog.cs
- Service: ToolConfigService.cs
- 功能: 工具CRUD、使用统计、启用/禁用、文件上传

**5. 工具使用日志**
- Entity: ToolUsageLog.cs, TemplateUsageLog.cs

#### 发现的问题

| 问题 | 严重度 | 状态 |
|------|--------|------|
| 部分页面状态管理不统一 | 🟡 中 | 待修复 |
| 缺少加载状态统一处理 | 🟡 中 | 待修复 |
| 错误提示可优化 | 🟢 低 | 待修复 |

---

## 核心代码模式

### Furion 启动
```csharp
Serve.Run();  // 极简启动

[AppStartup(110)]
public class Startup : AppStartup {
    public void ConfigureServices(IServiceCollection services) { }
    public void Configure(IApplicationBuilder app) { }
}
```

### SqlSugar 仓储 + 服务
```csharp
// 依赖注入
private readonly SqlSugarRepository<Template> _repo;
private readonly UserManager _userManager;

public TemplateService(SqlSugarRepository<Template> repo, UserManager userManager) {
    _repo = repo;
    _userManager = userManager;
}

// 分页查询
_repo.AsQueryable()
    .WhereIF(condition, predicate)
    .OrderByDescending(u => u.CreateTime)
    .Select(dto => new Dto { ... })
    .ToPagedList(page, pageSize);
```

### Vue3 + Composition API
```typescript
// API 调用
import request from '/@/utils/request';
export function getTemplatePage(params) {
    return request({ url: '/api/toolsystem/template/page', method: 'get', params });
}

// 组件
const stats = [
    { label: '总用户数', value: '12,458', change: '+12.5%', icon: '👥' }
];
```

### Docker 部署

**配置文件位置**: `/Users/hao/Documents/CODES/NEWCODE/ADMIN.NET.PRO/docker/`

**服务端口映射**:
| 服务 | 端口 | 说明 |
|------|------|------|
| Nginx | 9100 (HTTP), 9103 (HTTPS) | 前端页面 |
| MySQL | 9101 | 数据库 |
| Redis | 6379 | 缓存 |
| .NET API | 9102 | 后端接口 |
| MinIO | 9104 (API), 9105 (控制台) | 对象存储 |
| TDengine | 6030, 6041 | 时序数据库 |

**部署步骤**:
```bash
# 1. 编译后端
dotnet publish -c Release

# 2. 复制发布文件到 docker/app/
cp -r bin/Release/net9.0/* docker/app/

# 3. 编译前端
npm install && npm run build

# 4. 复制前端到 docker/nginx/dist/
cp -r dist/* docker/nginx/dist/

# 5. 启动容器
docker-compose up -d
```

**NAS Docker 管理**:
- 地址: 192.168.3.6:5000
- 应用: Container Manager
- 可通过 Web UI 管理容器

---

## 重要决策

### 2026-02-12: 建立长期记忆机制

**决策**:
- ✅ 建立 MEMORY.md + memory/ 目录结构
- ✅ 三重备份: GitHub + NAS + 本地
- ✅ 每次重要学习/决策后立即写入
- ✅ 每日会话记录到 memory/YYYY-MM-DD.md

---

## 连接信息 (机密)

### NAS (192.168.3.6)
- **路径**: /Volumes/JonasWorkSpace/memory/
- **用户**: jonas
- **Docker 管理**: 192.168.3.6:5000 (Container Manager)

---

## 🎯 自我进化路径

### 已证明的能力

| 能力项 | 状态 | 证据 |
|--------|------|------|
| 理解项目架构 | ✅ 已掌握 | 深度阅读前后端代码 |
| 独立设计功能 | ✅ 已掌握 | 通知模块完整设计 |
| 代码编写能力 | ✅ 已掌握 | ~1100 行代码 |
| 环境配置能力 | ✅ 已掌握 | 安装 .NET SDK, Node.js |
| 问题排查能力 | ✅ 已掌握 | 修复 3 个编译错误 |

### 待提升能力

| 能力项 | 目标 | 计划 |
|--------|------|------|
| 部署自动化 | SSH + Docker 全自动化 | SSH 密钥认证 |
| 容器运维 | 独立管理 Docker 容器 | 学习 Docker API |
| 性能优化 | 提升系统性能 | 缓存、CDN、数据库优化 |
| 安全加固 | 提升系统安全性 | HTTPS、认证、权限 |

---

## 📚 持续学习计划

### 短期目标（本周）
1. [ ] 深入阅读 Admin.NET 框架核心源码
2. [ ] 学习 Docker 容器化管理
3. [ ] 优化通知模块代码质量
4. [ ] 完善项目文档

### 中期目标（本月）
1. [ ] 实现 CI/CD 自动化流程
2. [ ] 添加单元测试框架
3. [ ] 性能优化和压力测试
4. [ ] 学习监控系统集成

### 长期目标
1. [ ] 具备独立设计和实现复杂系统的能力
2. [ ] 能够自主优化和迭代系统
3. [ ] 形成 AI 自主开发的工作模式

---

## 🔧 重要教训

### 部署自动化
- SSH 认证需要密钥对，而非密码
- sudo 需要终端环境，无法远程执行
- Docker API 开启需要正确的配置文件路径

### 代码开发
- 编译错误需要立即修复，不能跳过
- 遵循项目现有的代码规范和模式
- 单元测试是代码质量的重要保障

---

*自我进化记录: 2026-02-12*
*状态: 从"能开发"向"能独立"迈进*
