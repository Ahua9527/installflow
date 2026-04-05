import {
  INSTALL_SCRIPT_CONTENT,
  INSTALL_SCRIPT_SHA256
} from './install-script.generated.js';

const HTML_CONTENT = `<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>叮当装 InstallFlow | macOS 本地安装包批量安装工具</title>
    <meta name="description" content="叮当装 InstallFlow 是面向 macOS 的本地安装包批量安装工具，支持 DMG、PKG、ZIP、APP、ISO，一条命令启动交互式安装。">
    <meta name="theme-color" content="#07080a">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="/assets/css/style.css">
</head>
<body>
    <div class="page-shell">
        <nav class="nav">
            <div class="nav-inner">
                <a href="/" class="nav-brand">叮当装</a>
                <button
                    class="nav-toggle"
                    id="navToggle"
                    type="button"
                    aria-expanded="false"
                    aria-controls="navMenu"
                    aria-label="打开导航菜单"
                >
                    <span></span>
                    <span></span>
                </button>
                <div class="nav-menu" id="navMenu">
                    <ul class="nav-links">
                        <li><a href="#install">安装</a></li>
                        <li><a href="#features">功能</a></li>
                        <li><a href="#guide">指南</a></li>
                        <li><a href="https://github.com/Ahua9527/installflow" target="_blank" rel="noreferrer">GitHub</a></li>
                    </ul>
                    <a href="#install" class="nav-cta">开始安装</a>
                </div>
            </div>
        </nav>

        <main>
            <section class="hero-section">
                <div class="section-content hero-grid">
                    <div class="hero-copy">
                        <p class="hero-eyebrow">叮当装 InstallFlow</p>
                        <h1 class="hero-headline">一条命令，批量装好你的 Mac 应用。</h1>
                        <p class="hero-subheadline">为本地安装包准备的 macOS 批量安装工具。支持 DMG、PKG、ZIP、APP、ISO，并提供终端交互式选择、版本判断与嵌套结构处理。</p>
                        <div class="hero-ctas">
                            <a href="#install" class="cta-primary">复制安装命令</a>
                            <a href="#features" class="cta-secondary">查看能力</a>
                        </div>
                        <ul class="hero-meta" aria-label="核心能力">
                            <li>本地包批量安装</li>
                            <li>交互式终端选择</li>
                            <li>Apple Silicon 兼容检测</li>
                        </ul>
                    </div>

                    <div class="hero-stage" aria-label="InstallFlow 终端界面">
                        <div class="stage-orbit"></div>
                        <div class="terminal-panel">
                            <div class="panel-topline">
                                <span class="panel-label">InstallFlow Runtime</span>
                                <span class="panel-status"><span class="status-dot"></span> Ready</span>
                            </div>
                            <div class="terminal-window">
                                <div class="terminal-bar">
                                    <span class="terminal-dot terminal-dot-red"></span>
                                    <span class="terminal-dot terminal-dot-yellow"></span>
                                    <span class="terminal-dot terminal-dot-green"></span>
                                </div>
                                <div class="terminal-body">
                                    <p><span class="prompt">$</span> bash &lt;(curl -fsSL https://ding.ahua.space/install)</p>
                                    <p class="terminal-muted">扫描本地安装包目录…</p>
                                    <ul class="terminal-list">
                                        <li><span class="terminal-check">✓</span> Arc.dmg</li>
                                        <li><span class="terminal-check">✓</span> Xcode.pkg</li>
                                        <li><span class="terminal-check">✓</span> Cursor.zip</li>
                                        <li><span class="terminal-check">✓</span> Raycast.app</li>
                                    </ul>
                                    <p class="terminal-muted">使用方向键选择，按回车开始安装。</p>
                                </div>
                            </div>
                            <div class="panel-footer">
                                <div class="format-badges" aria-label="支持格式">
                                    <span class="badge">DMG</span>
                                    <span class="badge">PKG</span>
                                    <span class="badge">ZIP</span>
                                    <span class="badge">APP</span>
                                    <span class="badge">ISO</span>
                                </div>
                                <div class="shortcut-row" aria-label="快捷键">
                                    <span class="shortcut-key">↑</span>
                                    <span class="shortcut-key">↓</span>
                                    <span class="shortcut-key">Space</span>
                                    <span class="shortcut-key">Enter</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            <section class="install-section" id="install">
                <div class="section-content">
                    <div class="section-header">
                        <p class="section-kicker">Quick Start</p>
                        <h2 class="section-title">开始安装</h2>
                        <p class="section-description">复制下方命令，在终端中执行即可开始批量安装应用。</p>
                    </div>
                    <div class="install-card">
                        <div class="install-card-copy">
                            <p class="install-label">安装命令</p>
                            <code id="installCommand">bash <(curl -fsSL https://ding.ahua.space/install)</code>
                            <p class="section-footnote">支持 macOS 10.15 及以上版本，适合已经准备好本地安装包的用户。</p>
                        </div>
                        <button id="copyBtn" class="btn-copy" type="button">
                            <svg class="copy-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
                                <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
                                <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
                            </svg>
                            复制命令
                        </button>
                    </div>
                </div>
            </section>

            <section class="features-section" id="features">
                <div class="section-content">
                    <div class="section-header">
                        <p class="section-kicker">Capabilities</p>
                        <h2 class="section-title">功能特色</h2>
                        <p class="section-description">围绕本地安装包的真实使用场景设计，优先解决批量、兼容性和重复操作问题。</p>
                    </div>
                    <div class="feature-grid">
                        <article class="feature-card">
                            <span class="card-tag">Selection</span>
                            <h3>交互式选择</h3>
                            <p>使用方向键和空格键，在终端中直观选择要安装的应用。</p>
                        </article>
                        <article class="feature-card">
                            <span class="card-tag">Formats</span>
                            <h3>多格式支持</h3>
                            <p>支持 .dmg、.iso、.pkg、.zip、.app 等常见 macOS 应用格式。</p>
                        </article>
                        <article class="feature-card">
                            <span class="card-tag">Automation</span>
                            <h3>智能处理</h3>
                            <p>自动处理嵌套 DMG 结构、版本检测和 Apple Silicon 兼容性检测。</p>
                        </article>
                        <article class="feature-card">
                            <span class="card-tag">Security</span>
                            <h3>安全可靠</h3>
                            <p>路径验证、sudo 权限管理和 quarantine 属性清理都已内建。</p>
                        </article>
                    </div>
                </div>
            </section>

            <section class="guide-section" id="guide">
                <div class="section-content">
                    <div class="section-header">
                        <p class="section-kicker">Workflow</p>
                        <h2 class="section-title">使用指南</h2>
                        <p class="section-description">从复制命令到开始安装，保持最短操作路径。</p>
                    </div>
                    <div class="guide-steps">
                        <article class="guide-step">
                            <span class="step-number">01</span>
                            <div class="step-content">
                                <h3>复制安装命令</h3>
                                <p>点击上方“复制命令”按钮，将安装命令复制到剪贴板。</p>
                            </div>
                        </article>
                        <article class="guide-step">
                            <span class="step-number">02</span>
                            <div class="step-content">
                                <h3>打开终端</h3>
                                <p>在 Mac 上打开“终端”应用，并粘贴刚刚复制的命令。</p>
                            </div>
                        </article>
                        <article class="guide-step">
                            <span class="step-number">03</span>
                            <div class="step-content">
                                <h3>选择并执行</h3>
                                <p>根据提示选择要安装的应用，然后按回车开始批量安装。</p>
                            </div>
                        </article>
                    </div>
                </div>
            </section>
        </main>

        <footer class="footer">
            <div class="section-content footer-inner">
                <a href="https://github.com/Ahua9527/installflow" target="_blank" rel="noreferrer" class="footer-link">GitHub</a>
                <p class="footer-copyright">InstallFlow © 2025 · Designed & Developed by 哆啦Ahua</p>
            </div>
        </footer>
    </div>

    <script src="/assets/js/script.js"></script>
</body>
</html>`;

