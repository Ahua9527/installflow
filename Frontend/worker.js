// 内联的 HTML 内容
const HTML_CONTENT = `<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>叮当装 - InstallFlow</title>
    <link rel="stylesheet" href="/assets/css/style.css">
</head>
<body>
    <div class="container">
        <header class="hero-header">
            <div class="brand-logo">
                <div class="logo-icon">🔔</div>
                <h1>叮当装 InstallFlow</h1>
            </div>
            <p class="hero-subtitle">一键批量安装 Mac 应用，让装机像叮当一样简单</p>
        </header>

        <main class="main-content">
            <!-- 安装命令展示区域 -->
            <section class="command-section">
                <div class="card-header">
                    <h2>🚀 安装命令</h2>
                    <p>复制下方命令并在终端中执行</p>
                </div>
                
                <div class="command-container">
                    <div class="command-box">
                        <code id="installCommand">bash <(curl -fsSL https://ding.ahua.space/install)</code>
                    </div>
                    <button id="copyBtn" class="copy-button">
                        <svg class="copy-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
                            <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
                        </svg>
                        <span>复制命令</span>
                    </button>
                </div>
            </section>

            <!-- 功能特色 -->
            <section class="features-section">
                <h2>✨ 功能特色</h2>
                <div class="features-grid">
                    <div class="feature-item">
                        <div class="feature-icon">🎯</div>
                        <h3>交互式选择</h3>
                        <p>使用方向键和空格键轻松选择要安装的应用</p>
                    </div>
                    <div class="feature-item">
                        <div class="feature-icon">📦</div>
                        <h3>多格式支持</h3>
                        <p>支持 .dmg、.iso、.pkg、.zip、.app 等常见格式</p>
                    </div>
                    <div class="feature-item">
                        <div class="feature-icon">⚡</div>
                        <h3>一键执行</h3>
                        <p>通过简单的命令即可开始批量安装</p>
                    </div>
                </div>
            </section>
        </main>

        <footer class="footer">
            <div class="footer-container">
                <!-- GitHub链接 -->
                <div class="github-link-container">
                    <a href="https://github.com/Ahua9527/installflow" target="_blank" rel="noopener noreferrer" class="github-link">
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

    <script src="/assets/js/script.js"></script>
</body>
</html>`;

