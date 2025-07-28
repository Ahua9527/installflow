# 🔔 InstallFlow (叮当装)

> 让 Mac 应用安装像"叮当"一声那样简单 - 批量处理本地安装包的 macOS 工具
<div align="center">

[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey.svg?style=flat-square)](https://www.apple.com/macos/)
[![Workers](https://img.shields.io/badge/Deployed%20on-Cloudflare%20Workers-F38020?style=flat-square&logo=cloudflare)](https://workers.cloudflare.com/)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/Ahua9527/installflow)

[English](./README.en.md) · 简体中文 · [Demo](https://ding.ahua.space)
</div>
## 📖 项目介绍

InstallFlow (叮当装) 是一个专为 macOS 设计的本地安装包批量处理工具。它可以帮助您快速安装已下载到本地的应用程序文件，无需逐个手动处理 DMG、PKG 等格式的安装包。

### 🎯 核心价值

- **解决痛点**：批量处理本地下载的 Mac 应用安装包，避免逐个挂载、拖拽的重复操作
- **目标用户**：需要批量安装本地应用的 Mac 用户、开发者和 IT 管理员
- **设计理念**：一个脚本，交互选择，智能处理，安全安装

## ✨ 主要特性

### 🚀 多格式支持
- **DMG 文件**：自动挂载、提取应用、智能处理嵌套结构（支持5层深度）
- **ISO 文件**：磁盘镜像挂载、应用提取、支持多层嵌套结构
- **PKG 文件**：调用系统安装器进行安装，支持嵌套PKG处理
- **ZIP 文件**：解压并提取其中的应用程序或DMG文件
- **APP 文件**：直接复制到应用程序文件夹，自动版本检测

### 🛡️ 安全机制
- **路径验证**：严格的路径安全检查，防止命令注入
- **sudo权限管理**：后台保活机制，自动维护管理员权限
- **临时文件清理**：自动清理安装过程中的临时文件
- **权限处理**：自动移除 quarantine 属性，确保应用正常运行
- **版本检测**：智能检测应用版本，自动更新或跳过重复安装
- **信号处理**：完善的退出清理机制，确保资源释放

### 💡 交互体验
- **终端界面**：方向键浏览，空格键选择，回车确认，支持30项/页显示
- **键盘支持**：Ctrl+A全选、Ctrl+N全不选、ESC/q退出
- **实时反馈**：彩色日志输出，详细安装进度，带时间戳
- **智能提示**：Apple Silicon 兼容性检测和 Rosetta 安装提醒
- **拖放支持**：支持文件夹拖放到终端窗口
- **安装报告**：完整的安装汇总，成功率统计，结果分类展示

### 🎨 Web 界面
- **Cloudflare Workers**：基于边缘计算的快速访问
- **现代设计**：毛玻璃效果，响应式布局
- **便捷分享**：一键复制安装命令

## 🛠️ 技术栈

### 前端
- **运行时**: Cloudflare Workers (Edge Computing)
- **技术**: Vanilla JavaScript, HTML5, CSS3
- **设计**: 内联式单文件架构，毛玻璃效果UI

### 安装脚本
- **语言**: Bash Script (1,335行专业代码，完整中文文档)
- **兼容性**: macOS 10.15+ (Catalina 及以上)
- **架构**: Apple Silicon 原生支持，自动 Rosetta 检测
- **文档**: 全面的中文注释，详细的功能说明和技术实现

### 部署
- **CI/CD**: GitHub Actions 自动化部署
- **环境**: 开发环境和生产环境分离
- **域名**: ding.ahua.space (主页), gh.ahua.space (脚本代理)

## 🚀 快速开始

### 运行环境

- macOS 10.15 (Catalina) 或更高版本
- 本地已下载的应用安装包 (DMG/ISO/PKG/ZIP/APP)
- 终端访问权限

### 使用方法

在终端中运行以下命令：

```bash
bash <(curl -fsSL https://ding.ahua.space/install)
```

### 使用流程

1. **运行安装脚本**：执行上述命令
2. **选择安装包**：脚本会扫描当前目录和常见下载位置
3. **交互式选择**：使用方向键浏览，空格键选择需要安装的应用
4. **确认安装**：按回车键开始批量安装过程
5. **查看结果**：安装完成后查看详细的安装报告

### ⚠️ 注意事项

**加密镜像文件限制**：
- 加密的DMG或ISO文件会中断自动化安装流程
- 建议在使用前预先解密或移除密码保护
- 脚本会尝试处理加密文件，但可能需要手动干预

**其他使用建议**：
- 确保有足够的磁盘空间进行安装
- 在安装大量应用时，建议关闭其他消耗资源的程序
- 安装过程中请勿手动操作Finder或挂载/推出磁盘

## 📚 项目架构

### 文件结构

```
/Frontend/
  worker.js          # 完整的 Cloudflare Worker 应用
  wrangler.toml      # 部署配置文件
  
/Scripts/
  install.sh         # 主安装脚本 (1,335行，完整中文文档)
  
/.github/
  workflows/deploy.yml    # GitHub Actions 部署配置

CLAUDE.md            # Claude Code AI 开发指南
README.md            # 中文项目文档
README.en.md         # 英文项目文档
```

### 🔍 核心功能模块

#### 📝 中文文档化
- **全面注释**：每个函数都有详细的中文说明
- **功能解释**：解释不仅是功能，还包括实现逻辑
- **技术细节**：涉及macOS特有功能的技术说明
- **代码结构**：清晰的模块分组和函数分类

#### 🎯 智能版本管理
- **版本提取**：从CFBundleShortVersionString或CFBundleVersion获取
- **语义化比较**：使用sort -V进行精确的版本排序
- **自动决策**：自动判断是否需要更新、跳过或降级
- **结果跟踪**：记录所有版本操作历史

#### 🪆 嵌套结构处理
- **递归解析**：支持DMG中嵌套DMG，最多5层深度
- **目录搜索**：智能识别安装目录和特殊结构
- **混合内容**：同时处理PKG和APP文件
- **挂载管理**：自动挂载和卸载，防止资源泄漏

### 核心组件

#### 安装脚本 (`Scripts/install.sh`)
- **文件扫描**：智能扫描本地目录中的安装包
- **格式检测**：自动识别不同格式的安装文件
- **交互界面**：终端内的图形化选择体验（支持方向键导航、分页显示）
- **版本管理**：智能版本比较，自动检测更新需求
- **嵌套处理**：支持多层嵌套的DMG/ISO结构处理
- **安装处理**：根据文件格式采用对应的安装方式
- **错误处理**：完善的错误恢复和日志记录
- **中文文档**：每个函数都有详细的中文注释说明

#### Web 界面 (`Frontend/worker.js`)
- **静态服务**：提供项目介绍和安装命令
- **脚本代理**：通过 `/install` 路径提供脚本下载
- **响应式设计**：适配不同设备的现代化界面

## 🔧 本地开发

### 前置要求

- Node.js 22+
- Cloudflare 账户（用于部署）

### 开发步骤

1. **克隆仓库**
   ```bash
   git clone https://github.com/yourusername/installflow.git
   cd installflow
   ```

2. **安装 Wrangler CLI**
   ```bash
   npm install -g wrangler
   ```

3. **本地开发服务器**
   ```bash
   cd Frontend
   wrangler dev
   ```

4. **部署到开发环境**
   ```bash
   wrangler deploy --env development
   ```

5. **测试安装脚本**
   ```bash
   bash Scripts/install.sh
   ```

## 🤝 贡献指南

欢迎提交 Pull Request 或 Issue！对于重大更改，请先开启 Issue 进行讨论。

### 贡献流程

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

### 开发规范

- 遵循现有的代码风格和注释规范
- 确保安全检查和路径验证通过
- 测试您的更改在不同 macOS 版本上的兼容性

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- Cloudflare Workers 提供的边缘计算平台
- GitHub Actions 提供的 CI/CD 服务
- macOS 开发者社区的支持和建议

## 📮 联系方式

- 项目地址: [https://ding.ahua.space](https://ding.ahua.space)
- 问题反馈: 通过 GitHub Issues 提交

---

<p align="center">
  Made with ❤️ for the Mac Community
</p>