const CSS_CONTENT = `
:root {
    --bg: #07080a;
    --bg-100: #101111;
    --bg-card: #1b1c1e;
    --bg-soft: #0c0e10;
    --fg: #f9f9f9;
    --white: #ffffff;
    --light-gray: #cecece;
    --med-gray: #9c9c9d;
    --dim-gray: #6a6b6c;
    --border: #252829;
    --border-subtle: rgba(255, 255, 255, 0.06);
    --border-med: rgba(255, 255, 255, 0.1);
    --button-bg: hsla(0, 0%, 100%, 0.815);
    --button-fg: #18191a;
    --red: #ff6363;
    --blue: #55b3ff;
    --green: #5fc992;
    --yellow: #ffbc33;
    --blue-t: rgba(85, 179, 255, 0.15);
    --green-t: rgba(95, 201, 146, 0.12);
    --shadow-ring: rgb(27, 28, 30) 0px 0px 0px 1px, rgb(7, 8, 10) 0px 0px 0px 1px inset;
    --shadow-button: rgba(255, 255, 255, 0.05) 0px 1px 0px 0px inset, rgba(255, 255, 255, 0.25) 0px 0px 0px 1px, rgba(0, 0, 0, 0.2) 0px -1px 0px 0px inset;
    --shadow-float: rgba(0, 0, 0, 0.5) 0px 0px 0px 2px, rgba(255, 255, 255, 0.19) 0px 0px 14px 0px, rgba(0, 0, 0, 0.2) 0px -1px 0.4px 0px inset, rgb(255, 255, 255) 0px 1px 0.4px 0px inset;
    --shadow-key: rgba(0, 0, 0, 0.4) 0px 1.5px 0.5px 2.5px, rgba(255, 255, 255, 0.08) 0px 1px 0px 0px inset, rgba(255, 255, 255, 0.14) 0px 0px 0px 1px, rgba(0, 0, 0, 0.25) 0px -1px 0px 0px inset;
    --font-sans: "Inter", -apple-system, BlinkMacSystemFont, "PingFang SC", "Hiragino Sans GB", sans-serif;
    --font-mono: "GeistMono", ui-monospace, SFMono-Regular, "Roboto Mono", Menlo, Monaco, monospace;
}

* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

html {
    scroll-behavior: smooth;
}

body {
    min-height: 100vh;
    background:
        radial-gradient(circle at top right, rgba(255, 99, 99, 0.08), transparent 28%),
        radial-gradient(circle at top left, rgba(85, 179, 255, 0.07), transparent 26%),
        var(--bg);
    color: var(--fg);
    font-family: var(--font-sans);
    font-size: 16px;
    font-weight: 500;
    line-height: 1.6;
    letter-spacing: 0.2px;
    -webkit-font-smoothing: antialiased;
    font-feature-settings: "calt", "kern", "liga", "ss03";
}

a {
    color: inherit;
    text-decoration: none;
}

button,
a {
    -webkit-tap-highlight-color: transparent;
}

button,
input,
textarea {
    font: inherit;
}

button {
    border: 0;
    background: transparent;
    color: inherit;
}

img,
svg {
    display: block;
}

.page-shell {
    overflow: clip;
}

.section-content,
.nav-inner {
    width: min(100%, 1200px);
    margin: 0 auto;
    padding: 0 32px;
}

.nav {
    position: sticky;
    top: 0;
    z-index: 100;
    border-bottom: 1px solid var(--border-subtle);
    background: rgba(7, 8, 10, 0.88);
    backdrop-filter: blur(14px);
    -webkit-backdrop-filter: blur(14px);
}

.nav-inner {
    min-height: 72px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 20px;
}

.nav-brand {
    position: relative;
    z-index: 2;
    color: var(--white);
    font-size: 15px;
    font-weight: 600;
    letter-spacing: 0.2px;
}

.nav-menu {
    display: flex;
    align-items: center;
    gap: 24px;
}

.nav-links {
    display: flex;
    align-items: center;
    gap: 24px;
    list-style: none;
}

.nav-links a {
    color: var(--med-gray);
    font-size: 16px;
    font-weight: 500;
    line-height: 1.4;
    letter-spacing: 0.3px;
    transition: color 0.2s ease;
}

.nav-links a:hover,
.nav-links a:focus-visible {
    color: var(--white);
}

.nav-cta,
.cta-primary,
.btn-copy {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 10px;
    border-radius: 86px;
    padding: 12px 24px;
    background: var(--button-bg);
    color: var(--button-fg);
    font-size: 16px;
    font-weight: 600;
    line-height: 1.15;
    letter-spacing: 0.3px;
    transition: background 0.2s ease, opacity 0.2s ease, transform 0.2s ease;
}

.nav-cta:hover,
.cta-primary:hover,
.btn-copy:hover {
    background: var(--white);
}

.cta-secondary {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    border-radius: 86px;
    padding: 12px 24px;
    border: 1px solid var(--border-med);
    box-shadow: var(--shadow-button);
    color: var(--white);
    font-size: 16px;
    font-weight: 500;
    line-height: 1.15;
    letter-spacing: 0.3px;
    transition: opacity 0.2s ease;
}

.cta-secondary:hover {
    opacity: 0.6;
}

.nav-toggle {
    display: none;
    position: relative;
    z-index: 2;
    width: 44px;
    height: 44px;
    border-radius: 12px;
    border: 1px solid var(--border-subtle);
    box-shadow: var(--shadow-ring);
    align-items: center;
    justify-content: center;
    flex-direction: column;
    gap: 5px;
}

.nav-toggle span {
    width: 18px;
    height: 1.5px;
    border-radius: 999px;
    background: var(--white);
    transition: transform 0.2s ease, opacity 0.2s ease;
}

.nav-toggle[aria-expanded="true"] span:first-child {
    transform: translateY(3.25px) rotate(45deg);
}

.nav-toggle[aria-expanded="true"] span:last-child {
    transform: translateY(-3.25px) rotate(-45deg);
}

.hero-section,
.install-section,
.features-section,
.guide-section {
    position: relative;
}

.hero-section {
    padding: 96px 0 80px;
}

.hero-grid {
    display: grid;
    grid-template-columns: minmax(0, 1.03fr) minmax(320px, 0.97fr);
    gap: 48px;
    align-items: center;
}

.hero-copy {
    position: relative;
    z-index: 1;
}

.hero-copy::before {
    content: "";
    position: absolute;
    top: -56px;
    left: -18px;
    width: 280px;
    height: 280px;
    background: repeating-linear-gradient(-45deg, var(--red) 0px, var(--red) 16px, transparent 16px, transparent 32px);
    opacity: 0.14;
    filter: blur(1px);
    border-radius: 24px;
    transform: rotate(8deg);
    pointer-events: none;
}

.hero-eyebrow,
.section-kicker,
.install-label,
.panel-label {
    position: relative;
    z-index: 1;
    color: var(--med-gray);
    font-size: 12px;
    font-weight: 600;
    line-height: 1.33;
    letter-spacing: 0.4px;
    text-transform: uppercase;
}

.hero-headline {
    position: relative;
    z-index: 1;
    margin-top: 18px;
    max-width: 660px;
    color: var(--white);
    font-size: 64px;
    font-weight: 600;
    line-height: 1.1;
    letter-spacing: 0;
    font-feature-settings: "liga" 0, "ss02", "ss08";
}

.hero-subheadline {
    position: relative;
    z-index: 1;
    max-width: 620px;
    margin-top: 20px;
    color: var(--med-gray);
    font-size: 18px;
    font-weight: 400;
    line-height: 1.5;
    letter-spacing: 0.2px;
}

.hero-ctas {
    position: relative;
    z-index: 1;
    margin-top: 32px;
    display: flex;
    align-items: center;
    gap: 12px;
    flex-wrap: wrap;
}

.hero-meta {
    position: relative;
    z-index: 1;
    margin-top: 28px;
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    list-style: none;
}

.hero-meta li,
.badge,
.card-tag {
    display: inline-flex;
    align-items: center;
    border-radius: 6px;
    background: var(--bg-card);
    color: var(--light-gray);
    min-height: 28px;
    padding: 0 10px;
    border: 1px solid var(--border-subtle);
    font-size: 12px;
    font-weight: 600;
    line-height: 1.33;
    letter-spacing: 0.1px;
}

.hero-stage {
    position: relative;
    min-height: 560px;
}

.stage-orbit {
    position: absolute;
    inset: 52px 28px 36px 64px;
    border-radius: 24px;
    background:
        radial-gradient(circle at center, rgba(215, 201, 175, 0.05), transparent 60%),
        radial-gradient(circle at 24% 18%, rgba(85, 179, 255, 0.09), transparent 32%);
    filter: blur(10px);
}

.terminal-panel {
    position: absolute;
    inset: 0 0 auto 0;
    padding: 22px;
    border-radius: 20px;
    background: linear-gradient(180deg, rgba(16, 17, 17, 0.98), rgba(12, 14, 16, 0.98));
    box-shadow: var(--shadow-float);
}

.panel-topline,
.panel-footer {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
}

.panel-status {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    color: var(--light-gray);
    font-size: 13px;
    font-weight: 500;
    line-height: 1.4;
    letter-spacing: 0.2px;
}

.status-dot {
    width: 8px;
    height: 8px;
    border-radius: 999px;
    background: var(--green);
    box-shadow: 0 0 0 4px var(--green-t);
}

.terminal-window,
.install-card,
.feature-card,
.guide-step {
    background: var(--bg-100);
    border: 1px solid var(--border-subtle);
    box-shadow: var(--shadow-ring);
}

.terminal-window {
    margin-top: 18px;
    border-radius: 16px;
    overflow: hidden;
}

.terminal-bar {
    display: flex;
    align-items: center;
    gap: 8px;
    min-height: 44px;
    padding: 0 18px;
    border-bottom: 1px solid var(--border-subtle);
    background: rgba(255, 255, 255, 0.02);
}

.terminal-dot {
    width: 10px;
    height: 10px;
    border-radius: 999px;
}

.terminal-dot-red {
    background: #ff5f57;
}

.terminal-dot-yellow {
    background: #ffbd2e;
}

.terminal-dot-green {
    background: #28c840;
}

.terminal-body {
    padding: 28px 28px 30px;
    color: var(--fg);
    font-family: var(--font-mono);
    font-size: 14px;
    font-weight: 500;
    line-height: 1.6;
    letter-spacing: 0.3px;
}

.terminal-body p + p,
.terminal-list {
    margin-top: 10px;
}

.prompt,
.footer-link {
    color: var(--blue);
}

.terminal-muted,
.section-description,
.feature-card p,
.step-content p,
.section-footnote,
.footer-copyright {
    color: var(--med-gray);
}

.terminal-list {
    list-style: none;
}

.terminal-list li + li {
    margin-top: 8px;
}

.terminal-check {
    margin-right: 8px;
    color: var(--green);
}

.panel-footer {
    margin-top: 18px;
    align-items: flex-end;
}

.format-badges,
.shortcut-row {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
}

.shortcut-key {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    min-width: 36px;
    min-height: 30px;
    padding: 0 10px;
    border-radius: 5px;
    background: linear-gradient(180deg, #121212, #0d0d0d);
    box-shadow: var(--shadow-key);
    color: var(--fg);
    font-size: 12px;
    font-weight: 600;
    line-height: 1.33;
    letter-spacing: 0;
}

.install-section,
.features-section,
.guide-section {
    padding: 40px 0 88px;
}

.features-section,
.guide-section,
.footer {
    border-top: 1px solid var(--border-subtle);
}

.section-header {
    max-width: 720px;
}

.section-title {
    margin-top: 14px;
    color: var(--white);
    font-size: 44px;
    font-weight: 600;
    line-height: 1.1;
    letter-spacing: 0;
    font-feature-settings: "liga" 0, "ss02", "ss08";
}

.section-description {
    margin-top: 12px;
    font-size: 16px;
    font-weight: 500;
    line-height: 1.6;
    letter-spacing: 0.2px;
}

.install-card {
    margin-top: 40px;
    padding: 28px;
    border-radius: 20px;
    display: grid;
    grid-template-columns: minmax(0, 1fr) auto;
    gap: 24px;
    align-items: center;
}

.install-card-copy code {
    display: block;
    margin-top: 12px;
    word-break: break-all;
    color: var(--fg);
    font-family: var(--font-mono);
    font-size: 18px;
    font-weight: 500;
    line-height: 1.6;
    letter-spacing: 0.3px;
}

.section-footnote {
    margin-top: 14px;
    font-size: 14px;
    font-weight: 500;
    line-height: 1.5;
}

.copy-icon {
    width: 18px;
    height: 18px;
}

.feature-grid {
    margin-top: 40px;
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 16px;
}

.feature-card,
.guide-step {
    border-radius: 16px;
    padding: 28px;
    transition: border-color 0.2s ease, transform 0.2s ease;
}

.feature-card:hover,
.guide-step:hover {
    border-color: rgba(255, 255, 255, 0.12);
    transform: translateY(-2px);
}

.feature-card h3,
.step-content h3 {
    margin-top: 16px;
    color: var(--white);
    font-size: 22px;
    font-weight: 500;
    line-height: 1.15;
    letter-spacing: 0;
}

.feature-card p,
.step-content p {
    margin-top: 10px;
    font-size: 16px;
    font-weight: 500;
    line-height: 1.6;
    letter-spacing: 0.2px;
}

.guide-steps {
    margin-top: 40px;
    display: grid;
    gap: 16px;
}

.guide-step {
    display: grid;
    grid-template-columns: auto minmax(0, 1fr);
    gap: 20px;
    align-items: start;
}

.step-number {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    min-width: 48px;
    min-height: 34px;
    padding: 0 12px;
    border-radius: 6px;
    background: linear-gradient(180deg, #121212, #0d0d0d);
    box-shadow: var(--shadow-key);
    color: var(--white);
    font-size: 14px;
    font-weight: 600;
    line-height: 1.14;
    letter-spacing: 0;
}

.footer {
    padding: 40px 0 48px;
}

.footer-inner {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
}

.footer-link {
    font-size: 14px;
    font-weight: 500;
    line-height: 1.5;
    letter-spacing: 0.2px;
}

.footer-link:hover {
    opacity: 0.8;
}

.footer-copyright {
    font-size: 13px;
    font-weight: 500;
    line-height: 1.5;
    letter-spacing: 0.2px;
    text-align: right;
}

.notification {
    position: fixed;
    right: 24px;
    bottom: 24px;
    z-index: 1000;
    display: inline-flex;
    align-items: center;
    gap: 10px;
    min-height: 52px;
    padding: 0 18px;
    border-radius: 14px;
    background: rgba(16, 17, 17, 0.96);
    border: 1px solid var(--border-subtle);
    box-shadow: var(--shadow-float);
    color: var(--fg);
    font-size: 14px;
    font-weight: 500;
    line-height: 1.43;
    letter-spacing: 0.2px;
    transform: translateY(18px);
    opacity: 0;
    transition: transform 0.25s ease, opacity 0.25s ease;
}

.notification::before {
    content: "";
    width: 8px;
    height: 8px;
    border-radius: 999px;
    background: var(--green);
    box-shadow: 0 0 0 4px var(--green-t);
}

.notification.show {
    transform: translateY(0);
    opacity: 1;
}

:focus-visible {
    outline: none;
    box-shadow: 0 0 0 3px var(--blue-t);
}

@media (prefers-reduced-motion: reduce) {
    html {
        scroll-behavior: auto;
    }

    *,
    *::before,
    *::after {
        transition: none !important;
        animation: none !important;
    }
}

@media (max-width: 1024px) {
    .hero-grid {
        grid-template-columns: 1fr;
    }

    .hero-stage {
        min-height: 520px;
    }

    .install-card {
        grid-template-columns: 1fr;
    }

    .btn-copy {
        width: fit-content;
    }
}

@media (max-width: 768px) {
    .section-content,
    .nav-inner {
        padding: 0 20px;
    }

    .nav-inner {
        min-height: 68px;
    }

    .nav-toggle {
        display: inline-flex;
    }

    .nav-menu {
        position: absolute;
        top: calc(100% + 12px);
        left: 20px;
        right: 20px;
        display: none;
        flex-direction: column;
        align-items: stretch;
        padding: 16px;
        border-radius: 16px;
        background: rgba(16, 17, 17, 0.98);
        border: 1px solid var(--border-subtle);
        box-shadow: var(--shadow-float);
    }

    .nav-menu.is-open {
        display: flex;
    }

    .nav-links {
        flex-direction: column;
        align-items: stretch;
        gap: 8px;
    }

    .nav-links a,
    .nav-cta {
        min-height: 44px;
        padding: 12px 14px;
    }

    .nav-cta {
        margin-top: 8px;
        width: 100%;
    }

    .hero-section {
        padding: 72px 0 56px;
    }

    .hero-headline {
        font-size: 44px;
    }

    .hero-stage {
        min-height: 0;
    }

    .terminal-panel {
        position: relative;
    }

    .panel-topline,
    .panel-footer,
    .footer-inner {
        flex-direction: column;
        align-items: flex-start;
    }

    .feature-grid {
        grid-template-columns: 1fr;
    }

    .footer-copyright {
        text-align: left;
    }
}

@media (max-width: 600px) {
    .hero-headline {
        font-size: 36px;
    }

    .hero-subheadline {
        font-size: 16px;
    }

    .hero-ctas,
    .btn-copy {
        width: 100%;
    }

    .cta-primary,
    .cta-secondary,
    .btn-copy {
        width: 100%;
    }

    .install-section,
    .features-section,
    .guide-section {
        padding-bottom: 72px;
    }

    .install-card,
    .feature-card,
    .guide-step,
    .terminal-panel {
        padding: 20px;
    }

    .guide-step {
        grid-template-columns: 1fr;
    }

    .notification {
        left: 16px;
        right: 16px;
        bottom: 16px;
    }
}
`;

