# Web 文件选择器

一个现代化的 Web 文件夹选择器，用于配合 `bootstrap.sh` 脚本使用。支持点击选择和拖拽文件夹功能。

## 功能特性

- 📁 **文件夹选择**: 点击按钮选择文件夹
- 🎯 **拖拽支持**: 支持拖拽文件夹到指定区域
- 📋 **自动生成命令**: 根据选择的路径自动生成 shell 命令
- 🎨 **Markdown 渲染**: 使用 marked.js 美化命令显示
- 📱 **响应式设计**: 适配移动端和桌面端
- 🌙 **暗色模式**: 自动适配系统主题

## 技术栈

- **HTML5**: 文件 API + 拖拽 API
- **CSS3**: 现代化样式 + 响应式布局
- **JavaScript**: 原生 ES6+
- **Marked.js**: Markdown 渲染（通过 CDN 加载）

## 使用方法

### 1. 打开网页

直接在浏览器中打开 `index.html` 文件：

```bash
# macOS
open web-file-selector/index.html

# Linux
xdg-open web-file-selector/index.html

# Windows
start web-file-selector/index.html
```

### 2. 选择文件夹

有两种方式选择文件夹：

- **点击选择**: 点击"选择文件夹"按钮
- **拖拽选择**: 将文件夹拖拽到虚线框区域

### 3. 复制命令

1. 确认显示的文件夹路径正确
2. 点击"复制命令"按钮
3. 看到"✅ 已复制到剪贴板"提示

### 4. 执行命令

在终端中粘贴并执行复制的命令：

```bash
bash bootstrap.sh "your-folder-path"
```

## 与 Bootstrap.sh 集成

此工具专门设计用于配合 `bootstrap.sh` 脚本：

1. 用户通过网页选择包含安装包的文件夹
2. 工具自动生成正确格式的命令
3. 用户复制命令到终端执行
4. `bootstrap.sh` 脚本处理指定文件夹中的安装包

## 浏览器兼容性

- ✅ Chrome / Edge (推荐)
- ✅ Safari (需要较新版本)
- ⚠️ Firefox (不支持 webkitdirectory)

## 注意事项

1. 由于浏览器安全限制，只能获取文件夹名称，无法获取完整路径
2. 建议将要处理的文件夹放在易于访问的位置
3. 生成的命令中的路径是相对路径，需要在正确的目录下执行

## 文件结构

```
web-file-selector/
├── index.html          # 主页面
├── assets/
│   ├── css/
│   │   └── style.css   # 样式文件
│   └── js/
│       └── script.js   # JavaScript 逻辑
└── README.md           # 使用说明
```

## License

MIT License