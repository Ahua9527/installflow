# 🔔 叮当装 InstallFlow

> 一键批量安装 Mac 应用，让装机像叮当一样简单

## 简介

叮当装（InstallFlow）是一款专为 macOS 设计的批量应用安装工具。它能够自动化处理 .dmg、.pkg、.zip 和 .app 格式的安装包，让您的 Mac 装机过程变得简单高效。

## ✨ 特色功能

- 🎯 **交互式选择**：使用方向键和空格键轻松选择要安装的应用
- 📦 **多格式支持**：支持 .dmg、.pkg、.zip、.app 等常见格式
- 🔐 **Gatekeeper 管理**：智能处理系统安全设置，确保第三方应用顺利安装
- 🎪 **特殊包处理**：自动识别并处理嵌套结构的安装包（如 TNT 团队发布的软件）
- 🌐 **Web 界面**：提供在线文件夹选择器，方便生成安装命令
- 🚀 **一键执行**：通过简单的命令即可开始批量安装

## 🛠 使用方法

### 方式一：在线使用（推荐）

1. 访问 [叮当装在线工具](https://installflow.pages.dev)
2. 选择包含安装包的文件夹
3. 输入完整路径
4. 复制生成的命令到终端执行

### 方式二：命令行直接使用

```bash
# 使用 curl 下载并执行
curl -fsSL https://gh.ahua.space/https://raw.githubusercontent.com/Ahua9527/installflow/refs/heads/main/Scripts/install.sh | bash -s -- "/path/to/your/installers"

# 或使用 bash
bash <(curl -fsSL https://gh.ahua.space/https://raw.githubusercontent.com/Ahua9527/installflow/refs/heads/main/Scripts/install.sh) "/path/to/your/installers"
```

### 方式三：本地执行

```bash
# 克隆仓库
git clone https://github.com/Ahua9527/installflow.git
cd installflow

# 执行脚本
bash Scripts/install.sh /path/to/your/installers
```

## 📱 交互式界面

脚本启动后，您将看到一个友好的交互式界面：

- ⬆️⬇️ 使用方向键移动光标
- 空格键 切换选择状态
- Ctrl+A 全选
- Ctrl+N 全不选
- 回车键 确认安装

## 🔒 安全提示

- 脚本会检查 Gatekeeper 状态，并在需要时提供关闭建议
- 安装完成后会提醒您重新启用 Gatekeeper
- 所有操作都需要管理员权限确认

## 📋 系统要求

- macOS 10.12 或更高版本
- 管理员权限
- 足够的磁盘空间

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

---

🔔 **叮当装 InstallFlow** - 让 Mac 装机更简单