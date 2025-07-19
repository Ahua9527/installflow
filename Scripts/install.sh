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

# Removed set -e and set -o pipefail to prevent script interruption
# when hdiutil returns non-zero exit codes despite successful mounting

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
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARN: $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')] INFO: $1${NC}"
}


# 全局变量
LOCAL_INSTALLERS_DIR=""  # 用户提供的本地安装包目录

# 安装结果追踪数组
declare -a successful_installs=()    # 成功安装的应用
declare -a bypassed_installs=()      # 跳过的安装（已存在、加密绕过等）
declare -a failed_installs=()        # 失败的安装
declare -a updated_installs=()       # 版本更新的应用
declare -a temp_files=()             # 临时文件/目录追踪数组

# 清理函数
cleanup() {
    local temp_resource
    for temp_resource in "${temp_files[@]}"; do
        if [ -e "$temp_resource" ]; then
            rm -rf "$temp_resource" 2>/dev/null || true
        fi
    done
}

# 设置退出陷阱以确保清理
trap cleanup EXIT INT TERM

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
    local package_count=$(find "$installers_path" \( -name "*.dmg" -o -name "*.pkg" -o -name "*.zip" \) ! -name "._*" ! -name ".DS_Store" | wc -l)
    
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
    echo -e "${BLUE}║                   叮当装 InstallFlow                         ║${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}║         一键批量安装 Mac 应用，让装机像叮当一样简单          ║${NC}"
    echo -e "${BLUE}║                                                              ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}请提供安装包所在的文件夹路径：${NC}"
    echo ""
    echo -e "${GREEN}操作提示：${NC}"
    echo "   1. 在 Finder 中找到包含安装包的文件夹"
    echo "   2. 将文件夹直接拖拽到这个终端窗口"
    echo "   3. 按回车键确认"
    echo ""
    echo -e "${BLUE}支持的文件类型：${NC} .dmg、.pkg、.zip、.app"
    echo ""
    
    while true; do
        echo -n "请输入或拖拽文件夹路径: "
        read -r installers_path
        
        # 如果用户输入为空，继续提示
        if [ -z "$installers_path" ]; then
            echo -e "${YELLOW}WARN:  请输入文件夹路径或将文件夹拖拽到终端窗口${NC}"
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
        local package_count=$(find "$installers_path" \( -name "*.dmg" -o -name "*.pkg" -o -name "*.zip" -o -name "*.app" \) ! -name "._*" ! -name ".DS_Store" | wc -l)
        
        if [ "$package_count" -eq 0 ]; then
            error "指定目录中没有找到安装包文件 (.dmg, .pkg, .zip, .app)"
            echo -e "${YELLOW}请选择包含安装包的文件夹${NC}"
            echo ""
            continue
        else
            LOCAL_INSTALLERS_DIR="$installers_path"
            log "发现 $package_count 个安装包文件"
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
        echo -e "${GREEN}本地安装包目录: $LOCAL_INSTALLERS_DIR${NC}"
        echo ""
    fi
}

