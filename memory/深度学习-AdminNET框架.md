# OpenClaw 深度学习笔记 - Admin.NET 框架

> 学习时间: 2026-02-12
> 状态: 深入学习中

---

## 1. 整体架构

### 1.1 项目结构

```
Admin.NET.Pro/
├── Admin.NET.Application/     # 应用服务层 - 业务编排
├── Admin.NET.Core/          # 核心层 - 实体、服务、Seed数据
├── Admin.NET.Web.Core/     # Web中间件 - Startup配置
├── Admin.NET.Web.Entry/     # 程序入口 - Serve.Run()
├── Admin.NET.ToolsSystem/  # 业务模块 - 我们的工具系统
├── Plugins/*/              # 插件模块
├── Web/                    # 前端 Vue3
└── GoView/                 # 可视化设计器
```

### 1.2 技术栈

| 层级 | 技术 | 用途 |
|------|------|------|
| 后端框架 | **Furion** | DI、中间件、配置 |
| ORM | **SqlSugar** | 数据库访问 |
| 前端框架 | **Vue3 + Pinia** | 状态管理、组件化 |
| UI组件 | **Element Plus** | UI组件库 |
| API文档 | **Swagger/Knife4j** | 接口文档 |

---

## 2. Furion 框架核心

### 2.1 启动方式

```csharp
// 极简启动
Serve.Run();

// 模块注册
[AppStartup(110)]
public class Startup : AppStartup
{
    public void ConfigureServices(IServiceCollection services) { }
    public void Configure(IApplicationBuilder app) { }
}
```

### 2.2 配置读取

```csharp
// ✅ 推荐方式
var title = App.GetConfig<string>("Title");

// ❌ 传统方式
var title = Configuration["Title"];
```

### 2.3 常用扩展点

- `AppStartup` - 模块初始化
- `App.GetConfig<T>()` - 配置读取
- `dynamicapi` - 自动生成API
- 事件总线、虚拟文件系统、任务队列

---

## 3. 开发标准

### 3.1 代码风格

