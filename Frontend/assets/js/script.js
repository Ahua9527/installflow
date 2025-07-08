// DOM 元素
const dropZone = document.getElementById('dropZone');
const folderInput = document.getElementById('folderInput');
const selectBtn = document.getElementById('selectBtn');
const manualBtn = document.getElementById('manualBtn');
const commandSection = document.getElementById('commandSection');
const commandDisplay = document.getElementById('commandDisplay');
const copyBtn = document.getElementById('copyBtn');
const copyNotification = document.getElementById('copyNotification');

// 状态
let currentPath = '';
let fullPathInput = null;

// 事件监听器
selectBtn.addEventListener('click', () => {
    folderInput.click();
});

manualBtn.addEventListener('click', () => {
    const path = prompt('请输入文件夹路径：\n\n例如：\n• ~/Downloads/installers\n• /Users/fiber/Downloads/installers');
    if (path && path.trim()) {
        displayPath(path.trim());
    }
});

folderInput.addEventListener('change', handleFileSelect);

// 拖拽事件
dropZone.addEventListener('dragover', handleDragOver);
dropZone.addEventListener('dragleave', handleDragLeave);
dropZone.addEventListener('drop', handleDrop);

// 点击拖拽区域也可以选择文件
dropZone.addEventListener('click', () => {
    folderInput.click();
});

// 复制按钮
copyBtn.addEventListener('click', copyCommand);

// 处理文件选择
function handleFileSelect(e) {
    const files = e.target.files;
    
    if (files.length > 0) {
        // 获取第一个文件的路径
        const file = files[0];
        // webkitRelativePath 包含相对路径信息
        const relativePath = file.webkitRelativePath;
        
        // 提取文件夹名称（第一级目录）
        const folderName = relativePath.split('/')[0];
        
        // 尝试保存更多路径信息
        const pathInfo = {
            folderName: folderName,
            relativePath: relativePath,
            fileCount: files.length
        };
        
        console.log('Selected folder info:', pathInfo);
        displayPath(folderName);
    } else {
        // 用户可能选择了一个空文件夹或取消了选择
        // 在这种情况下，我们无法获取文件夹名称
        console.log('No files selected or empty folder');
        
        // 显示提示信息并建议使用手动输入
        alert('未能获取文件夹路径。\n\n可能原因：\n• 选择的文件夹为空\n• 浏览器安全限制\n\n建议使用"手动输入路径"按钮。');
    }
}

// 处理拖拽悬停
function handleDragOver(e) {
    e.preventDefault();
    e.stopPropagation();
    dropZone.classList.add('drag-over');
}

// 处理拖拽离开
function handleDragLeave(e) {
    e.preventDefault();
    e.stopPropagation();
    dropZone.classList.remove('drag-over');
}

// 处理拖放
function handleDrop(e) {
    e.preventDefault();
    e.stopPropagation();
    dropZone.classList.remove('drag-over');

    const items = e.dataTransfer.items;
    
    if (items) {
        for (let i = 0; i < items.length; i++) {
            const item = items[i];
            if (item.kind === 'file') {
                const entry = item.webkitGetAsEntry();
                if (entry && entry.isDirectory) {
                    // 获取文件夹名称
                    displayPath(entry.name);
                    break;
                } else if (entry && entry.isFile) {
                    // 如果是文件，获取其父文件夹
                    const path = entry.fullPath.substring(1); // 移除开头的斜杠
                    const folderPath = path.substring(0, path.lastIndexOf('/'));
                    if (folderPath) {
                        displayPath(folderPath);
                        break;
                    }
                }
            }
        }
    }
}

// 显示路径和生成命令
function displayPath(path) {
    if (!path) return;
    
    currentPath = path;
    generateCommand(path);
}

// 生成命令
function generateCommand(path) {
    // 获取输入框元素
    fullPathInput = document.getElementById('fullPath');
    
    // 尝试猜测完整路径
    let guessedPath = path;
    
    // 尝试从常见的路径模式中提取信息
    if (path.includes('/')) {
        // 检查是否包含Downloads路径
        if (path.includes('Downloads/')) {
            const downloadsIndex = path.lastIndexOf('Downloads/');
            const folderName = path.substring(downloadsIndex);
            guessedPath = `~/${folderName}`;
        } else {
            guessedPath = path;
        }
    } else {
        // 只有文件夹名称，默认假设在Downloads目录
        guessedPath = `~/Downloads/${path}`;
    }
    
    fullPathInput.value = guessedPath;
    fullPathInput.placeholder = '例如: ~/Downloads/installers 或 /Users/fiber/Downloads/installers';
    
    // 添加提示信息
    const hint = document.querySelector('.path-hint');
    if (hint) {
        hint.innerHTML = '支持 <code>~</code> 作为用户目录的简写';
    }
    
    // 监听路径输入变化（避免重复添加监听器）
    if (!fullPathInput.hasAttribute('data-listener-added')) {
        fullPathInput.addEventListener('input', handlePathInput);
        fullPathInput.setAttribute('data-listener-added', 'true');
    }
    
    // 聚焦到输入框，方便用户修改
    fullPathInput.focus();
    
    // 初始生成命令
    updateCommand();
    
    commandSection.style.display = 'block';
}

// 处理路径输入
function handlePathInput() {
    // 保存用户名到localStorage
    const currentPath = fullPathInput.value;
    const userMatch = currentPath.match(/\/Users\/([^\/]+)\//);
    if (userMatch && userMatch[1] && userMatch[1] !== '[username]') {
        localStorage.setItem('installflow_username', userMatch[1]);
    }
    
    updateCommand();
}

// 更新命令显示
function updateCommand() {
    const fullPath = fullPathInput.value || currentPath;
    const scriptUrl = 'https://gh.ahua.space/https://raw.githubusercontent.com/Ahua9527/installflow/refs/heads/main/Scripts/install.sh';
    
    // 使用 bash <() 语法来保持交互式环境
    const command = `bash <(curl -fsSL ${scriptUrl}) "${fullPath}"`;
    
    // 使用 Markdown 格式
    const markdownContent = `\`\`\`bash
${command}
\`\`\``;
    
    // 渲染 Markdown
    commandDisplay.innerHTML = marked.parse(markdownContent);
}

// 复制命令到剪贴板
async function copyCommand() {
    const fullPath = fullPathInput.value || currentPath;
    const scriptUrl = 'https://gh.ahua.space/https://raw.githubusercontent.com/Ahua9527/installflow/refs/heads/main/Scripts/install.sh';
    
    // 使用 bash <() 语法来保持交互式环境
    const command = `bash <(curl -fsSL ${scriptUrl}) "${fullPath}"`;
    
    try {
        await navigator.clipboard.writeText(command);
        showCopyNotification();
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
            showCopyNotification();
        } catch (err) {
            console.error('复制失败:', err);
            alert('复制失败，请手动复制命令');
        }
        
        document.body.removeChild(textArea);
    }
}

// 显示复制成功通知
function showCopyNotification() {
    copyNotification.classList.add('show');
    setTimeout(() => {
        copyNotification.classList.remove('show');
    }, 2000);
}

// 防止整个页面的默认拖放行为
document.addEventListener('dragover', (e) => {
    e.preventDefault();
});

document.addEventListener('drop', (e) => {
    e.preventDefault();
});