# 检查Gatekeeper状态
check_gatekeeper_status() {
    log "检查Gatekeeper状态..."
    
    local gatekeeper_status=$(spctl --status 2>/dev/null)
    
    echo ""
    echo -e "${BLUE}Gatekeeper状态检查${NC}"
    echo "================================"
    
    if [ "$gatekeeper_status" = "assessments enabled" ]; then
        echo -e "${YELLOW}WARN:  Gatekeeper状态：已启用${NC}"
        echo ""
        echo -e "${YELLOW}说明：${NC}"
        echo "   • Gatekeeper已启用，系统会验证应用签名"
        echo "   • 安装的应用可能需要额外确认才能运行"
        echo "   • 第三方应用可能显示\"无法打开\"的提示"
        echo ""
        echo -e "${BLUE}建议操作：${NC}"
        echo "   为了顺利安装和运行第三方应用，建议临时关闭Gatekeeper"
        echo ""
        echo -e "${GREEN}好处：${NC}"
        echo "   • 安装的应用可以直接运行，无需额外确认"
        echo "   • 避免\"无法打开应用\"的问题"
        echo "   • 简化安装流程"
        echo ""
        echo -e "${RED}WARN:  注意：${NC}"
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
                    echo -e "${BLUE}如遇到应用无法打开的问题：${NC}"
                    echo -e "     ${BLUE}1.${NC} 右键点击应用 → 选择\"打开\""
                    echo -e "     ${BLUE}2.${NC} 或在\"系统偏好设置 → 安全性与隐私\"中允许"
                    echo ""
                    break
                    ;;
                [Yy]*|"")
                    echo ""
                    echo -e "${BLUE}正在关闭Gatekeeper...${NC}"
                    if sudo spctl --master-disable 2>/dev/null; then
                        echo -e "${GREEN}Gatekeeper已关闭${NC}"
                        echo ""
                        echo -e "${YELLOW}NOTE: 重要提醒：${NC}"
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
        echo -e "${GREEN}Gatekeeper状态：已关闭 - 有利于第三方应用安装${NC}"
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
        log "Rosetta已安装"
        return 0
    fi
    
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
    
    # 询问用户是否要安装Rosetta
    while true; do
        local rosetta_choice
        read -p "是否要安装Rosetta？[默认: y] (y/n): " -r rosetta_choice
        case $rosetta_choice in
            [Nn]*)
                echo ""
                echo -e "${YELLOW}跳过Rosetta安装${NC}"
                echo -e "${YELLOW}WARN:  注意：某些Intel应用可能无法运行${NC}"
                echo ""
                break
                ;;
            [Yy]*|"")
                echo ""
                echo -e "${BLUE}正在安装Rosetta...${NC}"
                echo -e "${YELLOW}提示：安装过程可能需要几分钟时间${NC}"
                echo ""
                
                if sudo softwareupdate --install-rosetta --agree-to-license; then
                    echo ""
                    echo -e "${GREEN}Rosetta安装成功${NC}"
                    log "Rosetta安装完成"
                else
                    echo ""
                    echo -e "${RED}Rosetta安装失败${NC}"
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
    local page_size=30
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
        echo -e "${BLUE}║                    选择要安装的软件包                        ║${NC}"
        echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${YELLOW}使用方向键 ↑↓ 移动光标，空格键 ␣ 切换选择，回车键 ⏎ 确认${NC}"
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
    local temp_file=$(mktemp -t installflow_list.XXXXXX)
    if [ ! -f "$temp_file" ]; then
        error "无法创建临时文件"
        exit 1
    fi
    chmod 600 "$temp_file"  # 只有所有者可读写
    temp_files+=("$temp_file")  # 添加到临时文件追踪数组
    find "$LOCAL_INSTALLERS_DIR" \( -name "*.dmg" -o -name "*.pkg" -o -name "*.zip" -o -name "*.app" \) ! -name "._*" ! -name ".DS_Store" > "$temp_file"
    
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
# 获取APP文件的版本号
get_app_version() {
    local app_path="$1"
    local version=""
    
    if [ -d "$app_path" ]; then
        # 尝试从Info.plist中获取CFBundleShortVersionString
        local info_plist="$app_path/Contents/Info.plist"
        if [ -f "$info_plist" ]; then
            version=$(defaults read "$info_plist" CFBundleShortVersionString 2>/dev/null || echo "")
            if [ -z "$version" ]; then
                # 如果没有CFBundleShortVersionString，尝试CFBundleVersion
                version=$(defaults read "$info_plist" CFBundleVersion 2>/dev/null || echo "")
            fi
        fi
    fi
    
    echo "$version"
}

# 比较版本号 (返回0表示相等，1表示第一个版本更新，-1表示第二个版本更新)
compare_versions() {
    local version1="$1"
    local version2="$2"
    
    # 如果任一版本为空，无法比较
    if [ -z "$version1" ] || [ -z "$version2" ]; then
        echo "0"
        return
    fi
    
    # 使用sort的版本比较功能
    local result=$(printf '%s\n%s\n' "$version1" "$version2" | sort -V | head -n1)
    
    if [ "$result" = "$version1" ]; then
        if [ "$version1" = "$version2" ]; then
            echo "0"  # 相等
        else
            echo "-1"  # version1 < version2
        fi
    else
        echo "1"  # version1 > version2
    fi
}

# 智能APP覆盖检测（带版本号比较）
check_app_installation() {
    local new_app_path="$1"
    local filename="$2"
    
    local app_name=$(basename "$new_app_path")
    local target_app_path="/Applications/$app_name"
    
    # 检查应用是否已存在
    if [ -d "$target_app_path" ]; then
        echo "  检测到应用 '$app_name' 已存在"
        
        # 获取现有应用和新应用的版本号
        local existing_version=$(get_app_version "$target_app_path")
        local new_version=$(get_app_version "$new_app_path")
        
        echo "  现有版本: ${existing_version:-未知}"
        echo "  新版本:   ${new_version:-未知}"
        
        # 如果能获取到版本号，进行比较
        if [ -n "$existing_version" ] && [ -n "$new_version" ]; then
            local comparison=$(compare_versions "$new_version" "$existing_version")
            
            case $comparison in
                "1")
                    echo "  检测到新版本，自动更新: $existing_version → $new_version"
                    # 记录版本更新信息
                    updated_installs+=("$app_name: $existing_version → $new_version")
                    return 0  # 继续安装
                    ;;
                "0")
                    echo "  版本相同，跳过安装"
                    bypassed_installs+=("$filename (相同版本已存在: $existing_version)")
                    return 1
                    ;;
                "-1")
                    echo "  现有版本更高，跳过安装"
                    bypassed_installs+=("$filename (更高版本已存在: $existing_version)")
                    return 1
                    ;;
            esac
        else
            echo "  无法获取版本信息，跳过安装"
            bypassed_installs+=("$filename (应用已存在，版本未知)")
            return 1
        fi
    else
        return 0  # 应用不存在，可以安装
    fi
}

