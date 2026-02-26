/**
 * InstallFlow (叮当装) - Cloudflare Worker 前端应用
 * 
 * 这是一个基于 Cloudflare Workers 的单文件 Web 应用，为 macOS 批量应用安装工具提供前端界面。
 * 
 * 主要功能：
 * - 提供安装命令展示和复制功能
 * - 展示工具特色和使用方法
 * - 提供安装脚本的代理访问
 * - 现代化的玻璃拟态 UI 设计
 * 
 * 技术栈：
 * - Cloudflare Workers Runtime
 * - 原生 JavaScript (无外部依赖)
 * - CSS3 动画和玻璃拟态效果
 * - 响应式设计适配移动端
 * 
 * 架构说明：
 * - 所有资源(HTML/CSS/JS)内嵌在单个 Worker 文件中
 * - 通过路由分发不同类型的静态资源
 * - 支持缓存控制优化性能
 */

import {
  INSTALL_SCRIPT_CONTENT,
  INSTALL_SCRIPT_SHA256
} from './install-script.generated.js';

/* ================================
 * HTML 页面模板
 * 包含完整的页面结构，采用语义化标签和现代化布局
 * ================================ */
const HTML_CONTENT = `<!DOCTYPE html>
<html lang="zh-CN"> <!-- 设置页面语言为简体中文 -->
<head>
    <meta charset="UTF-8"> <!-- 字符编码设置 -->
    <meta name="viewport" content="width=device-width, initial-scale=1.0"> <!-- 响应式视口设置 -->
    <title>叮当装 - InstallFlow</title> <!-- 页面标题 -->
    <link rel="stylesheet" href="/assets/css/style.css"> <!-- 引入样式文件 -->
</head>
<body>
    <!-- 主容器：包含整个页面内容 -->
    <div class="container">
        <!-- 页面头部：品牌标识和主标题区域 -->
        <header class="hero-header">
            <!-- 品牌 Logo 组合 -->
            <div class="brand-logo">
                <div class="logo-icon">🔔</div> <!-- 品牌图标：叮当铃铛 -->
                <h1>叮当装 InstallFlow</h1> <!-- 产品名称 -->
            </div>
            <!-- 产品描述和宣传语 -->
            <p class="hero-subtitle">一键批量安装 Mac 应用，让装机像叮当一样简单</p>
        </header>

        <!-- 主要内容区域 -->
        <main class="main-content">
            <!-- 安装命令展示区域 -->
            <section class="command-section">
                <!-- 区块标题和说明 -->
                <div class="card-header">
                    <h2>🚀 安装命令</h2>
                    <p>复制下方命令并在终端中执行</p>
                </div>
                
                <!-- 命令展示和复制功能区域 -->
                <div class="command-container">
                    <!-- 命令展示框：使用玻璃拟态效果 -->
                    <div class="command-box">
                        <code id="installCommand">bash <(curl -fsSL https://ding.ahua.space/install)</code>
                    </div>
                    <!-- 复制按钮：带图标和渐变效果 -->
                    <button id="copyBtn" class="copy-button">
                        <!-- 复制图标 SVG -->
                        <svg class="copy-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
                            <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
                        </svg>
                        <span>复制命令</span>
                    </button>
                </div>
            </section>

            <!-- 功能特色展示区域 -->
            <section class="features-section">
                <h2>✨ 功能特色</h2>
                <!-- 特色功能网格布局：响应式三栏设计 -->
                <div class="features-grid">
                    <!-- 特色功能1：交互式选择 -->
                    <div class="feature-item">
                        <div class="feature-icon">🎯</div>
                        <h3>交互式选择</h3>
                        <p>使用方向键和空格键轻松选择要安装的应用</p>
                    </div>
                    <!-- 特色功能2：多格式支持 -->
                    <div class="feature-item">
                        <div class="feature-icon">📦</div>
                        <h3>多格式支持</h3>
                        <p>支持 .dmg、.iso、.pkg、.zip、.app 等常见格式</p>
                    </div>
                    <!-- 特色功能3：一键执行 -->
                    <div class="feature-item">
                        <div class="feature-icon">⚡</div>
                        <h3>一键执行</h3>
                        <p>通过简单的命令即可开始批量安装</p>
                    </div>
                </div>
            </section>
        </main>

        <!-- 页面底部：版权信息和链接 -->
        <footer class="footer">
            <div class="footer-container">
                <!-- GitHub 项目链接 -->
                <div class="github-link-container">
                    <a href="https://github.com/Ahua9527/installflow" target="_blank" rel="noopener noreferrer" class="github-link">
                        <!-- GitHub 图标 SVG -->
                        <svg class="github-icon" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                        </svg>
                        <span>GitHub</span>
                    </a>
                </div>
                
                <!-- 版权信息 -->
                <p class="footer-copyright">
                    InstallFlow © 2025 | Designed & Developed by 哆啦Ahua🌱
                </p>
            </div>
        </footer>
    </div>

    <!-- 引入 JavaScript 脚本：复制功能和交互逻辑 -->
    <script src="/assets/js/script.js"></script>
</body>
</html>`;

