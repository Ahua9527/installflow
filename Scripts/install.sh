#!/bin/bash

# ==============================================================================
# 🔔 叮当装 InstallFlow - Mac 批量安装工具
# 一键批量安装 Mac 应用，让装机像叮当一样简单
# 
# 使用方法：
# 1. 推荐方式（交互式）：
#    bash <(curl -fsSL https://gh.ahua.space/https://raw.githubusercontent.com/Ahua9527/installflow/refs/heads/main/Scripts/install.sh)
# 2. 传统方式（直接指定路径）：
#    bash <(curl -fsSL https://gh.ahua.space/https://raw.githubusercontent.com/Ahua9527/installflow/refs/heads/main/Scripts/install.sh) "/Users/your-name/Downloads/installers"

# ==============================================================================

set -e
set -o pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] ⚠️  $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ❌ $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')] ℹ️  $1${NC}"
}


# 全局变量
LOCAL_INSTALLERS_DIR=""  # 用户提供的本地安装包目录

# 安装结果追踪数组
declare -a successful_installs=()    # 成功安装的应用
declare -a bypassed_installs=()      # 跳过的安装（已存在、加密绕过等）
declare -a failed_installs=()        # 失败的安装
declare -a encrypted_dmg_files=()    # 跳过的加密DMG文件列表


# 解析命令行参数
parse_arguments() {
    if [ $# -eq 0 ]; then
        # 新的交互式模式：提示用户拖拽文件夹
        prompt_for_folder
        return
    fi
    
    local installers_path="$1"
    
    # 展开 ~ 路径
    installers_path="${installers_path/#\~/$HOME}"
    
    # 检查路径是否存在
    if [ ! -d "$installers_path" ]; then
        error "指定的目录不存在: $installers_path"
        exit 1
    fi
    
    # 检查目录中是否有安装包
    local package_count=$(find "$installers_path" -name "*.dmg" -o -name "*.pkg" -o -name "*.zip" | wc -l)
    
    if [ "$package_count" -eq 0 ]; then
        error "指定目录中没有找到安装包文件 (.dmg, .pkg, .zip)"
        exit 1
    else
        LOCAL_INSTALLERS_DIR="$installers_path"
        log "发现 $package_count 个本地安装包"
    fi
}

# 提示用户拖拽文件夹
prompt_for_folder() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}║                 🔔 叮当装 InstallFlow                        ║${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}║         一键批量安装 Mac 应用，让装机像叮当一样简单          ║${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}📁 请提供安装包所在的文件夹路径：${NC}"
    echo ""
    echo -e "${GREEN}💡 操作提示：${NC}"
    echo "   1. 在 Finder 中找到包含安装包的文件夹"
    echo "   2. 将文件夹直接拖拽到这个终端窗口"
    echo "   3. 按回车键确认"
    echo ""
    echo -e "${BLUE}📦 支持的文件类型：${NC} .dmg、.pkg、.zip、.app"
    echo ""
    
    while true; do
        echo -n "请输入或拖拽文件夹路径: "
        read -r installers_path
        
        # 如果用户输入为空，继续提示
        if [ -z "$installers_path" ]; then
            echo -e "${YELLOW}⚠️  请输入文件夹路径或将文件夹拖拽到终端窗口${NC}"
            continue
        fi
        
        # 清理路径（移除可能的引号和空格）
        installers_path=$(echo "$installers_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//')
        
        # 展开 ~ 路径
        installers_path="${installers_path/#\~/$HOME}"
        
        # 检查路径是否存在
        if [ ! -d "$installers_path" ]; then
            error "指定的目录不存在: $installers_path"
            echo -e "${YELLOW}请重新输入正确的文件夹路径${NC}"
            echo ""
            continue
        fi
        
        # 检查目录中是否有安装包
        local package_count=$(find "$installers_path" -name "*.dmg" -o -name "*.pkg" -o -name "*.zip" -o -name "*.app" | wc -l)
        
        if [ "$package_count" -eq 0 ]; then
            error "指定目录中没有找到安装包文件 (.dmg, .pkg, .zip, .app)"
            echo -e "${YELLOW}请选择包含安装包的文件夹${NC}"
            echo ""
            continue
        else
            LOCAL_INSTALLERS_DIR="$installers_path"
            log "✅ 发现 $package_count 个安装包文件"
            echo ""
            break
        fi
    done
}

# 显示欢迎信息
show_welcome() {
    # 如果是交互式模式，不显示欢迎信息（已经在 prompt_for_folder 中显示了）
    if [ -n "$LOCAL_INSTALLERS_DIR" ]; then
        echo ""
        echo -e "${GREEN}📁 本地安装包目录: $LOCAL_INSTALLERS_DIR${NC}"
        echo ""
    fi
}

# 检查Gatekeeper状态
check_gatekeeper_status() {
    log "检查Gatekeeper状态..."
    
    local gatekeeper_status=$(spctl --status 2>/dev/null)
    
    echo ""
    echo -e "${BLUE}📋 Gatekeeper状态检查${NC}"
    echo "================================"
    
    if [ "$gatekeeper_status" = "assessments enabled" ]; then
        echo -e "${YELLOW}⚠️  Gatekeeper状态：已启用${NC}"
        echo ""
        echo -e "${YELLOW}💡 说明：${NC}"
        echo "   • Gatekeeper已启用，系统会验证应用签名"
        echo "   • 安装的应用可能需要额外确认才能运行"
        echo "   • 第三方应用可能显示\"无法打开\"的提示"
        echo ""
        echo -e "${BLUE}🔧 建议操作：${NC}"
        echo "   为了顺利安装和运行第三方应用，建议临时关闭Gatekeeper"
        echo ""
        echo -e "${GREEN}✅ 好处：${NC}"
        echo "   • 安装的应用可以直接运行，无需额外确认"
        echo "   • 避免\"无法打开应用\"的问题"
        echo "   • 简化安装流程"
        echo ""
        echo -e "${RED}⚠️  注意：${NC}"
        echo "   • 关闭Gatekeeper会降低系统安全性"
        echo "   • 建议安装完成后重新启用"
        echo "   • 重新启用命令：sudo spctl --master-enable"
        echo ""
        
        # 询问用户是否要关闭Gatekeeper
        while true; do
            read -p "是否要临时关闭Gatekeeper以便顺利安装应用？[默认: y] (y/n): " -r gatekeeper_choice
            case $gatekeeper_choice in
                [Nn]*)
                    echo ""
                    echo -e "${YELLOW}保持Gatekeeper启用状态${NC}"
                    echo ""
                    echo -e "${BLUE}💡 如遇到应用无法打开的问题：${NC}"
                    echo -e "     ${BLUE}1.${NC} 右键点击应用 → 选择\"打开\""
                    echo -e "     ${BLUE}2.${NC} 或在\"系统偏好设置 → 安全性与隐私\"中允许"
                    echo ""
                    break
                    ;;
                [Yy]*|"")
                    echo ""
                    echo -e "${BLUE}正在关闭Gatekeeper...${NC}"
                    if sudo spctl --master-disable 2>/dev/null; then
                        echo -e "${GREEN}✅ Gatekeeper已关闭${NC}"
                        echo ""
                        echo -e "${YELLOW}📝 重要提醒：${NC}"
                        echo "   安装完成后，建议重新启用Gatekeeper："
                        echo -e "   ${BLUE}sudo spctl --master-enable${NC}"
                        echo ""
                    else
                        echo -e  "${YELLOW} 下一步：${NC}"
                        echo -e  "${YELLOW}1. 打开 系统偏好设置${NC}"
                        echo -e  "${YELLOW}2. 进入 安全性与隐私${NC}"
                        echo -e  "${YELLOW}3. 确认 允许任何来源 已勾选${NC}"
                    fi
                    break
                    ;;
                *)
                    echo "请输入 y (是) 或 n (否)"
                    ;;
            esac
        done
    elif [ "$gatekeeper_status" = "assessments disabled" ]; then
        echo -e "${GREEN}✅ Gatekeeper状态：已关闭 - 有利于第三方应用安装${NC}"
    else
        echo -e "${YELLOW}❓ Gatekeeper状态：未知${NC}"
        echo "   • 无法确定当前状态"
    fi
    
    echo "================================"
    echo ""
    
    # 只有在需要用户交互时才显示确认提示
    if [ "$gatekeeper_status" = "assessments enabled" ]; then
        # 如果Gatekeeper启用，可能需要用户决定，所以显示确认
        echo -e "${YELLOW}请确认您已了解上述信息。${NC}"
        read -p "按回车键继续，或按 Ctrl+C 退出... " -r
        echo ""
    elif [ "$gatekeeper_status" = "assessments disabled" ]; then
        # 如果Gatekeeper已关闭，直接继续，不需要额外确认
        echo ""
    else
        # 状态未知时显示确认
        echo -e "${YELLOW}请确认您已了解上述信息。${NC}"
        read -p "按回车键继续，或按 Ctrl+C 退出... " -r
        echo ""
    fi
}


