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

*记忆更新: 2026-02-12 10:40*
*新增: Docker 部署配置、端口映射、NAS Container Manager*
