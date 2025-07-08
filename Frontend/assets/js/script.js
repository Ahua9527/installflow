// DOM 元素
const dropZone = document.getElementById('dropZone');
const folderInput = document.getElementById('folderInput');
const selectBtn = document.getElementById('selectBtn');
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
    
    // 即使文件数量为0，也尝试从input元素获取信息
    if (folderInput.files && folderInput.files.length > 0) {
        const file = folderInput.files[0];
        const relativePath = file.webkitRelativePath;
        
        if (relativePath) {
            // 提取文件夹名称（第一级目录）
            const folderName = relativePath.split('/')[0];
            console.log('Selected folder:', folderName);
            displayPath(folderName);
            return;
        }
    }
    
    // 如果上面的方法失败，尝试使用一个技巧
    // 某些浏览器会在用户选择文件夹后立即触发change事件
    // 我们可以尝试获取最后选择的路径
    if (e.target.value) {
        // 从完整路径中提取文件夹名称
        const fullPath = e.target.value;
        const pathParts = fullPath.split(/[\\\/]/); // 支持Windows和Unix路径
        const folderName = pathParts[pathParts.length - 1] || pathParts[pathParts.length - 2];
        
        if (folderName) {
            console.log('Extracted folder name from path:', folderName);
            displayPath(folderName);
            return;
        }
    }
    
    // 如果所有方法都失败了
    console.log('Unable to determine folder name');
    
    // 提示用户直接在下方输入完整路径
    setTimeout(() => {
        commandSection.style.display = 'block';
        fullPathInput = document.getElementById('fullPath');
        fullPathInput.placeholder = '请直接输入完整文件夹路径';
        fullPathInput.focus();
        
        const hint = document.querySelector('.path-hint');
        if (hint) {
            hint.innerHTML = '由于浏览器限制，请直接输入文件夹的完整路径';
        }
        
        // 监听路径输入变化
        if (!fullPathInput.hasAttribute('data-listener-added')) {
            fullPathInput.addEventListener('input', handlePathInput);
            fullPathInput.setAttribute('data-listener-added', 'true');
        }
        
        updateCommand();
    }, 100);
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