// 内联的 CSS 内容 - 简洁现代设计
const CSS_CONTENT = `* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
    line-height: 1.6;
    color: #2d3748;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh;
    overflow-x: hidden;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 2rem;
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    text-align: center;
}

/* Header */
.hero-header {
    margin-bottom: 4rem;
    animation: fadeInUp 0.8s ease-out;
}

.brand-logo {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 1rem;
    margin-bottom: 1.5rem;
}

.logo-icon {
    font-size: 3.5rem;
    filter: drop-shadow(0 4px 8px rgba(0,0,0,0.2));
}

.hero-header h1 {
    font-size: 3.5rem;
    font-weight: 700;
    color: white;
    text-shadow: 0 4px 8px rgba(0,0,0,0.2);
    margin: 0;
}

.hero-subtitle {
    font-size: 1.25rem;
    color: rgba(255, 255, 255, 0.9);
    margin-top: 1rem;
    text-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

/* Main Content */
.main-content {
    width: 100%;
    max-width: 800px;
}

/* Command Section */
.command-section {
    margin-bottom: 4rem;
    animation: slideInUp 0.6s ease-out 0.2s both;
}

.card-header {
    margin-bottom: 2rem;
}

.card-header h2 {
    font-size: 2rem;
    font-weight: 600;
    color: white;
    margin-bottom: 0.5rem;
    text-shadow: 0 2px 4px rgba(0,0,0,0.2);
}

.card-header p {
    font-size: 1.125rem;
    color: rgba(255, 255, 255, 0.8);
    text-shadow: 0 1px 2px rgba(0,0,0,0.1);
}

.command-container {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
    align-items: center;
}

.command-box {
    background: rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(20px);
    color: #e2e8f0;
    border-radius: 48px;
    padding: 2rem;
    width: 100%;
    max-width: 600px;
    box-shadow: 0 4px 8px -2px rgba(0, 0, 0, 0.15), 0 2px 4px -1px rgba(0, 0, 0, 0.1);
    border: 1px solid rgba(255, 255, 255, 0.2);
}


.command-box code {
    display: block;
    font-family: 'SF Mono', 'Monaco', 'Inconsolata', 'Fira Code', 'Consolas', monospace;
    font-size: 0.95rem;
    line-height: 1.6;
    word-break: break-all;
    color: #e2e8f0;
}

.copy-button {
    background: linear-gradient(135deg, #10b981 0%, #059669 100%);
    color: white;
    border: none;
    padding: 1rem 2.5rem;
    font-size: 1rem;
    font-weight: 600;
    border-radius: 50px;
    cursor: pointer;
    transition: all 0.3s ease;
    display: flex;
    align-items: center;
    gap: 0.75rem;
    box-shadow: 0 10px 15px -3px rgba(16, 185, 129, 0.3), 0 4px 6px -2px rgba(16, 185, 129, 0.2);
    position: relative;
    overflow: hidden;
}

.copy-button::before {
    content: '';
    position: absolute;
    top: 0;
    left: -100%;
    width: 100%;
    height: 100%;
    background: linear-gradient(90deg, transparent, rgba(255,255,255,0.2), transparent);
    transition: left 0.5s ease;
}

.copy-button:hover::before {
    left: 100%;
}

.copy-button:hover {
    transform: translateY(-3px);
    box-shadow: 0 20px 25px -5px rgba(16, 185, 129, 0.4), 0 10px 10px -5px rgba(16, 185, 129, 0.3);
}

.copy-button:active {
    transform: translateY(-1px);
}

.copy-button:disabled {
    background: rgba(148, 163, 184, 0.8);
    cursor: not-allowed;
    transform: none;
    box-shadow: none;
}

.copy-icon {
    width: 20px;
    height: 20px;
    stroke-width: 2;
}

/* Features Section */
.features-section {
    animation: fadeInUp 0.6s ease-out 0.4s both;
}

.features-section h2 {
    font-size: 2.5rem;
    font-weight: 700;
    color: white;
    margin-bottom: 3rem;
    text-shadow: 0 4px 8px rgba(0,0,0,0.2);
}

.features-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
    gap: 2rem;
    margin-top: 2rem;
}

.feature-item {
    background: rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(20px);
    border-radius: 20px;
    padding: 2rem 1.5rem;
    border: 1px solid rgba(255, 255, 255, 0.2);
    transition: all 0.3s ease;
    animation: fadeInUp 0.6s ease-out both;
}

.feature-item:nth-child(1) { animation-delay: 0.5s; }
.feature-item:nth-child(2) { animation-delay: 0.6s; }
.feature-item:nth-child(3) { animation-delay: 0.7s; }

.feature-item:hover {
    transform: translateY(-8px);
    background: rgba(255, 255, 255, 0.15);
    box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.3), 0 10px 10px -5px rgba(0, 0, 0, 0.2);
}

.feature-icon {
    font-size: 3rem;
    margin-bottom: 1rem;
    display: block;
    filter: drop-shadow(0 2px 4px rgba(0,0,0,0.2));
}

.feature-item h3 {
    font-size: 1.25rem;
    font-weight: 600;
    color: white;
    margin-bottom: 0.75rem;
    text-shadow: 0 2px 4px rgba(0,0,0,0.2);
}

.feature-item p {
    color: rgba(255, 255, 255, 0.85);
    line-height: 1.6;
    font-size: 0.95rem;
}

/* Footer */
.footer {
    margin-top: 4rem;
    animation: fadeInUp 0.6s ease-out 0.8s both;
}

.footer-container {
    padding: 1rem 0;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0.5rem;
}

.github-link-container {
    display: flex;
    justify-content: center;
}

.github-link {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    color: rgba(255, 255, 255, 0.6);
    text-decoration: none;
    transition: color 0.3s ease;
    font-size: 0.9rem;
}

.github-link:hover {
    color: rgba(255, 255, 255, 0.9);
}

.github-icon {
    width: 16px;
    height: 16px;
    transition: transform 0.3s ease;
}

.github-link:hover .github-icon {
    transform: scale(1.1);
}

.footer-copyright {
    font-size: 0.75rem;
    color: rgba(255, 255, 255, 0.4);
    text-align: center;
    margin: 0;
}

/* Notification */
.notification {
    position: fixed;
    bottom: 2rem;
    right: 2rem;
    background: linear-gradient(135deg, #10b981 0%, #059669 100%);
    color: white;
    padding: 1rem 1.5rem;
    border-radius: 50px;
    box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.3), 0 10px 10px -5px rgba(0, 0, 0, 0.2);
    transform: translateX(100%);
    opacity: 0;
    transition: all 0.3s ease;
    z-index: 1000;
    font-weight: 500;
    backdrop-filter: blur(20px);
}

.notification.show {
    transform: translateX(0);
    opacity: 1;
}

/* Animations */
@keyframes fadeInUp {
    from {
        opacity: 0;
        transform: translateY(30px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}

@keyframes slideInUp {
    from {
        opacity: 0;
        transform: translateY(50px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}

/* Responsive Design */
@media (max-width: 768px) {
    .container {
        padding: 1rem;
    }
    
    .hero-header h1 {
        font-size: 2.5rem;
    }
    
    .hero-subtitle {
        font-size: 1rem;
    }
    
    .command-box {
        padding: 1.5rem 1.25rem;
        border-radius: 24px;
        max-width: none;
        margin: 0 0.5rem;
    }
    
    .command-box code {
        font-size: 0.85rem;
        line-height: 1.4;
    }
    
    .features-grid {
        grid-template-columns: 1fr;
        gap: 1.5rem;
    }
    
    .feature-item {
        padding: 1.5rem;
    }
    
    .notification {
        bottom: 1rem;
        right: 1rem;
        left: 1rem;
    }
}

@media (max-width: 480px) {
    .brand-logo {
        flex-direction: column;
        gap: 0.5rem;
    }
    
    .logo-icon {
        font-size: 3rem;
    }
    
    .hero-header h1 {
        font-size: 2rem;
    }
    
    .command-container {
        gap: 1rem;
    }
    
    .command-box {
        padding: 1.25rem 1rem;
        border-radius: 20px;
        margin: 0 0.25rem;
    }
    
    .command-box code {
        font-size: 0.8rem;
        line-height: 1.3;
    }
    
    .copy-button {
        padding: 0.875rem 1.5rem;
        font-size: 0.9rem;
    }
}

/* Dark mode - 保持当前设计，因为已经是暗色主题 */
@media (prefers-color-scheme: dark) {
    /* 当前设计已经适合暗色模式 */
}`;

