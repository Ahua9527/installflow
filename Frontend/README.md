# 🔔 叮当装 InstallFlow - Cloudflare Workers 前端

## 项目概述

已成功迁移到 Cloudflare Workers 的前端界面，提供一键访问和安装脚本重定向功能。

## 功能特性

- **🌐 单页面应用**: 完全运行在 Cloudflare Workers 上
- **🔗 智能重定向**: `/install` 路径自动重定向到安装脚本
- **📱 响应式设计**: 完美适配移动端和桌面端
- **🌙 暗色模式**: 自动适配系统主题
- **⚡ 高性能**: 全球 CDN 分发，毫秒级响应

## 访问地址

- **主页**: https://ding.ahua.space/
- **安装脚本**: https://ding.ahua.space/install

## 技术栈

- **Cloudflare Workers**: 无服务器计算平台
- **ES6 模块**: 现代 JavaScript 语法
- **内联资源**: CSS 和 JS 完全内联，零外部依赖

## 文件结构

```
Frontend/
├── worker.js           # Workers 主文件（包含所有前端代码）
├── wrangler.toml       # Wrangler 配置文件
├── DEPLOYMENT.md       # 部署指南
└── README.md          # 项目说明（本文件）
```

## 部署

### 自动部署（推荐）

项目已配置 GitHub Actions 自动部署：
- 推送到 `main` 分支：自动部署到生产环境
- 创建 Pull Request：自动部署到开发环境

### 手动部署

```bash
cd Frontend
wrangler deploy --env production
```

详细部署说明请参考 [DEPLOYMENT.md](./DEPLOYMENT.md)

## 开发

### 本地测试

```bash
cd Frontend
wrangler dev
```

### 预览部署

```bash
wrangler deploy --env development
```

## 安全特性

- ✅ 无外部依赖，避免供应链攻击
- ✅ 内容安全策略优化
- ✅ 适当的缓存策略
- ✅ API Token 安全管理

## 关于叮当装 InstallFlow

叮当装（InstallFlow）让 Mac 批量装机变得简单快捷，像按下门铃一样轻松。

## License

MIT License