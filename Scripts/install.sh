#!/bin/bash
# ==============================================================================
# InstallFlow (叮当装) - macOS 批量应用安装脚本
# ==============================================================================
# 功能说明：
#   这是一个专业的 macOS 应用批量安装工具，支持多种安装包格式，
#   提供交互式选择界面，具备智能版本管理和嵌套结构处理能力。
#
# 支持格式：.dmg, .iso, .pkg, .zip, .app
# 主要特性：
#   - 交互式包选择器（支持键盘导航）
#   - 智能版本检测和更新
#   - 嵌套安装包处理（支持DMG中嵌套DMG等复杂结构）
#   - sudo权限保活机制
#   - Apple Silicon 兼容性检查
#   - 详细的安装结果报告
# ==============================================================================

# ====================================
# 颜色定义 - 用于终端彩色输出
# ====================================
RED='\033[0;31m'      # 红色 - 错误信息
GREEN='\033[0;32m'    # 绿色 - 成功信息
YELLOW='\033[1;33m'   # 黄色 - 警告信息
BLUE='\033[0;34m'     # 蓝色 - 普通信息
NC='\033[0m'          # 无颜色 - 重置颜色

# ====================================
# 日志输出函数 - 提供带时间戳的彩色日志
# ====================================

# 成功日志输出（绿色）
log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] $1${NC}"
}

# 警告日志输出（黄色）
warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARN: $1${NC}"
}

# 错误日志输出（红色）
error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ERROR: $1${NC}"
}

# 信息日志输出（蓝色）
info() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')] INFO: $1${NC}"
}

# ====================================
# 全局变量定义
# ====================================

# 本地安装包目录路径
LOCAL_INSTALLERS_DIR=""

# sudo权限保活进程的PID
SUDO_KEEPALIVE_PID=""

# 安装结果统计数组
declare -a successful_installs=()  # 成功安装的应用列表
declare -a bypassed_installs=()    # 跳过安装的应用列表（已存在或版本更高）
declare -a failed_installs=()      # 安装失败的应用列表
declare -a updated_installs=()     # 版本更新的应用列表

# ====================================
# sudo权限管理函数
# ====================================

# 启动sudo权限保活进程
# 功能：在后台定期刷新sudo权限，防止在安装过程中权限过期
start_sudo_keepalive() {
    # 如果已存在保活进程，先停止它
    if [ -n "$SUDO_KEEPALIVE_PID" ] && kill -0 "$SUDO_KEEPALIVE_PID" 2>/dev/null; then
        stop_sudo_keepalive
    fi
    
    # 在后台启动保活进程
    (
        while true; do
            sleep 240                    # 每4分钟执行一次
            sudo -v 2>/dev/null || break # 刷新sudo权限，失败则退出循环
        done
    ) &
    
    # 保存后台进程PID
    SUDO_KEEPALIVE_PID=$!
    export SUDO_KEEPALIVE_PID
    log "已启动sudo权限保活进程 (PID: $SUDO_KEEPALIVE_PID)"
}

# 停止sudo权限保活进程
# 功能：清理后台保活进程，释放系统资源
stop_sudo_keepalive() {
    if [ -n "$SUDO_KEEPALIVE_PID" ]; then
        # 检查进程是否存在
        if kill -0 "$SUDO_KEEPALIVE_PID" 2>/dev/null; then
            kill "$SUDO_KEEPALIVE_PID" 2>/dev/null  # 终止保活进程
            log "已停止sudo权限保活进程"
        fi
        SUDO_KEEPALIVE_PID=""  # 清空PID变量
    fi
}

# ====================================
# 清理和信号处理
# ====================================

# 脚本退出时的清理函数
# 功能：确保在脚本退出时正确清理资源
cleanup_on_exit() {
    stop_sudo_keepalive  # 停止sudo保活进程
}

# 注册信号处理器：在脚本退出、中断或终止时执行清理
# EXIT: 正常退出  INT: Ctrl+C中断  TERM: 终止信号
trap cleanup_on_exit EXIT INT TERM

# ====================================
# 命令行参数处理
# ====================================

