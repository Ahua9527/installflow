// DOM 元素
const dropZone = document.getElementById('dropZone');
const commandSection = document.getElementById('commandSection');
const commandDisplay = document.getElementById('commandDisplay');
const copyBtn = document.getElementById('copyBtn');
const copyNotification = document.getElementById('copyNotification');

// 状态
let currentPath = '';
let fullPathInput = null;

// 拖拽事件
dropZone.addEventListener('dragover', handleDragOver);
dropZone.addEventListener('dragleave', handleDragLeave);
dropZone.addEventListener('drop', handleDrop);


// 复制按钮
copyBtn.addEventListener('click', copyCommand);


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
    const files = e.dataTransfer.files;
    
    // 首先尝试从 files 获取路径信息
    if (files && files.length > 0) {
        const file = files[0];
        console.log('File object:', file);
        console.log('File path (if available):', file.path || 'Not available');
        console.log('File webkitRelativePath:', file.webkitRelativePath || 'Not available');
    }
    
    if (items) {
        for (let i = 0; i < items.length; i++) {
            const item = items[i];
            if (item.kind === 'file') {
                const entry = item.webkitGetAsEntry();
                console.log('Entry:', entry);
                console.log('Entry fullPath:', entry ? entry.fullPath : 'Not available');
                console.log('Entry name:', entry ? entry.name : 'Not available');
                
                if (entry && entry.isDirectory) {
                    // 由于浏览器安全限制，我们只能获取文件夹名称
                    // 无法获取完整的绝对路径
                    displayPath(entry.name);
                    
                    // 显示提示让用户确认完整路径
                    setTimeout(() => {
                        const hint = document.querySelector('.path-hint');
                        if (hint) {
                            hint.innerHTML = '⚠️ 浏览器安全限制无法获取完整路径，请确认上方路径是否正确';
                            hint.style.color = '#dc2626';
                        }
                    }, 100);
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
    
    // 由于浏览器限制，我们只能获取文件夹名称
    // 让用户自己输入完整路径
    fullPathInput.value = '';
    fullPathInput.placeholder = `请输入 "${path}" 的完整路径`;
    
    // 添加提示信息
    const hint = document.querySelector('.path-hint');
    if (hint) {
        hint.innerHTML = `已识别文件夹: <code>${path}</code>，请输入其完整路径`;
        hint.style.color = 'var(--text-secondary)';
    }
    
    // 监听路径输入变化（避免重复添加监听器）
    if (!fullPathInput.hasAttribute('data-listener-added')) {
        fullPathInput.addEventListener('input', handlePathInput);
        fullPathInput.setAttribute('data-listener-added', 'true');
    }
    
    // 聚焦到输入框，方便用户修改
    fullPathInput.focus();
    fullPathInput.select();
    
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