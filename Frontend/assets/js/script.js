// DOM 元素
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
});