# 解析命令行参数
# 功能：处理用户提供的安装包目录路径，或提示用户输入
parse_arguments() {
    # 如果没有提供参数，则进入交互式模式
    if [ $# -eq 0 ]; then
        prompt_for_folder
        return
    fi
    
    # 获取第一个参数作为安装包目录路径
    local installers_path="$1"
    # 将波浪线符号替换为用户主目录路径
    installers_path="${installers_path/#\~/$HOME}"
    
    # 检查目录是否存在
    if [ ! -d "$installers_path" ]; then
        error "指定的目录不存在: $installers_path"
        exit 1
    fi
    
    # 统计支持的安装包文件数量（排除隐藏文件和系统文件）
    local package_count=$(find "$installers_path" \( -name "*.dmg" -o -name "*.iso" -o -name "*.pkg" -o -name "*.zip" \) ! -name "._*" ! -name ".DS_Store" | wc -l)
    
    # 检查是否找到安装包
    if [ "$package_count" -eq 0 ]; then
        error "指定目录中没有找到安装包文件 (.dmg, .iso, .pkg, .zip)"
        exit 1
    else
        # 设置全局变量并记录结果
        LOCAL_INSTALLERS_DIR="$installers_path"
        log "发现 $package_count 个本地安装包"
    fi
}

# 提示用户输入文件夹路径
# 功能：显示友好的交互界面，引导用户提供安装包目录
prompt_for_folder() {
    echo ""
    # 显示品牌标识和欢迎信息（精美的ASCII边框）
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}║                   叮当装 InstallFlow                         ║${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}║         一键批量安装 Mac 应用，让装机像叮当一样简单          ║${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # 用户操作指导
    echo -e "${YELLOW}请提供安装包所在的文件夹路径：${NC}"
    echo ""
    echo -e "${GREEN}操作提示：${NC}"
    echo "   1. 在 Finder 中找到包含安装包的文件夹"
    echo "   2. 将文件夹直接拖拽到这个终端窗口"
    echo "   3. 按回车键确认"
    echo ""
    echo -e "${BLUE}支持的文件类型：${NC} .dmg、.iso、.pkg、.zip、.app"
    echo ""
    
    # 循环提示用户输入，直到获得有效的目录路径
    while true; do
        echo -n "请输入或拖拽文件夹路径: "
        read -r installers_path
        
        # 检查是否为空输入
        if [ -z "$installers_path" ]; then
            echo -e "${YELLOW}WARN:  请输入文件夹路径或将文件夹拖拽到终端窗口${NC}"
            continue
        fi
        
        # 清理输入路径：去除首尾空格和引号
        installers_path=$(echo "$installers_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//')
        # 将波浪线替换为用户主目录
        installers_path="${installers_path/#\~/$HOME}"
        # 检查目录是否存在
        if [ ! -d "$installers_path" ]; then
            error "指定的目录不存在: $installers_path"
            echo -e "${YELLOW}请重新输入正确的文件夹路径${NC}"
            echo ""
            continue
        fi
        
        # 统计安装包数量（包括.app文件）
        local package_count=$(find "$installers_path" \( -name "*.dmg" -o -name "*.iso" -o -name "*.pkg" -o -name "*.zip" -o -name "*.app" \) ! -name "._*" ! -name ".DS_Store" | wc -l)
        
        # 检查是否找到安装包
        if [ "$package_count" -eq 0 ]; then
            error "指定目录中没有找到安装包文件 (.dmg, .iso, .pkg, .zip, .app)"
            echo -e "${YELLOW}请选择包含安装包的文件夹${NC}"
            echo ""
            continue
        else
            # 设置全局变量并退出循环
            LOCAL_INSTALLERS_DIR="$installers_path"
            log "发现 $package_count 个安装包文件"
            echo ""
            break
        fi
    done
}

show_welcome() {
    if [ -n "$LOCAL_INSTALLERS_DIR" ]; then
        echo ""
        echo -e "${GREEN}本地安装包目录: $LOCAL_INSTALLERS_DIR${NC}"
        echo ""
    fi
}

# 显示欢迎信息
# 功能：在存在本地安装包目录时显示目录路径
show_welcome() {
    if [ -n "$LOCAL_INSTALLERS_DIR" ]; then
        echo ""
        echo -e "${GREEN}本地安装包目录: $LOCAL_INSTALLERS_DIR${NC}"
        echo ""
    fi
}

# ====================================
# 系统兼容性检查
# ====================================

# 检查Rosetta转译层状态
# 功能：在Apple Silicon Mac上检查是否安装Rosetta，用于运行Intel应用
check_rosetta_status() {
    # 获取系统架构信息
    local arch=$(uname -m)
    # 如果不是Apple Silicon（arm64）架构，则无需Rosetta
    if [[ "$arch" != "arm64" ]]; then
        log "检测到Intel Mac，无需Rosetta"
        return 0
    fi
    
    log "检测到Apple Silicon Mac，正在检查Rosetta状态..."
    
    # 尝试运行x86_64指令来检查Rosetta是否已安装
    if arch -x86_64 /usr/bin/true 2>/dev/null; then
        log "Rosetta已安装"
        return 0
    fi
    
    # Rosetta未安装，显示警告信息和安装选项
    echo ""
    echo -e "${BLUE}Rosetta检测${NC}"
    echo "================================"
    echo -e "${YELLOW}WARN:  Rosetta未安装${NC}"
    echo ""
    echo -e "${BLUE}说明：${NC}"
    echo "   • 检测到Apple Silicon Mac，但未安装Rosetta"
    echo "   • 某些应用可能需要Rosetta才能运行"
    echo "   • 建议现在安装Rosetta以确保兼容性"
    echo ""
    
    # 循环提示用户选择是否安装Rosetta
    while true; do
        local rosetta_choice
        # 读取用户选择（默认为是）
        read -p "是否要安装Rosetta？[默认: y] (y/n): " -r rosetta_choice
        case $rosetta_choice in
            [Nn]*)
                # 用户选择不安装Rosetta
                echo ""
                echo -e "${YELLOW}跳过Rosetta安装${NC}"
                echo -e "${YELLOW}WARN:  注意：某些Intel应用可能无法运行${NC}"
                echo ""
                break
                ;;
            [Yy]*|"")
                # 用户选择安装Rosetta（默认选项）
                echo ""
                echo -e "${BLUE}正在安装Rosetta...${NC}"
                echo -e "${YELLOW}提示：安装过程可能需要几分钟时间${NC}"
                echo ""
                
                # 使用系统软件更新工具安装Rosetta（自动同意许可协议）
                if sudo softwareupdate --install-rosetta --agree-to-license; then
                    echo ""
                    echo -e "${GREEN}Rosetta安装成功${NC}"
                    log "Rosetta安装完成"
                else
                    # Rosetta安装失败，警告用户可能影响
                    echo ""
                    echo -e "${RED}Rosetta安装失败${NC}"
                    warn "继续安装可能导致某些应用无法运行"
                fi
                echo ""
                break
                ;;
            *)
                # 无效输入，提示用户重新输入
                echo "请输入 y (是) 或 n (否)"
                ;;
        esac
    done
    echo "================================"
    echo ""
}

# 检查系统要求和环境
# 功能：验证操作系统、Rosetta状态和管理员权限
check_requirements() {
    log "检查系统要求..."
    
    # 检查操作系统类型，确保是macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        error "此脚本仅支持 macOS 系统"
        exit 1
    fi
    
    log "系统检查通过"
    
    # 检查Rosetta兼容性（仅限Apple Silicon Mac）
    check_rosetta_status
    
    # 检查是否为交互式终端环境
    if tty -s; then
        log "获取管理员权限..."
        # 验证sudo权限，必须成功才能继续
        if ! sudo -v; then
            error "需要管理员权限才能安装PKG格式的软件包"
            exit 1
        fi
        # 启动sudo权限保活机制
        start_sudo_keepalive
    else
        # 非交互式环境（如脚本调用），在需要时再请求权限
        log "非交互式环境，将在需要时请求权限"
    fi
}

