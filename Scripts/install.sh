#!/bin/bash

# 启用严格错误处理模式
set -e  # 遇到错误立即退出
set -u  # 使用未定义变量时报错
set -o pipefail  # 管道中任何命令失败都会导致整个管道失败

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
declare -a installed_app_paths=()    # 已安装应用的完整路径追踪数组

# 安全路径验证函数
validate_path_security() {
    local path="$1"
    local context="$2"
    
    # 检查路径是否为空
    if [ -z "$path" ]; then
        error "$context: 路径不能为空"
        return 1
    fi
    
    # 检查路径是否以 - 开头（防止命令注入）
    if [[ "$path" =~ ^- ]]; then
        error "$context: 路径不能以 '-' 开头，这可能是命令注入攻击"
        return 1
    fi
    
    # 检查路径是否包含可疑字符或模式
    if [[ "$path" =~ [\;\|\&\`\$\(\)] ]]; then
        error "$context: 路径包含可疑字符，可能存在安全风险"
        return 1
    fi
    
    # 检查路径长度（防止缓冲区溢出）
    if [ ${#path} -gt 4096 ]; then
        error "$context: 路径过长，超过4096字符限制"
        return 1
    fi
    
    return 0
}

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

# 统一清理所有已安装应用的quarantine属性
remove_quarantine_from_installed_apps() {
    if [ ${#installed_app_paths[@]} -eq 0 ]; then
        return 0
    fi
    
    echo ""
    echo -e "${BLUE}🔓 正在处理应用权限...${NC}"
    echo "========================================"
    echo -e "${YELLOW}说明：移除已安装应用的隔离属性，确保正常运行${NC}"
    echo ""
    
    local processed=0
    local failed=0
    
    for app_path in "${installed_app_paths[@]}"; do
        if [ -e "$app_path" ]; then
            local app_name=$(basename "$app_path")
            echo -e "  🔓 处理: ${GREEN}$app_name${NC}"
            
            if sudo xattr -rd com.apple.quarantine "$app_path" 2>/dev/null; then
                echo -e "     ✅ 隔离属性移除成功"
                ((processed++))
            else
                echo -e "     ⚠️  隔离属性移除失败（可能不影响使用）"
                ((failed++))
            fi
        fi
    done
    
    echo ""
    if [ $processed -gt 0 ]; then
        echo -e "${GREEN}✅ 已处理 $processed 个应用的权限${NC}"
    fi
    if [ $failed -gt 0 ]; then
        echo -e "${YELLOW}⚠️  $failed 个应用权限处理失败（通常不影响正常使用）${NC}"
    fi
    echo "========================================"
}

# 解析命令行参数
parse_arguments() {
    if [ $# -eq 0 ]; then
        # 新的交互式模式：提示用户拖拽文件夹
        prompt_for_folder
        return
    fi
    
    local installers_path="$1"
    
    # 安全验证：检查路径参数
    if ! validate_path_security "$installers_path" "命令行参数"; then
        exit 1
    fi
    
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
            warn "请输入文件夹路径或将文件夹拖拽到终端窗口"
            continue
        fi
        
        # 清理路径（移除可能的引号和空格）
        installers_path=$(echo "$installers_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//')
        
        # 安全验证：检查用户输入的路径
        if ! validate_path_security "$installers_path" "用户输入"; then
            echo -e "${YELLOW}请重新输入安全的文件夹路径${NC}"
            echo ""
            continue
        fi
        
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
        echo -e "${GREEN}✅ Gatekeeper状态：已启用 (推荐)${NC}"
        echo ""
        echo -e "${BLUE}安全说明：${NC}"
        echo "   • Gatekeeper已启用，系统会验证应用签名"
        echo "   • 这是macOS推荐的安全设置"
        echo "   • 脚本将在安装后自动处理应用权限"
        echo ""
        echo -e "${GREEN}智能处理方案：${NC}"
        echo "   • 保持Gatekeeper启用状态（更安全）"
        echo "   • 安装完成后自动移除应用隔离属性"
        echo "   • 避免系统整体安全性降低"
        echo ""
        echo -e "${YELLOW}如遇到应用无法打开的问题：${NC}"
        echo "   • 右键点击应用 → 选择\"打开\""
        echo "   • 或在\"系统偏好设置 → 安全性与隐私\"中允许"
        echo ""
    elif [ "$gatekeeper_status" = "assessments disabled" ]; then
        echo -e "${YELLOW}⚠️  Gatekeeper状态：已关闭${NC}"
        echo ""
        echo -e "${YELLOW}安全提醒：${NC}"
        echo "   • 当前系统安全保护已关闭"
        echo "   • 建议安装完成后重新启用Gatekeeper"
        echo "   • 重新启用命令：sudo spctl --master-enable"
        echo ""
    else
        echo -e "${YELLOW}❓ Gatekeeper状态：未知${NC}"
        echo "   • 无法确定当前状态"
        echo "   • 将使用默认的安全处理方式"
    fi
    
    echo "================================"
    echo ""
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
    warn "Rosetta未安装"
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
                warn "注意：某些Intel应用可能无法运行"
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
    
    # 遍历本地安装包目录（使用Process Substitution，无临时文件）
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            local filename=$(basename "$file")
            local name_without_ext="${filename%.*}"
            # 清理文件名（移除版本号、特殊字符等）
            local clean_name=$(echo "$name_without_ext" | sed 's/[0-9\.-]*$//' | sed 's/[-_]/ /g' | sed 's/ *$//')
            
            packages_list+=("$clean_name")
            package_files_list+=("$file")
        fi
    done < <(find "$LOCAL_INSTALLERS_DIR" \( -name "*.dmg" -o -name "*.pkg" -o -name "*.zip" -o -name "*.app" \) ! -name "._*" ! -name ".DS_Store")
    
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

# DMG挂载辅助函数
mount_dmg() {
    local dmg_path="$1"
    local description="$2"
    
    echo "  正在挂载${description}: $(basename "$dmg_path")"
    
    # 获取挂载前的挂载点列表
    local mount_before=$(mount | grep "/Volumes" | sed -E 's/^.* on (\/Volumes\/[^(]+) \(.*/\1/' | sed 's/[[:space:]]*$//')
    
    # 使用 yes 命令自动回答许可协议，并重定向输出，添加超时保护
    (yes | hdiutil attach "$dmg_path" -nobrowse -noverify > /dev/null 2>&1) &
    local hdiutil_pid=$!
    
    # 等待最多15秒
    local timeout=15
    local count=0
    while [ $count -lt $timeout ]; do
        if ! kill -0 $hdiutil_pid 2>/dev/null; then
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
    
    sleep 1
    
    # 获取挂载后的挂载点列表
    local mount_after=$(mount | grep "/Volumes" | sed -E 's/^.* on (\/Volumes\/[^(]+) \(.*/\1/' | sed 's/[[:space:]]*$//')
    
    # 找出新增的挂载点
    local mount_point=""
    while IFS= read -r mount_path; do
        local found=0
        while IFS= read -r existing_mount; do
            if [ "$existing_mount" = "$mount_path" ]; then
                found=1
                break
            fi
        done <<< "$mount_before"
        if [ $found -eq 0 ]; then
            mount_point="$mount_path"
            break
        fi
    done <<< "$mount_after"
    
    if [ -n "$mount_point" ] && [ -d "$mount_point" ]; then
        echo "  ✅ ${description}挂载成功: $mount_point"
        echo "$mount_point"  # 返回挂载点路径
        return 0
    else
        echo "  ❌ ${description}挂载失败"
        return 1
    fi
}

# DMG推出辅助函数
unmount_dmg() {
    local mount_point="$1"
    local description="$2"
    
    echo "  正在推出${description}: $(basename "$mount_point")"
    sleep 1
    if sudo hdiutil detach "$mount_point" -quiet 2>/dev/null; then
        echo "  ✅ ${description}推出完成"
    else
        sudo hdiutil detach "$mount_point" -force -quiet 2>/dev/null || true
        echo "  ✅ ${description}强制推出完成"
    fi
}

# 从挂载点安装APP的辅助函数
install_app_from_mount_point() {
    local mount_point="$1"
    local filename="$2"
    local source_description="$3"
    
    # 查找.app文件
    local app_path=""
    shopt -s nullglob
    local app_files=("$mount_point"/*.app)
    if [ ${#app_files[@]} -gt 0 ] && [ -d "${app_files[0]}" ]; then
        app_path="${app_files[0]}"
    fi
    shopt -u nullglob
    
    if [ -n "$app_path" ]; then
        local app_name=$(basename "$app_path")
        echo "  🔍 找到应用: $app_name"
        
        # 使用智能APP覆盖检测
        if check_app_installation "$app_path" "$filename"; then
            local target_app_path="/Applications/$app_name"
            echo "  正在将 '$app_name' 拷贝到 /Applications ..."
            if sudo cp -R "$app_path" "/Applications/"; then
                echo "  拷贝完成"
                installed_app_paths+=("$target_app_path")
                successful_installs+=("$app_name ($source_description)")
                return 0
            else
                error "拷贝失败"
                failed_installs+=("$filename (${source_description}应用拷贝失败: $app_name)")
                return 1
            fi
        fi
        return 0
    else
        return 1  # 未找到.app文件
    fi
}

# 嵌套DMG处理辅助函数
install_from_nested_dmg() {
    local nested_dmg_path="$1"
    local filename="$2"
    local source_description="$3"
    
    local nested_mount_point
    if nested_mount_point=$(mount_dmg "$nested_dmg_path" "嵌套DMG"); then
        # 尝试从嵌套DMG安装应用
        if install_app_from_mount_point "$nested_mount_point" "$filename" "$source_description"; then
            unmount_dmg "$nested_mount_point" "嵌套DMG"
            return 0
        else
            echo "  ❌ 在嵌套DMG中未找到.app文件"
            failed_installs+=("$filename (嵌套DMG中未找到.app文件)")
            unmount_dmg "$nested_mount_point" "嵌套DMG"
            return 1
        fi
    else
        echo "  ❌ 嵌套DMG挂载失败"
        failed_installs+=("$filename (嵌套DMG挂载失败)")
        return 1
    fi
}

# 安装DMG文件（重构后的主函数）
install_dmg_file() {
    local installer_path="$1"
    local filename=$(basename "$installer_path")
    
    echo "  [类型: DMG] - 正在尝试挂载..."
    
    # 挂载主DMG
    local mount_point
    if ! mount_point=$(mount_dmg "$installer_path" "主DMG"); then
        failed_installs+=("$filename (DMG挂载失败)")
        return 1
    fi
    
    # 查找PKG文件并安装（优先级最高）
    local pkg_path=""
    shopt -s nullglob
    local pkg_files=("$mount_point"/*.pkg)
    if [ ${#pkg_files[@]} -gt 0 ] && [ -f "${pkg_files[0]}" ]; then
        pkg_path="${pkg_files[0]}"
    fi
    shopt -u nullglob
    
    if [ -n "$pkg_path" ] && [ -f "$pkg_path" ]; then
        local pkg_name=$(basename "$pkg_path")
        echo "  发现PKG安装包: $pkg_name"
        echo "  正在安装PKG..."
        
        if sudo installer -pkg "$pkg_path" -target /; then
            echo "  PKG安装成功"
            local pkg_base_name=$(basename "$pkg_path" .pkg)
            successful_installs+=("$pkg_base_name (从DMG中的PKG)")
        else
            error "PKG安装失败"
            failed_installs+=("$filename (DMG中的PKG安装失败)")
        fi
    else
        # 没有PKG，尝试安装.app文件
        echo "  查找 .app 文件..."
        
        # 尝试直接从主DMG安装应用
        if install_app_from_mount_point "$mount_point" "$filename" "从DMG"; then
            echo "  ✅ 主DMG安装完成"
        else
            # 主DMG中没有.app，检查嵌套结构
            echo "  未找到 .app 文件，检查嵌套安装结构..."
            
            # 查找Manual install目录
            local manual_install_dir=$(find "$mount_point" -name "*[Mm]anual*install*" -type d 2>/dev/null | head -1)
            
            if [ -n "$manual_install_dir" ]; then
                echo "  📁 发现嵌套安装结构: $(basename "$manual_install_dir")"
                
                # 在Manual install目录中查找DMG文件
                local manual_install_dmg=$(find "$manual_install_dir" -name "*.dmg" 2>/dev/null | head -1)
                
                if [ -n "$manual_install_dmg" ]; then
                    # 安装嵌套DMG
                    install_from_nested_dmg "$manual_install_dmg" "$filename" "嵌套DMG"
                else
                    # 直接在Manual install目录查找.app
                    echo "  🔍 安装目录中未找到DMG文件，直接查找.app文件..."
                    if ! install_app_from_mount_point "$manual_install_dir" "$filename" "嵌套安装"; then
                        echo "  ❌ 在安装目录中也未找到 .app 文件"
                        failed_installs+=("$filename (安装目录中未找到.app文件)")
                    fi
                fi
            else
                # 查找其他嵌套DMG文件（备用方案）
                echo "  🔍 查找其他嵌套DMG文件..."
                local nested_dmg=$(find "$mount_point" -name "*[Mm]anual*install*.dmg" -o -name "*[Mm]anual*.dmg" -o -name "*install*.dmg" 2>/dev/null | head -1)
                
                if [ -z "$nested_dmg" ]; then
                    # 查找任何DMG文件
                    nested_dmg=$(find "$mount_point" -name "*.dmg" -type f 2>/dev/null | head -1)
                fi
                
                if [ -n "$nested_dmg" ]; then
                    # 安装嵌套DMG
                    install_from_nested_dmg "$nested_dmg" "$filename" "嵌套DMG"
                else
                    # 完全没找到可安装的内容
                    echo "  ❌ 在DMG中未找到 .app 文件、安装目录或嵌套DMG文件"
                    echo "  📁 DMG内容列表："
                    ls -la "$mount_point" | head -10
                    failed_installs+=("$filename (DMG中未找到可安装的内容)")
                fi
            fi
        fi
    fi
    
    # 推出主DMG
    unmount_dmg "$mount_point" "主DMG"
}

# 检查PKG是否已安装
check_pkg_installation() {
    local installer_path="$1"
    local filename=$(basename "$installer_path")
    
    echo "  FIND: 检查PKG是否已安装..."
    
    # 创建临时目录来提取PKG信息（原子操作设置权限，避免竞态条件）
    local temp_dir=$(mktemp -d -t installflow_pkg.XXXXXX -m 700)
    if [ ! -d "$temp_dir" ]; then
        error "无法创建临时目录"
        return 0  # 默认允许安装
    fi
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
                    warn "PKG '$pkg_id' 已安装，跳过安装"
                    bypassed_installs+=("$filename (PKG已安装: $pkg_id)")
                    return 1
                fi
            fi
        fi
    fi
    
    # temp_dir将由cleanup函数统一清理
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
        error "PKG 安装失败"
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
        
        # 记录已安装应用路径，稍后统一处理权限
        installed_app_paths+=("$TARGET_APP_PATH")
        
        successful_installs+=("$APP_NAME (直接安装)")
    else
        error "拷贝失败"
        failed_installs+=("$filename (应用拷贝失败: $APP_NAME)")
    fi
}

# 安装ZIP文件
install_zip_file() {
    local installer_path="$1"
    local filename=$(basename "$installer_path")
    
    echo "  [类型: ZIP] - 正在解压..."
    
    # 创建临时解压目录（原子操作设置权限，避免竞态条件）
    local temp_extract=$(mktemp -d -t installflow_zip.XXXXXX -m 700)
    if [ ! -d "$temp_extract" ]; then
        error "无法创建临时目录"
        failed_installs+=("$filename (无法创建临时目录)")
        return
    fi
    temp_files+=("$temp_extract")  # 添加到临时文件追踪数组
    
    # 解压ZIP文件并检查是否成功
    if ! unzip -q "$installer_path" -d "$temp_extract"; then
        error "ZIP文件解压失败"
        failed_installs+=("$filename (ZIP解压失败)")
        return
    fi
    
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
                
                # 记录已安装应用路径，稍后统一处理权限
                installed_app_paths+=("$TARGET_APP_PATH")
                
                successful_installs+=("$APP_NAME (从ZIP)")
            else
                error "拷贝失败"
                failed_installs+=("$filename (应用拷贝失败: $APP_NAME)")
            fi
        fi
    else
        error "在ZIP中未找到 .app 文件"
        failed_installs+=("$filename (ZIP中未找到.app文件)")
    fi
    
    # temp_extract将由cleanup函数统一清理
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
    
    echo ""
    echo "🔔 叮当装正在为您安装应用..."
    echo "========================================"
    
    # 清空全局安装结果数组
    successful_installs=()
    failed_installs=()
    bypassed_installs=()
    updated_installs=()
    installed_app_paths=()  # 清空已安装应用路径追踪数组
    
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
    
    # 安装完成后统一处理应用权限
    remove_quarantine_from_installed_apps
    
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