# 检查Rosetta状态并安装
check_rosetta_status() {
    # 检查是否为Apple Silicon Mac
    local arch=$(uname -m)
    if [[ "$arch" != "arm64" ]]; then
        log "检测到Intel Mac，无需Rosetta"
        return 0
    fi
    
    log "检测到Apple Silicon Mac，正在检查Rosetta状态..."
    
    # 检查Rosetta是否已安装
    if arch -x86_64 /usr/bin/true 2>/dev/null; then
        log "✅ Rosetta已安装"
        return 0
    fi
    
    echo ""
    echo -e "${BLUE}🔄 Rosetta检测${NC}"
    echo "================================"
    echo -e "${YELLOW}⚠️  Rosetta未安装${NC}"
    echo ""
    echo -e "${BLUE}💡 说明：${NC}"
    echo "   • 检测到Apple Silicon Mac，但未安装Rosetta"
    echo "   • 某些应用可能需要Rosetta才能运行"
    echo "   • 建议现在安装Rosetta以确保兼容性"
    echo ""
    
    # 询问用户是否要安装Rosetta
    while true; do
        read -p "是否要安装Rosetta？[默认: y] (y/n): " -r rosetta_choice
        case $rosetta_choice in
            [Nn]*)
                echo ""
                echo -e "${YELLOW}跳过Rosetta安装${NC}"
                echo -e "${YELLOW}⚠️  注意：某些Intel应用可能无法运行${NC}"
                echo ""
                break
                ;;
            [Yy]*|"")
                echo ""
                echo -e "${BLUE}正在安装Rosetta...${NC}"
                echo -e "${YELLOW}💡 提示：安装过程可能需要几分钟时间${NC}"
                echo ""
                
                if sudo softwareupdate --install-rosetta --agree-to-license; then
                    echo ""
                    echo -e "${GREEN}✅ Rosetta安装成功${NC}"
                    log "Rosetta安装完成"
                else
                    echo ""
                    echo -e "${RED}❌ Rosetta安装失败${NC}"
                    warn "继续安装可能导致某些应用无法运行"
                fi
                echo ""
                break
                ;;
            *)
                echo "请输入 y (是) 或 n (否)"
                ;;
        esac
    done
    echo "================================"
    echo ""
}

# 检查系统要求
check_requirements() {
    log "检查系统要求..."
    
    # 检查是否为 macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        error "此脚本仅支持 macOS 系统"
        exit 1
    fi
    
    log "系统检查通过"
    
    # 检查Rosetta状态
    check_rosetta_status
    
    # 检查Gatekeeper状态
    check_gatekeeper_status
}