**后端 (C#)**:
- 遵守 C# 命名规范
- 使用 `async/await`
- 避免硬编码配置
- 通过 DI 注入服务，禁止 `new`

**前端 (Vue3)**:
- TypeScript 严格模式
- 使用 Pinia 统一状态管理
- 模块化组织代码

### 3.2 服务注册

```csharp
// ✅ 推荐
[AppStartup]
public class MyModule
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddScoped<IMyService, MyService>();
    }
}

// ❌ 禁止
var service = new MyService(); // 绕过DI
```

### 3.3 配置管理

```csharp
// appsettings.json
{
  "MySection": {
    "Key": "Value"
  }
}

// 代码读取
var value = App.GetConfig<string>("MySection:Key");
```

---

## 4. 菜单与路由

### 4.1 动态路由原理

```
后端 sys_menu 表
    ↓
GET /api/sysMenu/loginMenuTree
    ↓
前端 dynamicImport 渲染
    ↓
禁止在前端写死菜单！
```

### 4.2 菜单字段规范

| 字段 | 说明 | 示例 |
|------|------|------|
| path | 路由路径 | `/system/user` |
| name | 路由名称 | user |
| component | 组件路径 | `/views/system/user/index.vue` |
| meta | 扩展信息 | title、icon、isHide |

### 4.3 禁止硬编码

```typescript
// ❌ 禁止
const menuList = [{ title: '用户管理', path: '/user' }];

// ✅ 推荐
import { useRoutesList } from '/@/stores';
const routesList = useRoutesList();
```

---

## 5. SqlSugar 使用规范

### 5.1 仓储模式

```csharp
private readonly SqlSugarRepository<User> _userRepo;

public UserService(SqlSugarRepository<User> userRepo)
{
    _userRepo = userRepo;
}
```

### 5.2 查询模式

```csharp
// 基础查询
_repo.AsQueryable()
    .Where(u => u.Status == 1)
    .ToList();

// 条件查询
_repo.AsQueryable()
    .WhereIF(condition, predicate)
    .OrderByDescending(u => u.CreateTime)
    .ToPagedList(page, pageSize);

// 联表查询
_repo.AsQueryable()
    .LeftJoin<Role>((u, r) => u.RoleId == r.Id)
    .Where((u, r) => r.Status == 1)
    .Select((u, r) => new UserDto { ... })
    .ToList();
```

### 5.3 DTO 映射

```csharp
.Select(u => new UserDto
{
    Id = u.Id,
    Name = u.RealName,
    RoleName = SqlFunc.Subqueryable<Role>()
        .Where(r => r.Id == u.RoleId)
        .Select(r => r.Name)
})
```

---

## 6. 前端架构

### 6.1 目录结构

```
Web/src/
├── api/              # API接口
├── views/            # 页面组件
├── router/          # 路由配置
├── stores/           # Pinia状态管理
├── utils/           # 工具函数
└── api-services/    # 自动生成的API客户端
```

### 6.2 API 调用

```typescript
import request from '/@/utils/request';

// 手动封装
export function getUserList(params) {
    return request({
        url: '/api/user/list',
        method: 'get',
        params,
    });
}
```

### 6.3 动态路由

```typescript
// 从后端获取菜单
const getBackEndControlRoutes = async () => {
    const res = await SysMenuApi.apiSysMenuLoginMenuTreeGet();
    // 转换为Vue Router格式
    // dynamicImport 加载组件
};
```

---

## 7. 模块化开发

### 7.1 新增页面流程

**后端**:
1. 创建 Entity
2. 创建 Service
3. 创建 Controller
4. 在 `sys_menu` 表插入菜单记录

**前端**:
1. 创建页面组件 (`views/xxx/index.vue`)
2. 后端菜单的 `component` 字段填写路径
3. 测试登录后菜单是否显示

### 7.2 插件开发

```
Plugins/
├── MyPlugin/
│   ├── Startup.cs           # 插件初始化
│   ├── Service/             # 服务层
│   ├── Controller/          # API层
│   └── wwwroot/            # 静态资源
```

```csharp
[AppStartup]
public class MyPluginStartup : AppStartup
{
    public void ConfigureServices(IServiceCollection services) { }
    public void Configure(IApplicationBuilder app) { }
}
```

---

## 8. 数据库设计

### 8.1 核心表

| 表名 | 说明 |
|------|------|
| sys_user | 用户表 |
| sys_role | 角色表 |
| sys_menu | 菜单表 |
| sys_tenant | 租户表 |
| sys_org | 机构表 |

### 8.2 Seed 数据

- 位于 `Admin.NET.Core/SeedData/`
- 系统初始化时自动创建
- 包含初始管理员、字典、配置等

---

## 9. 部署架构

### 9.1 Docker 服务

| 服务 | 端口 | 用途 |
|------|------|------|
| nginx | 9100/9103 | 前端页面 |
| mysql | 9101 | 数据库 |
| redis | 6379 | 缓存 |
| adminNet | 9102 | 后端API |

### 9.2 配置文件

```
docker/
├── docker-compose.yml
├── app/                    # 后端发布文件
└── nginx/
    ├── conf/nginx.conf
    └── dist/               # 前端构建文件
```

---

## 10. 重要教训

### 10.1 开发规范

✅ **DO**:
- 使用 DI 注入服务
- 通过配置文件读取配置
- 使用异步编程
- 遵循代码规范
- 菜单从后端获取

❌ **DON'T**:
- 手动 `new` 服务实例
- 在代码中硬编码配置
- 同步阻塞调用
- 前端写死菜单

### 10.2 常见问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 菜单不显示 | token无效或无权限 | 检查登录状态和权限 |
| 组件找不到 | component路径错误 | 确认路径与views目录匹配 |
| API 500 | 服务未注册 | 检查 Startup 配置 |

---

## 11. 下一步学习

- [ ] 深入学习 SqlSugar 高级特性
- [ ] 学习事件总线和消息队列
- [ ] 掌握 Docker 容器化部署
- [ ] 理解多租户实现
- [ ] 学习性能优化技巧

---

*学习记录: 2026-02-12*
*来源: Admin.NET.Pro docs/*