/* ================================
 * CSS 样式定义
 * 采用现代化设计理念，包含玻璃拟态效果、动画和响应式布局
 * ================================ */
const CSS_CONTENT = `/* 全局样式重置和基础设置 */
* {
    margin: 0;              /* 清除默认外边距 */
    padding: 0;             /* 清除默认内边距 */
    box-sizing: border-box; /* 设置盒模型为边框盒 */
}

/* 页面基础样式设置 */
body {
    /* 字体栈：优先使用系统默认字体，提升渲染性能 */
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
    line-height: 1.6;       /* 行高设置，提升可读性 */
    color: #2d3748;         /* 默认文本颜色 */
    /* 背景渐变：紫蓝色系，营造科技感 */
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh;      /* 最小高度为视口高度 */
    overflow-x: hidden;     /* 隐藏水平滚动条 */
}

/* ================================
 * 布局容器样式
 * ================================ */

/* 主容器：页面内容的包装器 */
.container {
    max-width: 1200px;           /* 最大宽度限制，保持内容可读性 */
    margin: 0 auto;              /* 水平居中 */
    padding: 2rem;               /* 内边距 */
    min-height: 100vh;           /* 最小高度为视口高度 */
    display: flex;               /* 使用 Flexbox 布局 */
    flex-direction: column;      /* 垂直排列子元素 */
    justify-content: flex-start; /* 顶部对齐 */
    align-items: center;         /* 水平居中 */
    text-align: center;          /* 文本居中对齐 */
    padding-top: 4rem;           /* 顶部内边距 */
    padding-bottom: 0rem;        /* 底部内边距 */
}

/* ================================
 * 头部区域样式
 * ================================ */

/* 英雄区域头部 */
.hero-header {
    margin-bottom: 4rem;            /* 底部间距 */
    animation: fadeInUp 0.8s ease-out; /* 淡入向上动画 */
}

/* 品牌 Logo 组合容器 */
.brand-logo {
    display: flex;          /* Flexbox 布局 */
    align-items: center;    /* 垂直居中对齐 */
    justify-content: center; /* 水平居中对齐 */
    gap: 1rem;              /* 子元素间距 */
    margin-bottom: 1.5rem;  /* 底部间距 */
}

/* Logo 图标样式 */
.logo-icon {
    font-size: 3.5rem;      /* 大字号 */
    /* 阴影效果，增加立体感 */
    filter: drop-shadow(0 4px 8px rgba(0,0,0,0.2));
}

/* 主标题样式 */
.hero-header h1 {
    font-size: 3.5rem;      /* 大字号 */
    font-weight: 700;       /* 加粗字体 */
    color: white;           /* 白色文本 */
    /* 文本阴影，增强可读性 */
    text-shadow: 0 4px 8px rgba(0,0,0,0.2);
    margin: 0;              /* 清除默认间距 */
}

/* 副标题样式 */
.hero-subtitle {
    font-size: 1.25rem;     /* 中等字号 */
    color: rgba(255, 255, 255, 0.9); /* 半透明白色 */
    margin-top: 1rem;       /* 顶部间距 */
    /* 轻微文本阴影 */
    text-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

/* ================================
 * 主内容区域样式
 * ================================ */

/* 主内容区域容器 */
.main-content {
    width: 100%;        /* 全宽度 */
    max-width: 800px;   /* 最大宽度限制，保持内容可读性 */
}

/* 命令展示区域 */
.command-section {
    margin-bottom: 4rem;   /* 底部间距 */
    /* 向上滑入动画，延迟0.2秒执行 */
    animation: slideInUp 0.6s ease-out 0.2s both;
}

/* 卡片头部样式 */
.card-header {
    margin-bottom: 2rem;   /* 底部间距 */
}

/* 卡片标题样式 */
.card-header h2 {
    font-size: 2rem;       /* 大字号 */
    font-weight: 600;      /* 中等加粗 */
    color: white;          /* 白色文本 */
    margin-bottom: 0.5rem; /* 底部间距 */
    /* 文本阴影效果 */
    text-shadow: 0 2px 4px rgba(0,0,0,0.2);
}

/* 卡片描述文本样式 */
.card-header p {
    font-size: 1.125rem;   /* 中等字号 */
    color: rgba(255, 255, 255, 0.8); /* 半透明白色 */
    /* 轻微文本阴影 */
    text-shadow: 0 1px 2px rgba(0,0,0,0.1);
}

/* ================================
 * 命令展示组件样式
 * ================================ */

/* 命令容器布局 */
.command-container {
    display: flex;          /* Flexbox 布局 */
    flex-direction: column; /* 垂直排列 */
    gap: 1.5rem;           /* 子元素间距 */
    align-items: center;    /* 水平居中对齐 */
}

/* 命令展示框：采用玻璃拟态效果 */
.command-box {
    /* 玻璃拟态背景：半透明白色 */
    background: rgba(255, 255, 255, 0.1);
    /* 背景模糊效果，营造玻璃质感 */
    backdrop-filter: blur(20px);
    color: #e2e8f0;         /* 浅灰色文本 */
    border-radius: 48px;    /* 大圆角，现代化设计 */
    padding: 2rem;          /* 内边距 */
    width: 100%;            /* 全宽度 */
    max-width: 600px;       /* 最大宽度限制 */
    /* 多层阴影效果，增强立体感 */
    box-shadow: 0 4px 8px -2px rgba(0, 0, 0, 0.15), 0 2px 4px -1px rgba(0, 0, 0, 0.1);
    /* 半透明边框 */
    border: 1px solid rgba(255, 255, 255, 0.2);
}

/* 命令代码显示样式 */
.command-box code {
    display: block;         /* 块级显示 */
    /* 等宽字体栈，优先使用系统默认等宽字体 */
    font-family: 'SF Mono', 'Monaco', 'Inconsolata', 'Fira Code', 'Consolas', monospace;
    font-size: 0.95rem;     /* 小一号字体 */
    line-height: 1.6;       /* 行高 */
    word-break: break-all;  /* 强制换行，防止溢出 */
    color: #e2e8f0;         /* 浅灰色文本 */
}

/* ================================
 * 复制按钮样式
 * ================================ */

/* 复制按钮主体样式 */
.copy-button {
    /* 绿色渐变背景，营造成功感 */
    background: linear-gradient(135deg, #10b981 0%, #059669 100%);
    color: white;           /* 白色文本 */
    border: none;           /* 无边框 */
    padding: 1rem 2.5rem;   /* 内边距，提供足够的点击区域 */
    font-size: 1rem;        /* 标准字号 */
    font-weight: 600;       /* 中等加粗 */
    border-radius: 50px;    /* 全圆角，药丸形按钮 */
    cursor: pointer;        /* 手型光标 */
    /* 平滑过渡效果 */
    transition: all 0.3s ease;
    display: flex;          /* Flexbox 布局 */
    align-items: center;    /* 垂直居中对齐 */
    gap: 0.75rem;           /* 图标和文本间距 */
    /* 绿色阴影效果，与按钮颜色呼应 */
    box-shadow: 0 10px 15px -3px rgba(16, 185, 129, 0.3), 0 4px 6px -2px rgba(16, 185, 129, 0.2);
    position: relative;     /* 相对定位，为伪元素做准备 */
    overflow: hidden;       /* 隐藏溢出内容 */
}

/* 复制按钮动效和状态 */

/* 按钮发光效果伪元素 */
.copy-button::before {
    content: '';            /* 空内容 */
    position: absolute;     /* 绝对定位 */
    top: 0;
    left: -100%;           /* 初始位置在左侧外部 */
    width: 100%;
    height: 100%;
    /* 发光效果渐变：透明 -> 半透明白色 -> 透明 */
    background: linear-gradient(90deg, transparent, rgba(255,255,255,0.2), transparent);
    transition: left 0.5s ease; /* 平滑移动过渡 */
}

/* 鼠标悬停时的发光效果 */
.copy-button:hover::before {
    left: 100%;            /* 移动到右侧外部，实现扰过效果 */
}

/* 鼠标悬停状态 */
.copy-button:hover {
    transform: translateY(-3px); /* 向上提升，增强交互感 */
    /* 增强阴影效果，营造悬浮感 */
    box-shadow: 0 20px 25px -5px rgba(16, 185, 129, 0.4), 0 10px 10px -5px rgba(16, 185, 129, 0.3);
}

/* 按钮点击状态 */
.copy-button:active {
    transform: translateY(-1px); /* 轻微下压，模拟物理点击 */
}

/* 按钮禁用状态 */
.copy-button:disabled {
    background: rgba(148, 163, 184, 0.8); /* 灰色背景 */
    cursor: not-allowed;    /* 禁止光标 */
    transform: none;        /* 取消变形 */
    box-shadow: none;       /* 取消阴影 */
}

/* 复制图标样式 */
.copy-icon {
    width: 20px;           /* 图标宽度 */
    height: 20px;          /* 图标高度 */
    stroke-width: 2;       /* 笔画粗细 */
}

/* ================================
 * 功能特色区域样式
 * ================================ */

/* 功能特色区域容器 */
.features-section {
    /* 淡入向上动画，延迟0.4秒执行 */
    animation: fadeInUp 0.6s ease-out 0.4s both;
}

/* 功能特色标题 */
.features-section h2 {
    font-size: 2.5rem;     /* 大字号 */
    font-weight: 700;      /* 加粗字体 */
    color: white;          /* 白色文本 */
    margin-bottom: 3rem;   /* 底部间距 */
    /* 文本阴影效果 */
    text-shadow: 0 4px 8px rgba(0,0,0,0.2);
}

/* 功能特色网格布局 */
.features-grid {
    display: grid;          /* 网格布局 */
    /* 响应式网格：最小240px，自动适应容器宽度 */
    grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
    gap: 2rem;             /* 网格间距 */
    margin-top: 2rem;      /* 顶部间距 */
}

/* 功能特色单项样式 */
.feature-item {
    /* 玻璃拟态背景 */
    background: rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(20px);  /* 背景模糊 */
    border-radius: 20px;   /* 圆角 */
    padding: 2rem 1.5rem;  /* 内边距 */
    /* 半透明边框 */
    border: 1px solid rgba(255, 255, 255, 0.2);
    /* 平滑过渡效果 */
    transition: all 0.3s ease;
    /* 淡入向上动画 */
    animation: fadeInUp 0.6s ease-out both;
}

/* 功能特色单项动画延迟：错开动画时间，实现波浪效果 */
.feature-item:nth-child(1) { animation-delay: 0.5s; }
.feature-item:nth-child(2) { animation-delay: 0.6s; }
.feature-item:nth-child(3) { animation-delay: 0.7s; }

/* 功能特色单项悬停状态 */
.feature-item:hover {
    transform: translateY(-8px);    /* 向上提升，增强交互感 */
    /* 增强背景透明度 */
    background: rgba(255, 255, 255, 0.15);
    /* 增强阴影效果，营造悬浮感 */
    box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.3), 0 10px 10px -5px rgba(0, 0, 0, 0.2);
}

/* 功能图标样式 */
.feature-icon {
    font-size: 3rem;        /* 大字号图标 */
    margin-bottom: 1rem;    /* 底部间距 */
    display: block;         /* 块级显示 */
    /* 阴影效果，增加立体感 */
    filter: drop-shadow(0 2px 4px rgba(0,0,0,0.2));
}

/* 功能标题样式 */
.feature-item h3 {
    font-size: 1.25rem;     /* 中等字号 */
    font-weight: 600;       /* 中等加粗 */
    color: white;           /* 白色文本 */
    margin-bottom: 0.75rem; /* 底部间距 */
    /* 文本阴影效果 */
    text-shadow: 0 2px 4px rgba(0,0,0,0.2);
}

/* 功能描述文本样式 */
.feature-item p {
    color: rgba(255, 255, 255, 0.85); /* 半透明白色 */
    line-height: 1.6;       /* 行高 */
    font-size: 0.95rem;     /* 小一号字体 */
}

/* ================================
 * 页面底部样式
 * ================================ */

/* 底部区域容器 */
.footer {
    margin-top: 2rem;       /* 顶部间距 */
    /* 淡入向上动画，延迟0.8秒执行 */
    animation: fadeInUp 0.6s ease-out 0.8s both;
}

/* 底部内容容器 */
.footer-container {
    padding: 1rem 0;        /* 垂直内边距 */
    display: flex;          /* Flexbox 布局 */
    flex-direction: column; /* 垂直排列 */
    align-items: center;    /* 水平居中对齐 */
    gap: 0.5rem;           /* 子元素间距 */
}

/* GitHub 链接容器 */
.github-link-container {
    display: flex;          /* Flexbox 布局 */
    justify-content: center; /* 水平居中对齐 */
}

/* GitHub 链接样式 */
.github-link {
    display: flex;          /* Flexbox 布局 */
    align-items: center;    /* 垂直居中对齐 */
    gap: 0.5rem;           /* 图标和文本间距 */
    color: rgba(255, 255, 255, 0.6); /* 半透明白色 */
    text-decoration: none;  /* 去除下划线 */
    transition: color 0.3s ease; /* 颜色过渡效果 */
    font-size: 0.9rem;     /* 小字号 */
}

/* GitHub 链接悬停状态 */
.github-link:hover {
    color: rgba(255, 255, 255, 0.9); /* 增强不透明度 */
}

/* GitHub 图标样式 */
.github-icon {
    width: 16px;           /* 图标宽度 */
    height: 16px;          /* 图标高度 */
    /* 变形过渡效果 */
    transition: transform 0.3s ease;
}

/* GitHub 图标悬停状态 */
.github-link:hover .github-icon {
    transform: scale(1.1); /* 放大效果 */
}

/* 版权信息样式 */
.footer-copyright {
    font-size: 0.75rem;    /* 小字号 */
    color: rgba(255, 255, 255, 0.4); /* 低透明度白色 */
    text-align: center;     /* 文本居中 */
    margin: 0;             /* 清除默认间距 */
}

/* ================================
 * 通知组件样式
 * ================================ */

/* 通知消息样式 */
.notification {
    position: fixed;        /* 固定定位 */
    bottom: 2rem;          /* 底部距离 */
    right: 2rem;           /* 右侧距离 */
    /* 绿色渐变背景，与复制按钮保持一致 */
    background: linear-gradient(135deg, #10b981 0%, #059669 100%);
    color: white;          /* 白色文本 */
    padding: 1rem 1.5rem;  /* 内边距 */
    border-radius: 50px;   /* 全圆角，药丸形 */
    /* 阴影效果，增强立体感 */
    box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.3), 0 10px 10px -5px rgba(0, 0, 0, 0.2);
    transform: translateX(100%); /* 初始位置在右侧外部 */
    opacity: 0;            /* 初始透明度为0 */
    /* 平滑过渡效果 */
    transition: all 0.3s ease;
    z-index: 1000;         /* 高层级，保证在最上层 */
    font-weight: 500;      /* 中等字体粗细 */
    backdrop-filter: blur(20px); /* 背景模糊 */
}

/* 通知显示状态 */
.notification.show {
    transform: translateX(0); /* 移动到正常位置 */
    opacity: 1;            /* 完全不透明 */
}

/* ================================
 * CSS 动画定义
 * ================================ */

/* 淡入向上动画：用于页面元素的入场效果 */
@keyframes fadeInUp {
    from {
        opacity: 0;             /* 初始透明度为0 */
        transform: translateY(30px); /* 初始位置向下偏移30px */
    }
    to {
        opacity: 1;             /* 终止透明度为1 */
        transform: translateY(0); /* 终止位置为原位 */
    }
}

/* 滑入向上动画：用于命令区域的入场效果 */
@keyframes slideInUp {
    from {
        opacity: 0;             /* 初始透明度为0 */
        transform: translateY(50px); /* 初始位置向下偏移50px */
    }
    to {
        opacity: 1;             /* 终止透明度为1 */
        transform: translateY(0); /* 终止位置为原位 */
    }
}

/* ================================
 * 响应式设计 - 平板端适配
 * ================================ */

/* 平板端样式：屏幕宽度小于768px */
@media (max-width: 768px) {
    /* 缩小容器内边距 */
    .container {
        padding: 1rem;
    }
    
    /* 缩小主标题字号 */
    .hero-header h1 {
        font-size: 2.5rem;
    }
    
    /* 缩小副标题字号 */
    .hero-subtitle {
        font-size: 1rem;
    }
    
    /* 调整命令框样式 */
    .command-box {
        padding: 1.5rem 1.25rem; /* 缩小内边距 */
        border-radius: 24px;      /* 缩小圆角 */
        max-width: none;          /* 取消最大宽度限制 */
        margin: 0 0.5rem;         /* 添加水平间距 */
    }
    
    /* 缩小代码字体 */
    .command-box code {
        font-size: 0.85rem;
        line-height: 1.4;
    }
    
    /* 功能特色改为单列布局 */
    .features-grid {
        grid-template-columns: 1fr; /* 单列显示 */
        gap: 1.5rem;               /* 缩小间距 */
    }
    
    /* 缩小功能项内边距 */
    .feature-item {
        padding: 1.5rem;
    }
    
    /* 调整通知位置，占满屏宽 */
    .notification {
        bottom: 1rem;
        right: 1rem;
        left: 1rem; /* 占满屏宽 */
    }
}

/* ================================
 * 响应式设计 - 手机端适配
 * ================================ */

/* 手机端样式：屏幕宽度小于480px */
@media (max-width: 480px) {
    /* 品牌 Logo 改为垂直布局 */
    .brand-logo {
        flex-direction: column; /* 垂直排列 */
        gap: 0.5rem;           /* 缩小间距 */
    }
    
    /* 缩小 Logo 图标 */
    .logo-icon {
        font-size: 3rem;
    }
    
    /* 进一步缩小主标题 */
    .hero-header h1 {
        font-size: 2rem;
    }
    
    /* 缩小命令容器间距 */
    .command-container {
        gap: 1rem;
    }
    
    /* 进一步调整命令框 */
    .command-box {
        padding: 1.25rem 1rem;   /* 缩小内边距 */
        border-radius: 20px;     /* 缩小圆角 */
        margin: 0 0.25rem;       /* 缩小水平间距 */
    }
    
    /* 进一步缩小代码字体 */
    .command-box code {
        font-size: 0.8rem;
        line-height: 1.3;
    }
    
    /* 缩小复制按钮 */
    .copy-button {
        padding: 0.875rem 1.5rem; /* 缩小内边距 */
        font-size: 0.9rem;        /* 缩小字体 */
    }
}

/* ================================
 * 深色模式适配 (预留)
 * 当前设计主要针对深色背景，暂无特别适配
 * ================================ */
@media (prefers-color-scheme: dark) {
    /* 深色模式下的特殊样式可在此处添加 */
}`;

