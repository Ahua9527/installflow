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
    if (files.length > 0) {
        // 获取第一个文件的路径
        const file = files[0];
        // 提取文件夹路径
        const path = file.webkitRelativePath.split('/')[0];
        displayPath(path);
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
    
    // 设置默认推测的路径
    const guessedPath = path.includes('/') ? path : `/Users/username/Downloads/${path}`;
    fullPathInput.value = guessedPath;
    
    // 监听路径输入变化
    fullPathInput.addEventListener('input', updateCommand);
    
    // 初始生成命令
    updateCommand();
    
    commandSection.style.display = 'block';
}

// 更新命令显示
function updateCommand() {
    const fullPath = fullPathInput.value || currentPath;
    const scriptUrl = 'https://gh.ahua.space/https://raw.githubusercontent.com/Ahua9527/installflow/refs/heads/main/Scripts/install.sh';
    const command = `curl -fsSL ${scriptUrl} | bash -s -- "${fullPath}"`;
    
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
    const command = `curl -fsSL ${scriptUrl} | bash -s -- "${fullPath}"`;
    
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