# ====================================
# 交互式包选择器
# ====================================

# 交互式软件包选择器
# 功能：提供全功能的终端界面，支持键盘导航、多选、分页显示
interactive_package_selector() {
    # 检查是否为交互式环境
    if ! tty -s; then
        warn "检测到非交互式环境，将自动选择所有软件包进行安装"
        selected_local_files=("${package_files_list[@]}")
        return
    fi
    # 初始化变量
    local packages=("${packages_list[@]}")      # 应用名称列表
    local package_files=("${package_files_list[@]}")  # 文件路径列表
    local total=${#packages[@]}                 # 总数量
    
    # 检查是否有可用包
    if [ $total -eq 0 ]; then
        warn "没有找到可用的安装包"
        exit 1
    fi
    
    # 初始化选择状态（默认全选）
    local selected=()
    for i in $(seq 0 $((total-1))); do
        selected[i]=1  # 1=已选中，0=未选中
    done
    
    # 界面控制变量
    local cursor=0         # 当前光标位置
    local page_size=30     # 每页显示的项目数
    local page_start=0     # 当前页面的起始索引
    
    # 隐藏光标并禁用回显，为交互做准备
    printf '\e[?25l'   # 隐藏终端光标
    stty -echo         # 禁用键盘输入回显
    
    # 清理函数：恢复终端状态
    cleanup_selector() {
        printf '\e[?25h'  # 显示光标
        stty echo         # 恢复回显
    }
    # 注册清理函数，确保退出时恢复终端状态
    trap cleanup_selector EXIT
    
    while true; do
        clear
        echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║                    选择要安装的软件包                        ║${NC}"
        echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${YELLOW}使用方向键 ↑↓ 移动光标，空格键 ␣ 切换选择，回车键 ⏎ 确认${NC}"
        echo -e "${YELLOW}   Ctrl+A 全选，Ctrl+N 全不选，ESC 或 q 退出${NC}"
        echo ""
        local page_end=$((page_start + page_size - 1))
        if [ $page_end -ge $total ]; then
            page_end=$((total - 1))
        fi
        for i in $(seq $page_start $page_end); do
            local prefix=""
            local suffix=""
            local status_icon=""
            if [ "${selected[i]}" -eq 1 ]; then
                status_icon="${GREEN}[x]${NC}"
            else
                status_icon="${RED}[ ]${NC}"
            fi
            if [ $i -eq $cursor ]; then
                prefix="${BLUE}> ${NC}"
                suffix="${BLUE} <${NC}"
            else
                prefix="  "
                suffix=""
            fi
            
            echo -e "${prefix}[${status_icon}] ${packages[i]}${suffix}"
        done
        if [ $total -gt $page_size ]; then
            echo ""
            echo -e "${YELLOW}第 $((page_start/page_size + 1)) 页，共 $(((total-1)/page_size + 1)) 页${NC}"
        fi
        local selected_count=0
        for i in $(seq 0 $((total-1))); do
            if [ "${selected[i]}" -eq 1 ]; then
                ((selected_count++))
            fi
        done
        
        echo ""
        echo -e "${GREEN}已选择: $selected_count / $total${NC}"
        old_stty_cfg=$(stty -g)
        stty raw -echo
        key=$(dd bs=1 count=1 2>/dev/null)
        key_hex=$(printf '%s' "$key" | hexdump -ve '1/1 "%02x"')
        
        stty $old_stty_cfg
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
        case "$key_hex" in
            "20")
                if [ "${selected[cursor]}" -eq 1 ]; then
                    selected[cursor]=0
                else
                    selected[cursor]=1
                fi
                ;;
            "0a"|"0d"|"")
                if [ -z "$key" ] && [ "$key_hex" = "" ]; then
                    break
                elif [ "$key_hex" = "0a" ] || [ "$key_hex" = "0d" ]; then
                    break
                fi
                ;;
        esac
        case "$key" in
            'UP'|'k')
                if [ $cursor -gt 0 ]; then
                    ((cursor--))
                    if [ $cursor -lt $page_start ]; then
                        page_start=$((cursor / page_size * page_size))
                    fi
                fi
                ;;
            'DOWN'|'j')
                if [ $cursor -lt $((total-1)) ]; then
                    ((cursor++))
                    if [ $cursor -gt $page_end ]; then
                        page_start=$(((cursor / page_size) * page_size))
                    fi
                fi
                ;;
            $'\x01')
                for i in $(seq 0 $((total-1))); do
                    selected[i]=1
                done
                ;;
            $'\x0e')
                for i in $(seq 0 $((total-1))); do
                    selected[i]=0
                done
                ;;
            'ESC'|'q')
                cleanup_selector
                log "用户取消安装"
                exit 0
                ;;
        esac
    done
    cleanup_selector
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

# ====================================
# 包分析和处理函数
# ====================================

# 分析本地安装包
# 功能：扫描目录中的安装文件，提取应用名称并创建列表
analyze_local_packages() {
    
    log "分析本地安装包..."
    
    # 初始化全局列表数组
    packages_list=()       # 存储清理后的应用名称
    package_files_list=()  # 存储对应的文件路径
    
    # 使用临时文件存储find结果，避免命令替换问题
    local temp_file="/tmp/packages_list_$$"  # 唯一临时文件名
    # 查找所有支持的安装文件格式，排除系统隐藏文件
    find "$LOCAL_INSTALLERS_DIR" \( -name "*.dmg" -o -name "*.iso" -o -name "*.pkg" -o -name "*.zip" -o -name "*.app" \) ! -name "._*" ! -name ".DS_Store" > "$temp_file"
    
    # 逐行处理找到的文件
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            local filename=$(basename "$file")          # 获取文件名
            local name_without_ext="${filename%.*}"     # 移除文件扩展名
            # 清理应用名称：移除版本号、将下划线替换为空格、去除尾部空格
            local clean_name=$(echo "$name_without_ext" | sed 's/[0-9\.-]*$//' | sed 's/[-_]/ /g' | sed 's/ *$//')
            
            # 添加到全局列表
            packages_list+=("$clean_name")
            package_files_list+=("$file")
        fi
    done < "$temp_file"
    
    # 清理临时文件
    rm -f "$temp_file"
    # 调用交互式选择器
    interactive_package_selector
}