# 安装DMG文件
install_dmg_file() {
    local installer_path="$1"
    local filename=$(basename "$installer_path")
    
    echo "  [类型: DMG] - 移除隔离属性..."
    sudo xattr -r -d com.apple.quarantine "$installer_path" 2>/dev/null || true
    echo "  正在尝试挂载..."
    
    # 获取挂载前的挂载点列表（处理包含空格的路径）
    local mount_before=$(mount | grep "/Volumes" | sed -E 's/^.* on (\/Volumes\/[^(]+) \(.*/\1/' | sed 's/[[:space:]]*$//')
    
    # 使用 yes 命令自动回答许可协议，并重定向输出，添加超时保护
    (yes | hdiutil attach "$installer_path" -nobrowse -noverify > /dev/null 2>&1) &
    local hdiutil_pid=$!
    
    # 等待最多15秒
    local timeout=15
    local count=0
    while [ $count -lt $timeout ]; do
        if ! kill -0 $hdiutil_pid 2>/dev/null; then
            # 进程已结束
            break
        fi
        sleep 1
        count=$((count + 1))
        if [ $count -eq 5 ]; then
            echo "  等待许可协议处理..."
        fi
    done
    
    # 如果进程还在运行，就终止它
    if kill -0 $hdiutil_pid 2>/dev/null; then
        echo "  挂载超时，终止进程..."
        kill $hdiutil_pid 2>/dev/null
        sleep 1
        kill -9 $hdiutil_pid 2>/dev/null
    fi
    
    # 等待一下让挂载完成
    sleep 1
    
    # 获取挂载后的挂载点列表（处理包含空格的路径）
    local mount_after=$(mount | grep "/Volumes" | sed -E 's/^.* on (\/Volumes\/[^(]+) \(.*/\1/' | sed 's/[[:space:]]*$//')
    
    # 找出新增的挂载点
    MOUNT_POINT=""
    while IFS= read -r mount_path; do
        local found=0
        while IFS= read -r existing_mount; do
            if [ "$existing_mount" = "$mount_path" ]; then
                found=1
                break
            fi
        done <<< "$mount_before"
        if [ $found -eq 0 ]; then
            MOUNT_POINT="$mount_path"
            break
        fi
    done <<< "$mount_after"
    
    if [ -n "$MOUNT_POINT" ] && [ -d "$MOUNT_POINT" ]; then
        echo "  ✅ DMG挂载成功"
        echo "  已挂载到: $MOUNT_POINT"
    else
        echo "  ❌ DMG挂载失败: $filename"
        failed_installs+=("$filename (DMG挂载失败)")
        return 1
    fi
    
    # 查找PKG文件
    PKG_PATH=""
    shopt -s nullglob  # 启用nullglob，让glob在没有匹配时返回空
    pkg_files=("$MOUNT_POINT"/*.pkg)
    if [ ${#pkg_files[@]} -gt 0 ] && [ -f "${pkg_files[0]}" ]; then
        PKG_PATH="${pkg_files[0]}"
    fi
    shopt -u nullglob  # 恢复默认设置
    
    # 安装PKG（如果存在）
    if [ -n "$PKG_PATH" ] && [ -f "$PKG_PATH" ]; then
        PKG_NAME=$(basename "$PKG_PATH")
        echo "  发现PKG安装包: $PKG_NAME"
        echo "  正在安装PKG..."
        
        if sudo installer -pkg "$PKG_PATH" -target /; then
            echo "  PKG安装成功"
            local pkg_name=$(basename "$PKG_PATH" .pkg)
            successful_installs+=("$pkg_name (从DMG中的PKG)")
        else
            echo "  ERROR: PKG安装失败"
            failed_installs+=("$filename (DMG中的PKG安装失败)")
        fi
    fi
    
    # 查找并安装.app文件（只有在没有PKG时）
    if [ -z "$PKG_PATH" ]; then
        echo "  查找 .app 文件..."
        
        APP_PATH=""
        shopt -s nullglob  # 启用nullglob
        app_files=("$MOUNT_POINT"/*.app)
        if [ ${#app_files[@]} -gt 0 ] && [ -d "${app_files[0]}" ]; then
            APP_PATH="${app_files[0]}"
        fi
        shopt -u nullglob  # 恢复默认设置
        
        if [ -n "$APP_PATH" ]; then
            # 常规DMG包含.app文件
            APP_NAME=$(basename "$APP_PATH")
            echo "  找到应用: $APP_NAME"
            
            # 使用智能APP覆盖检测（带版本号比较）
            if check_app_installation "$APP_PATH" "$filename"; then
                TARGET_APP_PATH="/Applications/$APP_NAME"
                echo "  正在将 '$APP_NAME' 拷贝到 /Applications ..."
                if sudo cp -R "$APP_PATH" "/Applications/"; then
                    echo "  拷贝完成。"
                    
                    # 移除应用的隔离属性
                    echo "  正在移除应用的隔离属性..."
                    sudo xattr -r -d com.apple.quarantine "$TARGET_APP_PATH" 2>/dev/null || true
                    echo "  隔离属性移除完成。"
                    
                    successful_installs+=("$APP_NAME (从DMG)")
                else
                    echo "  ERROR: 拷贝失败"
                    failed_installs+=("$filename (应用拷贝失败: $APP_NAME)")
                fi
            fi
        else
            echo "  未找到 .app 文件，检查嵌套安装结构..."
            
            # 查找Manual install目录
            local MANUAL_INSTALL_DIR=$(find "$MOUNT_POINT" -name "*[Mm]anual*install*" -type d 2>/dev/null | head -1)
            
            if [ -n "$MANUAL_INSTALL_DIR" ]; then
                echo "  📁 发现嵌套安装结构，找到安装目录: $(basename "$MANUAL_INSTALL_DIR")"
                
                # 在Manual install目录中查找DMG文件
                local MANUAL_INSTALL_DMG=$(find "$MANUAL_INSTALL_DIR" -name "*.dmg" 2>/dev/null | head -1)
                
                if [ -n "$MANUAL_INSTALL_DMG" ]; then
                    echo "  📦 在安装目录中找到DMG: $(basename "$MANUAL_INSTALL_DMG")"
                    echo "  📦 正在挂载嵌套DMG..."
                    
                    # 获取嵌套DMG挂载前的挂载点列表
                    local nested_mount_before=$(mount | grep "/Volumes" | sed -E 's/^.* on (\/Volumes\/[^(]+) \(.*/\1/' | sed 's/[[:space:]]*$//')
                    
                    # 挂载嵌套的DMG（使用现代化方法）
                    (yes | hdiutil attach "$MANUAL_INSTALL_DMG" -nobrowse -noverify > /dev/null 2>&1) &
                    local nested_hdiutil_pid=$!
                    
                    # 等待最多15秒
                    local nested_timeout=15
                    local nested_count=0
                    while [ $nested_count -lt $nested_timeout ]; do
                        if ! kill -0 $nested_hdiutil_pid 2>/dev/null; then
                            break
                        fi
                        sleep 1
                        ((nested_count++))
                        if [ $nested_count -eq 5 ]; then
                            echo "  等待嵌套DMG挂载..."
                        fi
                    done
                    
                    # 终止进程如果还在运行
                    if kill -0 $nested_hdiutil_pid 2>/dev/null; then
                        kill $nested_hdiutil_pid 2>/dev/null
                        sleep 1
                        kill -9 $nested_hdiutil_pid 2>/dev/null
                    fi
                    
                    sleep 1
                    
                    # 获取嵌套DMG挂载后的挂载点列表
                    local nested_mount_after=$(mount | grep "/Volumes" | sed -E 's/^.* on (\/Volumes\/[^(]+) \(.*/\1/' | sed 's/[[:space:]]*$//')
                    
                    # 找出新增的挂载点
                    local NESTED_MOUNT_POINT=""
                    while IFS= read -r mount_path; do
                        local found=0
                        while IFS= read -r existing_mount; do
                            if [ "$existing_mount" = "$mount_path" ]; then
                                found=1
                                break
                            fi
                        done <<< "$nested_mount_before"
                        if [ $found -eq 0 ]; then
                            NESTED_MOUNT_POINT="$mount_path"
                            break
                        fi
                    done <<< "$nested_mount_after"
                    
                    if [ -n "$NESTED_MOUNT_POINT" ] && [ -d "$NESTED_MOUNT_POINT" ]; then
                        echo "  ✅ 嵌套DMG挂载成功"
                        echo "  已挂载到: $NESTED_MOUNT_POINT"
                        
                        # 在嵌套DMG中查找.app文件
                        local NESTED_APP_PATH=$(find "$NESTED_MOUNT_POINT" -name "*.app" -maxdepth 3 -print -quit 2>/dev/null)
                        
                        if [ -n "$NESTED_APP_PATH" ]; then
                            local APP_NAME=$(basename "$NESTED_APP_PATH")
                            echo "  🔍 在嵌套DMG中找到应用: $APP_NAME"
                            
                            # 使用智能APP覆盖检测
                            if check_app_installation "$NESTED_APP_PATH" "$filename"; then
                                local TARGET_APP_PATH="/Applications/$APP_NAME"
                                echo "  正在将 '$APP_NAME' 拷贝到 /Applications ..."
                                if sudo cp -R "$NESTED_APP_PATH" "/Applications/"; then
                                    echo "  拷贝完成。"
                                    
                                    # 移除应用的隔离属性
                                    echo "  正在移除应用的隔离属性..."
                                    sudo xattr -r -d com.apple.quarantine "$TARGET_APP_PATH" 2>/dev/null || true
                                    echo "  隔离属性移除完成。"
                                    
                                    successful_installs+=("$APP_NAME (嵌套DMG)")
                                else
                                    echo "  ERROR: 拷贝失败"
                                    failed_installs+=("$filename (嵌套DMG应用拷贝失败: $APP_NAME)")
                                fi
                            fi
                        else
                            echo "  ❌ 在嵌套DMG中也未找到 .app 文件。"
                            failed_installs+=("$filename (嵌套DMG中未找到.app文件)")
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
                        echo "  ❌ 嵌套DMG挂载失败"
                        failed_installs+=("$filename (嵌套DMG挂载失败)")
                    fi
                else
                    echo "  🔍 安装目录中未找到DMG文件，直接查找.app文件..."
                    # 直接在安装目录中查找.app文件
                    local MANUAL_APP_PATH=$(find "$MANUAL_INSTALL_DIR" -name "*.app" -maxdepth 3 -print -quit)
                    
                    if [ -n "$MANUAL_APP_PATH" ]; then
                        APP_NAME=$(basename "$MANUAL_APP_PATH")
                        echo "  🔍 在安装目录中找到应用: $APP_NAME"
                        
                        # 使用智能APP覆盖检测
                        if check_app_installation "$MANUAL_APP_PATH" "$filename"; then
                            TARGET_APP_PATH="/Applications/$APP_NAME"
                            echo "  正在将 '$APP_NAME' 拷贝到 /Applications ..."
                            if sudo cp -R "$MANUAL_APP_PATH" "/Applications/"; then
                                echo "  拷贝完成。"
                                
                                # 移除应用的隔离属性
                                echo "  正在移除应用的隔离属性..."
                                sudo xattr -r -d com.apple.quarantine "$TARGET_APP_PATH" 2>/dev/null || true
                                echo "  隔离属性移除完成。"
                                
                                successful_installs+=("$APP_NAME (嵌套安装)")
                            else
                                echo "  ERROR: 拷贝失败"
                                failed_installs+=("$filename (嵌套安装应用拷贝失败: $APP_NAME)")
                            fi
                        fi
                    else
                        echo "  ❌ 在安装目录中也未找到 .app 文件。"
                        failed_installs+=("$filename (安装目录中未找到.app文件)")
                    fi
                fi
            else
                # 查找直接的嵌套DMG文件（作为备用方案）
                echo "  🔍 查找其他嵌套DMG文件..."
                # 首先查找特定模式的DMG
                local MANUAL_INSTALL_DMG=$(find "$MOUNT_POINT" -name "*[Mm]anual*install*.dmg" -o -name "*[Mm]anual*.dmg" -o -name "*install*.dmg" 2>/dev/null | head -1)
                
                # 如果没找到特定模式，查找任何DMG文件（排除当前主DMG）
                if [ -z "$MANUAL_INSTALL_DMG" ]; then
                    echo "  🔍 查找任何嵌套DMG文件..."
                    MANUAL_INSTALL_DMG=$(find "$MOUNT_POINT" -name "*.dmg" -type f 2>/dev/null | head -1)
                fi
                
                if [ -n "$MANUAL_INSTALL_DMG" ]; then
                    echo "  📦 发现嵌套DMG文件: $(basename "$MANUAL_INSTALL_DMG")"
                    echo "  📦 正在挂载嵌套DMG..."
                    
                    # 获取嵌套DMG挂载前的挂载点列表
                    local nested_mount_before=$(mount | grep "/Volumes" | sed -E 's/^.* on (\/Volumes\/[^(]+) \(.*/\1/' | sed 's/[[:space:]]*$//')
                    
                    # 挂载嵌套的DMG（使用现代化方法）
                    (yes | hdiutil attach "$MANUAL_INSTALL_DMG" -nobrowse -noverify > /dev/null 2>&1) &
                    local nested_hdiutil_pid=$!
                    
                    # 等待最多15秒
                    local nested_timeout=15
                    local nested_count=0
                    while [ $nested_count -lt $nested_timeout ]; do
                        if ! kill -0 $nested_hdiutil_pid 2>/dev/null; then
                            break
                        fi
                        sleep 1
                        ((nested_count++))
                        if [ $nested_count -eq 5 ]; then
                            echo "  等待嵌套DMG挂载..."
                        fi
                    done
                    
                    # 终止进程如果还在运行
                    if kill -0 $nested_hdiutil_pid 2>/dev/null; then
                        kill $nested_hdiutil_pid 2>/dev/null
                        sleep 1
                        kill -9 $nested_hdiutil_pid 2>/dev/null
                    fi
                    
                    sleep 1
                    
                    # 获取嵌套DMG挂载后的挂载点列表
                    local nested_mount_after=$(mount | grep "/Volumes" | sed -E 's/^.* on (\/Volumes\/[^(]+) \(.*/\1/' | sed 's/[[:space:]]*$//')
                    
                    # 找出新增的挂载点
                    local NESTED_MOUNT_POINT=""
                    while IFS= read -r mount_path; do
                        local found=0
                        while IFS= read -r existing_mount; do
                            if [ "$existing_mount" = "$mount_path" ]; then
                                found=1
                                break
                            fi
                        done <<< "$nested_mount_before"
                        if [ $found -eq 0 ]; then
                            NESTED_MOUNT_POINT="$mount_path"
                            break
                        fi
                    done <<< "$nested_mount_after"
                    
                    if [ -n "$NESTED_MOUNT_POINT" ] && [ -d "$NESTED_MOUNT_POINT" ]; then
                        echo "  ✅ 嵌套DMG挂载成功"
                        echo "  已挂载到: $NESTED_MOUNT_POINT"
                        
                        # 在嵌套DMG中查找.app文件
                        local NESTED_APP_PATH=$(find "$NESTED_MOUNT_POINT" -name "*.app" -maxdepth 3 -print -quit 2>/dev/null)
                        
                        if [ -n "$NESTED_APP_PATH" ]; then
                            local APP_NAME=$(basename "$NESTED_APP_PATH")
                            echo "  🔍 在嵌套DMG中找到应用: $APP_NAME"
                            
                            # 使用智能APP覆盖检测
                            if check_app_installation "$NESTED_APP_PATH" "$filename"; then
                                local TARGET_APP_PATH="/Applications/$APP_NAME"
                                echo "  正在将 '$APP_NAME' 拷贝到 /Applications ..."
                                if sudo cp -R "$NESTED_APP_PATH" "/Applications/"; then
                                    echo "  拷贝完成。"
                                    
                                    # 移除应用的隔离属性
                                    echo "  正在移除应用的隔离属性..."
                                    sudo xattr -r -d com.apple.quarantine "$TARGET_APP_PATH" 2>/dev/null || true
                                    echo "  隔离属性移除完成。"
                                    
                                    successful_installs+=("$APP_NAME (嵌套DMG)")
                                else
                                    echo "  ERROR: 拷贝失败"
                                    failed_installs+=("$filename (嵌套DMG应用拷贝失败: $APP_NAME)")
                                fi
                            fi
                        else
                            echo "  ❌ 在嵌套DMG中也未找到 .app 文件。"
                            failed_installs+=("$filename (嵌套DMG中未找到.app文件)")
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
                        echo "  ❌ 嵌套DMG挂载失败"
                        failed_installs+=("$filename (嵌套DMG挂载失败)")
                    fi
                else
                    echo "  ❌ 在DMG中未找到 .app 文件、安装目录或嵌套DMG文件。"
                    echo "  📁 DMG内容列表："
                    ls -la "$MOUNT_POINT" | head -10
                    failed_installs+=("$filename (DMG中未找到可安装的内容)")
                fi
            fi
        fi
    fi
    
    # 推出DMG
    echo "  正在推出DMG: $filename..."
    sleep 1
    if sudo hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null; then
        echo "  DMG推出完成。"
    else
        sudo hdiutil detach "$MOUNT_POINT" -force -quiet 2>/dev/null || true
        echo "  DMG强制推出完成。"
    fi
}

# 检查PKG是否已安装
check_pkg_installation() {
    local installer_path="$1"
    local filename=$(basename "$installer_path")
    
    echo "  FIND: 检查PKG是否已安装..."
    
    # 创建临时目录来提取PKG信息
    local temp_dir=$(mktemp -d -t installflow_pkg.XXXXXX)
    if [ ! -d "$temp_dir" ]; then
        echo "  ERROR: 无法创建临时目录"
        return 0  # 默认允许安装
    fi
    chmod 700 "$temp_dir"  # 只有所有者可访问
    temp_files+=("$temp_dir")  # 添加到临时文件追踪数组
    
    # 尝试提取PKG信息
    if pkgutil --expand-full "$installer_path" "$temp_dir" 2>/dev/null; then
        # 查找PackageInfo文件来获取包标识符
        local package_info=$(find "$temp_dir" -name "PackageInfo" -type f | head -1)
        if [ -n "$package_info" ] && [ -f "$package_info" ]; then
            # 提取包标识符
            local pkg_id=$(grep -o 'identifier="[^"]*"' "$package_info" | sed 's/identifier="//;s/"//' | head -1)
            
            if [ -n "$pkg_id" ]; then
                echo "  PKG: 包标识符: $pkg_id"
                
                # 检查包是否已安装
                if pkgutil --pkg-info "$pkg_id" >/dev/null 2>&1; then
                    echo "  WARN: PKG '$pkg_id' 已安装，跳过安装。"
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
    
    echo "  PKG: 正在安装PKG..."
    if sudo installer -pkg "$installer_path" -target /; then
        echo "  PKG 安装成功。"
        
        # 尝试获取包名用于记录
        local pkg_name=$(basename "$installer_path" .pkg)
        successful_installs+=("$pkg_name (PKG)")
    else
        echo "  ERROR: PKG 安装失败。"
        failed_installs+=("$filename (PKG安装失败)")
    fi
}

# 安装APP文件
install_app_file() {
    local installer_path="$1"
    local filename=$(basename "$installer_path")
    
    echo "  [类型: APP] - 直接安装应用..."
    
    # 使用智能APP覆盖检测（带版本号比较）
    if ! check_app_installation "$installer_path" "$filename"; then
        return 0  # 跳过安装
    fi
    
    APP_NAME=$(basename "$installer_path")
    TARGET_APP_PATH="/Applications/$APP_NAME"
    
    echo "  正在将 '$APP_NAME' 拷贝到 /Applications ..."
    if sudo cp -R "$installer_path" "/Applications/"; then
        echo "  拷贝完成。"
        
        # 移除应用的隔离属性
        echo "  正在移除应用的隔离属性..."
        sudo xattr -r -d com.apple.quarantine "$TARGET_APP_PATH" 2>/dev/null || true
        echo "  隔离属性移除完成。"
        
        successful_installs+=("$APP_NAME (直接安装)")
    else
        echo "  ERROR: 拷贝失败"
        failed_installs+=("$filename (应用拷贝失败: $APP_NAME)")
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
    local temp_extract=$(mktemp -d -t installflow_zip.XXXXXX)
    if [ ! -d "$temp_extract" ]; then
        echo "  ERROR: 无法创建临时目录"
        failed_installs+=("$filename (无法创建临时目录)")
        return
    fi
    chmod 700 "$temp_extract"  # 只有所有者可访问
    temp_files+=("$temp_extract")  # 添加到临时文件追踪数组
    
    unzip -q "$installer_path" -d "$temp_extract"
    
    # 在解压后的内容中移除隔离属性
    sudo xattr -r -d com.apple.quarantine "$temp_extract" 2>/dev/null || true
    
    # 查找 .app 文件
    local APP_PATH=$(find "$temp_extract" -name "*.app" -maxdepth 5 ! -name "._*" ! -name ".DS_Store" -print -quit)
    
    if [ -n "$APP_PATH" ]; then
        local APP_NAME=$(basename "$APP_PATH")
        echo "  找到应用: $APP_NAME"
        
        # 使用智能APP覆盖检测（带版本号比较）
        if check_app_installation "$APP_PATH" "$filename"; then
            local TARGET_APP_PATH="/Applications/$APP_NAME"
            echo "  正在将 '$APP_NAME' 拷贝到 /Applications ..."
            if sudo cp -R "$APP_PATH" "/Applications/"; then
                echo "  拷贝完成。"
                
                # 移除应用的隔离属性
                echo "  正在移除应用的隔离属性..."
                sudo xattr -r -d com.apple.quarantine "$TARGET_APP_PATH" 2>/dev/null || true
                echo "  隔离属性移除完成。"
                
                successful_installs+=("$APP_NAME (从ZIP)")
            else
                echo "  ERROR: 拷贝失败"
                failed_installs+=("$filename (应用拷贝失败: $APP_NAME)")
            fi
        fi
    else
        echo "  ERROR: 在ZIP中未找到 .app 文件。"
        failed_installs+=("$filename (ZIP中未找到.app文件)")
    fi
    
    # 清理临时目录
    rm -rf "$temp_extract"
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
    
    # 清空全局安装结果数组
    successful_installs=()
    failed_installs=()
    bypassed_installs=()
    updated_installs=()
    
    # 安装所有选中的文件
    for installer_path in "${selected_local_files[@]}"; do
        [ -e "$installer_path" ] || continue
        
        local filename=$(basename "$installer_path")
        local extension="${filename##*.}"
        
        echo ""
        echo "----------------------------------------"
        echo "正在处理: $filename"
        echo "----------------------------------------"
        
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
                echo "  [类型: $extension] - 跳过，不支持的文件类型。"
                ;;
        esac
    done
    
    # 显示安装总结
    echo ""
    echo "========================================"
    echo "✅ 所有软件安装任务已执行完毕！"
    echo "========================================"
    echo ""
    
    if [ ${#successful_installs[@]} -gt 0 ]; then
        echo -e "${GREEN}✅ 成功安装 (${#successful_installs[@]})：${NC}"
        for install in "${successful_installs[@]}"; do
            echo -e "  ${GREEN}• $install${NC}"
        done
        echo ""
    fi
    
    if [ ${#bypassed_installs[@]} -gt 0 ]; then
        echo -e "${YELLOW}⏭ 跳过安装 (${#bypassed_installs[@]})：${NC}"
        for install in "${bypassed_installs[@]}"; do
            echo -e "  ${YELLOW}• $install${NC}"
        done
        echo ""
    fi
    
    if [ ${#failed_installs[@]} -gt 0 ]; then
        echo -e "${RED}❌ 安装失败 (${#failed_installs[@]})：${NC}"
        for install in "${failed_installs[@]}"; do
            echo -e "  ${RED}• $install${NC}"
        done
        echo ""
    fi
    
    echo "========================================"
}

# 显示安装汇总报告
show_installation_summary() {
    echo ""
    echo -e "${BLUE}📊 安装汇总报告${NC}"
    echo "========================================"
    echo "  成功安装: ${#successful_installs[@]}"
    echo "  版本更新: ${#updated_installs[@]}"
    echo "  跳过安装: ${#bypassed_installs[@]}"
    echo "  失败安装: ${#failed_installs[@]}"
    
    # 显示成功安装的应用
    if [ ${#successful_installs[@]} -gt 0 ]; then
        echo -e "${GREEN}✅ 成功安装 (${#successful_installs[@]})${NC}"
        echo "----------------------------------------"
        for app in "${successful_installs[@]}"; do
            echo "  • $app"
        done
        echo ""
    fi
    
    # 显示版本更新的应用
    if [ ${#updated_installs[@]} -gt 0 ]; then
        echo -e "${BLUE}🔄 版本更新 (${#updated_installs[@]})${NC}"
        echo "----------------------------------------"
        for app in "${updated_installs[@]}"; do
            echo "  • $app"
        done
        echo ""
    fi
    
    # 显示跳过的安装
    if [ ${#bypassed_installs[@]} -gt 0 ]; then
        echo -e "${YELLOW}⏭️  跳过安装 (${#bypassed_installs[@]})${NC}"
        echo "----------------------------------------"
        for app in "${bypassed_installs[@]}"; do
            echo "  • $app"
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
        local total_completed=$((${#successful_installs[@]} + ${#updated_installs[@]}))
        if [ $total_completed -gt 0 ]; then
            if [ ${#updated_installs[@]} -gt 0 ] && [ ${#successful_installs[@]} -gt 0 ]; then
                echo -e "${GREEN}🎉 所有应用处理完成！${NC}（${#successful_installs[@]} 个新安装，${#updated_installs[@]} 个版本更新）"
            elif [ ${#updated_installs[@]} -gt 0 ]; then
                echo -e "${GREEN}🎉 所有应用更新完成！${NC}（${#updated_installs[@]} 个版本更新）"
            else
                echo -e "${GREEN}🎉 所有应用安装成功！${NC}（${#successful_installs[@]} 个新安装）"
            fi
        else
            echo -e "${YELLOW}📝 没有新的应用需要安装或更新${NC}"
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
    echo "  • 🔍 智能检测嵌套DMG结构和特殊安装包"
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
}


# 运行主函数
main "$@"

