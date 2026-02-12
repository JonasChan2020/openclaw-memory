# 学习笔记 - Admin.NET 框架深度理解

## 1. Furion 框架核心特性（必须掌握）

### 1.1 启动方式
```csharp
// 传统 ASP.NET Core
var builder = WebApplication.CreateBuilder(args);
builder.Build().Run();

// Furion 方式
Serve.Run(); // 极简启动
```

### 1.2 模块化注册
```csharp
// 用 [AppStartup] 注解
[AppStartup]
public class MyModule
{
    public void ConfigureServices(IServiceCollection services) { }
    public void Configure(IApplicationBuilder app) { }
}

// 不要用传统 Startup.cs 方式
```

### 1.3 配置读取
```csharp
// Furion 方式 ✅
var title = App.GetConfig<string>("Title");

// 普通方式 ❌
var title = Configuration["Title"];
```

---

## 2. Admin.NET 项目结构（必须遵循）

```
Admin.NET.Pro/
├── Admin.NET.Web.Entry          # 程序入口 (Program.cs)
├── Admin.NET.Core              # 核心层（实体、服务、Seed数据）
├── Admin.NET.Application        # 应用服务层（业务编排）
├── Admin.NET.Web.Core          # Web中间件
├── Admin.NET.ToolsSystem        # 业务模块（已实现）
│   ├── Entity/                 # 业务实体
│   ├── Service/                # 业务服务
│   ├── Controller/             # API控制器
│   └── Startup.cs              # 模块注册
└── Plugins/*                   # 插件目录
```

---

## 3. 已实现的业务模块（ToolsSystem）

### 实体层
- [x] Template, TemplateCategory - 模板相关
- [x] SubscriptionPlan, SubscriptionOrder, UserSubscription - 订阅相关
- [x] Feedback, FeedbackReply - 用户反馈
- [x] ToolConfig, ToolUsageLog - 工具配置
- [x] TemplateUsageLog - 模板使用日志

### 服务层
- [x] TemplateService, TemplateCategoryService
- [x] SubscriptionService
- [x] FeedbackService
- [x] ToolsUserService, ToolsMobileAuthService

---

## 4. 前后端交互规范

### API 约定
- 统一前缀: `/api/*`
- 返回格式: `{ code: 0|非0, message: string, data: any }`
- 认证: `Authorization: Bearer <token>`

### 菜单动态化（重要！）
```
后端 sys_menu 表
    ↓
GET /api/sysMenu/loginMenuTree
    ↓
前端 dynamicImport 渲染
    ↓
禁止在前端写死菜单！
```

---

## 5. 开发注意事项

### DO（必须做）
- [ ] 使用 `[AppStartup]` 注册服务
- [ ] 用 `App.GetConfig<T>()` 读取配置
- [ ] 菜单从后端获取
- [ ] 使用 async/await
- [ ] 遵循 C# 命名规范

### DON'T（不要做）
- [ ] 不要硬编码菜单
- [ ] 不要直接 new 服务实例
- [ ] 不要在页面写死配置
- [ ] 不要忽略 Seed 数据的 ID

---

## 6. 下一步学习计划

### 本周目标
1. [ ] 深入阅读 Admin.NET 源码（Core 层）
2. [ ] 理解 SqlSugar ORM 用法
3. [ ] 学习 Vue3 组件化思想
4. [ ] 阅读 ToolsSystem 服务代码

### 学习资源
- 项目文档: `docs/`
- 框架源码: `Admin.NET/*/`
- 前端代码: `Web/src/`
- 移动端: `Mobile/`

---

## 7. 待解决问题（需要 Jonas 协助）

1. [ ] 前后端联调问题（API 连不上）
2. [ ] 菜单写死的问题需要修复
3. [ ] 理解 Java 项目结构（工作中用）

---

## 8. NAS 信息（机密，仅用于学习）

### 连接信息
- **地址**: 192.168.3.6:5000
- **用户名**: jonas
- **密码**: 1988Chen0219
- **用途**: 项目部署、资料存储、GitLab 代码管理

### NAS 包含的服务
- [ ] Docker
  - [ ] MySQL (数据库)
  - [ ] GitLab (代码仓库)
- [ ] 文件存储
- [ ] 备份系统

### 学习计划
1. [ ] 熟悉群晖 Web 管理界面
2. [ ] 学习 Docker 基本操作（容器管理、镜像、网络）
3. [ ] 了解 MySQL Docker 部署方式
4. [ ] 学习 GitLab 基本使用（创建项目、权限管理）
5. [ ] 尝试在 NAS 上部署测试环境

### 后续用途
- 开发环境部署测试
- 生产环境部署
- 代码版本控制
- 资料备份存储

---

*最后更新: 2026-02-11*