# 交互式选择界面
interactive_package_selector() {
    # 检查是否为交互式终端
    if ! tty -s; then
        warn "检测到非交互式环境，将自动选择所有软件包进行安装"
        selected_local_files=("${package_files_list[@]}")
        return
    fi
    local packages=("${packages_list[@]}")
    local package_files=("${package_files_list[@]}")
    local total=${#packages[@]}
    
    if [ $total -eq 0 ]; then
        warn "没有找到可用的安装包"
        exit 1
    fi
    
    # 初始化选择状态（默认全部选中）
    local selected=()
    for i in $(seq 0 $((total-1))); do
        selected[i]=1
    done
    
    local cursor=0
    local page_size=50
    local page_start=0
    
    # 隐藏光标并启用原始模式
    printf '\e[?25l'  # 隐藏光标
    stty -echo        # 禁用回显
    
    # 清理函数
    cleanup_selector() {
        printf '\e[?25h'  # 显示光标
        stty echo         # 启用回显
    }
    
    # 设置清理陷阱
    trap cleanup_selector EXIT
    
    while true; do
        # 清屏并移动到顶部
        clear
        
        # 显示标题
        echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║                    📦 选择要安装的软件包                     ║${NC}"
        echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${YELLOW}💡 使用方向键 ↑↓ 移动光标，空格键 ␣ 切换选择，回车键 ⏎ 确认${NC}"
        echo -e "${YELLOW}   Ctrl+A 全选，Ctrl+N 全不选，ESC 或 q 退出${NC}"
        echo ""
        
        # 计算分页
        local page_end=$((page_start + page_size - 1))
        if [ $page_end -ge $total ]; then
            page_end=$((total - 1))
        fi
        
        # 显示当前页的软件包
        for i in $(seq $page_start $page_end); do
            local prefix=""
            local suffix=""
            local status_icon=""
            
            # 选择状态图标
            if [ "${selected[i]}" -eq 1 ]; then
                status_icon="${GREEN}✓${NC}"
            else
                status_icon="${RED}✗${NC}"
            fi
            
            # 光标位置高亮
            if [ $i -eq $cursor ]; then
                prefix="${BLUE}► ${NC}"
                suffix="${BLUE} ◄${NC}"
            else
                prefix="  "
                suffix=""
            fi
            
            echo -e "${prefix}[${status_icon}] ${packages[i]}${suffix}"
        done
        
        # 显示分页信息
        if [ $total -gt $page_size ]; then
            echo ""
            echo -e "${YELLOW}第 $((page_start/page_size + 1)) 页，共 $(((total-1)/page_size + 1)) 页${NC}"
        fi
        
        # 显示统计信息
        local selected_count=0
        for i in $(seq 0 $((total-1))); do
            if [ "${selected[i]}" -eq 1 ]; then
                ((selected_count++))
            fi
        done
        
        echo ""
        echo -e "${GREEN}已选择: $selected_count / $total${NC}"
        
        # 使用更精确的按键检测方法
        old_stty_cfg=$(stty -g)
        stty raw -echo
        
        # 读取一个字符，使用十六进制分析
        key=$(dd bs=1 count=1 2>/dev/null)
        key_hex=$(printf '%s' "$key" | hexdump -ve '1/1 "%02x"')
        
        stty $old_stty_cfg
        
        # 处理转义序列（方向键）
        if [ "$key" = $'\x1b' ]; then
            stty raw -echo
            seq1=$(dd bs=1 count=1 2>/dev/null)
            seq2=$(dd bs=1 count=1 2>/dev/null)
            stty $old_stty_cfg
            
            if [ "$seq1" = "[" ]; then
                case "$seq2" in
                    'A')  key="UP" ;;
                    'B')  key="DOWN" ;;
                    'C')  key="RIGHT" ;;
                    'D')  key="LEFT" ;;
                esac
            else
                key="ESC"
            fi
        fi
        
        # 根据十六进制值精确判断按键
        case "$key_hex" in
            "20")     # 空格键的十六进制值 (ASCII 32)
                if [ "${selected[cursor]}" -eq 1 ]; then
                    selected[cursor]=0
                else
                    selected[cursor]=1
                fi
                ;;
            "0a"|"0d"|"")  # 回车键的十六进制值 (ASCII 10, 13) 或空字符串
                # 对于空字符串，我们需要进一步区分
                if [ -z "$key" ] && [ "$key_hex" = "" ]; then
                    # 这是真正的回车键（产生空字符串）
                    break
                elif [ "$key_hex" = "0a" ] || [ "$key_hex" = "0d" ]; then
                    # 这是换行符形式的回车键
                    break
                fi
                ;;
        esac
        
        # 处理其他按键
        case "$key" in
            'UP'|'k')  # 上箭头或 k
                if [ $cursor -gt 0 ]; then
                    ((cursor--))
                    if [ $cursor -lt $page_start ]; then
                        page_start=$((cursor / page_size * page_size))
                    fi
                fi
                ;;
            'DOWN'|'j')  # 下箭头或 j
                if [ $cursor -lt $((total-1)) ]; then
                    ((cursor++))
                    if [ $cursor -gt $page_end ]; then
                        page_start=$(((cursor / page_size) * page_size))
                    fi
                fi
                ;;
            $'\x01')  # Ctrl+A 全选
                for i in $(seq 0 $((total-1))); do
                    selected[i]=1
                done
                ;;
            $'\x0e')  # Ctrl+N 全不选
                for i in $(seq 0 $((total-1))); do
                    selected[i]=0
                done
                ;;
            'ESC'|'q')  # ESC 或 q 退出
                cleanup_selector
                log "用户取消安装"
                exit 0
                ;;
        esac
    done
    
    # 清理
    cleanup_selector
    
    # 收集选中的文件
    selected_local_files=()
    for i in $(seq 0 $((total-1))); do
        if [ "${selected[i]}" -eq 1 ]; then
            selected_local_files+=("${package_files[i]}")
        fi
    done
    
    if [ ${#selected_local_files[@]} -eq 0 ]; then
        warn "没有选择任何安装包"
        exit 0
    fi
    
    # 显示最终选择
    clear
    echo ""
    log "将安装以下软件包："
    for file in "${selected_local_files[@]}"; do
        echo -e "  • ${GREEN}$(basename "$file")${NC}"
    done
    echo ""
    
    read -p "确认安装？[默认: y] (y/n): " -r confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        log "用户取消安装"
        exit 0
    fi
}

# 分析本地安装包
analyze_local_packages() {
    
    log "分析本地安装包..."
    
    packages_list=()
    package_files_list=()
    
    # 遍历本地安装包目录（兼容bash 3.x，包括子目录和.app文件）
    local temp_file="/tmp/packages_list_$$"
    find "$LOCAL_INSTALLERS_DIR" -name "*.dmg" -o -name "*.pkg" -o -name "*.zip" -o -name "*.app" > "$temp_file"
    
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            local filename=$(basename "$file")
            local name_without_ext="${filename%.*}"
            # 清理文件名（移除版本号、特殊字符等）
            local clean_name=$(echo "$name_without_ext" | sed 's/[0-9\.-]*$//' | sed 's/[-_]/ /g' | sed 's/ *$//')
            
            packages_list+=("$clean_name")
            package_files_list+=("$file")
        fi
    done < "$temp_file"
    
    rm -f "$temp_file"
    
    # 启动交互式选择器
    interactive_package_selector
}

# 显示软件包选择菜单
show_package_menu() {
    analyze_local_packages
}


# 创建安装脚本
create_install_script() {
    log "创建安装脚本..."
    
    # 直接使用内置脚本（不再尝试网络下载）
    create_embedded_install_script
    chmod +x install.sh
}


# 处理加密的DMG文件（使用原生hdiutil attach，支持密码错误2次后自动跳过）
handle_encrypted_dmg() {
    local installer_path="$1"
    local filename=$(basename "$installer_path")
    
    echo "  🔐 检测到加密DMG文件: $filename"
    echo "  💡 此文件需要密码才能打开，您有2次输入机会"
    
    local attempt_count=0
    local max_attempts=2
    
    # 给用户2次密码输入机会
    while [ $attempt_count -lt $max_attempts ]; do
        ((attempt_count++))
        echo ""
        echo "  尝试 $attempt_count/$max_attempts"
        
        # 使用原生hdiutil attach让用户直接输入密码
        echo "  🔓 正在挂载DMG，请输入密码..."
        
        if sudo hdiutil attach "$installer_path" -nobrowse -owners on; then
            echo "  ✅ 密码正确，DMG已成功挂载"
            # 获取挂载点信息
            HDIUTIL_OUTPUT=$(mount | grep "$(basename "$installer_path" .dmg)" | tail -1)
            return 0
        else
            echo "  ❌ 密码错误或挂载失败 (尝试 $attempt_count/$max_attempts)"
            
            if [ $attempt_count -lt $max_attempts ]; then
                echo "  💡 您还有 $((max_attempts - attempt_count)) 次机会"
            else
                echo "  ⏭️  已达到最大尝试次数，自动跳过此文件"
                return 1
            fi
        fi
    done
    
    return 1
}

# 安全推出DMG函数
safe_detach_dmg() {
    local mount_point="$1"
    local filename="$2"
    
    if [ -z "$mount_point" ] || [ ! -d "$mount_point" ]; then
        echo "  ⚠️  挂载点无效，跳过推出: $mount_point"
        return 0
    fi
    
    echo "  正在推出DMG: $filename..."
    sleep 2  # 给系统一些时间完成文件操作
    
    # 尝试1: 优雅推出
    if timeout 15 sudo hdiutil detach "$mount_point" -quiet 2>/dev/null; then
        echo "  ✅ DMG推出完成"
        return 0
    fi
    
    echo "  ⏰ 优雅推出超时，尝试强制推出..."
    
    # 尝试2: 强制推出
    if timeout 10 sudo hdiutil detach "$mount_point" -force -quiet 2>/dev/null; then
        echo "  ✅ DMG强制推出完成"
        return 0
    fi
    
    echo "  ⚠️  强制推出也失败，尝试清理挂载点..."
    
    # 尝试3: 检查并手动清理
    if mount | grep -q "$mount_point"; then
        echo "  🔧 挂载点仍然存在，尝试umount..."
        sudo umount "$mount_point" 2>/dev/null || true
        sleep 1
        sudo hdiutil detach "$mount_point" -force -quiet 2>/dev/null || true
    fi
    
    echo "  ✅ DMG推出处理完成（可能需要手动检查）"
    return 0
}

# 安装DMG文件
install_dmg_file() {
    local installer_path="$1"
    local filename=$(basename "$installer_path")
    
    echo "  [类型: DMG] - 移除隔离属性..."
    sudo xattr -r -d com.apple.quarantine "$installer_path" 2>/dev/null || true
    echo "  [类型: DMG] - 正在尝试挂载（使用空密码）..."
    
    # 统一使用空密码尝试挂载所有DMG文件（添加超时保护）
    HDIUTIL_OUTPUT=$(timeout 30 bash -c "printf '\n' | sudo hdiutil attach '$installer_path' -stdinpass -nobrowse -owners on 2>&1")
    HDIUTIL_EXIT_CODE=$?
    
    # 检查挂载结果
    if [ $HDIUTIL_EXIT_CODE -ne 0 ]; then
        # 检测超时或认证错误，表示需要密码
        if [ $HDIUTIL_EXIT_CODE -eq 124 ] || echo "$HDIUTIL_OUTPUT" | grep -q "认证错误\|Authentication error\|authentication failed"; then
            echo "  🔐 检测到加密DMG文件（需要密码），自动跳过"
            echo "  💡 提示：此文件将在安装完成后询问您是否重试"
            encrypted_dmg_files+=("$installer_path")
            bypassed_installs+=("$filename (加密DMG，需要密码)")
            return 0
        else
            echo "  ❌ 挂载失败: $filename"
            echo "  错误信息: $HDIUTIL_OUTPUT"
            failed_installs+=("$filename (DMG挂载失败)")
            return 1
        fi
    fi
    
    MOUNT_POINT=$(echo "$HDIUTIL_OUTPUT" | grep '/Volumes/' | tail -1 | sed 's/.*\(\/Volumes\/.*\)$/\1/' | sed 's/[[:space:]]*$//')
    
    if [ -z "$MOUNT_POINT" ] || [ ! -d "$MOUNT_POINT" ]; then
        echo "  ❌ 无法确定挂载点: $filename"
        return
    fi
    
    echo "  ✅ 已挂载到: $MOUNT_POINT"
    
    # 查找PKG文件（支持多个PKG）
    local pkg_files=()
    while IFS= read -r -d '' file; do
        pkg_files+=("$file")
    done < <(find "$MOUNT_POINT" -maxdepth 1 -name "*.pkg" -type f -print0)
    local pkg_count=${#pkg_files[@]}
    
    if [ $pkg_count -gt 0 ]; then
        if [ $pkg_count -gt 1 ]; then
            echo "  📦 发现多个PKG安装包: $pkg_count 个"
            bypassed_installs+=("$filename (异常: 包含$pkg_count个PKG文件)")
        else
            echo "  📦 发现PKG安装包: $(basename "${pkg_files[0]}")"
        fi
        
        for pkg_file in "${pkg_files[@]}"; do
            local pkg_name=$(basename "$pkg_file")
            echo "  📦 正在安装PKG: $pkg_name"
            
            if sudo installer -pkg "$pkg_file" -target /; then
                echo "  ✅ PKG安装成功: $pkg_name"
                successful_installs+=("$pkg_name (从DMG中的PKG)")
            else
                echo "  ❌ PKG安装失败: $pkg_name"
                failed_installs+=("$filename (DMG中的PKG安装失败: $pkg_name)")
            fi
        done
    fi
    
    # 查找并安装.app文件（只有在没有PKG时）
    if [ $pkg_count -eq 0 ]; then
        echo "  🔍 查找 .app 文件..."
        
        local app_files=()
        while IFS= read -r -d '' file; do
            app_files+=("$file")
        done < <(find "$MOUNT_POINT" -maxdepth 1 -name "*.app" -type d -print0)
        local app_count=${#app_files[@]}
        
        if [ $app_count -gt 0 ]; then
            if [ $app_count -gt 1 ]; then
                echo "  📱 发现多个应用: $app_count 个"
                bypassed_installs+=("$filename (异常: 包含$app_count个.app文件)")
            else
                echo "  📱 发现应用: $(basename "${app_files[0]}")"
            fi
            
            for app_path in "${app_files[@]}"; do
                local app_name=$(basename "$app_path")
                local target_app_path="/Applications/$app_name"
                echo "  ✅ 处理应用: $app_name"
                
                if [ -d "$target_app_path" ]; then
                    echo "  🟡 应用 '$app_name' 已存在，跳过安装。"
                    bypassed_installs+=("$filename (应用已存在: $app_name)")
                else
                    echo "  正在将 '$app_name' 拷贝到 /Applications ..."
                    if sudo cp -R "$app_path" "/Applications/"; then
                        echo "  ✅ 拷贝完成: $app_name"
                        
                        # 移除应用的隔离属性
                        echo "  正在移除应用的隔离属性..."
                        sudo xattr -r -d com.apple.quarantine "$target_app_path" 2>/dev/null || true
                        echo "  ✅ 隔离属性移除完成: $app_name"
                        
                        successful_installs+=("$app_name (从DMG)")
                    else
                        echo "  ❌ 拷贝失败: $app_name"
                        failed_installs+=("$filename (应用拷贝失败: $app_name)")
                    fi
                fi
            done
        else
            echo "  ❌ 未找到 .app 文件"
            failed_installs+=("$filename (DMG中未找到.app文件)")
        fi
    fi
    
    # 安全推出DMG
    safe_detach_dmg "$MOUNT_POINT" "$filename"
}

# 检查PKG是否已安装
check_pkg_installation() {
    local installer_path="$1"
    local filename=$(basename "$installer_path")
    
    echo "  🔍 检查PKG是否已安装..."
    
    # 创建临时目录来提取PKG信息
    local temp_dir="/tmp/pkg_check_$$"
    mkdir -p "$temp_dir"
    
    # 尝试提取PKG信息
    if pkgutil --expand-full "$installer_path" "$temp_dir" 2>/dev/null; then
        # 查找PackageInfo文件来获取包标识符
        local package_info=$(find "$temp_dir" -name "PackageInfo" -type f | head -1)
        if [ -n "$package_info" ] && [ -f "$package_info" ]; then
            # 提取包标识符
            local pkg_id=$(grep -o 'identifier="[^"]*"' "$package_info" | sed 's/identifier="//;s/"//' | head -1)
            
            if [ -n "$pkg_id" ]; then
                echo "  📦 包标识符: $pkg_id"
                
                # 检查包是否已安装
                if pkgutil --pkg-info "$pkg_id" >/dev/null 2>&1; then
                    echo "  🟡 PKG '$pkg_id' 已安装，跳过安装。"
                    bypassed_installs+=("$filename (PKG已安装: $pkg_id)")
                    rm -rf "$temp_dir"
                    return 1
                fi
            fi
        fi
    fi
    
    rm -rf "$temp_dir"
    return 0
}

# 安装PKG文件
install_pkg_file() {
    local installer_path="$1"
    local filename=$(basename "$installer_path")
    
    echo "  [类型: PKG] - 准备安装..."
    
    # 检查PKG是否已安装
    if ! check_pkg_installation "$installer_path"; then
        return 0
    fi
    
    echo "  📦 正在安装PKG..."
    if sudo installer -pkg "$installer_path" -target /; then
        echo "  ✅ PKG 安装成功。"
        
        # 尝试获取包名用于记录
        local pkg_name=$(basename "$installer_path" .pkg)
        successful_installs+=("$pkg_name (PKG)")
    else
        echo "  ❌ PKG 安装失败。"
        failed_installs+=("$filename (PKG安装失败)")
    fi
}

# 安装APP文件
install_app_file() {
    local installer_path="$1"
    local filename=$(basename "$installer_path")
    
    echo "  [类型: APP] - 直接安装应用..."
    APP_NAME=$(basename "$installer_path")
    TARGET_APP_PATH="/Applications/$APP_NAME"
    
    if [ -d "$TARGET_APP_PATH" ]; then
        echo "  🟡 应用 '$APP_NAME' 已存在，跳过安装。"
        bypassed_installs+=("$filename (应用已存在: $APP_NAME)")
    else
        echo "  正在将 '$APP_NAME' 拷贝到 /Applications ..."
        if sudo cp -R "$installer_path" "/Applications/"; then
            echo "  ✅ 拷贝完成。"
            
            # 移除应用的隔离属性
            echo "  正在移除应用的隔离属性..."
            sudo xattr -r -d com.apple.quarantine "$TARGET_APP_PATH" 2>/dev/null || true
            echo "  ✅ 隔离属性移除完成。"
            
            successful_installs+=("$APP_NAME (直接安装)")
        else
            echo "  ❌ 拷贝失败"
            failed_installs+=("$filename (应用拷贝失败: $APP_NAME)")
        fi
    fi
}

# 安装ZIP文件
install_zip_file() {
    local installer_path="$1"
    local filename=$(basename "$installer_path")
    
    echo "  [类型: ZIP] - 移除隔离属性..."
    sudo xattr -r -d com.apple.quarantine "$installer_path" 2>/dev/null || true
    echo "  [类型: ZIP] - 正在解压..."
    
    # 创建临时解压目录
    local temp_extract="/tmp/zip_extract_$$"
    mkdir -p "$temp_extract"
    
    unzip -q "$installer_path" -d "$temp_extract"
    
    # 在解压后的内容中移除隔离属性
    sudo xattr -r -d com.apple.quarantine "$temp_extract" 2>/dev/null || true
    
    # 查找 .app 文件
    APP_PATH=$(find "$temp_extract" -name "*.app" -maxdepth 5 -print -quit)
    
    if [ -n "$APP_PATH" ]; then
        APP_NAME=$(basename "$APP_PATH")
        TARGET_APP_PATH="/Applications/$APP_NAME"
        echo "  🔍 找到应用: $APP_NAME"
        
        if [ -d "$TARGET_APP_PATH" ]; then
            echo "  🟡 应用 '$APP_NAME' 已存在，跳过安装。"
            bypassed_installs+=("$filename (应用已存在: $APP_NAME)")
        else
            echo "  正在将 '$APP_NAME' 拷贝到 /Applications ..."
            if sudo cp -R "$APP_PATH" "/Applications/"; then
                echo "  ✅ 拷贝完成。"
                
                # 移除应用的隔离属性
                echo "  正在移除应用的隔离属性..."
                sudo xattr -r -d com.apple.quarantine "$TARGET_APP_PATH" 2>/dev/null || true
                echo "  ✅ 隔离属性移除完成。"
                
                successful_installs+=("$APP_NAME (从ZIP)")
            else
                echo "  ❌ 拷贝失败"
                failed_installs+=("$filename (应用拷贝失败: $APP_NAME)")
            fi
        fi
    else
        echo "  ❌ 在ZIP中未找到 .app 文件。"
        failed_installs+=("$filename (ZIP中未找到.app文件)")
    fi
    
    # 清理临时目录
    rm -rf "$temp_extract"
}

# 创建内置的安装脚本（保留用于兼容性，但不再使用）
create_embedded_install_script() {
    cat > install.sh << 'EOF'
#!/bin/bash

# 内置的安装脚本
set -e
set -o pipefail

cd "$(dirname "$0")"
INSTALLERS_DIR="./installers"
APPLICATIONS_DIR="/Applications"

echo "🔔 叮当装正在为您安装应用..."
echo "========================================"

if [ ! -d "$INSTALLERS_DIR" ]; then
  echo "❌ 错误：未找到 'installers' 目录。"
  exit 1
fi

# sudo权限已在bootstrap.sh中验证

for installer_path in "$INSTALLERS_DIR"/*; do
  [ -e "$installer_path" ] || continue
  
  filename=$(basename "$installer_path")
  extension="${filename##*.}"
  
  echo ""
  echo "----------------------------------------"
  echo "⚙️  正在处理: $filename"
  echo "----------------------------------------"
  
  case "$extension" in
    "dmg")
      echo "  [类型: DMG] - 移除隔离属性..."
      sudo xattr -r -d com.apple.quarantine "$installer_path" 2>/dev/null || true
      echo "  [类型: DMG] - 正在挂载..."
      HDIUTIL_OUTPUT=$(sudo hdiutil attach "$installer_path" -nobrowse -owners on 2>&1)
      HDIUTIL_EXIT_CODE=$?
      
      if [ $HDIUTIL_EXIT_CODE -ne 0 ]; then
        echo "  ❌ 挂载失败: $filename"
        continue
      fi
      
      MOUNT_POINT=$(echo "$HDIUTIL_OUTPUT" | grep '/Volumes/' | tail -1 | sed 's/.*\(\/Volumes\/.*\)$/\1/' | sed 's/[[:space:]]*$//')
      
      if [ -z "$MOUNT_POINT" ] || [ ! -d "$MOUNT_POINT" ]; then
        echo "  ❌ 无法确定挂载点: $filename"
        continue
      fi
      
      echo "  ✅ 已挂载到: $MOUNT_POINT"
      
      
      # 查找PKG文件
      PKG_PATH=""
      if [ -f "$MOUNT_POINT"/*.pkg ]; then
        PKG_PATH=$(echo "$MOUNT_POINT"/*.pkg | head -1)
      fi
      
      # 安装PKG（如果存在）
      if [ -n "$PKG_PATH" ] && [ -f "$PKG_PATH" ]; then
        PKG_NAME=$(basename "$PKG_PATH")
        echo "  📦 发现PKG安装包: $PKG_NAME"
        echo "  📦 正在安装PKG..."
        
        if sudo installer -pkg "$PKG_PATH" -target /; then
          echo "  ✅ PKG安装成功"
        else
          echo "  ❌ PKG安装失败"
        fi
      fi
      
      # 查找并安装.app文件（只有在没有PKG时）
      if [ -z "$PKG_PATH" ]; then
        echo "  🔍 查找 .app 文件..."
        
        APP_PATH=""
        if [ -d "$MOUNT_POINT"/*.app ]; then
          APP_PATH=$(echo "$MOUNT_POINT"/*.app | head -1)
        fi
      else
        APP_PATH=""
      fi
      
      if [ -n "$APP_PATH" ]; then
        # 常规DMG包含.app文件
        APP_NAME=$(basename "$APP_PATH")
        TARGET_APP_PATH="$APPLICATIONS_DIR/$APP_NAME"
        echo "  ✅ 找到应用: $APP_NAME"
        
        if [ -d "$TARGET_APP_PATH" ]; then
          echo "  🟡 应用 '$APP_NAME' 已存在，跳过安装。"
        else
          echo "  正在将 '$APP_NAME' 拷贝到 $APPLICATIONS_DIR ..."
          sudo cp -R "$APP_PATH" "$APPLICATIONS_DIR/"
          echo "  ✅ 拷贝完成。"
          
          # 移除应用的隔离属性
          echo "  正在移除应用的隔离属性..."
          sudo xattr -r -d com.apple.quarantine "$TARGET_APP_PATH" 2>/dev/null || true
          echo "  ✅ 隔离属性移除完成。"
        fi
      else
        echo "  ❌ 未找到 .app 文件"
        # 第三步：检查是否是TNT团队的特殊结构
        echo "  🔍 Step 3: 检查TNT特殊结构..."
        
        # 首先查找Manual install目录
        MANUAL_INSTALL_DIR=$(find "$MOUNT_POINT" -name "*[Mm]anual*install*" -type d 2>/dev/null | head -1)
        
        if [ -n "$MANUAL_INSTALL_DIR" ]; then
          echo "  🎯 发现TNT结构，找到Manual install目录: $(basename "$MANUAL_INSTALL_DIR")"
          
          # 在Manual install目录中查找DMG文件
          MANUAL_INSTALL_DMG=$(find "$MANUAL_INSTALL_DIR" -name "*.dmg" 2>/dev/null | head -1)
          
          if [ -n "$MANUAL_INSTALL_DMG" ]; then
            echo "  📦 在Manual install目录中找到DMG: $(basename "$MANUAL_INSTALL_DMG")"
            echo "  📦 正在挂载嵌套DMG..."
            
            # 挂载嵌套的DMG
            NESTED_HDIUTIL_OUTPUT=$(sudo hdiutil attach "$MANUAL_INSTALL_DMG" -nobrowse -owners on 2>&1)
            NESTED_HDIUTIL_EXIT_CODE=$?
            
            if [ $NESTED_HDIUTIL_EXIT_CODE -ne 0 ]; then
              echo "  ❌ 嵌套DMG挂载失败"
            else
              NESTED_MOUNT_POINT=$(echo "$NESTED_HDIUTIL_OUTPUT" | grep '/Volumes/' | tail -1 | sed 's/.*\(\/Volumes\/.*\)$/\1/' | sed 's/[[:space:]]*$//')
              
              if [ -n "$NESTED_MOUNT_POINT" ] && [ -d "$NESTED_MOUNT_POINT" ]; then
                echo "  ✅ 嵌套DMG已挂载到: $NESTED_MOUNT_POINT"
                
                # 在嵌套DMG中查找.app文件
                NESTED_APP_PATH=$(find "$NESTED_MOUNT_POINT" -name "*.app" -maxdepth 3 -print -quit 2>/dev/null)
                
                if [ -n "$NESTED_APP_PATH" ]; then
                  APP_NAME=$(basename "$NESTED_APP_PATH")
                  TARGET_APP_PATH="$APPLICATIONS_DIR/$APP_NAME"
                  echo "  🔍 在嵌套DMG中找到应用: $APP_NAME"
                  
                  if [ -d "$TARGET_APP_PATH" ]; then
                    echo "  🟡 应用 '$APP_NAME' 已存在，跳过安装。"
                  else
                    echo "  正在将 '$APP_NAME' 拷贝到 $APPLICATIONS_DIR ..."
                    sudo cp -R "$NESTED_APP_PATH" "$APPLICATIONS_DIR/"
                    echo "  ✅ 拷贝完成。"
                  fi
                else
                  echo "  ❌ 在嵌套DMG中也未找到 .app 文件。"
                fi
                
                # 推出嵌套DMG
                echo "  正在推出嵌套DMG: $(basename "$MANUAL_INSTALL_DMG")..."
                sleep 1
                if sudo hdiutil detach "$NESTED_MOUNT_POINT" -quiet 2>/dev/null; then
                  echo "  ✅ 嵌套DMG推出完成。"
                else
                  sudo hdiutil detach "$NESTED_MOUNT_POINT" -force -quiet 2>/dev/null || true
                  echo "  ✅ 嵌套DMG强制推出完成。"
                fi
              else
                echo "  ❌ 无法确定嵌套DMG挂载点"
              fi
            fi
          else
            echo "  🔍 Manual install目录中未找到DMG文件，直接查找.app文件..."
            # 直接在Manual install目录中查找.app文件
            MANUAL_APP_PATH=$(find "$MANUAL_INSTALL_DIR" -name "*.app" -maxdepth 3 -print -quit)
            
            if [ -n "$MANUAL_APP_PATH" ]; then
              APP_NAME=$(basename "$MANUAL_APP_PATH")
              TARGET_APP_PATH="$APPLICATIONS_DIR/$APP_NAME"
              echo "  🔍 在Manual install目录中找到应用: $APP_NAME"
              
              if [ -d "$TARGET_APP_PATH" ]; then
                echo "  🟡 应用 '$APP_NAME' 已存在，跳过安装。"
              else
                echo "  正在将 '$APP_NAME' 拷贝到 $APPLICATIONS_DIR ..."
                sudo cp -R "$MANUAL_APP_PATH" "$APPLICATIONS_DIR/"
                echo "  ✅ 拷贝完成。"
              fi
            else
              echo "  ❌ 在Manual install目录中也未找到 .app 文件。"
            fi
          fi
        else
          # 查找直接的嵌套DMG文件（作为备用方案）
          MANUAL_INSTALL_DMG=$(find "$MOUNT_POINT" -name "*[Mm]anual*install*.dmg" -o -name "*[Mm]anual*.dmg" -o -name "*install*.dmg" 2>/dev/null | head -1)
          
            if [ -n "$MANUAL_INSTALL_DMG" ]; then
              echo "  🎯 发现嵌套DMG文件: $(basename "$MANUAL_INSTALL_DMG")"
              echo "  📦 正在挂载嵌套DMG..."
              
              # 挂载嵌套的DMG
              NESTED_HDIUTIL_OUTPUT=$(sudo hdiutil attach "$MANUAL_INSTALL_DMG" -nobrowse -owners on 2>&1)
              NESTED_HDIUTIL_EXIT_CODE=$?
              
              if [ $NESTED_HDIUTIL_EXIT_CODE -ne 0 ]; then
                echo "  ❌ 嵌套DMG挂载失败"
              else
                NESTED_MOUNT_POINT=$(echo "$NESTED_HDIUTIL_OUTPUT" | grep '/Volumes/' | tail -1 | sed 's/.*\(\/Volumes\/.*\)$/\1/' | sed 's/[[:space:]]*$//')
                
                if [ -n "$NESTED_MOUNT_POINT" ] && [ -d "$NESTED_MOUNT_POINT" ]; then
                  echo "  ✅ 嵌套DMG已挂载到: $NESTED_MOUNT_POINT"
                  
                  # 在嵌套DMG中查找.app文件
                  NESTED_APP_PATH=$(find "$NESTED_MOUNT_POINT" -name "*.app" -maxdepth 3 -print -quit 2>/dev/null)
                  
                  if [ -n "$NESTED_APP_PATH" ]; then
                    APP_NAME=$(basename "$NESTED_APP_PATH")
                    TARGET_APP_PATH="$APPLICATIONS_DIR/$APP_NAME"
                    echo "  🔍 在嵌套DMG中找到应用: $APP_NAME"
                    
                    if [ -d "$TARGET_APP_PATH" ]; then
                      echo "  🟡 应用 '$APP_NAME' 已存在，跳过安装。"
                    else
                      echo "  正在将 '$APP_NAME' 拷贝到 $APPLICATIONS_DIR ..."
                      sudo cp -R "$NESTED_APP_PATH" "$APPLICATIONS_DIR/"
                      echo "  ✅ 拷贝完成。"
                  fi
                else
                  echo "  ❌ 在嵌套DMG中也未找到 .app 文件。"
                fi
                
                # 推出嵌套DMG
                echo "  正在推出嵌套DMG: $(basename "$MANUAL_INSTALL_DMG")..."
                sleep 1
                if sudo hdiutil detach "$NESTED_MOUNT_POINT" -quiet 2>/dev/null; then
                  echo "  ✅ 嵌套DMG推出完成。"
                else
                  sudo hdiutil detach "$NESTED_MOUNT_POINT" -force -quiet 2>/dev/null || true
                  echo "  ✅ 嵌套DMG强制推出完成。"
                fi
              else
                echo "  ❌ 无法确定嵌套DMG挂载点"
              fi
            fi
          else
            echo "  ❌ 在DMG中未找到 .app 文件、Manual install目录或嵌套DMG文件。"
            echo "  📁 DMG内容列表："
            ls -la "$MOUNT_POINT" | head -10
          fi
        fi
      fi
      
      echo "  正在推出DMG: $filename..."
      sleep 1
      if sudo hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null; then
        echo "  ✅ DMG推出完成。"
      else
        sudo hdiutil detach "$MOUNT_POINT" -force -quiet 2>/dev/null || true
        echo "  ✅ DMG强制推出完成。"
      fi
      ;;
      
    "pkg")
      echo "  [类型: PKG] - 准备安装..."
      sudo installer -pkg "$installer_path" -target /
      echo "  ✅ PKG 安装成功。"
      ;;
      
    "zip")
      echo "  [类型: ZIP] - 移除隔离属性..."
      sudo xattr -r -d com.apple.quarantine "$installer_path" 2>/dev/null || true
      echo "  [类型: ZIP] - 正在解压..."
      unzip -q "$installer_path" -d temp_extract
      
      # 在解压后的内容中移除隔离属性
      sudo xattr -r -d com.apple.quarantine temp_extract 2>/dev/null || true
      
      # 查找 .app 文件（支持更深层次搜索）
      APP_PATH=$(find temp_extract -name "*.app" -maxdepth 5 -print -quit)
      
      if [ -n "$APP_PATH" ]; then
        APP_NAME=$(basename "$APP_PATH")
        TARGET_APP_PATH="$APPLICATIONS_DIR/$APP_NAME"
        echo "  🔍 找到应用: $APP_NAME"
        
        if [ -d "$TARGET_APP_PATH" ]; then
          echo "  🟡 应用 '$APP_NAME' 已存在，跳过安装。"
        else
          echo "  正在将 '$APP_NAME' 拷贝到 $APPLICATIONS_DIR ..."
          sudo cp -R "$APP_PATH" "$APPLICATIONS_DIR/"
          echo "  ✅ 拷贝完成。"
          
          # 移除应用的隔离属性
          echo "  正在移除应用的隔离属性..."
          sudo xattr -r -d com.apple.quarantine "$TARGET_APP_PATH" 2>/dev/null || true
          echo "  ✅ 隔离属性移除完成。"
        fi
      else
        # 检查是否有嵌套的ZIP或DMG文件
        echo "  🔍 未找到 .app 文件，检查嵌套结构..."
        
        NESTED_ZIP=$(find temp_extract -name "*.zip" | head -1)
        NESTED_DMG=$(find temp_extract -name "*.dmg" | head -1)
        NESTED_PKG=$(find temp_extract -name "*.pkg" | head -1)
        
        if [ -n "$NESTED_ZIP" ]; then
          echo "  📦 发现嵌套ZIP: $(basename "$NESTED_ZIP")"
          echo "  📦 正在解压嵌套ZIP..."
          unzip -q "$NESTED_ZIP" -d temp_extract/nested
          
          NESTED_APP_PATH=$(find temp_extract/nested -name "*.app" -maxdepth 3 -print -quit)
          if [ -n "$NESTED_APP_PATH" ]; then
            APP_NAME=$(basename "$NESTED_APP_PATH")
            TARGET_APP_PATH="$APPLICATIONS_DIR/$APP_NAME"
            echo "  🔍 在嵌套ZIP中找到应用: $APP_NAME"
            
            if [ -d "$TARGET_APP_PATH" ]; then
              echo "  🟡 应用 '$APP_NAME' 已存在，跳过安装。"
            else
              echo "  正在将 '$APP_NAME' 拷贝到 $APPLICATIONS_DIR ..."
              sudo cp -R "$NESTED_APP_PATH" "$APPLICATIONS_DIR/"
              echo "  ✅ 拷贝完成。"
            fi
          else
            echo "  ❌ 在嵌套ZIP中也未找到 .app 文件。"
          fi
        elif [ -n "$NESTED_DMG" ]; then
          echo "  📦 发现嵌套DMG: $(basename "$NESTED_DMG")"
          echo "  📦 正在挂载嵌套DMG..."
          
          # 移除嵌套DMG的隔离属性
          sudo xattr -r -d com.apple.quarantine "$NESTED_DMG" 2>/dev/null || true
          
          NESTED_HDIUTIL_OUTPUT=$(sudo hdiutil attach "$NESTED_DMG" -nobrowse -owners on 2>&1)
          NESTED_HDIUTIL_EXIT_CODE=$?
          
          if [ $NESTED_HDIUTIL_EXIT_CODE -ne 0 ]; then
            echo "  ❌ 嵌套DMG挂载失败"
          else
            NESTED_MOUNT_POINT=$(echo "$NESTED_HDIUTIL_OUTPUT" | grep '/Volumes/' | tail -1 | sed 's/.*\(\/Volumes\/.*\)$/\1/' | sed 's/[[:space:]]*$//')
            
            if [ -n "$NESTED_MOUNT_POINT" ] && [ -d "$NESTED_MOUNT_POINT" ]; then
              echo "  ✅ 嵌套DMG已挂载到: $NESTED_MOUNT_POINT"
              
              NESTED_APP_PATH=$(find "$NESTED_MOUNT_POINT" -name "*.app" -maxdepth 3 -print -quit)
              
              if [ -n "$NESTED_APP_PATH" ]; then
                APP_NAME=$(basename "$NESTED_APP_PATH")
                TARGET_APP_PATH="$APPLICATIONS_DIR/$APP_NAME"
                echo "  🔍 在嵌套DMG中找到应用: $APP_NAME"
                
                if [ -d "$TARGET_APP_PATH" ]; then
                  echo "  🟡 应用 '$APP_NAME' 已存在，跳过安装。"
                else
                  echo "  正在将 '$APP_NAME' 拷贝到 $APPLICATIONS_DIR ..."
                  sudo cp -R "$NESTED_APP_PATH" "$APPLICATIONS_DIR/"
                  echo "  ✅ 拷贝完成。"
                fi
              else
                echo "  ❌ 在嵌套DMG中也未找到 .app 文件。"
              fi
              
              # 推出嵌套DMG
              echo "  正在推出嵌套DMG: $(basename "$NESTED_DMG")..."
              sleep 1
              if sudo hdiutil detach "$NESTED_MOUNT_POINT" -quiet 2>/dev/null; then
                echo "  ✅ 嵌套DMG推出完成。"
              else
                sudo hdiutil detach "$NESTED_MOUNT_POINT" -force -quiet 2>/dev/null || true
                echo "  ✅ 嵌套DMG强制推出完成。"
              fi
            else
              echo "  ❌ 无法确定嵌套DMG挂载点"
            fi
          fi
        elif [ -n "$NESTED_PKG" ]; then
          echo "  📦 发现PKG: $(basename "$NESTED_PKG")"
          echo "  📦 正在安装PKG..."
          sudo installer -pkg "$NESTED_PKG" -target /
          echo "  ✅ PKG安装成功。"
        else
          echo "  ❌ 在ZIP中未找到 .app 文件或嵌套文件。"
          echo "  📁 ZIP内容列表："
          find temp_extract -type f | head -10
        fi
      fi
      
      rm -rf temp_extract
      ;;
      
    "app")
      echo "  [类型: APP] - 直接安装应用..."
      APP_NAME=$(basename "$installer_path")
      TARGET_APP_PATH="$APPLICATIONS_DIR/$APP_NAME"
      
      if [ -d "$TARGET_APP_PATH" ]; then
        echo "  🟡 应用 '$APP_NAME' 已存在，跳过安装。"
      else
        echo "  正在将 '$APP_NAME' 拷贝到 $APPLICATIONS_DIR ..."
        sudo cp -R "$installer_path" "$APPLICATIONS_DIR/"
        echo "  ✅ 拷贝完成。"
        
        # 移除应用的隔离属性
        echo "  正在移除应用的隔离属性..."
        sudo xattr -r -d com.apple.quarantine "$TARGET_APP_PATH" 2>/dev/null || true
        echo "  ✅ 隔离属性移除完成。"
      fi
      ;;
      
    *)
      echo "  🟡 [类型: $extension] - 跳过，不支持的文件类型。"
      ;;
  esac
done

echo ""
echo "========================================"
echo "✅ 所有软件安装任务已执行完毕！"
echo "========================================"
EOF
}


# 直接安装选中的文件
run_direct_installation() {
    log "开始执行安装..."
    
    # 提前验证sudo权限，提供更友好的提示
    echo ""
    echo -e "${BLUE}🔐 权限验证${NC}"
    echo "================================"
    echo -e "${YELLOW}📋 说明：${NC}"
    echo "   • 安装应用程序需要管理员权限"
    echo "   • 用于挂载/推出DMG文件和复制应用到 Applications 文件夹"
    echo ""
    
    info "请输入管理员密码："
    
    # 尝试获取 sudo 权限，最多尝试3次
    local attempts=0
    local max_attempts=3
    
    while [ $attempts -lt $max_attempts ]; do
        if sudo -v; then
            log "✅ 管理员权限验证成功"
            break
        else
            ((attempts++))
            if [ $attempts -lt $max_attempts ]; then
                echo -e "${YELLOW}验证失败，请重试 (剩余 $((max_attempts - attempts)) 次机会)${NC}"
            else
                error "无法获取管理员权限，安装终止"
                echo -e "${YELLOW}💡 请确保：${NC}"
                echo "   • 当前用户具有管理员权限"
                echo "   • 正确输入了管理员密码"
                exit 1
            fi
        fi
    done
    
    echo "================================"
    echo ""
    
    # 保持sudo权限有效
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    
    echo ""
    echo "🔔 叮当装正在为您安装应用..."
    echo "========================================"
    
    # 直接处理选中的文件
    for installer_path in "${selected_local_files[@]}"; do
        [ -e "$installer_path" ] || continue
        
        filename=$(basename "$installer_path")
        extension="${filename##*.}"
        
        echo ""
        echo "----------------------------------------"
        echo "⚙️  正在处理: $filename"
        echo "----------------------------------------"
        
        # 直接调用安装逻辑
        case "$extension" in
            "dmg")
                install_dmg_file "$installer_path"
                ;;
            "pkg")
                install_pkg_file "$installer_path"
                ;;
            "zip")
                install_zip_file "$installer_path"
                ;;
            "app")
                install_app_file "$installer_path"
                ;;
            *)
                echo "  🟡 [类型: $extension] - 跳过，不支持的文件类型。"
                bypassed_installs+=("$filename (不支持的文件类型: $extension)")
                ;;
        esac
    done
    
    echo ""
    echo "========================================"
    echo "✅ 所有软件安装任务已执行完毕！"
    echo "========================================"
}


# 处理加密DMG重试
handle_encrypted_dmg_retry() {
    if [ ${#encrypted_dmg_files[@]} -eq 0 ]; then
        return 0
    fi
    
    echo ""
    echo "========================================"
    echo "🔐 发现加密DMG文件"
    echo "========================================"
    echo ""
    echo -e "${YELLOW}📋 在安装过程中跳过了以下加密DMG文件：${NC}"
    echo "----------------------------------------"
    
    local count=1
    for dmg_file in "${encrypted_dmg_files[@]}"; do
        local filename=$(basename "$dmg_file")
        echo "  $count. $filename"
        ((count++))
    done
    
    echo ""
    echo -e "${BLUE}💡 选项说明：${NC}"
    echo "  • 这些文件需要密码才能打开"
    echo "  • 可以选择重试安装（每个文件有2次密码输入机会）"
    echo "  • 密码错误2次后会自动跳过该文件"
    echo "  • 或者您可以选择稍后手动处理"
    echo ""
    
    while true; do
        echo -e "${YELLOW}是否要重试安装这些加密DMG文件？${NC} [y/n/s]"
        echo "  y) 是，尝试重试安装（每个文件2次机会）"
        echo "  n) 否，跳过这些文件"
        echo "  s) 显示详细文件路径"
        echo ""
        read -p "请选择 (y/n/s): " -r choice
        
        case $choice in
            [Yy]*)
                echo ""
                echo -e "${BLUE}🔄 开始重试加密DMG文件...${NC}"
                echo -e "${YELLOW}💡 提示：每个文件有2次密码输入机会，错误2次后自动跳过${NC}"
                echo "========================================"
                
                for dmg_file in "${encrypted_dmg_files[@]}"; do
                    local filename=$(basename "$dmg_file")
                    echo ""
                    echo "----------------------------------------"
                    echo "⚙️  重试处理: $filename"
                    echo "----------------------------------------"
                    
                    if handle_encrypted_dmg "$dmg_file"; then
                        # 成功解密，继续安装逻辑
                        echo "  ✅ 成功解密，继续安装..."
                        
                        # 获取挂载点
                        local mount_point=$(echo "$HDIUTIL_OUTPUT" | grep '/Volumes/' | tail -1 | sed 's/.*\(\/Volumes\/.*\)$/\1/' | sed 's/[[:space:]]*$//')
                        
                        if [ -n "$mount_point" ] && [ -d "$mount_point" ]; then
                            # 执行安装逻辑（简化版）
                            local pkg_files=()
                            while IFS= read -r -d '' file; do
                                pkg_files+=("$file")
                            done < <(find "$mount_point" -maxdepth 1 -name "*.pkg" -type f -print0)
                            if [ ${#pkg_files[@]} -gt 0 ]; then
                                for pkg_file in "${pkg_files[@]}"; do
                                    local pkg_name=$(basename "$pkg_file")
                                    echo "  📦 正在安装PKG: $pkg_name"
                                    if sudo installer -pkg "$pkg_file" -target /; then
                                        echo "  ✅ PKG安装成功: $pkg_name"
                                        successful_installs+=("$pkg_name (从加密DMG重试)")
                                    else
                                        echo "  ❌ PKG安装失败: $pkg_name"
                                        failed_installs+=("$filename (加密DMG重试，PKG安装失败)")
                                    fi
                                done
                            else
                                local app_files=()
                                while IFS= read -r -d '' file; do
                                    app_files+=("$file")
                                done < <(find "$mount_point" -maxdepth 1 -name "*.app" -type d -print0)
                                if [ ${#app_files[@]} -gt 0 ]; then
                                    for app_path in "${app_files[@]}"; do
                                        local app_name=$(basename "$app_path")
                                        local target_app_path="/Applications/$app_name"
                                        if [ -d "$target_app_path" ]; then
                                            echo "  🟡 应用 '$app_name' 已存在，跳过安装。"
                                        else
                                            echo "  正在将 '$app_name' 拷贝到 /Applications ..."
                                            if sudo cp -R "$app_path" "/Applications/"; then
                                                echo "  ✅ 拷贝完成: $app_name"
                                                sudo xattr -r -d com.apple.quarantine "$target_app_path" 2>/dev/null || true
                                                successful_installs+=("$app_name (从加密DMG重试)")
                                            else
                                                echo "  ❌ 拷贝失败: $app_name"
                                                failed_installs+=("$filename (加密DMG重试，应用拷贝失败)")
                                            fi
                                        fi
                                    done
                                else
                                    echo "  ❌ 未找到 .app 或 .pkg 文件"
                                    failed_installs+=("$filename (加密DMG重试，未找到安装文件)")
                                fi
                            fi
                            
                            # 安全推出DMG
                            safe_detach_dmg "$mount_point" "$filename"
                        else
                            echo "  ❌ 无法确定挂载点"
                            failed_installs+=("$filename (加密DMG重试，无法确定挂载点)")
                        fi
                    else
                        echo "  ❌ 重试失败或密码错误2次后自动跳过"
                        failed_installs+=("$filename (加密DMG重试失败或密码错误)")
                    fi
                done
                
                echo ""
                echo "========================================"
                echo "✅ 加密DMG重试完成！"
                echo "========================================"
                break
                ;;
            [Nn]*)
                echo ""
                echo -e "${YELLOW}📝 已跳过加密DMG文件${NC}"
                echo -e "${BLUE}💡 您可以稍后手动处理这些文件${NC}"
                break
                ;;
            [Ss]*)
                echo ""
                echo -e "${BLUE}📁 加密DMG文件详细路径：${NC}"
                echo "----------------------------------------"
                local count=1
                for dmg_file in "${encrypted_dmg_files[@]}"; do
                    echo "  $count. $dmg_file"
                    ((count++))
                done
                echo ""
                continue
                ;;
            *)
                echo -e "${RED}请输入有效选项：y (是)、n (否)、s (显示路径)${NC}"
                echo ""
                continue
                ;;
        esac
    done
    
    echo ""
}

# 显示安装汇总报告
show_installation_summary() {
    echo ""
    echo "========================================"
    echo "📋 安装汇总报告"
    echo "========================================"
    
    local total_processed=$((${#successful_installs[@]} + ${#bypassed_installs[@]} + ${#failed_installs[@]}))
    
    echo -e "${BLUE}📊 总体统计${NC}"
    echo "----------------------------------------"
    echo "  总处理数量: $total_processed"
    echo "  成功安装: ${#successful_installs[@]}"
    echo "  跳过安装: ${#bypassed_installs[@]}"
    echo "  失败安装: ${#failed_installs[@]}"
    if [ ${#encrypted_dmg_files[@]} -gt 0 ]; then
        echo "  加密DMG: ${#encrypted_dmg_files[@]}"
    fi
    echo ""
    
    # 显示成功安装的应用
    if [ ${#successful_installs[@]} -gt 0 ]; then
        echo -e "${GREEN}✅ 成功安装 (${#successful_installs[@]})${NC}"
        echo "----------------------------------------"
        for app in "${successful_installs[@]}"; do
            echo "  • $app"
        done
        echo ""
    fi
    
    # 显示跳过的安装（包含异常标注）
    if [ ${#bypassed_installs[@]} -gt 0 ]; then
        local anomaly_count=0
        for app in "${bypassed_installs[@]}"; do
            if [[ "$app" == *"异常:"* ]]; then
                ((anomaly_count++))
            fi
        done
        
        if [ $anomaly_count -gt 0 ]; then
            echo -e "${YELLOW}⏭️  跳过安装 (${#bypassed_installs[@]}) ${RED}⚠️ 包含 $anomaly_count 个异常${NC}"
        else
            echo -e "${YELLOW}⏭️  跳过安装 (${#bypassed_installs[@]})${NC}"
        fi
        echo "----------------------------------------"
        
        for app in "${bypassed_installs[@]}"; do
            if [[ "$app" == *"异常:"* ]]; then
                echo -e "  • ${RED}⚠️  $app${NC}"
            else
                echo "  • $app"
            fi
        done
        echo ""
    fi
    
    # 显示失败的安装
    if [ ${#failed_installs[@]} -gt 0 ]; then
        echo -e "${RED}❌ 失败安装 (${#failed_installs[@]})${NC}"
        echo "----------------------------------------"
        for app in "${failed_installs[@]}"; do
            echo "  • $app"
        done
        echo ""
    fi
    
    echo "========================================"
    
    # 根据结果显示不同的完成消息
    if [ ${#failed_installs[@]} -eq 0 ]; then
        if [ ${#successful_installs[@]} -gt 0 ]; then
            echo -e "${GREEN}🎉 所有应用安装成功！${NC}"
        else
            echo -e "${YELLOW}📝 没有新的应用需要安装${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  部分应用安装失败，请检查上述失败列表${NC}"
    fi
    
    echo ""
}

# 显示使用帮助
show_help() {
    echo "🔔 叮当装 InstallFlow - Mac 批量安装工具"
    echo ""
    echo "用法: $0 [选项] [安装包目录]"
    echo ""
    echo "选项："
    echo "  -h, --help     显示此帮助信息"
    echo ""
    echo "参数："
    echo "  安装包目录     包含 .dmg/.pkg/.zip/.app 文件的目录路径（可选）"
    echo "                如果不提供，将进入交互式模式提示用户输入"
    echo ""
    echo "功能："
    echo "  • 🎯 交互式选择界面，默认全选所有软件包"
    echo "  • ⌨️  方向键 ↑↓ 移动光标，空格键切换选择状态"
    echo "  • 🔄 Ctrl+A 全选，Ctrl+N 全不选"
    echo "  • ✅ 支持 .dmg、.pkg、.zip、.app 格式"
    echo "  • 🔍 智能检测TNT团队软件包（嵌套DMG结构）"
    echo "  • 📁 递归遍历子目录中的安装包"
    echo "  • 🔐 自动移除应用的隔离属性（quarantine）"
    echo "  • 📦 支持ZIP中的PKG安装包"
    echo "  • 🚀 自动安装所有选中的软件包"
    echo "  • 🤖 Apple Silicon Mac自动检测并安装Rosetta"
    echo "  • 🔓 智能绕过加密DMG文件（尝试常见密码）"
    echo "  • 📊 PKG安装检测，避免重复安装"
    echo "  • 📋 详细的安装汇总报告"
    echo ""
    echo "示例："
    echo "  $0                                          # 交互式模式"
    echo "  $0 /Users/fiber/dev/install_workflow/installers   # 直接指定路径"
    echo "  $0 ~/Downloads/mac_apps                     # 使用相对路径"
    echo ""
}

# 主函数
main() {
    # 解析参数
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_help
        exit 0
    fi
    
    parse_arguments "$@"
    show_welcome
    check_requirements
    show_package_menu
    run_direct_installation
    
    # 显示安装汇总报告
    show_installation_summary
    
    # 处理加密DMG重试
    handle_encrypted_dmg_retry
}


# 运行主函数
main "$@"