const JS_CONTENT = `
const copyBtn = document.getElementById('copyBtn');
const installCommand = document.getElementById('installCommand');
const navToggle = document.getElementById('navToggle');
const navMenu = document.getElementById('navMenu');
const navLinks = document.querySelectorAll('.nav-menu a');

if (copyBtn && installCommand) {
    copyBtn.addEventListener('click', copyInstallCommand);
}

if (navToggle && navMenu) {
    navToggle.addEventListener('click', toggleMenu);
}

navLinks.forEach((link) => {
    link.addEventListener('click', () => {
        if (window.matchMedia('(max-width: 768px)').matches) {
            closeMenu();
        }
    });
});

document.addEventListener('click', (event) => {
    if (!navToggle || !navMenu) {
        return;
    }

    if (!navMenu.contains(event.target) && !navToggle.contains(event.target)) {
        closeMenu();
    }
});

window.addEventListener('resize', () => {
    if (window.innerWidth > 768) {
        closeMenu();
    }
});

async function copyInstallCommand() {
    if (!copyBtn || !installCommand) {
        return;
    }

    const command = installCommand.textContent;

    try {
        await navigator.clipboard.writeText(command);
        handleCopySuccess();
    } catch (err) {
        const textArea = document.createElement('textarea');
        textArea.value = command;
        textArea.style.position = 'absolute';
        textArea.style.left = '-9999px';
        document.body.appendChild(textArea);
        textArea.select();

        try {
            document.execCommand('copy');
            handleCopySuccess();
        } catch (fallbackErr) {
            console.error('复制失败:', fallbackErr);
            showNotification('复制失败，请手动复制');
        }

        document.body.removeChild(textArea);
    }
}

function handleCopySuccess() {
    if (!copyBtn) {
        return;
    }

    showNotification('命令已复制到剪贴板');

    const originalContent = copyBtn.innerHTML;
    copyBtn.innerHTML = '<span>已复制</span>';
    copyBtn.disabled = true;

    setTimeout(() => {
        copyBtn.innerHTML = originalContent;
        copyBtn.disabled = false;
    }, 2000);
}

function toggleMenu() {
    if (!navToggle || !navMenu) {
        return;
    }

    const isOpen = navToggle.getAttribute('aria-expanded') === 'true';
    navToggle.setAttribute('aria-expanded', String(!isOpen));
    navMenu.classList.toggle('is-open', !isOpen);
}

function closeMenu() {
    if (!navToggle || !navMenu) {
        return;
    }

    navToggle.setAttribute('aria-expanded', 'false');
    navMenu.classList.remove('is-open');
}

function showNotification(message) {
    const notification = document.createElement('div');
    notification.className = 'notification';
    notification.textContent = message;
    document.body.appendChild(notification);

    requestAnimationFrame(() => {
        notification.classList.add('show');
    });

    setTimeout(() => {
        notification.classList.remove('show');
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 250);
    }, 2000);
}

document.addEventListener('dragover', (event) => {
    event.preventDefault();
});

document.addEventListener('drop', (event) => {
    event.preventDefault();
});
`;

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const pathname = url.pathname;

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

    return new Response(HTML_CONTENT, {
      headers: {
        'Content-Type': 'text/html; charset=utf-8',
        'Cache-Control': 'public, max-age=3600'
      }
    });
  }
};