# 显示包选择菜单
# 功能：封装包分析流程的入口函数
show_package_menu() {
    analyze_local_packages
}

# ====================================
# 嵌套结构处理和版本管理
# ====================================

# 挂载和处理嵌套DMG文件
# 功能：处理DMG中嵌套的DMG文件，支持多层嵌套结构
mount_and_process_nested_dmg() {
    # 参数解析
    local dmg_path="$1"          # 嵌套DMG文件路径
    local parent_type="$2"       # 父文件类型（DMG/ISO/ZIP）
    local parent_filename="$3"   # 父文件名
    local depth="${4:-1}"        # 嵌套深度（默认1）
    local max_depth=5            # 最大嵌套深度限制
    
    local dmg_name=$(basename "$dmg_path")
    
    # 检查嵌套深度，防止无限循环
    if [ $depth -gt $max_depth ]; then
        echo "  ✗ 嵌套深度超过限制($max_depth)，跳过: $dmg_name"
        failed_installs+=("$parent_filename (嵌套DMG深度超过限制)")
        return 1
    fi
    
    echo "  处理嵌套DMG: $dmg_name"
    
    # 尝试挂载嵌套DMG文件
    local NESTED_MOUNT_POINT=$(mount_dmg_with_retry "$dmg_path" "$dmg_name")
    # 检查挂载是否成功
    if [ $? -ne 0 ] || [ -z "$NESTED_MOUNT_POINT" ]; then
        failed_installs+=("$parent_filename (嵌套DMG挂载失败: $dmg_name)")
        return 1
    fi
    
    if [ -n "$NESTED_MOUNT_POINT" ] && [ -d "$NESTED_MOUNT_POINT" ]; then
        
        local DEEPER_DMG=$(find "$NESTED_MOUNT_POINT" -name "*.dmg" -maxdepth 2 -print -quit 2>/dev/null)
        
        if [ -n "$DEEPER_DMG" ]; then
            echo "  [PKG] 发现更深层DMG文件，递归处理..."
            mount_and_process_nested_dmg "$DEEPER_DMG" "${parent_type}" "$parent_filename" $((depth + 1))
        else
            local NESTED_PKG_PATH=""
            shopt -s nullglob
            pkg_files=("$NESTED_MOUNT_POINT"/*.pkg)
            if [ ${#pkg_files[@]} -gt 0 ] && [ -f "${pkg_files[0]}" ]; then
                NESTED_PKG_PATH="${pkg_files[0]}"
            fi
            shopt -u nullglob
            
            if [ -n "$NESTED_PKG_PATH" ] && [ -f "$NESTED_PKG_PATH" ]; then
                echo "  正在安装PKG..."
                
                if sudo installer -pkg "$NESTED_PKG_PATH" -target /; then
                    echo "  ✓ PKG安装成功"
                    local pkg_name=$(basename "$NESTED_PKG_PATH" .pkg)
                    successful_installs+=("$pkg_name (嵌套安装)")
                else
                    echo "  ✗ PKG安装失败"
                    failed_installs+=("$parent_filename (嵌套DMG中的PKG安装失败)")
                fi
            fi
            
            if [ -z "$NESTED_PKG_PATH" ]; then
                local NESTED_APP_PATH=$(filter_uninstall_apps "$NESTED_MOUNT_POINT" "false")
                
                if [ -n "$NESTED_APP_PATH" ]; then
                    local APP_NAME=$(basename "$NESTED_APP_PATH")
                    echo "  找到应用: $APP_NAME"
                    
                    if check_app_installation "$NESTED_APP_PATH" "$parent_filename"; then
                        local TARGET_APP_PATH="/Applications/$APP_NAME"
                        if cp -R "$NESTED_APP_PATH" "/Applications/"; then
                            xattr -r -d com.apple.quarantine "$TARGET_APP_PATH" 2>/dev/null || true
                            
                            echo "  ✓ 安装成功"
                            successful_installs+=("$APP_NAME (嵌套安装)")
                        else
                            echo "  ✗ 安装失败 - 拷贝错误"
                            failed_installs+=("$parent_filename (${parent_type}嵌套DMG应用拷贝失败: $APP_NAME)")
                        fi
                    fi
                else
                    search_nested_install_directory "$NESTED_MOUNT_POINT" "DMG" "$parent_filename"
                fi
            fi
        fi
        
        sleep 1
        if ! hdiutil detach "$NESTED_MOUNT_POINT" -quiet 2>/dev/null; then
            sudo hdiutil detach "$NESTED_MOUNT_POINT" -force -quiet 2>/dev/null || true
        fi
    fi
}

search_nested_install_directory() {
    local mount_point="$1"
    local file_type="$2"
    local filename="$3"
    
    local install_dirs=$(find "$mount_point" \( \
        -name "*[Mm]anual*install*" -o \
        -name "*[Ii]nstall*" -o \
        -name "*[Cc]ontents*" -o \
        -name "*[Aa]pplications*" -o \
        -name "*[Aa]pp*" -o \
        -name "*[Ss]oftware*" -o \
        -name "*[Pp]rogram*" -o \
        -name "*[Rr]esources*" \
        \) -type d -maxdepth 3 2>/dev/null)
    
    if [ -n "$install_dirs" ]; then
        local INSTALL_DIR=$(echo "$install_dirs" | head -1)
        echo "  [DIR] 发现嵌套安装结构，找到安装目录: $(basename "$INSTALL_DIR")"
        
        local NESTED_DMG=$(find "$INSTALL_DIR" -name "*.dmg" 2>/dev/null | head -1)
        
        if [ -n "$NESTED_DMG" ]; then
            mount_and_process_nested_dmg "$NESTED_DMG" "$file_type" "$filename"
        else
            local INSTALL_PKG_PATH=$(find "$INSTALL_DIR" -name "*.pkg" -type f -print -quit 2>/dev/null)
            
            if [ -n "$INSTALL_PKG_PATH" ] && [ -f "$INSTALL_PKG_PATH" ]; then
                echo "  正在安装PKG..."
                
                if sudo installer -pkg "$INSTALL_PKG_PATH" -target /; then
                    echo "  ✓ PKG安装成功"
                    local pkg_name=$(basename "$INSTALL_PKG_PATH" .pkg)
                    successful_installs+=("$pkg_name (嵌套安装)")
                else
                    echo "  ✗ PKG安装失败"
                    failed_installs+=("$filename (${file_type}嵌套目录中的PKG安装失败)")
                fi
            fi
            
            if [ -z "$INSTALL_PKG_PATH" ]; then
                local INSTALL_APP_PATH=$(filter_uninstall_apps "$INSTALL_DIR" "false")
                
                if [ -n "$INSTALL_APP_PATH" ]; then
                    local APP_NAME=$(basename "$INSTALL_APP_PATH")
                    echo "  找到应用: $APP_NAME"
                    
                    if check_app_installation "$INSTALL_APP_PATH" "$filename"; then
                        local TARGET_APP_PATH="/Applications/$APP_NAME"
                        if cp -R "$INSTALL_APP_PATH" "/Applications/"; then
                            xattr -r -d com.apple.quarantine "$TARGET_APP_PATH" 2>/dev/null || true
                            
                            echo "  ✓ 安装成功"
                            successful_installs+=("$APP_NAME (嵌套安装)")
                        else
                            echo "  ✗ 安装失败 - 拷贝错误"
                            failed_installs+=("$filename (${file_type}嵌套目录应用拷贝失败: $APP_NAME)")
                        fi
                    fi
                else
                    echo "  ✗ 在安装目录中也未找到.app文件"
                    echo "  [DEBUG] 安装目录内容:"
                    if [ -d "$INSTALL_DIR" ]; then
                        ls -la "$INSTALL_DIR" 2>/dev/null | head -10 | sed 's/^/    /'
                    else
                        echo "    安装目录不存在: $INSTALL_DIR"
                    fi
                    echo "  [DEBUG] 递归搜索.app文件:"
                    if [ -d "$INSTALL_DIR" ]; then
                        find "$INSTALL_DIR" -name "*.app" -type d 2>/dev/null | head -5 | sed 's/^/    /' || echo "    未找到.app文件"
                    fi
                    failed_installs+=("$filename (${file_type}安装目录中未找到.app文件)")
                fi
            fi
        fi
    else
        echo "  [DEBUG] 未找到嵌套安装结构，显示${file_type}内容:"
        echo "  [DEBUG] 根目录内容:"
        if [ -d "$mount_point" ]; then
            ls -la "$mount_point" 2>/dev/null | head -10 | sed 's/^/    /'
        else
            echo "    挂载点不存在: $mount_point"
        fi
        echo "  [DEBUG] 搜索所有.app文件:"
        if [ -d "$mount_point" ]; then
            find "$mount_point" -name "*.app" -type d 2>/dev/null | head -5 | sed 's/^/    /' || echo "    未找到.app文件"
        fi
        echo "  [DEBUG] 搜索所有子目录:"
        if [ -d "$mount_point" ]; then
            find "$mount_point" -type d -maxdepth 2 2>/dev/null | head -10 | sed 's/^/    /' || echo "    未找到子目录"
        fi
        failed_installs+=("$filename (${file_type}中未找到.app文件)")
    fi
}

# 获取应用程序版本号
# 功能：从.app包的Info.plist文件中读取版本信息
get_app_version() {
    local app_path="$1"  # .app包的路径
    local version=""
    
    # 检查.app包是否存在
    if [ -d "$app_path" ]; then
        local info_plist="$app_path/Contents/Info.plist"
        # 检查Info.plist文件是否存在
        if [ -f "$info_plist" ]; then
            # 首先尝试获取CFBundleShortVersionString（显示版本）
            version=$(defaults read "$info_plist" CFBundleShortVersionString 2>/dev/null || echo "")
            # 如果没有，则尝试CFBundleVersion（构建版本）
            if [ -z "$version" ]; then
                version=$(defaults read "$info_plist" CFBundleVersion 2>/dev/null || echo "")
            fi
        fi
    fi
    
    echo "$version"  # 返回版本号字符串
}

# 比较两个版本号的大小
# 功能：使用语义化版本比较，支持多级版本号
compare_versions() {
    local version1="$1"  # 第一个版本号
    local version2="$2"  # 第二个版本号
    
    # 如果任意一个版本为空，返回0（相等）
    if [ -z "$version1" ] || [ -z "$version2" ]; then
        echo "0"
        return
    fi
    
    # 使用sort -V进行语义化版本排序，获取较小的版本
    local result=$(printf '%s\n%s\n' "$version1" "$version2" | sort -V | head -n1)
    
    # 比较结果并返回相应值
    if [ "$result" = "$version1" ]; then
        if [ "$version1" = "$version2" ]; then
            echo "0"   # 相等
        else
            echo "-1"  # version1 < version2
        fi
    else
        echo "1"      # version1 > version2
    fi
}

# 检查应用安装状态和版本比较
# 功能：检查目标应用是否已存在，并比较版本决定是否需要更新
check_app_installation() {
    local new_app_path="$1"   # 新应用的路径
    local filename="$2"       # 文件名（用于错误报告）
    
    local app_name=$(basename "$new_app_path")    # 应用名称
    local target_app_path="/Applications/$app_name"  # 目标安装路径
    
    # 检查目标位置是否已存在相同应用
    if [ -d "$target_app_path" ]; then
        echo "  检测到应用 '$app_name' 已存在"
        
        # 获取现有和新版本号
        local existing_version=$(get_app_version "$target_app_path")
        local new_version=$(get_app_version "$new_app_path")
        
        echo "  现有版本: ${existing_version:-未知}"
        echo "  新版本:   ${new_version:-未知}"
        
        # 只有在两个版本号都可获取时才进行比较
        if [ -n "$existing_version" ] && [ -n "$new_version" ]; then
            local comparison=$(compare_versions "$new_version" "$existing_version")
            
            # 根据版本比较结果决定操作
            case $comparison in
                "1")
                    # 新版本更高，执行更新
                    echo "  检测到新版本，自动更新: $existing_version → $new_version"
                    updated_installs+=("$app_name: $existing_version → $new_version")
                    return 0
                    ;;
                "0")
                    # 版本相同，跳过安装
                    echo "  版本相同，跳过安装"
                    bypassed_installs+=("$filename (相同版本已存在: $existing_version)")
                    return 1
                    ;;
                "-1")
                    # 现有版本更高，跳过安装
                    echo "  现有版本更高，跳过安装"
                    bypassed_installs+=("$filename (更高版本已存在: $existing_version)")
                    return 1
                    ;;
            esac
        else
            # 无法获取版本信息，为安全起见跳过安装
            echo "  无法获取版本信息，跳过安装"
            bypassed_installs+=("$filename (应用已存在，版本未知)")
            return 1
        fi
    else
        # 应用未安装，可以继续安装
        return 0
    fi
}

filter_uninstall_apps() {
    local mount_point="$1"
    local has_pkg="$2"
    
    if [ "$has_pkg" = "true" ]; then
        find "$mount_point" -name "*.app" -type d -maxdepth 3 2>/dev/null | \
        grep -v -i "uninstall\|remove\|cleaner\|delete\|uninst" | head -1
    else
        find "$mount_point" -name "*.app" -type d -maxdepth 3 -print -quit 2>/dev/null
    fi
}

mount_dmg_with_retry() {
    local installer_path="$1"
    local filename="$2"
    local max_attempts="${3:-3}"
    
    for attempt in $(seq 1 $max_attempts); do        
        local mount_output=$(yes | hdiutil attach "$installer_path" -nobrowse -noverify 2>&1)
        local mount_result=$?
        
        if [ $mount_result -eq 0 ] && [ -n "$mount_output" ]; then
            local mount_point=$(echo "$mount_output" | grep '/Volumes/' | sed -E 's/.*\t([^[:space:]]+.*)/\1/' | tail -n1)
            
            if [ -n "$mount_point" ] && [ -d "$mount_point" ]; then
                echo "$mount_point"
                return 0
            fi
        fi
        
        if [ $attempt -lt $max_attempts ]; then
            sleep 3
        fi
    done
    
    echo "  错误: DMG挂载失败 ($filename)" >&2
    return 1
}

# ====================================
# 各种文件格式安装函数
# ====================================

# 安装DMG文件
# 功能：挂载DMG文件，处理其中PKG或APP内容，支持嵌套结构
install_dmg_file() {
    local installer_path="$1"  # DMG文件路径
    local filename=$(basename "$installer_path")  # 文件名
    
    MOUNT_POINT=$(mount_dmg_with_retry "$installer_path" "$filename")
    if [ $? -ne 0 ] || [ -z "$MOUNT_POINT" ]; then
        failed_installs+=("$filename (DMG挂载失败)")
        return 1
    fi
    
    PKG_PATH=""
    shopt -s nullglob
    pkg_files=("$MOUNT_POINT"/*.pkg)
    if [ ${#pkg_files[@]} -gt 0 ] && [ -f "${pkg_files[0]}" ]; then
        PKG_PATH="${pkg_files[0]}"
    fi
    shopt -u nullglob
    
    if [ -n "$PKG_PATH" ] && [ -f "$PKG_PATH" ]; then
        PKG_NAME=$(basename "$PKG_PATH")
        echo "  正在安装PKG..."
        
        if sudo installer -pkg "$PKG_PATH" -target /; then
            echo "  ✓ PKG安装成功"
            local pkg_name=$(basename "$PKG_PATH" .pkg)
            successful_installs+=("$pkg_name (从DMG中的PKG)")
        else
            echo "  ✗ PKG安装失败"
            failed_installs+=("$filename (DMG中的PKG安装失败)")
        fi
    fi
    
    if [ -z "$PKG_PATH" ]; then
        local NESTED_DMG=$(find "$MOUNT_POINT" -name "*.dmg" -maxdepth 2 -print -quit 2>/dev/null)
        
        if [ -n "$NESTED_DMG" ]; then
            echo "  [PKG] 在DMG中发现嵌套DMG文件: $(basename "$NESTED_DMG")"
            mount_and_process_nested_dmg "$NESTED_DMG" "DMG" "$filename" 1
        else
            local has_pkg="false"
            if [ -n "$PKG_PATH" ]; then
                has_pkg="true"
            fi
            APP_PATH=$(filter_uninstall_apps "$MOUNT_POINT" "$has_pkg")
            
            if [ -n "$APP_PATH" ]; then
                APP_NAME=$(basename "$APP_PATH")
                
                if check_app_installation "$APP_PATH" "$filename"; then
                    TARGET_APP_PATH="/Applications/$APP_NAME"
                    if cp -R "$APP_PATH" "/Applications/"; then
                        xattr -r -d com.apple.quarantine "$TARGET_APP_PATH" 2>/dev/null || true
                        
                        echo "  ✓ 安装成功"
                        successful_installs+=("$APP_NAME (从DMG)")
                    else
                        echo "  ✗ 安装失败 - 拷贝错误"
                        failed_installs+=("$filename (应用拷贝失败: $APP_NAME)")
                    fi
                fi
            else
                search_nested_install_directory "$MOUNT_POINT" "DMG" "$filename"
            fi
        fi
    fi
    
    sleep 1
    if ! hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null; then
        if ! sudo hdiutil detach "$MOUNT_POINT" -force -quiet 2>/dev/null; then
            warn "DMG推出失败，但这不影响正常使用"
        fi
    fi
}

install_iso_file() {
    local installer_path="$1"
    local filename=$(basename "$installer_path")
    
    MOUNT_POINT=$(mount_dmg_with_retry "$installer_path" "$filename")
    if [ $? -ne 0 ] || [ -z "$MOUNT_POINT" ]; then
        failed_installs+=("$filename (ISO挂载失败)")
        return 1
    fi
    
    local DMG_PATH=""
    shopt -s nullglob
    dmg_files=("$MOUNT_POINT"/*.dmg)
    if [ ${#dmg_files[@]} -gt 0 ] && [ -f "${dmg_files[0]}" ]; then
        DMG_PATH="${dmg_files[0]}"
    fi
    shopt -u nullglob
    
    if [ -n "$DMG_PATH" ]; then
        echo "  [PKG] 在ISO中发现DMG文件: $(basename "$DMG_PATH")"
        mount_and_process_nested_dmg "$DMG_PATH" "ISO" "$filename" 1
    else
        PKG_PATH=""
        shopt -s nullglob
        pkg_files=("$MOUNT_POINT"/*.pkg)
        if [ ${#pkg_files[@]} -gt 0 ] && [ -f "${pkg_files[0]}" ]; then
            PKG_PATH="${pkg_files[0]}"
        fi
        shopt -u nullglob
        
        if [ -n "$PKG_PATH" ] && [ -f "$PKG_PATH" ]; then
            PKG_NAME=$(basename "$PKG_PATH")
            echo "  正在安装PKG..."
            
            if sudo installer -pkg "$PKG_PATH" -target /; then
                echo "  ✓ PKG安装成功"
                local pkg_name=$(basename "$PKG_PATH" .pkg)
                successful_installs+=("$pkg_name (从ISO中的PKG)")
            else
                echo "  ✗ PKG安装失败"
                failed_installs+=("$filename (ISO中的PKG安装失败)")
            fi
        fi
        
        if [ -z "$PKG_PATH" ]; then
            local has_pkg="false"
            if [ -n "$PKG_PATH" ]; then
                has_pkg="true"
            fi
            APP_PATH=$(filter_uninstall_apps "$MOUNT_POINT" "$has_pkg")
            
            if [ -n "$APP_PATH" ]; then
                APP_NAME=$(basename "$APP_PATH")
                
                if check_app_installation "$APP_PATH" "$filename"; then
                    TARGET_APP_PATH="/Applications/$APP_NAME"
                    if cp -R "$APP_PATH" "/Applications/"; then
                        xattr -r -d com.apple.quarantine "$TARGET_APP_PATH" 2>/dev/null || true
                        
                        echo "  ✓ 安装成功"
                        successful_installs+=("$APP_NAME (从ISO)")
                    else
                        echo "  ✗ 安装失败 - 拷贝错误"
                        failed_installs+=("$filename (应用拷贝失败: $APP_NAME)")
                    fi
                fi
            else
                search_nested_install_directory "$MOUNT_POINT" "ISO" "$filename"
            fi
        fi
    fi
    
    sleep 1
    if ! hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null; then
        if ! sudo hdiutil detach "$MOUNT_POINT" -force -quiet 2>/dev/null; then
            warn "ISO推出失败，但这不影响正常使用"
        fi
    fi
}

# 安装PKG文件
# 功能：直接使用installer命令安装PKG文件
install_pkg_file() {
    local installer_path="$1"  # PKG文件路径
    local filename=$(basename "$installer_path")  # 文件名
    
    echo "  正在安装PKG..."
    
    if sudo installer -pkg "$installer_path" -target /; then
        echo "  ✓ PKG安装成功"
        local pkg_name=$(basename "$installer_path" .pkg)
        successful_installs+=("$pkg_name")
    else
        echo "  ✗ PKG安装失败"
        failed_installs+=("$filename (PKG安装失败)")
    fi
}

install_zip_file() {
    local installer_path="$1"
    local filename=$(basename "$installer_path")
    
    echo "  [类型: ZIP] - 正在处理..."
    
    local temp_dir="/tmp/install_zip_$$"
    mkdir -p "$temp_dir"
    
    if unzip -q "$installer_path" -d "$temp_dir"; then
        echo "  ZIP解压完成"
        
        local dmg_path=$(find "$temp_dir" -name "*.dmg" -type f -print -quit 2>/dev/null)
        if [ -n "$dmg_path" ]; then
            mount_and_process_nested_dmg "$dmg_path" "ZIP" "$filename"
        else
            local pkg_path=$(find "$temp_dir" -name "*.pkg" -type f -print -quit 2>/dev/null)
            if [ -n "$pkg_path" ]; then
                echo "  正在安装PKG..."
                if sudo installer -pkg "$pkg_path" -target /; then
                    echo "  ✓ PKG安装成功"
                    local pkg_name=$(basename "$pkg_path" .pkg)
                    successful_installs+=("$pkg_name (从ZIP中的PKG)")
                else
                    echo "  ✗ PKG安装失败"
                    failed_installs+=("$filename (ZIP中的PKG安装失败)")
                fi
            else
                local has_pkg="false"
                if [ -n "$pkg_path" ]; then
                    has_pkg="true"
                fi
                local app_path=$(filter_uninstall_apps "$temp_dir" "$has_pkg")
                if [ -n "$app_path" ]; then
                    local app_name=$(basename "$app_path")
                    
                    if check_app_installation "$app_path" "$filename"; then
                        local target_app_path="/Applications/$app_name"
                        if cp -R "$app_path" "/Applications/"; then
                            xattr -r -d com.apple.quarantine "$target_app_path" 2>/dev/null || true
                            
                            echo "  ✓ 安装成功"
                            successful_installs+=("$app_name (从ZIP)")
                        else
                            echo "  ✗ 安装失败 - 拷贝错误"
                            failed_installs+=("$filename (ZIP应用拷贝失败: $app_name)")
                        fi
                    fi
                else
                    echo "  ✗ ZIP文件中未找到可安装文件"
                    failed_installs+=("$filename (ZIP中未找到DMG/PKG/APP文件)")
                fi
            fi
        fi
    else
        echo "  ✗ ZIP解压失败"
        failed_installs+=("$filename (ZIP解压失败)")
    fi
    
    rm -rf "$temp_dir"
}

install_app_file() {
    local installer_path="$1"
    local filename=$(basename "$installer_path")
    local app_name=$(basename "$installer_path")
    
    echo "  [类型: APP] - 正在处理..."
    
    if check_app_installation "$installer_path" "$filename"; then
        local target_app_path="/Applications/$app_name"
        if cp -R "$installer_path" "/Applications/"; then
            xattr -r -d com.apple.quarantine "$target_app_path" 2>/dev/null || true
            
            echo "  ✓ 安装成功"
            successful_installs+=("$app_name (直接拷贝)")
        else
            echo "  ✗ 安装失败 - 拷贝错误"
            failed_installs+=("$filename (APP拷贝失败)")
        fi
    fi
}

install_local_packages() {
    local total=${#selected_local_files[@]}
    local current=1
    
    log "开始安装本地安装包..."
    
    for file in "${selected_local_files[@]}"; do
        local filename=$(basename "$file")
        echo ""
        echo "[$current/$total] 正在处理: $filename"
        
        case "${file##*.}" in
            dmg)
                install_dmg_file "$file"
                ;;
            iso)
                install_iso_file "$file"
                ;;
            pkg)
                install_pkg_file "$file"
                ;;
            zip)
                install_zip_file "$file"
                ;;
            app)
                install_app_file "$file"
                ;;
            *)
                warn "不支持的文件类型: $filename"
                failed_installs+=("$filename (不支持的文件类型)")
                ;;
        esac
        
        ((current++))
    done
}

# ====================================
# 安装结果报告和主函数
# ====================================

# 显示安装结果摘要
# 功能：统计并显示所有安装结果，包括成功、失败、跳过和更新的应用
show_install_summary() {
    echo ""
    # 显示报告标题
    echo "════════════════════════════════════════════════════════════════"
    echo -e "${BLUE}                        安装结果摘要${NC}"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    
    # 显示成功安装的应用列表
    if [ ${#successful_installs[@]} -gt 0 ]; then
        echo -e "${GREEN}[OK] 成功安装 (${#successful_installs[@]}个):${NC}"
        for app in "${successful_installs[@]}"; do
            echo -e "   • ${GREEN}$app${NC}"
        done
        echo ""
    fi
    
    # 显示版本更新的应用列表
    if [ ${#updated_installs[@]} -gt 0 ]; then
        echo -e "${BLUE}[UPDATE] 版本更新 (${#updated_installs[@]}个):${NC}"
        for update in "${updated_installs[@]}"; do
            echo -e "   • ${BLUE}$update${NC}"
        done
        echo ""
    fi
    
    # 显示跳过安装的应用列表
    if [ ${#bypassed_installs[@]} -gt 0 ]; then
        echo -e "${YELLOW}[SKIP] 跳过安装 (${#bypassed_installs[@]}个):${NC}"
        for bypass in "${bypassed_installs[@]}"; do
            echo -e "   • ${YELLOW}$bypass${NC}"
        done
        echo ""
    fi
    
    # 显示安装失败的应用列表
    if [ ${#failed_installs[@]} -gt 0 ]; then
        echo -e "${RED}✗ 安装失败 (${#failed_installs[@]}个):${NC}"
        for failure in "${failed_installs[@]}"; do
            echo -e "   • ${RED}$failure${NC}"
        done
        echo ""
    fi
    
    # 计算统计数据
    local total_processed=$((${#successful_installs[@]} + ${#bypassed_installs[@]} + ${#failed_installs[@]}))
    local success_rate=0
    if [ $total_processed -gt 0 ]; then
        # 成功率 = (成功 + 跳过) / 总数 * 100
        success_rate=$(( (${#successful_installs[@]} + ${#bypassed_installs[@]}) * 100 / total_processed ))
    fi
    
    # 显示统计信息
    echo "════════════════════════════════════════════════════════════════"
    echo -e "${BLUE}统计信息:${NC}"
    echo -e "   处理总数: $total_processed"
    echo -e "   成功率:   $success_rate%"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    
    # 根据安装结果显示不同的结束信息
    if [ ${#successful_installs[@]} -gt 0 ] || [ ${#updated_installs[@]} -gt 0 ]; then
        echo -e "${GREEN}✓ 安装完成！所有应用已成功安装到 /Applications 目录。${NC}"
        echo ""
        echo -e "${BLUE}注意事项：${NC}"
        echo "   • 首次打开应用时，macOS 可能会显示安全提示"
        echo "   • 如果应用无法打开，请右键点击应用选择「打开」"
        echo "   • 或在「系统偏好设置 → 安全性与隐私」中允许应用运行"
    else
        # 没有成功安装任何应用
        echo -e "${YELLOW}没有成功安装任何新应用。${NC}"
    fi
    
    echo ""
}

# ====================================
# 主函数 - 程序入口点
# ====================================

# 主函数
# 功能：协调整个安装流程，从环境检查到最终结果展示
main() {
    # 1. 检查系统要求和环境
    check_requirements
    
    # 2. 解析命令行参数或提示用户输入
    parse_arguments "$@"
    
    # 3. 显示欢迎信息
    show_welcome
    
    # 4. 显示包选择菜单并获取用户选择
    show_package_menu
    
    # 5. 执行安装过程
    install_local_packages
    
    # 6. 显示安装结果摘要
    show_install_summary
}

# 启动主函数，传递所有命令行参数
main "$@"