/* ================================
 * JavaScript 交互逻辑
 * 实现复制功能、通知系统和事件处理
 * ================================ */
const JS_CONTENT = `/* =====================================
 * DOM 元素获取和事件绑定
 * ===================================== */

// 获取复制按钮元素
const copyBtn = document.getElementById('copyBtn');
// 获取安装命令元素
const installCommand = document.getElementById('installCommand');

// 绑定复制按钮点击事件
copyBtn.addEventListener('click', copyInstallCommand);

/* =====================================
 * 复制功能实现
 * 支持现代浏览器的 Clipboard API 和传统的 execCommand 方法
 * ===================================== */

/**
 * 复制安装命令到剪贴板
 * 优先使用现代 Clipboard API，失败后降级使用传统方法
 */
async function copyInstallCommand() {
    // 获取要复制的命令文本
    const command = installCommand.textContent;
    
    try {
        // 尝试使用现代 Clipboard API
        await navigator.clipboard.writeText(command);
        // 复制成功，显示成功通知
        showNotification('✅ 命令已复制到剪贴板');
        
        // 保存按钮原始内容
        const originalContent = copyBtn.innerHTML;
        // 修改按钮文本为“已复制”
        copyBtn.innerHTML = '<span>已复制</span>';
        // 禁用按钮，防止重复点击
        copyBtn.disabled = true;
        
        // 2秒后恢复按钮原始状态
        setTimeout(() => {
            copyBtn.innerHTML = originalContent;
            copyBtn.disabled = false;
        }, 2000);
        
    } catch (err) {
        // Clipboard API 失败，使用传统的 execCommand 方法
        
        // 创建临时文本域元素
        const textArea = document.createElement('textarea');
        textArea.value = command;           // 设置文本内容
        textArea.style.position = 'absolute'; // 绝对定位
        textArea.style.left = '-9999px';    // 放置在可视区域外
        document.body.appendChild(textArea); // 添加到 DOM
        textArea.select();                  // 选中文本
        
        try {
            // 尝试使用传统复制命令
            document.execCommand('copy');
            showNotification('✅ 命令已复制到剪贴板');
        } catch (err) {
            // 复制完全失败，记录错误并显示失败通知
            console.error('复制失败:', err);
            showNotification('❌ 复制失败，请手动复制命令');
        }
        
        // 清理临时创建的文本域元素
        document.body.removeChild(textArea);
    }
}

/* =====================================
 * 通知系统实现
 * 提供右侧滑入的通知消息显示
 * ===================================== */

/**
 * 显示通知消息
 * @param {string} message - 要显示的通知文本
 */
function showNotification(message) {
    // 动态创建通知元素
    const notification = document.createElement('div');
    notification.className = 'notification';  // 设置 CSS 类名
    notification.textContent = message;        // 设置通知文本
    document.body.appendChild(notification);   // 添加到页面
    
    // 延迟100ms后显示通知（添加 show 类）
    // 这个延迟确保 DOM 元素渲染完成后再触发动画
    setTimeout(() => {
        notification.classList.add('show');
    }, 100);
    
    // 2秒后开始隐藏通知
    setTimeout(() => {
        notification.classList.remove('show');  // 移除 show 类，触发隐藏动画
        // 等待隐藏动画完成后（300ms）移除 DOM 元素
        setTimeout(() => {
            document.body.removeChild(notification);
        }, 300);
    }, 2000);
}

/* =====================================
 * 页面事件处理
 * 防止意外的文件拖放操作
 * ===================================== */

// 防止页面接受拖放文件（dragover 事件）
// 防止浏览器默认的文件拖放行为，保持页面稳定
document.addEventListener('dragover', (e) => {
    e.preventDefault();  // 阻止默认行为
});

// 防止页面接受拖放文件（drop 事件）
// 防止用户意外将文件拖到页面上时浏览器尝试打开文件
document.addEventListener('drop', (e) => {
    e.preventDefault();  // 阻止默认行为
});`;