// 内联的 JavaScript 内容
const JS_CONTENT = `// DOM 元素
const copyBtn = document.getElementById('copyBtn');
const installCommand = document.getElementById('installCommand');

// 复制按钮事件
copyBtn.addEventListener('click', copyInstallCommand);

// 复制安装命令
async function copyInstallCommand() {
    const command = installCommand.textContent;
    
    try {
        await navigator.clipboard.writeText(command);
        showNotification('✅ 命令已复制到剪贴板');
        
        // 临时改变按钮状态
        const originalContent = copyBtn.innerHTML;
        copyBtn.innerHTML = '<span>已复制</span>';
        copyBtn.disabled = true;
        
        setTimeout(() => {
            copyBtn.innerHTML = originalContent;
            copyBtn.disabled = false;
        }, 2000);
        
    } catch (err) {
        // 降级方案
        const textArea = document.createElement('textarea');
        textArea.value = command;
        textArea.style.position = 'absolute';
        textArea.style.left = '-9999px';
        document.body.appendChild(textArea);
        textArea.select();
        
        try {
            document.execCommand('copy');
            showNotification('✅ 命令已复制到剪贴板');
        } catch (err) {
            console.error('复制失败:', err);
            showNotification('❌ 复制失败，请手动复制命令');
        }
        
        document.body.removeChild(textArea);
    }
}

// 显示通知
function showNotification(message) {
    const notification = document.createElement('div');
    notification.className = 'notification';
    notification.textContent = message;
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.classList.add('show');
    }, 100);
    
    setTimeout(() => {
        notification.classList.remove('show');
        setTimeout(() => {
            document.body.removeChild(notification);
        }, 300);
    }, 2000);
}

// 防止整个页面的默认拖放行为
document.addEventListener('dragover', (e) => {
    e.preventDefault();
});

document.addEventListener('drop', (e) => {
    e.preventDefault();
});`;

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const pathname = url.pathname;

    // 处理 /install 路径重定向
    if (pathname === '/install') {
      return Response.redirect('https://gh.ahua.space/https://raw.githubusercontent.com/Ahua9527/installflow/main/Scripts/install.sh', 302);
    }

    // 处理静态资源
    if (pathname === '/assets/css/style.css') {
      return new Response(CSS_CONTENT, {
        headers: {
          'Content-Type': 'text/css; charset=utf-8',
          'Cache-Control': 'public, max-age=86400'
        }
      });
    }

    if (pathname === '/assets/js/script.js') {
      return new Response(JS_CONTENT, {
        headers: {
          'Content-Type': 'application/javascript; charset=utf-8',
          'Cache-Control': 'public, max-age=86400'
        }
      });
    }

    // 默认返回主页面（根路径和其他所有路径）
    return new Response(HTML_CONTENT, {
      headers: {
        'Content-Type': 'text/html; charset=utf-8',
        'Cache-Control': 'public, max-age=3600'
      }
    });
  }
};