/* ================================
 * Cloudflare Worker 主程序
 * 处理所有请求的路由分发逻辑
 * ================================ */

/**
 * Cloudflare Worker 导出对象
 * 包含 fetch 方法来处理所有入站请求
 */
export default {
  /**
   * 处理所有 HTTP 请求
   * @param {Request} request - 入站请求对象
   * @returns {Response} 相应的响应对象
   */
  async fetch(request) {
    // 解析请求 URL，获取路径信息
    const url = new URL(request.url);
    const pathname = url.pathname;

    /* =====================================
     * 路由处理逻辑
     * ===================================== */

    // 安装脚本路由：/install
    // 返回同源脚本文本，避免依赖外部可变代理
    if (pathname === '/install') {
      return new Response(INSTALL_SCRIPT_CONTENT, {
        status: 200,
        headers: {
          'Content-Type': 'text/plain; charset=utf-8',
          'Content-Disposition': 'inline; filename="install.sh"',
          'Cache-Control': 'no-store',
          'X-Content-Type-Options': 'nosniff',
          'X-Install-Script-Sha256': INSTALL_SCRIPT_SHA256
        }
      });
    }

    // CSS 样式路由：/assets/css/style.css
    // 返回内嵌的 CSS 样式内容
    if (pathname === '/assets/css/style.css') {
      return new Response(CSS_CONTENT, {
        headers: {
          'Content-Type': 'text/css; charset=utf-8',  // CSS MIME 类型
          'Cache-Control': 'public, max-age=86400'     // 缓存 24 小时
        }
      });
    }

    // JavaScript 路由：/assets/js/script.js
    // 返回内嵌的 JavaScript 代码
    if (pathname === '/assets/js/script.js') {
      return new Response(JS_CONTENT, {
        headers: {
          'Content-Type': 'application/javascript; charset=utf-8',  // JS MIME 类型
          'Cache-Control': 'public, max-age=86400'                   // 缓存 24 小时
        }
      });
    }

    // 默认路由：所有其他路径
    // 返回主页 HTML 内容
    return new Response(HTML_CONTENT, {
      headers: {
        'Content-Type': 'text/html; charset=utf-8',  // HTML MIME 类型
        'Cache-Control': 'public, max-age=3600'       // 缓存 1 小时
      }
    });
  }
};

/* =====================================
 * 文件结束
 * 
 * 此文件包含了完整的 InstallFlow 前端应用：
 * - HTML 页面结构和内容
 * - CSS 样式和响应式设计
 * - JavaScript 交互逻辑和复制功能
 * - Cloudflare Worker 路由处理
 * 
 * 所有资源均内嵌在单个 Worker 文件中，
 * 无需外部依赖，便于部署和维护。
 * ===================================== */
